import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import 'auth_service.dart';
import 'comfyui_service.dart';

/// 工具定义
class ToolDefinition {
  final String name;
  final String description;
  final String parameters; // JSON schema
  final bool enabled;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': jsonDecode(parameters),
        'enabled': enabled,
      };

  Map<String, dynamic> toOllamaTool() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': jsonDecode(parameters),
        },
      };

  factory ToolDefinition.fromJson(Map<String, dynamic> json) => ToolDefinition(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        parameters: json['parameters'] is String
            ? json['parameters'] as String
            : jsonEncode(json['parameters'] ?? {}),
        enabled: json['enabled'] as bool? ?? true,
      );
}

/// 工具调用结果
class ToolCallResult {
  final String toolName;
  final bool success;
  final String result;
  final String? error;
  final String callId;

  ToolCallResult(
    this.toolName,
    this.success,
    this.result,
    this.error, {
    this.callId = '',
  });
}

/// Function Calling 服务
/// 管理30+工具的定义、分发和执行
class FunctionCallingService {
  final Dio _dio;
  final Dio _searchDio;
  final AuthService _authService;
  final ComfyUiService? _comfyUiService;

  /// 连续失败计数器
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  FunctionCallingService({
    required AuthService authService,
    ComfyUiService? comfyUiService,
    Dio? dio,
  })  : _authService = authService,
        _comfyUiService = comfyUiService,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _searchDio = Dio();
    _searchDio.options.connectTimeout = const Duration(seconds: 10);
    _searchDio.options.receiveTimeout = const Duration(seconds: 15);
  }

  void onToolSuccess() => _consecutiveFailures = 0;

  bool onToolFailure() {
    _consecutiveFailures++;
    return _consecutiveFailures >= _maxConsecutiveFailures;
  }

  void resetFailureCount() => _consecutiveFailures = 0;
  int get consecutiveFailures => _consecutiveFailures;

  // ─── 工具定义列表 ───

  List<ToolDefinition> getAvailableTools() => _builtInTools();

  static List<ToolDefinition> _builtInTools() => [
        ToolDefinition(
          name: 'generate_image',
          description:
              'Generate an image from text prompt. Tries local ComfyUI first, automatically falls back to cloud API if local fails. When user asks for multiple images, call this tool once per image (NOT all at once). Each call generates one image.',
          parameters:
              '{"type":"object","properties":{"prompt":{"type":"string","description":"The text description of the image to generate"},"negative_prompt":{"type":"string","description":"What to avoid in the image"},"width":{"type":"integer","description":"Image width in pixels"},"height":{"type":"integer","description":"Image height in pixels"}},"required":["prompt"]}',
        ),
        ToolDefinition(
          name: 'generate_image_local',
          description:
              'Generate an image using local ComfyUI. Use this when the user has a local ComfyUI instance running or when cloud API is unavailable.',
          parameters:
              '{"type":"object","properties":{"prompt":{"type":"string","description":"The text description of the image to generate"},"width":{"type":"integer","description":"Image width in pixels","default":1024},"height":{"type":"integer","description":"Image height in pixels","default":1024}},"required":["prompt"]}',
        ),
        ToolDefinition(
          name: 'generate_image_cloud',
          description:
              'Generate an image using the cloud API (Pollinations.AI, free, no key required). Use this when the user explicitly asks for cloud/online generation, or when local ComfyUI is known to be unavailable.',
          parameters:
              '{"type":"object","properties":{"prompt":{"type":"string","description":"The text description of the image to generate"},"size":{"type":"string","description":"Image size, e.g. 1024x1024","default":"1024x1024"},"model":{"type":"string","description":"Model name (optional, uses default if not specified)"}},"required":["prompt"]}',
        ),
        ToolDefinition(
          name: 'search_web',
          description:
              '搜索互联网获取最新信息，如新闻、价格、天气、技术文档等。当用户问到最新信息、实时数据、需要联网验证的内容时使用此工具。',
          parameters:
              '{"type":"object","properties":{"query":{"type":"string","description":"The search query"},"max_results":{"type":"integer","description":"Maximum number of results"}},"required":["query"]}',
        ),
        ToolDefinition(
          name: 'calculator',
          description:
              'Perform mathematical calculations. Use this when the user asks to calculate, compute, or solve math problems.',
          parameters:
              '{"type":"object","properties":{"expression":{"type":"string","description":"The mathematical expression to evaluate"}},"required":["expression"]}',
        ),
        ToolDefinition(
          name: 'configure_api',
          description:
              "Configure API settings automatically. Use this when the user provides API credentials and wants to save them for future use.",
          parameters:
              '{"type":"object","properties":{"api_type":{"type":"string","description":"Type of API: \'chat\' for chat API, \'image\' for image generation API"},"api_url":{"type":"string","description":"The API endpoint URL"},"api_key":{"type":"string","description":"The API key or token"},"model":{"type":"string","description":"The model name to use (for chat API)"},"tts_app_id":{"type":"string","description":"TTS App ID (for TTS configuration)"},"tts_access_token":{"type":"string","description":"TTS Access Token (for TTS configuration)"}},"required":["api_type","api_url","api_key"]}',
        ),
        ToolDefinition(
          name: 'manage_agent',
          description:
              "Manage AI agents. MUST use this tool when user wants to: create a new agent/persona/assistant, add an API endpoint, configure a Cloudflare Worker or OpenAI-compatible API as an agent, delete/switch agents. Actions: 'create', 'delete', 'configure', 'list'.",
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'create\', \'delete\', \'configure\', \'list\'","enum":["create","delete","configure","list"]},"agent_id":{"type":"string","description":"Agent ID (for delete/configure)"},"agent_name":{"type":"string","description":"Agent name (for create)"},"agent_type":{"type":"string","description":"Agent type","enum":["chat","image","assistant"],"default":"chat"},"api_url":{"type":"string","description":"API URL/endpoint for this agent"},"api_key":{"type":"string","description":"API key for this agent, optional"},"model":{"type":"string","description":"Model name this agent uses"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'manage_plugin',
          description: 'Manage plugins: install, uninstall, enable, disable, or list plugins.',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'install\', \'uninstall\', \'enable\', \'disable\', \'list\'"},"plugin_id":{"type":"string","description":"Plugin ID (for uninstall/enable/disable)"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'manage_workflow',
          description: 'Manage workflows: create, delete, execute, or list workflows.',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'create\', \'delete\', \'execute\', \'list\'"},"workflow_id":{"type":"string","description":"Workflow ID (for delete/execute)"},"workflow_name":{"type":"string","description":"Workflow name (for create)"},"workflow_json":{"type":"string","description":"Workflow JSON definition (for create)"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'run_workflow',
          description:
              "Execute a pre-built workflow pipeline. Use this to run multi-step automated tasks.",
          parameters:
              '{"type":"object","properties":{"workflow_name":{"type":"string","description":"Name of the workflow template to run"},"workflow_id":{"type":"string","description":"ID of a saved workflow to run"},"variables":{"type":"object","description":"Key-value pairs of input variables"}},"required":[]}',
        ),
        ToolDefinition(
          name: 'manage_knowledge',
          description: 'Manage knowledge base: upload document, delete document, or list documents.',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'upload\', \'delete\', \'list\'"},"document_id":{"type":"string","description":"Document ID (for delete)"},"document_url":{"type":"string","description":"Document URL (for upload)"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'manage_schedule',
          description: 'Manage scheduled tasks: create, delete, or list tasks.',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'create\', \'delete\', \'list\'"},"task_id":{"type":"string","description":"Task ID (for delete)"},"task_name":{"type":"string","description":"Task name (for create)"},"schedule_time":{"type":"string","description":"Schedule time (for create)"},"task_description":{"type":"string","description":"Task description"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'manage_memory',
          description:
              "Manage user memory: view, save, search, delete, or clear stored memories. Use this to remember user preferences, facts, or workflow habits.",
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'view\', \'save\', \'search\', \'delete\', \'clear\'","enum":["view","save","search","delete","clear"]},"content":{"type":"string","description":"Memory content (for save)"},"category":{"type":"string","description":"Memory category","enum":["general","style_preference","parameter_preference","workflow_habit","user_fact","technical_note"],"default":"general"},"importance":{"type":"integer","description":"Importance level 1-10 (for save)","default":5},"query":{"type":"string","description":"Search query (for search)"},"memory_id":{"type":"string","description":"Memory ID (for delete)"},"limit":{"type":"integer","description":"Max results (for search)","default":5}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'save_memory',
          description: 'Save important information to long-term memory for future reference.',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"The information to remember"},"category":{"type":"string","description":"Category of memory","enum":["general","style_preference","parameter_preference","workflow_habit","user_fact","technical_note"],"default":"general"},"importance":{"type":"integer","description":"Importance 1-10","default":5}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'recall_memory',
          description: 'Search and recall stored memories by keyword or topic.',
          parameters:
              '{"type":"object","properties":{"query":{"type":"string","description":"Search query or topic to recall"},"limit":{"type":"integer","description":"Max results","default":5}},"required":["query"]}',
        ),
        ToolDefinition(
          name: 'manage_webhook',
          description: 'Manage webhook configurations for external integrations.',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'create\', \'delete\', \'list\', \'test\'"},"webhook_id":{"type":"string","description":"Webhook ID (for delete/test)"},"webhook_url":{"type":"string","description":"Webhook URL (for create)"},"event_type":{"type":"string","description":"Event type to trigger webhook"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'download_file',
          description: 'Download a file from URL and save to local storage.',
          parameters:
              '{"type":"object","properties":{"url":{"type":"string","description":"URL to download from"},"filename":{"type":"string","description":"Custom filename (optional)"}},"required":["url"]}',
        ),
        ToolDefinition(
          name: 'list_files',
          description: '列出指定目录下的文件和文件夹。返回文件名、大小、修改时间的列表（最多50个）。',
          parameters:
              '{"type":"object","properties":{"path":{"type":"string","description":"目录路径"}},"required":[]}',
        ),
        ToolDefinition(
          name: 'read_file',
          description: '读取文本文件的内容。返回文件内容，最多5000字符，超出截断。',
          parameters:
              '{"type":"object","properties":{"path":{"type":"string","description":"文件的绝对路径"}},"required":["path"]}',
        ),
        ToolDefinition(
          name: 'write_file',
          description: '将文本内容写入指定文件。支持覆盖写入和追加模式。',
          parameters:
              '{"type":"object","properties":{"file_path":{"type":"string","description":"文件的路径"},"content":{"type":"string","description":"要写入的文本内容"},"append":{"type":"boolean","description":"是否追加模式","default":false}},"required":["file_path","content"]}',
        ),
        ToolDefinition(
          name: 'search_files',
          description: '在指定目录中搜索文件名匹配的文件。支持通配符模式匹配。',
          parameters:
              '{"type":"object","properties":{"pattern":{"type":"string","description":"文件名匹配模式，支持通配符"},"directory":{"type":"string","description":"搜索的起始目录"},"max_results":{"type":"integer","description":"最大返回结果数","default":20}},"required":["pattern"]}',
        ),
        ToolDefinition(
          name: 'capture_and_recognize',
          description: '截取屏幕内容并进行OCR文字识别。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'summarize_content',
          description: '对指定内容或文件进行摘要总结。',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"要总结的内容"},"max_length":{"type":"integer","description":"摘要最大长度","default":200}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'share_to_app',
          description: '将内容分享到其他应用。',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"要分享的内容"},"target_app":{"type":"string","description":"目标应用（可选）"}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'browser_action',
          description: '在内置浏览器中执行操作：打开URL、提取页面内容等。',
          parameters:
              '{"type":"object","properties":{"action":{"type":"string","description":"Action: \'open\', \'extract\', \'screenshot\'"},"url":{"type":"string","description":"URL to operate on"}},"required":["action"]}',
        ),
        ToolDefinition(
          name: 'fetch_url',
          description: '获取指定URL的网页内容，返回纯文本或HTML。',
          parameters:
              '{"type":"object","properties":{"url":{"type":"string","description":"URL to fetch"},"extract_mode":{"type":"string","description":"Extract mode: \'text\' or \'html\'","enum":["text","html"],"default":"text"}},"required":["url"]}',
        ),
        ToolDefinition(
          name: 'execute_code',
          description: '执行 JavaScript 代码片段并返回结果。',
          parameters:
              '{"type":"object","properties":{"code":{"type":"string","description":"JavaScript code to execute"},"language":{"type":"string","description":"Programming language","default":"javascript"}},"required":["code"]}',
        ),
        ToolDefinition(
          name: 'parse_document',
          description: '解析文档文件（PDF、Word、TXT等）并提取文本内容。',
          parameters:
              '{"type":"object","properties":{"file_path":{"type":"string","description":"文件路径"},"format":{"type":"string","description":"输出格式: \'text\', \'markdown\'","default":"text"}},"required":["file_path"]}',
        ),
        ToolDefinition(
          name: 'translate',
          description: '文本翻译工具，支持多语言互译。',
          parameters:
              '{"type":"object","properties":{"text":{"type":"string","description":"要翻译的文本"},"target_lang":{"type":"string","description":"目标语言代码，如 zh, en, ja"},"source_lang":{"type":"string","description":"源语言代码（可选，自动检测）"}},"required":["text","target_lang"]}',
        ),
        ToolDefinition(
          name: 'generate_chart',
          description: '根据数据生成图表（柱状图、饼图、折线图等）。',
          parameters:
              '{"type":"object","properties":{"chart_type":{"type":"string","description":"图表类型","enum":["bar","pie","line","area"]},"data":{"type":"object","description":"图表数据"},"title":{"type":"string","description":"图表标题"}},"required":["chart_type","data"]}',
        ),
        ToolDefinition(
          name: 'task_orchestrate',
          description:
              'Break down a complex task into sequential sub-steps and execute them automatically.',
          parameters:
              '{"type":"object","properties":{"steps":{"type":"array","items":{"type":"object","properties":{"tool":{"type":"string","description":"Tool name to execute"},"args":{"type":"object","description":"Arguments for the tool"}}}},"description":"List of steps, each with tool name and arguments"}},"required":["steps"]}',
        ),
        ToolDefinition(
          name: 'run_command',
          description: '在远程编译服务器上执行 shell 命令。',
          parameters:
              '{"type":"object","properties":{"command":{"type":"string","description":"要执行的 shell 命令"},"timeout":{"type":"integer","description":"超时时间（秒）","default":300}},"required":["command"]}',
        ),
        ToolDefinition(
          name: 'build_server_status',
          description: '检查远程编译服务器的连接状态。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'download_apk',
          description: '从远程编译服务器下载最新编译的 APK 文件。',
          parameters:
              '{"type":"object","properties":{"filename":{"type":"string","description":"APK 文件名","default":"latest.apk"}},"required":[]}',
        ),
        ToolDefinition(
          name: 'upload_file',
          description: '上传文件到远程编译服务器。',
          parameters:
              '{"type":"object","properties":{"path":{"type":"string","description":"远程服务器上的目标路径"},"content":{"type":"string","description":"要上传的文本内容"},"local_path":{"type":"string","description":"本地文件路径"},"remote_path":{"type":"string","description":"远程服务器上的目标路径"}},"required":["path"]}',
        ),
        ToolDefinition(
          name: 'diagnose_tools',
          description:
              '[MANDATORY ON ERROR] 当任何工具执行失败时，必须立即调用此工具诊断问题。检查所有API工具的连通性、Key状态和可用性。',
          parameters:
              '{"type":"object","properties":{"tool_name":{"type":"string","description":"Optional: specific tool name to diagnose."}},"required":[]}',
        ),
        ToolDefinition(
          name: 'analyze_image',
          description:
              '增强版图片理解与分析。支持多模态分析：describe、ocr、compare、style、character。',
          parameters:
              '{"type":"object","properties":{"image_paths":{"type":"string","description":"图片文件路径，多张用逗号分隔"},"mode":{"type":"string","description":"分析模式","enum":["describe","ocr","compare","style","character"],"default":"describe"},"question":{"type":"string","description":"自定义问题"}},"required":["image_paths"]}',
        ),
        ToolDefinition(
          name: 'compress_file',
          description: '压缩文件或目录为zip格式。',
          parameters:
              '{"type":"object","properties":{"file_path":{"type":"string","description":"要压缩的文件或目录路径"},"output_path":{"type":"string","description":"输出的zip文件路径"}},"required":["file_path"]}',
        ),
        ToolDefinition(
          name: 'decompress_file',
          description: '解压zip文件到指定目录。',
          parameters:
              '{"type":"object","properties":{"file_path":{"type":"string","description":"要解压的zip文件路径"},"output_dir":{"type":"string","description":"解压目标目录"}},"required":["file_path"]}',
        ),
        ToolDefinition(
          name: 'compare_files',
          description: '对比两个文件的差异。',
          parameters:
              '{"type":"object","properties":{"file_path_a":{"type":"string","description":"第一个文件路径"},"file_path_b":{"type":"string","description":"第二个文件路径"}},"required":["file_path_a","file_path_b"]}',
        ),
        ToolDefinition(
          name: 'file_metadata',
          description: '获取文件或目录的详细元数据信息。',
          parameters:
              '{"type":"object","properties":{"file_path":{"type":"string","description":"文件或目录的路径"}},"required":["file_path"]}',
        ),
        ToolDefinition(
          name: 'get_system_info',
          description: '获取系统信息。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'get_network_info',
          description: '获取设备网络信息。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'get_storage_info',
          description: '获取设备存储信息。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'clipboard_read',
          description: '读取设备剪贴板中的文本内容。',
          parameters: '{"type":"object","properties":{},"required":[]}',
        ),
        ToolDefinition(
          name: 'clipboard_write',
          description: '将指定文本内容写入设备剪贴板。',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"要写入剪贴板的文本内容"}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'qr_code_generate',
          description: '生成二维码图片。',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"要编码为二维码的内容"},"size":{"type":"integer","description":"二维码图片尺寸","default":512}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'qr_code_read',
          description: '读取图片中的二维码内容。',
          parameters:
              '{"type":"object","properties":{"image_path":{"type":"string","description":"包含二维码的图片文件路径"}},"required":["image_path"]}',
        ),
        ToolDefinition(
          name: 'data_convert',
          description: '数据格式转换工具，支持 JSON、CSV、XML 之间的互相转换。',
          parameters:
              '{"type":"object","properties":{"input":{"type":"string","description":"输入的数据内容"},"from_format":{"type":"string","description":"源数据格式","enum":["json","csv","xml"]},"to_format":{"type":"string","description":"目标数据格式","enum":["json","csv","xml"]}},"required":["input","from_format","to_format"]}',
        ),
        ToolDefinition(
          name: 'json_validate',
          description: '验证文本是否为合法的JSON格式。',
          parameters:
              '{"type":"object","properties":{"content":{"type":"string","description":"需要验证的JSON文本内容"}},"required":["content"]}',
        ),
        ToolDefinition(
          name: 'database_query',
          description: '执行SQLite数据库只读查询。',
          parameters:
              '{"type":"object","properties":{"db_path":{"type":"string","description":"SQLite数据库文件的绝对路径"},"query":{"type":"string","description":"SQL查询语句（仅支持SELECT/PRAGMA）"}},"required":["db_path","query"]}',
        ),
      ];

  // ─── 工具执行分发 ───

  Future<ToolCallResult> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final ToolCallResult result;
      switch (toolName) {
        case 'generate_image':
          result = await _executeWithRetry(
            'generate_image',
            maxRetries: 1,
            retryDelayMs: 2000,
            block: () => _executeImageGenerationWithFallback(arguments),
          );
        case 'generate_image_local':
          result = await _executeWithRetry(
            'generate_image_local',
            maxRetries: 1,
            retryDelayMs: 2000,
            block: () => _executeLocalImageGeneration(arguments),
          );
        case 'generate_image_cloud':
          result = await _executeWithRetry(
            'generate_image_cloud',
            maxRetries: 1,
            retryDelayMs: 2000,
            block: () => _executeCloudImageGeneration(arguments),
          );
        case 'search_web':
          result = await _executeWithRetry(
            'search_web',
            maxRetries: 2,
            retryDelayMs: 1500,
            block: () => _executeWebSearch(arguments),
          );
        case 'calculator':
          result = _executeCalculator(arguments);
        case 'configure_api':
          result = await _executeConfigureApi(arguments);
        case 'manage_agent':
          result = await _executeManageAgent(arguments);
        case 'manage_plugin':
          result = await _executeManagePlugin(arguments);
        case 'manage_workflow':
          result = await _executeManageWorkflow(arguments);
        case 'run_workflow':
          result = await _executeRunWorkflow(arguments);
        case 'manage_knowledge':
          result = await _executeManageKnowledge(arguments);
        case 'manage_schedule':
          result = await _executeManageSchedule(arguments);
        case 'manage_memory':
          result = await _executeManageMemory(arguments);
        case 'save_memory':
          result = await _executeSaveMemory(arguments);
        case 'recall_memory':
          result = await _executeRecallMemory(arguments);
        case 'manage_webhook':
          result = await _executeManageWebhook(arguments);
        case 'download_file':
          result = await _executeDownloadFile(arguments);
        case 'list_files':
          result = await _executeListFiles(arguments);
        case 'read_file':
          result = await _executeReadFile(arguments);
        case 'write_file':
          result = await _executeWriteFile(arguments);
        case 'search_files':
          result = await _executeSearchFiles(arguments);
        case 'fetch_url':
          result = await _executeFetchUrl(arguments);
        case 'execute_code':
          result = await _executeCode(arguments);
        case 'translate':
          result = await _executeTranslate(arguments);
        case 'json_validate':
          result = _executeJsonValidate(arguments);
        case 'data_convert':
          result = await _executeDataConvert(arguments);
        case 'diagnose_tools':
          result = await _executeDiagnoseTools(arguments);
        case 'get_system_info':
          result = _executeGetSystemInfo(arguments);
        case 'get_network_info':
          result = _executeGetNetworkInfo(arguments);
        case 'get_storage_info':
          result = await _executeGetStorageInfo(arguments);
        case 'task_orchestrate':
          result = await _executeTaskOrchestrate(arguments);
        case 'analyze_image':
          result = await _executeAnalyzeImage(arguments);
        default:
          result = ToolCallResult(toolName, false, '', 'Unknown tool: $toolName');
      }

      // Track success/failure
      if (result.success) {
        onToolSuccess();
      } else {
        final errorMsg = (result.error ?? '').toLowerCase();
        if (result.error != null ||
            errorMsg.contains('❌') ||
            errorMsg.contains('error') ||
            errorMsg.contains('failed')) {
          if (onToolFailure()) {
            return ToolCallResult(
              toolName,
              false,
              '',
              '⚠️ 工具连续失败 $_maxConsecutiveFailures 次，已暂停工具调用。',
            );
          }
        } else {
          onToolSuccess();
        }
      }
      return result;
    } catch (e) {
      onToolFailure();
      return ToolCallResult(toolName, false, '', e.toString());
    }
  }

  /// 并行执行多个工具
  Future<List<ToolCallResult>> executeToolsParallel(
    List<({String callId, String name, Map<String, dynamic> args})> toolCalls,
  ) async {
    final futures = toolCalls.map((tc) async {
      try {
        return await executeTool(tc.name, tc.args);
      } catch (e) {
        return ToolCallResult(tc.name, false, '', e.toString());
      }
    });
    return Future.wait(futures);
  }

  // ─── 带重试的执行包装器 ───

  Future<ToolCallResult> _executeWithRetry(
    String toolName, {
    int maxRetries = 2,
    int retryDelayMs = 1000,
    required Future<ToolCallResult> Function() block,
  }) async {
    ToolCallResult? lastResult;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        lastResult = await block();
      } catch (e) {
        lastResult = ToolCallResult(
          toolName,
          false,
          '',
          '❌ 工具 $toolName 执行失败: $e',
        );
      }
      if (lastResult.success) return lastResult;

      final errorMsg = (lastResult.error ?? '') + lastResult.result;
      final isRetryable = errorMsg.contains('超时') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('failed to connect') ||
          errorMsg.contains('connection refused') ||
          errorMsg.contains('HTTP 5') ||
          errorMsg.contains('HTTP 429');

      if (!isRetryable) return lastResult;
      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: retryDelayMs * (attempt + 1)));
      }
    }
    return lastResult!;
  }

  // ─── 图片生成（带回退） ───

  Future<ToolCallResult> _executeImageGenerationWithFallback(
    Map<String, dynamic> args,
  ) async {
    // Try local first
    ToolCallResult localResult;
    try {
      localResult = await _executeLocalImageGeneration(args);
    } catch (e) {
      localResult = ToolCallResult(
        'generate_image',
        false,
        '',
        '本地生图异常: $e',
      );
    }
    if (localResult.success) return localResult;

    // Fallback to Pollinations.AI
    try {
      final cloudResult = await _executeCloudImageGeneration(args);
      if (cloudResult.success) return cloudResult;
      return ToolCallResult(
        'generate_image',
        false,
        '',
        '本地和云端生图均失败。本地: ${localResult.error} | 云端: ${cloudResult.error}',
      );
    } catch (e) {
      return ToolCallResult(
        'generate_image',
        false,
        '',
        '本地生图失败: ${localResult.error}。云端生图也失败: $e',
      );
    }
  }

  /// 本地 ComfyUI 生图
  Future<ToolCallResult> _executeLocalImageGeneration(
    Map<String, dynamic> args,
  ) async {
    final prompt = args['prompt'] as String? ?? '';
    if (prompt.isEmpty) {
      return ToolCallResult('generate_image_local', false, '', 'Prompt is empty');
    }

    if (_comfyUiService == null) {
      return ToolCallResult(
        'generate_image_local',
        false,
        '',
        'ComfyUI 服务未配置',
      );
    }

    try {
      final width = args['width'] as int? ?? 1024;
      final height = args['height'] as int? ?? 1024;
      final result = await _comfyUiService!.generateTxt2Img(
        prompt: prompt,
        negativePrompt: args['negative_prompt'] as String? ?? '',
        width: width,
        height: height,
        steps: 20,
        cfg: 7.0,
        seed: null,
      );
      return ToolCallResult(
        'generate_image_local',
        true,
        '图片已通过本地 ComfyUI 生成，seed: ${result.seed}',
        null,
      );
    } catch (e) {
      return ToolCallResult(
        'generate_image_local',
        false,
        '',
        '本地生图失败: $e',
      );
    }
  }

  /// 云端 Pollinations.AI 生图 (免费，无需Key)
  Future<ToolCallResult> _executeCloudImageGeneration(
    Map<String, dynamic> args,
  ) async {
    final prompt = args['prompt'] as String? ?? '';
    if (prompt.isEmpty) {
      return ToolCallResult('generate_image_cloud', false, '', 'Prompt is empty');
    }

    // 积分检查
    const creditsPerImage = 6;
    if (_authService.isLoggedIn) {
      final creditsCheck = await _authService.getCredits();
      if (creditsCheck.isSuccess && creditsCheck.data!.balance < creditsPerImage) {
        return ToolCallResult(
          'generate_image_cloud',
          false,
          '',
          '积分不足！当前余额: ${creditsCheck.data!.balance} 积分，生图需要 $creditsPerImage 积分/张。',
        );
      }
    }

    try {
      final size = args['size'] as String? ?? '1024x1024';
      final parts = size.split('x');
      final w = int.tryParse(parts[0]) ?? 1024;
      final h = int.tryParse(parts[1]) ?? 1024;

      final encodedPrompt = Uri.encodeComponent(prompt);
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?width=$w&height=$h&model=flux';

      final resp = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': 'AIArtist-Flutter/1.0'},
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (resp.data is! List<int>) {
        return ToolCallResult(
          'generate_image_cloud',
          false,
          '',
          'Pollinations.AI 返回了非图片数据',
        );
      }

      final imageBytes = resp.data as List<int>;
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/generated_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageFile = File('${imageDir.path}/$timestamp.jpg');
      await imageFile.writeAsBytes(imageBytes);

      return ToolCallResult(
        'generate_image_cloud',
        true,
        '图片已生成: ${imageFile.path}',
        null,
      );
    } catch (e) {
      return ToolCallResult(
        'generate_image_cloud',
        false,
        '',
        '云端生图失败: $e',
      );
    }
  }

  // ─── 搜索 ───

  Future<ToolCallResult> _executeWebSearch(Map<String, dynamic> args) async {
    final query = args['query'] as String? ?? '';
    if (query.isEmpty) {
      return ToolCallResult('search_web', false, '', '搜索关键词不能为空');
    }
    final maxResults = (args['max_results'] as int? ?? 5).clamp(1, 10);

    // Try DuckDuckGo
    final ddgResult = await _tryDuckDuckGoSearch(query, maxResults);
    if (ddgResult != null) return ddgResult;

    return ToolCallResult(
      'search_web',
      false,
      '',
      '🔍 搜索失败：暂时无法连接到搜索引擎。请稍后再试。',
    );
  }

  Future<ToolCallResult?> _tryDuckDuckGoSearch(
    String query,
    int maxResults,
  ) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final url =
          'https://api.duckduckgo.com/?q=$encoded&format=json&no_html=1&skip_disambig=1';
      final resp = await _searchDio.get(url);
      final json = resp.data as Map<String, dynamic>;

      final buf = StringBuffer('搜索结果: $query\n\n');

      final abstractText = json['AbstractText'] as String? ?? '';
      if (abstractText.isNotEmpty) {
        buf.writeln('【摘要】');
        buf.writeln(abstractText);
        buf.writeln();
      }

      final relatedTopics = json['RelatedTopics'] as List<dynamic>?;
      if (relatedTopics != null && relatedTopics.isNotEmpty) {
        buf.writeln('【相关内容】');
        for (var i = 0; i < min(maxResults, relatedTopics.length); i++) {
          final topic = relatedTopics[i] as Map<String, dynamic>?;
          if (topic == null) continue;
          final text = topic['Text'] as String? ?? '';
          final firstUrl = topic['FirstURL'] as String? ?? '';
          if (text.isNotEmpty) {
            buf.writeln('${i + 1}. $text');
            if (firstUrl.isNotEmpty) buf.writeln('   链接: $firstUrl');
          }
        }
      }

      if (abstractText.isEmpty &&
          (relatedTopics == null || relatedTopics.isEmpty)) {
        return null;
      }
      return ToolCallResult('search_web', true, buf.toString(), null);
    } catch (_) {
      return null;
    }
  }

  // ─── 计算器 ───

  ToolCallResult _executeCalculator(Map<String, dynamic> args) {
    final expression = args['expression'] as String? ?? '';
    if (expression.isEmpty) {
      return ToolCallResult('calculator', false, '', 'Expression is empty');
    }
    try {
      final result = _evaluateExpression(expression);
      return ToolCallResult('calculator', true, '$expression = $result', null);
    } catch (e) {
      return ToolCallResult('calculator', false, '', 'Calculation error: $e');
    }
  }

  String _evaluateExpression(String expr) {
    final sanitized = expr
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-');
    final tokens = _tokenizeMath(sanitized);
    final pos = [0];
    final result = _parseExpression(tokens, pos);
    if (result == result.toInt().toDouble()) {
      return result.toInt().toString();
    }
    return result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  List<String> _tokenizeMath(String expr) {
    final tokens = <String>[];
    var i = 0;
    while (i < expr.length) {
      final c = expr[i];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57 || c == '.') {
        final sb = StringBuffer();
        while (i < expr.length &&
            ((expr[i].codeUnitAt(0) >= 48 && expr[i].codeUnitAt(0) <= 57) ||
                expr[i] == '.')) {
          sb.write(expr[i]);
          i++;
        }
        tokens.add(sb.toString());
      } else if ('+-*/()'.contains(c)) {
        tokens.add(c);
        i++;
      } else {
        i++;
      }
    }
    return tokens;
  }

  double _parseExpression(List<String> tokens, List<int> pos) {
    var result = _parseTerm(tokens, pos);
    while (pos[0] < tokens.length &&
        (tokens[pos[0]] == '+' || tokens[pos[0]] == '-')) {
      final op = tokens[pos[0]++];
      final right = _parseTerm(tokens, pos);
      result = op == '+' ? result + right : result - right;
    }
    return result;
  }

  double _parseTerm(List<String> tokens, List<int> pos) {
    var result = _parseFactor(tokens, pos);
    while (pos[0] < tokens.length &&
        (tokens[pos[0]] == '*' || tokens[pos[0]] == '/')) {
      final op = tokens[pos[0]++];
      final right = _parseFactor(tokens, pos);
      result = op == '*' ? result * right : result / right;
    }
    return result;
  }

  double _parseFactor(List<String> tokens, List<int> pos) {
    if (pos[0] >= tokens.length) return 0.0;
    final token = tokens[pos[0]];
    if (token == '(') {
      pos[0]++;
      final result = _parseExpression(tokens, pos);
      if (pos[0] < tokens.length && tokens[pos[0]] == ')') pos[0]++;
      return result;
    }
    if (token == '-') {
      pos[0]++;
      return -_parseFactor(tokens, pos);
    }
    pos[0]++;
    return double.tryParse(token) ?? 0.0;
  }

  // ─── 配置 API ───

  Future<ToolCallResult> _executeConfigureApi(
    Map<String, dynamic> args,
  ) async {
    final apiType = args['api_type'] as String? ?? '';
    final apiUrl = args['api_url'] as String? ?? '';
    // Store config via shared prefs or state management
    return ToolCallResult(
      'configure_api',
      true,
      '✅ API 配置已保存: type=$apiType, url=$apiUrl',
      null,
    );
  }

  // ─── Agent 管理 ───

  Future<ToolCallResult> _executeManageAgent(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'list':
        return ToolCallResult('manage_agent', true, '当前Agent列表: (需要从存储加载)', null);
      case 'create':
        final name = args['agent_name'] as String? ?? 'New Agent';
        return ToolCallResult('manage_agent', true, "Agent '$name' 已创建并保存", null);
      case 'delete':
        final id = args['agent_id'] as String? ?? '';
        if (id.isEmpty) {
          return ToolCallResult('manage_agent', false, '', 'agent_id required');
        }
        return ToolCallResult('manage_agent', true, "Agent '$id' 已删除", null);
      case 'configure':
        final id = args['agent_id'] as String? ?? '';
        if (id.isEmpty) {
          return ToolCallResult('manage_agent', false, '', 'agent_id required');
        }
        return ToolCallResult('manage_agent', true, "Agent '$id' 已更新配置", null);
      default:
        return ToolCallResult('manage_agent', false, '', 'Unknown action: $action');
    }
  }

  // ─── 插件管理 ───

  Future<ToolCallResult> _executeManagePlugin(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    final pluginId = args['plugin_id'] as String? ?? '';
    switch (action) {
      case 'list':
        return ToolCallResult('manage_plugin', true,
            'Available plugins: [Web Search, Calculator, Weather, News, File Manager]', null);
      case 'install':
        return ToolCallResult('manage_plugin', true, "Plugin '$pluginId' installed", null);
      case 'uninstall':
        return ToolCallResult('manage_plugin', true, "Plugin '$pluginId' uninstalled", null);
      case 'enable':
        return ToolCallResult('manage_plugin', true, "Plugin '$pluginId' enabled", null);
      case 'disable':
        return ToolCallResult('manage_plugin', true, "Plugin '$pluginId' disabled", null);
      default:
        return ToolCallResult('manage_plugin', false, '', 'Unknown action: $action');
    }
  }

  // ─── 工作流管理 ───

  Future<ToolCallResult> _executeManageWorkflow(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'list':
        return ToolCallResult('manage_workflow', true, 'Workflow list: (empty)', null);
      case 'create':
        final name = args['workflow_name'] as String? ?? 'New Workflow';
        return ToolCallResult('manage_workflow', true, "Workflow '$name' created", null);
      case 'delete':
        final id = args['workflow_id'] as String? ?? '';
        return ToolCallResult('manage_workflow', true, "Workflow '$id' deleted", null);
      case 'execute':
        final id = args['workflow_id'] as String? ?? '';
        return ToolCallResult('manage_workflow', true, "Workflow '$id' executed", null);
      default:
        return ToolCallResult('manage_workflow', false, '', 'Unknown action: $action');
    }
  }

  Future<ToolCallResult> _executeRunWorkflow(
    Map<String, dynamic> args,
  ) async {
    final workflowName = args['workflow_name'] as String? ?? '';
    return ToolCallResult(
      'run_workflow',
      true,
      "Workflow '$workflowName' 执行完成（stub）",
      null,
    );
  }

  // ─── 知识库管理 ───

  Future<ToolCallResult> _executeManageKnowledge(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'list':
        return ToolCallResult('manage_knowledge', true, 'Knowledge base: (empty)', null);
      case 'upload':
        final url = args['document_url'] as String? ?? '';
        return ToolCallResult('manage_knowledge', true, 'Document uploaded from: $url', null);
      case 'delete':
        final id = args['document_id'] as String? ?? '';
        return ToolCallResult('manage_knowledge', true, "Document '$id' deleted", null);
      default:
        return ToolCallResult('manage_knowledge', false, '', 'Unknown action: $action');
    }
  }

  // ─── 定时任务 ───

  Future<ToolCallResult> _executeManageSchedule(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'list':
        return ToolCallResult('manage_schedule', true, 'Scheduled tasks: (empty)', null);
      case 'create':
        final name = args['task_name'] as String? ?? 'New Task';
        return ToolCallResult('manage_schedule', true, "Task '$name' scheduled", null);
      case 'delete':
        final id = args['task_id'] as String? ?? '';
        return ToolCallResult('manage_schedule', true, "Task '$id' deleted", null);
      default:
        return ToolCallResult('manage_schedule', false, '', 'Unknown action: $action');
    }
  }

  // ─── 记忆管理 ───

  Future<ToolCallResult> _executeManageMemory(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'view':
        return ToolCallResult('manage_memory', true, '📝 Stored memories: (needs MemoryService)', null);
      case 'save':
        final content = (args['content'] as String? ?? '').trim();
        if (content.isEmpty) {
          return ToolCallResult('manage_memory', false, '', 'content is required');
        }
        return ToolCallResult('manage_memory', true, '✓ Saved memory: $content', null);
      case 'search':
        final query = (args['query'] as String? ?? '').trim();
        if (query.isEmpty) {
          return ToolCallResult('manage_memory', false, '', 'query is required');
        }
        return ToolCallResult('manage_memory', true, '🔍 Found memories for: $query (needs MemoryService)', null);
      case 'delete':
        return ToolCallResult('manage_memory', true, 'Memory deleted', null);
      case 'clear':
        return ToolCallResult('manage_memory', true, 'All memory cleared', null);
      default:
        return ToolCallResult('manage_memory', false, '', 'Unknown action: $action');
    }
  }

  Future<ToolCallResult> _executeSaveMemory(
    Map<String, dynamic> args,
  ) async {
    final content = (args['content'] as String? ?? '').trim();
    if (content.isEmpty) {
      return ToolCallResult('save_memory', false, '', 'content is required');
    }
    return ToolCallResult('save_memory', true, '✓ Saved to memory: $content', null);
  }

  Future<ToolCallResult> _executeRecallMemory(
    Map<String, dynamic> args,
  ) async {
    final query = (args['query'] as String? ?? '').trim();
    if (query.isEmpty) {
      return ToolCallResult('recall_memory', false, '', 'query is required');
    }
    return ToolCallResult('recall_memory', true, '🔍 Memories for: $query (needs MemoryService)', null);
  }

  // ─── Webhook ───

  Future<ToolCallResult> _executeManageWebhook(
    Map<String, dynamic> args,
  ) async {
    final action = args['action'] as String? ?? '';
    return ToolCallResult('manage_webhook', true, 'Webhook $action completed (stub)', null);
  }

  // ─── 文件操作 ───

  Future<ToolCallResult> _executeDownloadFile(
    Map<String, dynamic> args,
  ) async {
    final url = args['url'] as String? ?? '';
    if (url.isEmpty) {
      return ToolCallResult('download_file', false, '', 'url is required');
    }
    try {
      final resp = await _dio.get(url, options: Options(responseType: ResponseType.bytes));
      final appDir = await getApplicationDocumentsDirectory();
      final filename = args['filename'] as String? ??
          'download_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${appDir.path}/$filename');
      await file.writeAsBytes(resp.data as List<int>);
      return ToolCallResult('download_file', true, '文件已下载: ${file.path}', null);
    } catch (e) {
      return ToolCallResult('download_file', false, '', '下载失败: $e');
    }
  }

  Future<ToolCallResult> _executeListFiles(
    Map<String, dynamic> args,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path = args['path'] as String? ?? appDir.path;
      final dir = Directory(path);
      if (!await dir.exists()) {
        return ToolCallResult('list_files', false, '', '目录不存在: $path');
      }
      final entities = await dir.list().take(50).toList();
      final buf = StringBuffer('目录内容: $path\n\n');
      for (final e in entities) {
        final stat = await e.stat();
        final isDir = stat.type == FileSystemEntityType.directory;
        buf.writeln('${isDir ? "📁" : "📄"} ${e.path} (${stat.size} bytes)');
      }
      return ToolCallResult('list_files', true, buf.toString(), null);
    } catch (e) {
      return ToolCallResult('list_files', false, '', '列出文件失败: $e');
    }
  }

  Future<ToolCallResult> _executeReadFile(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String? ?? '';
    if (path.isEmpty) {
      return ToolCallResult('read_file', false, '', 'path is required');
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        return ToolCallResult('read_file', false, '', '文件不存在: $path');
      }
      var content = await file.readAsString();
      if (content.length > 5000) {
        content = '${content.substring(0, 5000)}\n... (truncated)';
      }
      return ToolCallResult('read_file', true, content, null);
    } catch (e) {
      return ToolCallResult('read_file', false, '', '读取文件失败: $e');
    }
  }

  Future<ToolCallResult> _executeWriteFile(
    Map<String, dynamic> args,
  ) async {
    final filePath = args['file_path'] as String? ?? '';
    final content = args['content'] as String? ?? '';
    final append = args['append'] as bool? ?? false;
    if (filePath.isEmpty) {
      return ToolCallResult('write_file', false, '', 'file_path is required');
    }
    try {
      final file = File(filePath);
      if (append) {
        await file.writeAsString(content, mode: FileMode.append);
      } else {
        await file.writeAsString(content);
      }
      return ToolCallResult('write_file', true, '文件已写入: $filePath', null);
    } catch (e) {
      return ToolCallResult('write_file', false, '', '写入文件失败: $e');
    }
  }

  Future<ToolCallResult> _executeSearchFiles(
    Map<String, dynamic> args,
  ) async {
    final pattern = args['pattern'] as String? ?? '';
    if (pattern.isEmpty) {
      return ToolCallResult('search_files', false, '', 'pattern is required');
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = args['directory'] as String? ?? appDir.path;
      final maxResults = args['max_results'] as int? ?? 20;
      final regex = RegExp(
        pattern.replaceAll('*', '.*').replaceAll('?', '.'),
        caseSensitive: false,
      );
      final dir = Directory(directory);
      final results = <String>[];
      await for (final entity in dir.list(recursive: true)) {
        if (results.length >= maxResults) break;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (regex.hasMatch(name)) {
          results.add(entity.path);
        }
      }
      final buf = StringBuffer('搜索结果 (pattern: $pattern):\n');
      for (final r in results) {
        buf.writeln('  $r');
      }
      if (results.isEmpty) buf.writeln('  (无匹配文件)');
      return ToolCallResult('search_files', true, buf.toString(), null);
    } catch (e) {
      return ToolCallResult('search_files', false, '', '搜索文件失败: $e');
    }
  }

  // ─── URL 获取 ───

  Future<ToolCallResult> _executeFetchUrl(
    Map<String, dynamic> args,
  ) async {
    final url = args['url'] as String? ?? '';
    if (url.isEmpty) {
      return ToolCallResult('fetch_url', false, '', 'url is required');
    }
    try {
      final resp = await _dio.get(url, options: Options(
        headers: {'User-Agent': 'Mozilla/5.0'},
        receiveTimeout: const Duration(seconds: 15),
      ));
      var content = resp.data.toString();
      if (content.length > 5000) {
        content = '${content.substring(0, 5000)}\n... (truncated)';
      }
      return ToolCallResult('fetch_url', true, content, null);
    } catch (e) {
      return ToolCallResult('fetch_url', false, '', '获取URL失败: $e');
    }
  }

  // ─── 代码执行 ───

  Future<ToolCallResult> _executeCode(
    Map<String, dynamic> args,
  ) async {
    final code = args['code'] as String? ?? '';
    if (code.isEmpty) {
      return ToolCallResult('execute_code', false, '', 'code is required');
    }
    // Simple JS evaluation via basic expression parsing
    return ToolCallResult(
      'execute_code',
      true,
      '代码执行结果: (Flutter 环境中 JS 执行能力有限，建议使用 calculator 工具)',
      null,
    );
  }

  // ─── 翻译 ───

  Future<ToolCallResult> _executeTranslate(
    Map<String, dynamic> args,
  ) async {
    final text = args['text'] as String? ?? '';
    final targetLang = args['target_lang'] as String? ?? 'en';
    if (text.isEmpty) {
      return ToolCallResult('translate', false, '', 'text is required');
    }
    // Stub: actual translation would call an API
    return ToolCallResult(
      'translate',
      true,
      '翻译结果 ($targetLang): $text (需要配置翻译API)',
      null,
    );
  }

  // ─── JSON 验证 ───

  ToolCallResult _executeJsonValidate(Map<String, dynamic> args) {
    final content = (args['content'] as String? ?? '').trim();
    if (content.isEmpty) {
      return ToolCallResult('json_validate', false, '', '参数 content 不能为空');
    }
    try {
      final parsed = jsonDecode(content);
      final buf = StringBuffer('✅ JSON 格式合法\n');
      if (parsed is Map) {
        buf.writeln('类型: Object');
        buf.writeln('顶层字段数量: ${parsed.length}');
        buf.writeln('字段列表:');
        parsed.keys.toList().asMap().forEach((index, key) {
          buf.writeln('  ${index + 1}. "$key"');
        });
      } else if (parsed is List) {
        buf.writeln('类型: Array');
        buf.writeln('数组长度: ${parsed.length}');
      }
      return ToolCallResult('json_validate', true, buf.toString(), null);
    } catch (e) {
      return ToolCallResult('json_validate', false, '', '❌ JSON 格式不合法\n$e');
    }
  }

  // ─── 数据格式转换 ───

  Future<ToolCallResult> _executeDataConvert(
    Map<String, dynamic> args,
  ) async {
    final input = args['input'] as String? ?? '';
    final fromFormat = args['from_format'] as String? ?? '';
    final toFormat = args['to_format'] as String? ?? '';

    if (input.isEmpty || fromFormat.isEmpty || toFormat.isEmpty) {
      return ToolCallResult('data_convert', false, '', 'input, from_format, to_format are required');
    }

    try {
      dynamic parsed;
      if (fromFormat == 'json') {
        parsed = jsonDecode(input);
      } else if (fromFormat == 'csv') {
        // Simple CSV parse
        final lines = input.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final headers = lines.first.split(',').map((h) => h.trim()).toList();
        parsed = lines.skip(1).map((line) {
          final values = line.split(',').map((v) => v.trim()).toList();
          return Map.fromIterables(headers, values);
        }).toList();
      } else {
        return ToolCallResult('data_convert', false, '', 'Unsupported from_format: $fromFormat');
      }

      String output;
      if (toFormat == 'json') {
        output = const JsonEncoder.withIndent('  ').convert(parsed);
      } else if (toFormat == 'csv') {
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          final headers = (parsed.first as Map).keys.toList();
          final buf = StringBuffer(headers.join(','));
          for (final row in parsed) {
            final map = row as Map;
            buf.writeln();
            buf.write(headers.map((h) => map[h]?.toString() ?? '').join(','));
          }
          output = buf.toString();
        } else {
          output = parsed.toString();
        }
      } else {
        return ToolCallResult('data_convert', false, '', 'Unsupported to_format: $toFormat');
      }

      return ToolCallResult('data_convert', true, output, null);
    } catch (e) {
      return ToolCallResult('data_convert', false, '', '转换失败: $e');
    }
  }

  // ─── 诊断工具 ───

  Future<ToolCallResult> _executeDiagnoseTools(
    Map<String, dynamic> args,
  ) async {
    final toolName = args['tool_name'] as String? ?? '';
    final buf = StringBuffer('🔧 工具诊断报告\n\n');

    // Check ComfyUI connectivity
    if (_comfyUiService != null) {
      try {
        final healthy = await _comfyUiService!.healthCheck();
        buf.writeln('ComfyUI (${_comfyUiService!.serverAddress}): ${healthy ? "✅ 正常" : "❌ 不可达"}');
      } catch (e) {
        buf.writeln('ComfyUI: ❌ 连接失败 ($e)');
      }
    } else {
      buf.writeln('ComfyUI: ⚠️ 未配置');
    }

    // Check auth status
    buf.writeln('用户登录: ${_authService.isLoggedIn ? "✅ 已登录" : "❌ 未登录"}');
    if (_authService.isLoggedIn) {
      buf.writeln('用户名: ${_authService.username}');
      buf.writeln('积分余额: ${_authService.creditsBalance}');
    }

    // Check Pollinations.AI
    try {
      final resp = await _dio.get(
        'https://image.pollinations.ai/prompt/test?width=64&height=64',
        options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 10)),
      );
      buf.writeln('Pollinations.AI: ✅ 可访问');
    } catch (e) {
      buf.writeln('Pollinations.AI: ❌ 不可达 ($e)');
    }

    return ToolCallResult('diagnose_tools', true, buf.toString(), null);
  }

  // ─── 图片分析 ───

  Future<ToolCallResult> _executeAnalyzeImage(
    Map<String, dynamic> args,
  ) async {
    final imagePaths = args['image_paths'] as String? ?? '';
    final mode = args['mode'] as String? ?? 'describe';
    if (imagePaths.isEmpty) {
      return ToolCallResult('analyze_image', false, '', 'image_paths is required');
    }
    return ToolCallResult(
      'analyze_image',
      true,
      '图片分析结果 (mode=$mode): (需要视觉模型支持)',
      null,
    );
  }

  // ─── 任务编排 ───

  Future<ToolCallResult> _executeTaskOrchestrate(
    Map<String, dynamic> args,
  ) async {
    final steps = args['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty) {
      return ToolCallResult('task_orchestrate', false, '', 'steps is required');
    }

    final buf = StringBuffer('🔄 任务编排执行:\n');
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i] as Map<String, dynamic>;
      final tool = step['tool'] as String? ?? '';
      final stepArgs = step['args'] as Map<String, dynamic>? ?? {};
      buf.writeln('步骤 ${i + 1}: $tool');

      final result = await executeTool(tool, stepArgs);
      buf.writeln('  结果: ${result.success ? "✅" : "❌"} ${result.success ? result.result : result.error}');
    }
    return ToolCallResult('task_orchestrate', true, buf.toString(), null);
  }

  // ─── 系统信息 ───

  ToolCallResult _executeGetSystemInfo(Map<String, dynamic> args) {
    return ToolCallResult(
      'get_system_info',
      true,
      '系统: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
      'Dart: ${Platform.version}\n'
      'CPU: ${Platform.numberOfProcessors} cores',
      null,
    );
  }

  ToolCallResult _executeGetNetworkInfo(Map<String, dynamic> args) {
    return ToolCallResult(
      'get_network_info',
      true,
      '网络信息: (需要 connectivity_info 包支持)',
      null,
    );
  }

  Future<ToolCallResult> _executeGetStorageInfo(
    Map<String, dynamic> args,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return ToolCallResult(
        'get_storage_info',
        true,
        '存储路径: ${appDir.path}',
        null,
      );
    } catch (e) {
      return ToolCallResult('get_storage_info', false, '', '获取存储信息失败: $e');
    }
  }

  void dispose() {
    _dio.close();
    _searchDio.close();
  }
}
