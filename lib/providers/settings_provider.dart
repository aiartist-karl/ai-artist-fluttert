import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

/// 设置状态管理
/// 参考 Android Preferences.kt (GenerationPreferences) 的逻辑
class SettingsProvider extends ChangeNotifier {
  // ==================== 主题相关 ====================
  String _themeMode = 'system'; // system, light, dark
  String _colorScheme = 'default';

  // ==================== Chat API 配置 ====================
  String _chatApiType = 'ollama'; // ollama, openai
  String _ollamaHost = 'http://10.0.2.2:11434';
  String _ollamaModel = 'deepseek-r1-distill-qwen-14b';
  String _openAIHost = '';
  String _openAIApiKey = '';
  String _openAIModel = '';

  // ==================== 工具 API 配置 ====================
  String _toolApiUrl = '';
  String _toolApiKey = '';
  String _toolApiModel = '';
  String _toolApiType = '';

  // ==================== 本地 ComfyUI 配置 ====================
  String _localImageApiUrl = 'https://basement-island-certification-neil.trycloudflare.com';

  // ==================== 图片生成 API 配置 ====================
  String _imageApiUrl = '';
  String _imageApiKey = '';

  // ==================== 构建服务器配置 ====================
  String _buildServerUrl = '';
  String _buildServerToken = '';

  // ==================== 记忆相关 ====================
  int _memoryContextCount = 5;

  // ==================== 上下文摘要 ====================
  bool _contextSummaryEnabled = true;
  int _contextSummaryThreshold = 20;

  // ==================== TTS 配置 ====================
  bool _ttsEnabled = false;
  double _ttsSpeed = 1.0;
  String _ttsVoiceType = 'zh_female_cancan_mars_bigtts';
  String _ttsAppId = '';
  String _ttsAccessToken = '';
  bool _speechInputEnabled = false;

  // ==================== Webhook 配置 ====================
  String _webhookUrl = '';
  bool _webhookEnabled = false;
  String _webhookTemplate = '{"text": "AI Artist: {event} - {message}"}';

  // ==================== 分享配置 ====================
  bool _shareUseBase64 = true;
  bool _shareClearClipboard = true;

  // ==================== 加载状态 ====================
  bool _isLoading = false;

  // ==================== Getters ====================
  String get themeMode => _themeMode;
  String get colorScheme => _colorScheme;
  String get chatApiType => _chatApiType;
  String get ollamaHost => _ollamaHost;
  String get ollamaModel => _ollamaModel;
  String get openAIHost => _openAIHost;
  String get openAIApiKey => _openAIApiKey;
  String get openAIModel => _openAIModel;
  String get toolApiUrl => _toolApiUrl;
  String get toolApiKey => _toolApiKey;
  String get toolApiModel => _toolApiModel;
  String get toolApiType => _toolApiType;
  String get localImageApiUrl => _localImageApiUrl;
  String get imageApiUrl => _imageApiUrl;
  String get imageApiKey => _imageApiKey;
  String get buildServerUrl => _buildServerUrl;
  String get buildServerToken => _buildServerToken;
  int get memoryContextCount => _memoryContextCount;
  bool get contextSummaryEnabled => _contextSummaryEnabled;
  int get contextSummaryThreshold => _contextSummaryThreshold;
  bool get ttsEnabled => _ttsEnabled;
  double get ttsSpeed => _ttsSpeed;
  String get ttsVoiceType => _ttsVoiceType;
  String get ttsAppId => _ttsAppId;
  String get ttsAccessToken => _ttsAccessToken;
  bool get speechInputEnabled => _speechInputEnabled;
  String get webhookUrl => _webhookUrl;
  bool get webhookEnabled => _webhookEnabled;
  String get webhookTemplate => _webhookTemplate;
  bool get shareUseBase64 => _shareUseBase64;
  bool get shareClearClipboard => _shareClearClipboard;
  bool get isLoading => _isLoading;

  // ==================== 初始化 ====================

  /// 从持久化存储加载所有设置
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _themeMode = await PreferencesService.getThemeMode();
      _colorScheme = await PreferencesService.getColorScheme();
      _chatApiType = await PreferencesService.getChatApiType();
      _ollamaHost = await PreferencesService.getOllamaHost();
      _ollamaModel = await PreferencesService.getOllamaModel();
      _openAIHost = await PreferencesService.getOpenAIHost();
      _openAIApiKey = await PreferencesService.getOpenAIApiKey();
      _openAIModel = await PreferencesService.getOpenAIModel();
      _toolApiUrl = await PreferencesService.getToolApiUrl();
      _toolApiKey = await PreferencesService.getToolApiKey();
      _toolApiModel = await PreferencesService.getToolApiModel();
      _toolApiType = await PreferencesService.getToolApiType();
      _localImageApiUrl = await PreferencesService.getLocalImageApiUrl();
      _imageApiUrl = await PreferencesService.getImageApiUrl();
      _imageApiKey = await PreferencesService.getImageApiKey();
      _buildServerUrl = await PreferencesService.getBuildServerUrl();
      _buildServerToken = await PreferencesService.getBuildServerToken();
      _memoryContextCount = await PreferencesService.getMemoryContextCount();
      _contextSummaryEnabled = await PreferencesService.getContextSummaryEnabled();
      _contextSummaryThreshold = await PreferencesService.getContextSummaryThreshold();
      _ttsEnabled = await PreferencesService.getTtsEnabled();
      _ttsSpeed = await PreferencesService.getTtsSpeed();
      _ttsVoiceType = await PreferencesService.getTtsVoiceType();
      _ttsAppId = await PreferencesService.getTtsAppId();
      _ttsAccessToken = await PreferencesService.getTtsAccessToken();
      _speechInputEnabled = await PreferencesService.getSpeechInputEnabled();
      _webhookUrl = await PreferencesService.getWebhookUrl();
      _webhookEnabled = await PreferencesService.getWebhookEnabled();
      _webhookTemplate = await PreferencesService.getWebhookTemplate();
      _shareUseBase64 = await PreferencesService.getShareUseBase64();
      _shareClearClipboard = await PreferencesService.getShareClearClipboard();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 主题设置 ====================

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    notifyListeners();
    await PreferencesService.saveThemeMode(mode);
  }

  Future<void> setColorScheme(String scheme) async {
    _colorScheme = scheme;
    notifyListeners();
    await PreferencesService.saveColorScheme(scheme);
  }

  // ==================== Chat API 设置 ====================

  Future<void> setChatApiType(String type) async {
    _chatApiType = type;
    notifyListeners();
    await PreferencesService.saveChatApiType(type);
  }

  Future<void> setOllamaHost(String host) async {
    _ollamaHost = host;
    notifyListeners();
    await PreferencesService.saveOllamaHost(host);
  }

  Future<void> setOllamaModel(String model) async {
    _ollamaModel = model;
    notifyListeners();
    await PreferencesService.saveOllamaModel(model);
  }

  Future<void> setOpenAIHost(String host) async {
    _openAIHost = host;
    notifyListeners();
    await PreferencesService.saveOpenAIHost(host);
  }

  Future<void> setOpenAIApiKey(String key) async {
    _openAIApiKey = key;
    notifyListeners();
    await PreferencesService.saveOpenAIApiKey(key);
  }

  Future<void> setOpenAIModel(String model) async {
    _openAIModel = model;
    notifyListeners();
    await PreferencesService.saveOpenAIModel(model);
  }

  // ==================== 工具 API 设置 ====================

  Future<void> setToolApiUrl(String url) async {
    _toolApiUrl = url;
    notifyListeners();
    await PreferencesService.saveToolApiUrl(url);
  }

  Future<void> setToolApiKey(String key) async {
    _toolApiKey = key;
    notifyListeners();
    await PreferencesService.saveToolApiKey(key);
  }

  Future<void> setToolApiModel(String model) async {
    _toolApiModel = model;
    notifyListeners();
    await PreferencesService.saveToolApiModel(model);
  }

  Future<void> setToolApiType(String type) async {
    _toolApiType = type;
    notifyListeners();
    await PreferencesService.saveToolApiType(type);
  }

  // ==================== 本地 ComfyUI 设置 ====================

  Future<void> setLocalImageApiUrl(String url) async {
    _localImageApiUrl = url;
    notifyListeners();
    await PreferencesService.saveLocalImageApiUrl(url);
  }

  // ==================== 图片生成 API 设置 ====================

  Future<void> setImageApiUrl(String url) async {
    _imageApiUrl = url;
    notifyListeners();
    await PreferencesService.saveImageApiUrl(url);
  }

  Future<void> setImageApiKey(String key) async {
    _imageApiKey = key;
    notifyListeners();
    await PreferencesService.saveImageApiKey(key);
  }

  // ==================== 构建服务器设置 ====================

  Future<void> setBuildServerUrl(String url) async {
    _buildServerUrl = url;
    notifyListeners();
    await PreferencesService.saveBuildServerUrl(url);
  }

  Future<void> setBuildServerToken(String token) async {
    _buildServerToken = token;
    notifyListeners();
    await PreferencesService.saveBuildServerToken(token);
  }

  // ==================== 记忆设置 ====================

  Future<void> setMemoryContextCount(int count) async {
    _memoryContextCount = count.clamp(1, 20);
    notifyListeners();
    await PreferencesService.saveMemoryContextCount(_memoryContextCount);
  }

  // ==================== 上下文摘要设置 ====================

  Future<void> setContextSummaryEnabled(bool enabled) async {
    _contextSummaryEnabled = enabled;
    notifyListeners();
    await PreferencesService.saveContextSummaryEnabled(enabled);
  }

  Future<void> setContextSummaryThreshold(int threshold) async {
    _contextSummaryThreshold = threshold;
    notifyListeners();
    await PreferencesService.saveContextSummaryThreshold(threshold);
  }

  // ==================== TTS 设置 ====================

  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    notifyListeners();
    await PreferencesService.saveTtsEnabled(enabled);
  }

  Future<void> setTtsSpeed(double speed) async {
    _ttsSpeed = speed;
    notifyListeners();
    await PreferencesService.saveTtsSpeed(speed);
  }

  Future<void> setTtsVoiceType(String voiceType) async {
    _ttsVoiceType = voiceType;
    notifyListeners();
    await PreferencesService.saveTtsVoiceType(voiceType);
  }

  Future<void> setTtsAppId(String appId) async {
    _ttsAppId = appId;
    notifyListeners();
    await PreferencesService.saveTtsAppId(appId);
  }

  Future<void> setTtsAccessToken(String token) async {
    _ttsAccessToken = token;
    notifyListeners();
    await PreferencesService.saveTtsAccessToken(token);
  }

  Future<void> setSpeechInputEnabled(bool enabled) async {
    _speechInputEnabled = enabled;
    notifyListeners();
    await PreferencesService.saveSpeechInputEnabled(enabled);
  }

  // ==================== Webhook 设置 ====================

  Future<void> setWebhookUrl(String url) async {
    _webhookUrl = url;
    notifyListeners();
    await PreferencesService.saveWebhookUrl(url);
  }

  Future<void> setWebhookEnabled(bool enabled) async {
    _webhookEnabled = enabled;
    notifyListeners();
    await PreferencesService.saveWebhookEnabled(enabled);
  }

  Future<void> setWebhookTemplate(String template) async {
    _webhookTemplate = template;
    notifyListeners();
    await PreferencesService.saveWebhookTemplate(template);
  }

  // ==================== 分享设置 ====================

  Future<void> setShareUseBase64(bool value) async {
    _shareUseBase64 = value;
    notifyListeners();
    await PreferencesService.saveShareUseBase64(value);
  }

  Future<void> setShareClearClipboard(bool value) async {
    _shareClearClipboard = value;
    notifyListeners();
    await PreferencesService.saveShareClearClipboard(value);
  }

  // ==================== Agent 工具配置 ====================

  /// 获取 Agent 启用的工具列表
  Future<String> getAgentEnabledTools(String agentId) async {
    return await PreferencesService.getAgentEnabledTools(agentId);
  }

  /// 保存 Agent 启用的工具列表
  Future<void> saveAgentEnabledTools(String agentId, String tools) async {
    await PreferencesService.saveAgentEnabledTools(agentId, tools);
  }

  /// 获取 Agent 知识库 ID
  Future<String> getAgentKnowledgeBase(String agentId) async {
    return await PreferencesService.getAgentKnowledgeBase(agentId);
  }

  /// 保存 Agent 知识库 ID
  Future<void> saveAgentKnowledgeBase(String agentId, String kbId) async {
    await PreferencesService.saveAgentKnowledgeBase(agentId, kbId);
  }

  // ==================== 生图参数（per-model）====================

  /// 获取模型的生图参数
  Future<Map<String, dynamic>> getGenerationPrefs(String modelId) async {
    return await PreferencesService.getGenerationPrefs(modelId);
  }

  /// 保存模型的生图参数
  Future<void> saveGenerationPrefs(String modelId, Map<String, dynamic> prefs) async {
    await PreferencesService.saveGenerationPrefs(modelId, prefs);
  }

  /// 清除模型的生图参数
  Future<void> clearGenerationPrefs(String modelId) async {
    await PreferencesService.clearGenerationPrefs(modelId);
  }

  /// 迁移模型参数到新 ID
  Future<void> migrateGenerationPrefs(String oldId, String newId) async {
    await PreferencesService.migrateGenerationPrefs(oldId, newId);
  }
}
