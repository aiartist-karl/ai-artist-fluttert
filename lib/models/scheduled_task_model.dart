import 'dart:convert';

/// 定时任务模型
/// 对应 Android: ScheduledTask
class ScheduledTask {
  final String id;
  final String name;
  final String taskType; // "generate_image", "backup", "cleanup"
  final String cronExpression;
  final int intervalMinutes;
  final bool enabled;
  final String params; // JSON string
  final int lastRunTime;
  final int createdAt;

  ScheduledTask({
    required this.id,
    required this.name,
    this.taskType = 'generate_image',
    this.cronExpression = '',
    this.intervalMinutes = 60,
    this.enabled = true,
    this.params = '{}',
    this.lastRunTime = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      taskType: json['taskType'] as String? ?? 'generate_image',
      cronExpression: json['cronExpression'] as String? ?? '',
      intervalMinutes: json['intervalMinutes'] as int? ?? 60,
      enabled: json['enabled'] as bool? ?? true,
      params: json['params'] as String? ?? '{}',
      lastRunTime: json['lastRunTime'] as int? ?? 0,
      createdAt: json['createdAt'] as int?,
    );
  }

  factory ScheduledTask.fromJsonString(String jsonString) {
    return ScheduledTask.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'taskType': taskType,
        'cronExpression': cronExpression,
        'intervalMinutes': intervalMinutes,
        'enabled': enabled,
        'params': params,
        'lastRunTime': lastRunTime,
        'createdAt': createdAt,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 解析 params JSON 字符串为 Map
  Map<String, dynamic> get paramsMap {
    try {
      return jsonDecode(params) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// 上次运行时间
  DateTime? get lastRunDateTime =>
      lastRunTime > 0 ? DateTime.fromMillisecondsSinceEpoch(lastRunTime) : null;

  /// 创建时间
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  static String generateId() => 'task_${DateTime.now().millisecondsSinceEpoch}';

  ScheduledTask copyWith({
    String? id,
    String? name,
    String? taskType,
    String? cronExpression,
    int? intervalMinutes,
    bool? enabled,
    String? params,
    int? lastRunTime,
    int? createdAt,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      name: name ?? this.name,
      taskType: taskType ?? this.taskType,
      cronExpression: cronExpression ?? this.cronExpression,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      enabled: enabled ?? this.enabled,
      params: params ?? this.params,
      lastRunTime: lastRunTime ?? this.lastRunTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ScheduledTask && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScheduledTask(id: $id, name: $name, type: $taskType, enabled: $enabled)';
}

/// 定时任务执行记录
/// 对应 Android: ScheduledTaskExecution
class ScheduledTaskExecution {
  final String id;
  final String taskId;
  final String taskName;
  final String taskType;
  final bool success;
  final String resultMessage;
  final int executedAt;
  final int durationMs;

  ScheduledTaskExecution({
    required this.id,
    required this.taskId,
    required this.taskName,
    this.taskType = '',
    this.success = false,
    this.resultMessage = '',
    int? executedAt,
    this.durationMs = 0,
  }) : executedAt = executedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ScheduledTaskExecution.fromJson(Map<String, dynamic> json) {
    return ScheduledTaskExecution(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      taskName: json['taskName'] as String? ?? '',
      taskType: json['taskType'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      resultMessage: json['resultMessage'] as String? ?? '',
      executedAt: json['executedAt'] as int?,
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  factory ScheduledTaskExecution.fromJsonString(String jsonString) {
    return ScheduledTaskExecution.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskName': taskName,
        'taskType': taskType,
        'success': success,
        'resultMessage': resultMessage,
        'executedAt': executedAt,
        'durationMs': durationMs,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 执行时间
  DateTime get executedDateTime =>
      DateTime.fromMillisecondsSinceEpoch(executedAt);

  /// 执行时长（秒）
  double get durationSeconds => durationMs / 1000.0;

  static String generateId() => 'exec_${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ScheduledTaskExecution && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScheduledTaskExecution(id: $id, taskId: $taskId, success: $success)';
}
