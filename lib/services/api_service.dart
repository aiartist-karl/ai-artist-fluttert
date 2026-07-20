import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// AI 服务提供者枚举
enum ServiceProvider {
  ollama('Ollama'),
  openaiCompatible('OpenAI Compatible'),
  anthropic('Anthropic'),
  custom('Custom');

  final String displayName;
  const ServiceProvider(this.displayName);
}

/// AI 服务实例配置
class ApiService {
  final String id;
  String name;
  ServiceProvider provider;
  String baseUrl;
  String apiKey;
  List<String> models;
  bool enabled;
  int maxConcurrent;
  int timeoutSeconds;
  int maxRetries;
  int priority;
  int quotaPerDay; // -1 = unlimited
  List<String> taskTypes;
  int createdAt;
  int lastHealthCheck;
  bool isHealthy;
  int totalRequests;
  int failedRequests;
  int totalTokens;
  double totalCostEstimate;

  ApiService({
    String? id,
    this.name = '',
    this.provider = ServiceProvider.openaiCompatible,
    this.baseUrl = '',
    this.apiKey = '',
    this.models = const [],
    this.enabled = true,
    this.maxConcurrent = 3,
    this.timeoutSeconds = 60,
    this.maxRetries = 3,
    this.priority = 0,
    this.quotaPerDay = -1,
    this.taskTypes = const ['text', 'chat'],
    int? createdAt,
    this.lastHealthCheck = 0,
    this.isHealthy = true,
    this.totalRequests = 0,
    this.failedRequests = 0,
    this.totalTokens = 0,
    this.totalCostEstimate = 0.0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'models': models,
        'enabled': enabled,
        'maxConcurrent': maxConcurrent,
        'timeoutSeconds': timeoutSeconds,
        'maxRetries': maxRetries,
        'priority': priority,
        'quotaPerDay': quotaPerDay,
        'taskTypes': taskTypes,
        'createdAt': createdAt,
        'lastHealthCheck': lastHealthCheck,
        'isHealthy': isHealthy,
        'totalRequests': totalRequests,
        'failedRequests': failedRequests,
        'totalTokens': totalTokens,
        'totalCostEstimate': totalCostEstimate,
      };

  factory ApiService.fromJson(Map<String, dynamic> json) {
    ServiceProvider provider;
    try {
      provider = ServiceProvider.values.firstWhere(
        (e) => e.name == (json['provider'] ?? 'openaiCompatible'),
      );
    } catch (_) {
      provider = ServiceProvider.openaiCompatible;
    }
    return ApiService(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      provider: provider,
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      models: (json['models'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      enabled: json['enabled'] as bool? ?? true,
      maxConcurrent: json['maxConcurrent'] as int? ?? 3,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 60,
      maxRetries: json['maxRetries'] as int? ?? 3,
      priority: json['priority'] as int? ?? 0,
      quotaPerDay: json['quotaPerDay'] as int? ?? -1,
      taskTypes: (json['taskTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['text', 'chat'],
      createdAt: json['createdAt'] as int?,
      lastHealthCheck: json['lastHealthCheck'] as int? ?? 0,
      isHealthy: json['isHealthy'] as bool? ?? true,
      totalRequests: json['totalRequests'] as int? ?? 0,
      failedRequests: json['failedRequests'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      totalCostEstimate: (json['totalCostEstimate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ApiService withUpdatedStats({
    required int requests,
    required int failed,
    required int tokens,
    required double cost,
  }) {
    return ApiService(
      id: id,
      name: name,
      provider: provider,
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: models,
      enabled: enabled,
      maxConcurrent: maxConcurrent,
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
      priority: priority,
      quotaPerDay: quotaPerDay,
      taskTypes: taskTypes,
      createdAt: createdAt,
      lastHealthCheck: lastHealthCheck,
      isHealthy: isHealthy,
      totalRequests: totalRequests + requests,
      failedRequests: failedRequests + failed,
      totalTokens: totalTokens + tokens,
      totalCostEstimate: totalCostEstimate + cost,
    );
  }
}

/// 网关请求
class GatewayRequest {
  final String taskId;
  final String taskType;
  final String prompt;
  final String? model;
  final int maxTokens;
  final double temperature;
  final String? preferredServiceId;
  final Map<String, String> metadata;

  GatewayRequest({
    String? taskId,
    this.taskType = 'text',
    this.prompt = '',
    this.model,
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.preferredServiceId,
    this.metadata = const {},
  }) : taskId = taskId ?? const Uuid().v4();
}

/// 网关响应
class GatewayResponse {
  final bool success;
  final String serviceId;
  final String serviceName;
  final String model;
  final String content;
  final int tokensUsed;
  final int durationMs;
  final double costEstimate;
  final String? error;
  final int retryCount;

  GatewayResponse({
    required this.success,
    this.serviceId = '',
    this.serviceName = '',
    this.model = '',
    this.content = '',
    this.tokensUsed = 0,
    this.durationMs = 0,
    this.costEstimate = 0.0,
    this.error,
    this.retryCount = 0,
  });
}

/// 每日用量记录
class DailyUsageRecord {
  final String date; // yyyy-MM-dd
  final int requestCount;
  final int successCount;
  final int failedCount;
  final int tokensUsed;
  final double costEstimate;
  final int avgResponseTimeMs;
  final Map<String, int> agentUsage;

  DailyUsageRecord({
    required this.date,
    this.requestCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.tokensUsed = 0,
    this.costEstimate = 0.0,
    this.avgResponseTimeMs = 0,
    this.agentUsage = const {},
  });
}

/// 时间桶
class TimeBucket {
  final String label;
  final double value;

  TimeBucket({required this.label, required this.value});
}

/// 配额用量
class QuotaUsage {
  final String serviceId;
  final String date;
  final int used;
  final int limit;

  QuotaUsage({
    required this.serviceId,
    required this.date,
    this.used = 0,
    this.limit = -1,
  });

  int get remaining => limit < 0 ? 999999 : (limit - used).clamp(0, 999999);
  double get usagePercent =>
      limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
  bool get isExceeded => limit >= 0 && used >= limit;
}

/// API 服务管理器：对话、流式、健康检查
class ApiServiceManager {
  final Dio _dio;
  final List<ApiService> _services = [];

  ApiServiceManager({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  List<ApiService> get services => List.unmodifiable(_services);

  void addService(ApiService service) {
    _services.add(service);
    _services.sort((a, b) => b.priority.compareTo(a.priority));
  }

  void removeService(String id) {
    _services.removeWhere((s) => s.id == id);
  }

  ApiService? getBestService({String taskType = 'text'}) {
    for (final s in _services) {
      if (s.enabled && s.isHealthy && s.taskTypes.contains(taskType)) {
        return s;
      }
    }
    return null;
  }

  /// 发送对话请求（非流式）
  Future<GatewayResponse> chat({
    required String serviceId,
    required List<Map<String, dynamic>> messages,
    String? model,
    int maxTokens = 2048,
    double temperature = 0.7,
  }) async {
    final service = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw Exception('Service not found: $serviceId'),
    );

    final body = {
      'model': model ?? (service.models.isNotEmpty ? service.models.first : ''),
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    final headers = <String, dynamic>{};
    if (service.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${service.apiKey}';
    }

    final sw = Stopwatch()..start();
    try {
      final resp = await _dio.post(
        '${service.baseUrl}/v1/chat/completions',
        data: body,
        options: Options(headers: headers),
      );
      sw.stop();

      final data = resp.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      final content = (choices != null && choices.isNotEmpty)
          ? (choices[0]['message']['content'] as String? ?? '')
          : '';
      final usage = data['usage'] as Map<String, dynamic>?;

      return GatewayResponse(
        success: true,
        serviceId: service.id,
        serviceName: service.name,
        model: data['model'] as String? ?? '',
        content: content,
        tokensUsed: usage?['total_tokens'] as int? ?? 0,
        durationMs: sw.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      sw.stop();
      return GatewayResponse(
        success: false,
        serviceId: service.id,
        serviceName: service.name,
        error: e.message ?? 'Request failed',
        durationMs: sw.elapsedMilliseconds,
      );
    }
  }

  /// 流式对话请求
  Stream<String> chatStream({
    required String serviceId,
    required List<Map<String, dynamic>> messages,
    String? model,
    int maxTokens = 2048,
    double temperature = 0.7,
  }) async* {
    final service = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw Exception('Service not found: $serviceId'),
    );

    final body = {
      'model': model ?? (service.models.isNotEmpty ? service.models.first : ''),
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': true,
    };

    final headers = <String, dynamic>{};
    if (service.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${service.apiKey}';
    }

    final resp = await _dio.post(
      '${service.baseUrl}/v1/chat/completions',
      data: body,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );

    final stream = resp.data.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.isEmpty) continue;
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data == '[DONE]') break;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices[0]['delta'];
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {
        // skip malformed chunks
      }
    }
  }

  /// 健康检查
  Future<bool> healthCheck(ApiService service) async {
    try {
      final resp = await _dio.get(
        '${service.baseUrl}/v1/models',
        options: Options(
          headers: service.apiKey.isNotEmpty
              ? {'Authorization': 'Bearer ${service.apiKey}'}
              : {},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}
