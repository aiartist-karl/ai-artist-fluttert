import 'package:flutter/foundation.dart';
import '../models/agent_model.dart';
import '../services/agent_service.dart';

/// Agent 状态管理
/// 参考 Android AgentRepository.kt 的逻辑
class AgentProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================
  final List<Agent> _agents = [];
  String _activeAgentId = 'default';
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================
  List<Agent> get agents => List.unmodifiable(_agents);
  String get activeAgentId => _activeAgentId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 当前激活的 Agent
  Agent get activeAgent {
    if (_agents.isEmpty) return Agent.defaultAgent();
    return _agents.firstWhere(
      (a) => a.id == _activeAgentId,
      orElse: () => _agents.first,
    );
  }

  /// Agent 数量
  int get agentCount => _agents.length;

  // ==================== 操作方法 ====================

  /// 加载所有 Agent 列表
  Future<void> loadAgents() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final loadedAgents = await AgentService.loadAgents();
      _agents
        ..clear()
        ..addAll(loadedAgents);

      // 如果列表为空，加载默认 Agent
      if (_agents.isEmpty) {
        _agents.add(Agent.defaultAgent());
        await _persistAgents();
      }

      _activeAgentId = await AgentService.getActiveAgentId();
      // 验证 activeAgentId 是否存在于列表中
      if (!_agents.any((a) => a.id == _activeAgentId)) {
        _activeAgentId = _agents.first.id;
      }
    } catch (e) {
      _errorMessage = '加载 Agent 列表失败: ${e.toString()}';
      // 加载失败时使用默认 Agent
      _agents
        ..clear()
        ..add(Agent.defaultAgent());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换激活的 Agent
  Future<void> setActiveAgent(String agentId) async {
    if (_activeAgentId == agentId) return;
    if (!_agents.any((a) => a.id == agentId)) return;

    _activeAgentId = agentId;
    notifyListeners();

    try {
      await AgentService.setActiveAgentId(agentId);
    } catch (e) {
      debugPrint('保存激活 Agent 失败: $e');
    }
  }

  /// 添加新 Agent
  Future<void> addAgent(Agent agent) async {
    _agents.add(agent);
    notifyListeners();

    try {
      await _persistAgents();
    } catch (e) {
      _agents.removeLast();
      _errorMessage = '添加 Agent 失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 创建新 Agent 并返回生成的 ID
  Future<String> createAgent({
    required String name,
    String description = '',
    String emoji = '🤖',
    String systemPrompt = '',
    String apiType = 'openai',
    String host = '',
    String apiKey = '',
    String model = '',
  }) async {
    final agentId = Agent.generateId();
    final agent = Agent(
      id: agentId,
      name: name,
      description: description,
      emoji: emoji,
      systemPrompt: systemPrompt,
      apiType: apiType,
      host: host,
      apiKey: apiKey,
      model: model,
    );

    _agents.add(agent);
    notifyListeners();

    try {
      await _persistAgents();
    } catch (e) {
      _agents.removeLast();
      _errorMessage = '创建 Agent 失败: ${e.toString()}';
      notifyListeners();
      return '';
    }

    return agentId;
  }

  /// 更新 Agent
  Future<void> updateAgent(Agent agent) async {
    final idx = _agents.indexWhere((a) => a.id == agent.id);
    if (idx < 0) return;

    final oldAgent = _agents[idx];
    _agents[idx] = agent;
    notifyListeners();

    try {
      await _persistAgents();
    } catch (e) {
      _agents[idx] = oldAgent;
      _errorMessage = '更新 Agent 失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 删除 Agent
  Future<void> deleteAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;

    final removedAgent = _agents.removeAt(idx);

    // 如果删光了，恢复默认 Agent
    if (_agents.isEmpty) {
      _agents.add(Agent.defaultAgent());
    }

    // 如果删除的是当前激活的，切换到第一个
    if (_activeAgentId == agentId) {
      _activeAgentId = _agents.first.id;
      await AgentService.setActiveAgentId(_activeAgentId);
    }

    notifyListeners();

    try {
      await _persistAgents();
    } catch (e) {
      _agents.insert(idx, removedAgent);
      _errorMessage = '删除 Agent 失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 根据 ID 获取 Agent
  Agent? getAgentById(String id) {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 清除错误
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 私有方法 ====================

  /// 持久化 Agent 列表到本地存储
  Future<void> _persistAgents() async {
    await AgentService.saveAgents(_agents);
  }

  void _clearError() {
    _errorMessage = null;
  }
}
