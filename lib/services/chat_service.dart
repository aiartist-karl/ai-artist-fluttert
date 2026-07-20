import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 聊天服务 - 封装 API 调用
/// 对应 Android ChatScreen.kt 中的网络请求逻辑
class ChatService {
  // ==================== SharedPreferences keys ====================
  static const String _keyChatApiType = 'chat_api_type';
  static const String _keyOllamaHost = 'ollama_host';
  static const String _keyOllamaModel = 'ollama_model';
  static const String _keyOpenAIHost = 'openai_host';
  static const String _keyOpenAIApiKey = 'openai_api_key';
  static const String _keyOpenAIModel = 'openai_model';

  // ==================== Config getters ====================
  static Future<String> getChatApiType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyChatApiType) ?? 'ollama';
  }

  static Future<String> getOllamaHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOllamaHost) ?? 'http://10.0.2.2:11434';
  }

  static Future<String> getOllamaModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOllamaModel) ?? 'deepseek-r1-distill-qwen-14b';
  }

  static Future<String> getOpenAIHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenAIHost) ?? '';
  }

  static Future<String> getOpenAIApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenAIApiKey) ?? '';
  }

  static Future<String> getOpenAIModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenAIModel) ?? 'deepseek-chat';
  }

  // ==================== Chat history ====================
  static Future<String> getChatHistoryForAgent(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chat_history_$agentId') ?? '[]';
  }

  static Future<void> saveChatHistoryForAgent(String agentId, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history_$agentId', json);
  }

  static Future<void> clearChatHistoryForAgent(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history_$agentId');
  }

  // ==================== Ollama streaming ====================
  static Stream<String> streamOllamaChat({
    required String host,
    required String model,
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String? imageBase64,
  }) async* {
    // Placeholder - in real app, make HTTP request to Ollama API
    yield 'Ollama 流式响应占位';
  }

  // ==================== OpenAI streaming ====================
  static Stream<String> streamOpenAIChat({
    required String host,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String? imageBase64,
  }) async* {
    // Placeholder - in real app, make HTTP request to OpenAI API
    yield 'OpenAI 流式响应占位';
  }
}
