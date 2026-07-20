import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 偏好设置服务 - 封装 SharedPreferences 读写
class PreferencesService {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ==================== 基础类型读写 ====================

  static Future<String> getString(String key, {String defaultValue = ''}) async {
    final p = await _prefs;
    return p.getString(key) ?? defaultValue;
  }

  static Future<void> setString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final p = await _prefs;
    return p.getInt(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    final p = await _prefs;
    await p.setInt(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await _prefs;
    return p.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  static Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final p = await _prefs;
    return p.getDouble(key) ?? defaultValue;
  }

  static Future<void> setDouble(String key, double value) async {
    final p = await _prefs;
    await p.setDouble(key, value);
  }

  // ==================== 主题相关 ====================

  static Future<String> getThemeMode() async {
    return getString('theme_mode', defaultValue: 'system');
  }

  static Future<void> saveThemeMode(String mode) async {
    await setString('theme_mode', mode);
  }

  static Future<String> getColorScheme() async {
    return getString('color_scheme', defaultValue: 'default');
  }

  static Future<void> saveColorScheme(String scheme) async {
    await setString('color_scheme', scheme);
  }

  // ==================== Chat API 配置 ====================

  static Future<String> getChatApiType() async {
    return getString('chat_api_type', defaultValue: 'ollama');
  }

  static Future<void> saveChatApiType(String type) async {
    await setString('chat_api_type', type);
  }

  static Future<String> getOllamaHost() async {
    return getString('ollama_host', defaultValue: 'http://10.0.2.2:11434');
  }

  static Future<void> saveOllamaHost(String host) async {
    await setString('ollama_host', host);
  }

  static Future<String> getOllamaModel() async {
    return getString('ollama_model', defaultValue: 'deepseek-r1-distill-qwen-14b');
  }

  static Future<void> saveOllamaModel(String model) async {
    await setString('ollama_model', model);
  }

  static Future<String> getOpenAIHost() async {
    return getString('openai_host', defaultValue: '');
  }

  static Future<void> saveOpenAIHost(String host) async {
    await setString('openai_host', host);
  }

  static Future<String> getOpenAIApiKey() async {
    return getString('openai_api_key', defaultValue: '');
  }

  static Future<void> saveOpenAIApiKey(String key) async {
    await setString('openai_api_key', key);
  }

  static Future<String> getOpenAIModel() async {
    return getString('openai_model', defaultValue: 'deepseek-chat');
  }

  static Future<void> saveOpenAIModel(String model) async {
    await setString('openai_model', model);
  }

  // ==================== 工具 API 配置 ====================

  static Future<String> getToolApiUrl() async {
    return getString('tool_api_url', defaultValue: '');
  }

  static Future<void> saveToolApiUrl(String url) async {
    await setString('tool_api_url', url);
  }

  static Future<String> getToolApiKey() async {
    return getString('tool_api_key', defaultValue: '');
  }

  static Future<void> saveToolApiKey(String key) async {
    await setString('tool_api_key', key);
  }

  static Future<String> getToolApiModel() async {
    return getString('tool_api_model', defaultValue: '');
  }

  static Future<void> saveToolApiModel(String model) async {
    await setString('tool_api_model', model);
  }

  static Future<String> getToolApiType() async {
    return getString('tool_api_type', defaultValue: '');
  }

  static Future<void> saveToolApiType(String type) async {
    await setString('tool_api_type', type);
  }

  // ==================== 本地 ComfyUI 配置 ====================

  static Future<String> getLocalImageApiUrl() async {
    return getString('local_image_api_url', defaultValue: '');
  }

  static Future<void> saveLocalImageApiUrl(String url) async {
    await setString('local_image_api_url', url);
  }

  // ==================== 图片生成 API 配置 ====================

  static Future<String> getImageApiUrl() async {
    return getString('image_api_url', defaultValue: '');
  }

  static Future<void> saveImageApiUrl(String url) async {
    await setString('image_api_url', url);
  }

  static Future<String> getImageApiKey() async {
    return getString('image_api_key', defaultValue: '');
  }

  static Future<void> saveImageApiKey(String key) async {
    await setString('image_api_key', key);
  }

  // ==================== 构建服务器配置 ====================

  static Future<String> getBuildServerUrl() async {
    return getString('build_server_url', defaultValue: '');
  }

  static Future<void> saveBuildServerUrl(String url) async {
    await setString('build_server_url', url);
  }

  static Future<String> getBuildServerToken() async {
    return getString('build_server_token', defaultValue: '');
  }

  static Future<void> saveBuildServerToken(String token) async {
    await setString('build_server_token', token);
  }

  // ==================== 记忆相关 ====================

  static Future<int> getMemoryContextCount() async {
    return getInt('memory_context_count', defaultValue: 5);
  }

  static Future<void> saveMemoryContextCount(int count) async {
    await setInt('memory_context_count', count);
  }

  // ==================== 上下文摘要 ====================

  static Future<bool> getContextSummaryEnabled() async {
    return getBool('context_summary_enabled', defaultValue: true);
  }

  static Future<void> saveContextSummaryEnabled(bool enabled) async {
    await setBool('context_summary_enabled', enabled);
  }

  static Future<int> getContextSummaryThreshold() async {
    return getInt('context_summary_threshold', defaultValue: 20);
  }

  static Future<void> saveContextSummaryThreshold(int threshold) async {
    await setInt('context_summary_threshold', threshold);
  }

  // ==================== TTS 配置 ====================

  static Future<bool> getTtsEnabled() async {
    return getBool('tts_enabled', defaultValue: false);
  }

  static Future<void> saveTtsEnabled(bool enabled) async {
    await setBool('tts_enabled', enabled);
  }

  static Future<double> getTtsSpeed() async {
    return getDouble('tts_speed', defaultValue: 1.0);
  }

  static Future<void> saveTtsSpeed(double speed) async {
    await setDouble('tts_speed', speed);
  }

  static Future<String> getTtsVoiceType() async {
    return getString('tts_voice_type', defaultValue: 'zh_female_cancan_mars_bigtts');
  }

  static Future<void> saveTtsVoiceType(String voiceType) async {
    await setString('tts_voice_type', voiceType);
  }

  static Future<String> getTtsAppId() async {
    return getString('tts_app_id', defaultValue: '');
  }

  static Future<void> saveTtsAppId(String appId) async {
    await setString('tts_app_id', appId);
  }

  static Future<String> getTtsAccessToken() async {
    return getString('tts_access_token', defaultValue: '');
  }

  static Future<void> saveTtsAccessToken(String token) async {
    await setString('tts_access_token', token);
  }

  static Future<bool> getSpeechInputEnabled() async {
    return getBool('speech_input_enabled', defaultValue: false);
  }

  static Future<void> saveSpeechInputEnabled(bool enabled) async {
    await setBool('speech_input_enabled', enabled);
  }

  // ==================== Webhook 配置 ====================

  static Future<String> getWebhookUrl() async {
    return getString('webhook_url', defaultValue: '');
  }

  static Future<void> saveWebhookUrl(String url) async {
    await setString('webhook_url', url);
  }

  static Future<bool> getWebhookEnabled() async {
    return getBool('webhook_enabled', defaultValue: false);
  }

  static Future<void> saveWebhookEnabled(bool enabled) async {
    await setBool('webhook_enabled', enabled);
  }

  static Future<String> getWebhookTemplate() async {
    return getString('webhook_template', defaultValue: '{"text": "AI Artist: {event} - {message}"}');
  }

  static Future<void> saveWebhookTemplate(String template) async {
    await setString('webhook_template', template);
  }

  // ==================== 分享配置 ====================

  static Future<bool> getShareUseBase64() async {
    return getBool('share_use_base64', defaultValue: true);
  }

  static Future<void> saveShareUseBase64(bool value) async {
    await setBool('share_use_base64', value);
  }

  static Future<bool> getShareClearClipboard() async {
    return getBool('share_clear_clipboard', defaultValue: true);
  }

  static Future<void> saveShareClearClipboard(bool value) async {
    await setBool('share_clear_clipboard', value);
  }

  // ==================== Agent 工具配置 ====================

  static Future<String> getAgentEnabledTools(String agentId) async {
    return getString('agent_enabled_tools_$agentId', defaultValue: '');
  }

  static Future<void> saveAgentEnabledTools(String agentId, String tools) async {
    await setString('agent_enabled_tools_$agentId', tools);
  }

  static Future<String> getAgentKnowledgeBase(String agentId) async {
    return getString('agent_kb_$agentId', defaultValue: '');
  }

  static Future<void> saveAgentKnowledgeBase(String agentId, String kbId) async {
    await setString('agent_kb_$agentId', kbId);
  }

  // ==================== 生图参数（per-model）====================

  static Future<Map<String, dynamic>> getGenerationPrefs(String modelId) async {
    final json = await getString('gen_prefs_$modelId', defaultValue: '');
    if (json.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveGenerationPrefs(String modelId, Map<String, dynamic> prefs) async {
    await setString('gen_prefs_$modelId', jsonEncode(prefs));
  }

  static Future<void> clearGenerationPrefs(String modelId) async {
    final p = await _prefs;
    await p.remove('gen_prefs_$modelId');
  }

  static Future<void> migrateGenerationPrefs(String oldId, String newId) async {
    final prefs = await getGenerationPrefs(oldId);
    if (prefs.isNotEmpty) {
      await saveGenerationPrefs(newId, prefs);
      await clearGenerationPrefs(oldId);
    }
  }
}
