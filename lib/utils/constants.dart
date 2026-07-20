class AppConstants {
  // 服务器地址
  static const String baseUrl = 'http://47.116.29.140';
  static const String apiPrefix = '/auth/auth';
  static const String fullApiBase = '$baseUrl$apiPrefix';
  
  // ComfyUI本地地址
  static const String comfyuiHost = '127.0.0.1';
  static const int comfyuiPort = 8188;
  static const String comfyuiBaseUrl = 'http://$comfyuiHost:$comfyuiPort';
  
  // Pollinations.AI
  static const String pollinationsBase = 'https://image.pollinations.ai/prompt';
  
  // 积分定价
  static const int chatCost = 1; // 对话1积分/次
  static const int imageCost = 6; // 云端生图6积分/张
  static const int registerBonus = 100; // 注册送100积分
  
  // 充值档位
  static const Map<int, int> rechargeProducts = {
    10: 1100,   // 10元→1100积分
    50: 5500,   // 50元→5500积分
    100: 11500, // 100元→11500积分
  };
  
  // 默认模型
  static const String defaultModel = 'glm-4-flash';
  
  // 用户Agent
  static const String userAgent = 'AIArtist-Flutter/5.10.0';
  
  // SharedPreferences keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyCredits = 'credits';
  static const String keyThemeMode = 'theme_mode';
  static const String keyComfyuiHost = 'comfyui_host';
  static const String keyComfyuiPort = 'comfyui_port';
  static const String keyActiveAgentId = 'active_agent_id';
  static const String keyAgentsList = 'agents_list';
}
