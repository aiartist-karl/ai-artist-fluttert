import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/agent_model.dart';
import '../services/chat_service.dart';
import '../services/function_calling_service.dart';

/// 对话状态管理
/// 参考 Android ChatScreen.kt + FunctionCallingManager.kt 的逻辑
class ChatProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _inputText = '';
  Agent? _currentAgent;
  bool _isLoadingHistory = false;
  String? _historyLoadedForAgent;
  StreamSubscription? _streamSubscription;
  Map<String, String> _toolProgress = {};
  String? _errorMessage;

  // 连续工具调用失败计数
  int _consecutiveToolFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const int _maxToolRounds = 30;

  // ==================== Getters ====================
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get inputText => _inputText;
  Agent? get currentAgent => _currentAgent;
  bool get isLoadingHistory => _isLoadingHistory;
  Map<String, String> get toolProgress => Map.unmodifiable(_toolProgress);
  String? get errorMessage => _errorMessage;
  int get consecutiveToolFailures => _consecutiveToolFailures;

  // ==================== 操作方法 ====================

  /// 设置输入文本
  void setInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  /// 设置当前 Agent
  void setCurrentAgent(Agent agent) {
    _currentAgent = agent;
    // 切换 agent 时重置历史加载标记
    _historyLoadedForAgent = null;
    notifyListeners();
  }

  /// 添加消息到列表
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// 更新最后一条助手消息（用于流式更新）
  void updateLastAssistantMessage(String content) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'assistant') {
        _messages[i] = _messages[i].copyWith(content: content, isLoading: false);
        notifyListeners();
        return;
      }
    }
  }

  /// 发送消息（支持流式回复）
  Future<void> sendMessage({String? imageBase64}) async {
    if (_inputText.trim().isEmpty && imageBase64 == null) return;
    if (_isLoading) return;

    final userContent = _inputText.trim();
    _inputText = '';

    // 添加用户消息
    final userMessage = ChatMessage(
      role: 'user',
      content: userContent,
      imageBase64: imageBase64,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _messages.add(userMessage);

    // 添加 AI 加载占位消息
    final aiPlaceholder = ChatMessage(
      role: 'assistant',
      content: '',
      isLoading: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _messages.add(aiPlaceholder);

    _isLoading = true;
    _consecutiveToolFailures = 0;
    _toolProgress = {};
    _clearError();
    notifyListeners();

    try {
      // 解析 API 配置：agent 覆盖 > 全局偏好
      final apiType = _currentAgent?.apiType.isNotEmpty == true
          ? _currentAgent!.apiType
          : await ChatService.getChatApiType();

      final effectiveHost = _currentAgent?.host.isNotEmpty == true
          ? _currentAgent!.host
          : null;
      final effectiveApiKey = _currentAgent?.apiKey.isNotEmpty == true
          ? _currentAgent!.apiKey
          : null;
      final effectiveModel = _currentAgent?.model.isNotEmpty == true
          ? _currentAgent!.model
          : null;
      final systemPrompt = _currentAgent?.systemPrompt.isNotEmpty == true
          ? _currentAgent!.systemPrompt
          : '';

      // 构建历史消息（过滤 isLoading 的占位消息）
      final historyMessages = _messages
          .where((m) => !m.isLoading)
          .toList();

      if (apiType == 'ollama') {
        await _handleOllamaStream(
          host: effectiveHost,
          model: effectiveModel,
          systemPrompt: systemPrompt,
          history: historyMessages,
          imageBase64: imageBase64,
        );
      } else {
        await _handleOpenAIStream(
          host: effectiveHost,
          apiKey: effectiveApiKey,
          model: effectiveModel,
          systemPrompt: systemPrompt,
          history: historyMessages,
          imageBase64: imageBase64,
        );
      }
    } catch (e) {
      _updateLastAssistantContent('❌ 请求失败: ${e.toString()}');
    } finally {
      _isLoading = false;
      _toolProgress = {};
      notifyListeners();
    }
  }

  /// Ollama API 流式处理
  Future<void> _handleOllamaStream({
    String? host,
    String? model,
    required String systemPrompt,
    required List<ChatMessage> history,
    String? imageBase64,
  }) async {
    final resolvedHost = host ?? await ChatService.getOllamaHost();
    final resolvedModel = model ?? await ChatService.getOllamaModel();

    // 构建消息数组
    final messagesList = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      messagesList.add({'role': 'system', 'content': systemPrompt});
    }

    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      if (msg.isLoading) continue;

      final msgMap = <String, dynamic>{
        'role': msg.role,
        'content': msg.content,
      };

      // 最后一条用户消息如果有图片，附加 images
      if (msg.role == 'user' && msg.imageBase64 != null && i == history.length - 1) {
        msgMap['images'] = [msg.imageBase64];
      }
      messagesList.add(msgMap);
    }

    int round = 0;
    var currentMessages = List<Map<String, dynamic>>.from(messagesList);

    while (round < _maxToolRounds) {
      round++;

      // 通过流式回调处理 SSE
      final fullResponse = StringBuffer();
      final pendingToolCalls = <Map<String, dynamic>>[];

      await for (final chunk in ChatService.streamOllamaChat(
        host: resolvedHost,
        model: resolvedModel,
        messages: currentMessages,
      )) {
        if (chunk['done'] == true) {
          // 最终消息中可能包含 tool_calls
          final messageObj = chunk['message'] as Map<String, dynamic>?;
          if (messageObj != null) {
            final toolCalls = messageObj['tool_calls'] as List?;
            if (toolCalls != null) {
              for (final tc in toolCalls) {
                final fnObj = tc['function'] as Map<String, dynamic>?;
                if (fnObj != null) {
                  pendingToolCalls.add({
                    'id': tc['id'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
                    'name': fnObj['name'] ?? '',
                    'arguments': fnObj['arguments'] ?? '{}',
                  });
                }
              }
            }
            final content = messageObj['content']?.toString() ?? '';
            if (content.isNotEmpty && content != 'null') {
              fullResponse.write(content);
            }
          }
        } else {
          final messageObj = chunk['message'] as Map<String, dynamic>?;
          if (messageObj != null) {
            // 检查 tool_calls
            final toolCalls = messageObj['tool_calls'] as List?;
            if (toolCalls != null && toolCalls.isNotEmpty) {
              for (final tc in toolCalls) {
                final fnObj = tc['function'] as Map<String, dynamic>?;
                if (fnObj != null) {
                  pendingToolCalls.add({
                    'id': tc['id'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
                    'name': fnObj['name'] ?? '',
                    'arguments': fnObj['arguments'] ?? '{}',
                  });
                }
              }
            }
            final content = messageObj['content']?.toString() ?? '';
            if (content.isNotEmpty && content != 'null') {
              fullResponse.write(content);
              _updateLastAssistantContent(fullResponse.toString());
            }
          }
        }
      }

      if (pendingToolCalls.isNotEmpty) {
        // 添加 assistant 消息到对话上下文
        currentMessages.add({
          'role': 'assistant',
          'content': fullResponse.toString().isNotEmpty ? fullResponse.toString() : null,
          'tool_calls': pendingToolCalls,
        });

        // 如果有中间文本，先显示
        if (fullResponse.toString().trim().isNotEmpty) {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: _filterThinkingContent(fullResponse.toString()),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
          notifyListeners();
        }

        // 显示工具调用进度
        _toolProgress = {
          for (final tc in pendingToolCalls)
            tc['name'] as String: _getToolProgressText(tc['name'] as String),
        };
        notifyListeners();

        // 并行执行工具
        final toolResults = await FunctionCallingService.executeToolsParallel(
          pendingToolCalls.map((tc) => {
            'id': tc['id'],
            'name': tc['name'],
            'arguments': tc['arguments'],
          }).toList(),
        );

        // 将工具结果添加到上下文
        for (final result in toolResults) {
          if (result['success'] == true) {
            _onToolSuccess();
          } else {
            final shouldBreak = _onToolFailure();
            if (shouldBreak) {
              _updateLastAssistantContent(
                '⚠️ 工具连续失败$_consecutiveToolFailures次，已暂停。请检查配置。',
              );
              return;
            }
          }

          currentMessages.add({
            'role': 'tool',
            'content': result['success'] == true
                ? result['result']
                : '工具调用失败: ${result['error'] ?? "未知错误"}，请如实告知用户失败原因',
          });

          // 检查是否有图片生成结果
          final imageUrl = _extractImageUrl(result['result']?.toString() ?? '');
          if (imageUrl != null) {
            _messages.add(ChatMessage(
              role: 'assistant',
              content: '🖼️ 图片已生成',
              imageUrl: imageUrl,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));
            notifyListeners();
          }
        }

        _toolProgress = {'thinking': '🤔 正在思考...'};
        notifyListeners();
      } else {
        // 没有工具调用，这是最终回复
        _updateLastAssistantContent(_filterThinkingContent(fullResponse.toString()));
        return;
      }
    }

    // 达到最大轮次
    _updateLastAssistantContent(
      _filterThinkingContent('⚠️ 已执行 $_maxToolRounds 轮工具调用，达到上限。如果要继续，请告诉我。'),
    );
  }

  /// OpenAI Compatible API 流式处理
  Future<void> _handleOpenAIStream({
    String? host,
    String? apiKey,
    String? model,
    required String systemPrompt,
    required List<ChatMessage> history,
    String? imageBase64,
  }) async {
    final resolvedHost = host ?? await ChatService.getOpenAIHost();
    final resolvedApiKey = apiKey ?? await ChatService.getOpenAIApiKey();
    final resolvedModel = model ?? await ChatService.getOpenAIModel();

    if (resolvedHost.isEmpty) {
      _updateLastAssistantContent('请先在 API 设置中填写兼容 API 地址');
      return;
    }

    // 构建 URL
    final baseUrl = resolvedHost.trimRight().replaceAll(RegExp(r'/+$'), '');
    String url;
    if (baseUrl.endsWith('/chat/completions') || baseUrl.endsWith('/v1/chat/completions')) {
      url = baseUrl;
    } else if (RegExp(r'.*/v\d+$').hasMatch(baseUrl)) {
      url = '$baseUrl/chat/completions';
    } else {
      url = '$baseUrl/v1/chat/completions';
    }

    // 构建消息数组
    final messagesList = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      messagesList.add({'role': 'system', 'content': systemPrompt});
    }

    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      if (msg.isLoading) continue;

      if (msg.role == 'user' && msg.imageBase64 != null && i == history.length - 1) {
        // 带图片的消息使用 multimodal 格式
        messagesList.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': msg.content},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,${msg.imageBase64}'},
            },
          ],
        });
      } else {
        messagesList.add({'role': msg.role, 'content': msg.content});
      }
    }

    // 获取可用工具定义
    final tools = FunctionCallingService.getAvailableTools();
    final toolsArray = tools.map((t) => t.toOpenAITool()).toList();

    int round = 0;
    var currentMessages = List<Map<String, dynamic>>.from(messagesList);

    while (round < _maxToolRounds) {
      round++;

      final fullResponse = StringBuffer();
      // 累积 tool_calls: Map<index, {id, name, arguments}>
      final toolCallAccumulator = <int, Map<String, StringBuffer>>{};

      await for (final chunk in ChatService.streamOpenAIChat(
        url: url,
        apiKey: resolvedApiKey,
        model: resolvedModel,
        messages: currentMessages,
        tools: toolsArray,
      )) {
        final choices = chunk['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;

        final delta = choices[0]['delta'] as Map<String, dynamic>?;
        if (delta == null) continue;

        // 累积文本内容
        final content = delta['content']?.toString() ?? '';
        if (content.isNotEmpty && content != 'null') {
          fullResponse.write(content);
          _updateLastAssistantContent(fullResponse.toString());
        }

        // 累积 tool_calls
        final tcArray = delta['tool_calls'] as List?;
        if (tcArray != null) {
          for (int i = 0; i < tcArray.length; i++) {
            final tc = tcArray[i] as Map<String, dynamic>;
            final idx = tc['index'] as int? ?? i;
            final entry = toolCallAccumulator.putIfAbsent(idx, () => {
              'id': StringBuffer(),
              'name': StringBuffer(),
              'arguments': StringBuffer(),
            });

            if (tc['id'] != null) entry['id']!.write(tc['id']);
            final fnObj = tc['function'] as Map<String, dynamic>?;
            if (fnObj != null) {
              if (fnObj['name'] != null) entry['name']!.write(fnObj['name']);
              if (fnObj['arguments'] != null) entry['arguments']!.write(fnObj['arguments']);
            }
          }
        }
      }

      // 解析累积的 tool_calls
      final pendingToolCalls = <Map<String, dynamic>>[];
      if (toolCallAccumulator.isNotEmpty) {
        final sortedKeys = toolCallAccumulator.keys.toList()..sort();
        for (final idx in sortedKeys) {
          final parts = toolCallAccumulator[idx]!;
          final tcId = parts['id']!.toString().isNotEmpty
              ? parts['id']!.toString()
              : 'call_${DateTime.now().millisecondsSinceEpoch}_$idx';
          final tcName = parts['name']!.toString();
          final tcArgs = parts['arguments']!.toString().isNotEmpty
              ? parts['arguments']!.toString()
              : '{}';

          if (tcName.isNotEmpty) {
            pendingToolCalls.add({
              'id': tcId,
              'name': tcName,
              'arguments': tcArgs,
            });
          }
        }
      }

      if (pendingToolCalls.isNotEmpty) {
        // 添加 assistant 消息到对话上下文
        final assistantMsg = <String, dynamic>{
          'role': 'assistant',
        };
        if (fullResponse.toString().trim().isNotEmpty) {
          assistantMsg['content'] = fullResponse.toString();
        } else {
          assistantMsg['content'] = null;
        }
        assistantMsg['tool_calls'] = pendingToolCalls.map((tc) => {
          'id': tc['id'],
          'type': 'function',
          'function': {
            'name': tc['name'],
            'arguments': tc['arguments'],
          },
        }).toList();
        currentMessages.add(assistantMsg);

        // 中间文本回复
        if (fullResponse.toString().trim().isNotEmpty) {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: _filterThinkingContent(fullResponse.toString()),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
          notifyListeners();
        }

        // 工具进度
        _toolProgress = {
          for (final tc in pendingToolCalls)
            tc['name'] as String: _getToolProgressText(tc['name'] as String),
        };
        notifyListeners();

        // 并行执行工具
        final toolResults = await FunctionCallingService.executeToolsParallel(
          pendingToolCalls.map((tc) => {
            'id': tc['id'],
            'name': tc['name'],
            'arguments': tc['arguments'],
          }).toList(),
        );

        for (final result in toolResults) {
          if (result['success'] == true) {
            _onToolSuccess();
          } else {
            final shouldBreak = _onToolFailure();
            if (shouldBreak) {
              _updateLastAssistantContent(
                '⚠️ 工具连续失败$_consecutiveToolFailures次，已暂停。请检查配置。',
              );
              return;
            }
          }

          currentMessages.add({
            'role': 'tool',
            'tool_call_id': result['callId'] ?? '',
            'content': result['success'] == true
                ? result['result']
                : '工具调用失败: ${result['error'] ?? "未知错误"}，请如实告知用户失败原因',
          });

          final imageUrl = _extractImageUrl(result['result']?.toString() ?? '');
          if (imageUrl != null) {
            _messages.add(ChatMessage(
              role: 'assistant',
              content: '🖼️ 图片已生成',
              imageUrl: imageUrl,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));
            notifyListeners();
          }
        }

        _toolProgress = {'thinking': '🤔 正在思考...'};
        notifyListeners();
      } else {
        _updateLastAssistantContent(_filterThinkingContent(fullResponse.toString()));
        return;
      }
    }

    _updateLastAssistantContent(
      _filterThinkingContent('⚠️ 已执行 $_maxToolRounds 轮工具调用，达到上限。如果要继续，请告诉我。'),
    );
  }

  /// 停止当前请求
  void stop() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isLoading = false;
    // 移除 isLoading 占位
    if (_messages.isNotEmpty && _messages.last.isLoading) {
      _messages.removeLast();
    }
    notifyListeners();
  }

  /// 加载 Agent 的历史对话
  Future<void> loadHistoryForAgent(String agentId) async {
    if (_historyLoadedForAgent == agentId) return;
    _historyLoadedForAgent = agentId;
    _isLoadingHistory = true;
    _messages.clear();
    notifyListeners();

    try {
      final historyJson = await ChatService.getChatHistoryForAgent(agentId);
      final List<dynamic> historyList = jsonDecode(historyJson) as List;
      for (final item in historyList) {
        final map = item as Map<String, dynamic>;
        _messages.add(ChatMessage(
          role: map['role'] as String,
          content: map['content'] as String,
          timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ));
      }
    } catch (e) {
      debugPrint('加载历史失败: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// 保存当前对话历史
  Future<void> saveHistory() async {
    if (_currentAgent == null) return;
    try {
      final historyList = _messages
          .where((m) => !m.isLoading)
          .map((m) => {
            'role': m.role,
            'content': m.content,
            'timestamp': m.timestamp,
          })
          .toList();
      await ChatService.saveChatHistoryForAgent(
        _currentAgent!.id,
        jsonEncode(historyList),
      );
    } catch (e) {
      debugPrint('保存历史失败: $e');
    }
  }

  /// 清空当前对话
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// 删除指定消息
  void removeMessageAt(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  /// 重新生成最后一条 AI 回复
  Future<void> regenerate() async {
    if (_messages.isEmpty) return;

    // 找到最后一条用户消息
    String? lastUserContent;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        lastUserContent = _messages[i].content;
        break;
      }
    }
    if (lastUserContent == null) return;

    // 移除最后一条 AI 回复
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'assistant') {
        _messages.removeAt(i);
        break;
      }
    }

    _inputText = lastUserContent;
    // 移除最后一条用户消息（因为 sendMessage 会重新添加）
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user' && _messages[i].content == lastUserContent) {
        _messages.removeAt(i);
        break;
      }
    }
    await sendMessage();
  }

  /// 清除错误
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 私有方法 ====================
  void _updateLastAssistantContent(String content) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'assistant') {
        _messages[i] = _messages[i].copyWith(
          content: content,
          isLoading: content.isEmpty,
        );
        notifyListeners();
        return;
      }
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _onToolSuccess() {
    _consecutiveToolFailures = 0;
  }

  bool _onToolFailure() {
    _consecutiveToolFailures++;
    return _consecutiveToolFailures >= _maxConsecutiveFailures;
  }

  /// 过滤 <think>...</think> 标签内容
  String _filterThinkingContent(String text) {
    return text.replaceAll(RegExp(r'<think>[\s\S]*?</think>', dotAll: true), '').trim();
  }

  /// 获取工具进度文本
  String _getToolProgressText(String toolName) {
    switch (toolName) {
      case 'generate_image':
      case 'generate_image_local':
      case 'generate_image_cloud':
        return '🎨 正在生成图片...';
      case 'search_web':
        return '🔍 正在搜索...';
      case 'fetch_url':
        return '📄 正在读取网页...';
      case 'calculator':
        return '🧮 正在计算...';
      case 'analyze_image':
        return '🖼️ 正在分析图片...';
      case 'read_file':
      case 'write_file':
        return '📁 文件操作中...';
      default:
        return '⚙️ 正在执行 $toolName...';
    }
  }

  /// 从文本中提取图片 URL
  String? _extractImageUrl(String text) {
    final match = RegExp(r'content://[^\s]+').firstMatch(text);
    return match?.group(0);
  }
}
