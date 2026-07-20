import 'dart:convert';

/// 记忆分类枚举
/// 对应 Android: MemoryCategory enum
enum MemoryCategory {
  stylePreference('风格偏好', '🎨'),
  parameterPreference('参数偏好', '⚙️'),
  contentPreference('内容偏好', '💬'),
  workflowHabit('工作习惯', '🕐'),
  featureUsage('功能使用', '🔧'),
  creativeTaste('创作口味', '✨'),
  userFact('用户信息', '👤'),
  general('通用', '📝');

  final String displayName;
  final String icon;

  const MemoryCategory(this.displayName, this.icon);

  static MemoryCategory fromString(String value) {
    return MemoryCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemoryCategory.general,
    );
  }
}

/// 记忆重要性枚举
/// 对应 Android: MemoryImportance enum
enum MemoryImportance {
  low(1, '低'),
  medium(3, '中'),
  high(5, '高'),
  critical(10, '关键');

  final int weight;
  final String displayName;

  const MemoryImportance(this.weight, this.displayName);

  static MemoryImportance fromInt(int value) {
    return MemoryImportance.values.firstWhere(
      (e) => e.weight == value,
      orElse: () => MemoryImportance.medium,
    );
  }
}

/// 用户记忆实体
/// 对应 Android: UserMemoryEntity (Room Entity)
class UserMemoryEntity {
  final int id;
  final String content;
  final String category;
  final int importance;
  final String source;
  final String context;
  final int accessCount;
  final int lastAccessed;
  final bool isActive;
  final int createdAt;
  final int expiresAt;
  final String note;

  UserMemoryEntity({
    this.id = 0,
    required this.content,
    this.category = 'GENERAL',
    this.importance = 3,
    this.source = 'observation',
    this.context = '',
    this.accessCount = 0,
    this.lastAccessed = 0,
    this.isActive = true,
    int? createdAt,
    this.expiresAt = 0,
    this.note = '',
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory UserMemoryEntity.fromJson(Map<String, dynamic> json) {
    return UserMemoryEntity(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'GENERAL',
      importance: json['importance'] as int? ?? 3,
      source: json['source'] as String? ?? 'observation',
      context: json['context'] as String? ?? '',
      accessCount: json['accessCount'] as int? ?? 0,
      lastAccessed: json['lastAccessed'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as int?,
      expiresAt: json['expiresAt'] as int? ?? 0,
      note: json['note'] as String? ?? '',
    );
  }

  factory UserMemoryEntity.fromJsonString(String jsonString) {
    return UserMemoryEntity.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'category': category,
        'importance': importance,
        'source': source,
        'context': context,
        'accessCount': accessCount,
        'lastAccessed': lastAccessed,
        'isActive': isActive,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'note': note,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 获取分类枚举
  MemoryCategory get memoryCategory => MemoryCategory.fromString(category);

  /// 获取重要性枚举
  MemoryImportance get memoryImportance => MemoryImportance.fromInt(importance);

  /// 是否已过期
  bool get isExpired {
    if (expiresAt <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  /// 创建时间
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  UserMemoryEntity copyWith({
    int? id,
    String? content,
    String? category,
    int? importance,
    String? source,
    String? context,
    int? accessCount,
    int? lastAccessed,
    bool? isActive,
    int? createdAt,
    int? expiresAt,
    String? note,
  }) {
    return UserMemoryEntity(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      source: source ?? this.source,
      context: context ?? this.context,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserMemoryEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserMemoryEntity(id: $id, category: $category, importance: $importance, active: $isActive)';
}

/// 记忆统计
/// 对应 Android: MemoryStats
class MemoryStats {
  final int totalMemories;
  final int activeMemories;
  final Map<MemoryCategory, int> byCategory;
  final MemoryCategory? mostAccessedCategory;
  final int recentMemoryCount;

  const MemoryStats({
    this.totalMemories = 0,
    this.activeMemories = 0,
    this.byCategory = const {},
    this.mostAccessedCategory,
    this.recentMemoryCount = 0,
  });

  factory MemoryStats.fromJson(Map<String, dynamic> json) {
    return MemoryStats(
      totalMemories: json['totalMemories'] as int? ?? 0,
      activeMemories: json['activeMemories'] as int? ?? 0,
      byCategory: (json['byCategory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(MemoryCategory.fromString(k), v as int),
          ) ??
          {},
      mostAccessedCategory: json['mostAccessedCategory'] != null
          ? MemoryCategory.fromString(json['mostAccessedCategory'] as String)
          : null,
      recentMemoryCount: json['recentMemoryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalMemories': totalMemories,
        'activeMemories': activeMemories,
        'byCategory': byCategory.map((k, v) => MapEntry(k.name, v)),
        'mostAccessedCategory': mostAccessedCategory?.name,
        'recentMemoryCount': recentMemoryCount,
      };
}

/// 记忆注入上下文
/// 对应 Android: MemoryContext
class MemoryContext {
  final List<UserMemoryEntity> memories;
  final String systemPrompt;
  final int tokenEstimate;

  const MemoryContext({
    this.memories = const [],
    this.systemPrompt = '',
    this.tokenEstimate = 0,
  });

  /// 将记忆列表格式化为系统提示词注入内容
  static String formatForSystemPrompt(List<UserMemoryEntity> memories) {
    if (memories.isEmpty) return '';

    final grouped = <MemoryCategory, List<UserMemoryEntity>>{};
    for (final m in memories) {
      final cat = m.memoryCategory;
      grouped.putIfAbsent(cat, () => []).add(m);
    }

    final buffer = StringBuffer();
    buffer.writeln('\n[用户记忆 - 以下信息来自用户的本地记忆，请在回复时适当参考：]');

    for (final entry in grouped.entries) {
      final category = entry.key;
      final items = entry.value;
      buffer.writeln('${category.icon} ${category.displayName}：');
      items.sort((a, b) => b.importance.compareTo(a.importance));
      for (final memory in items) {
        buffer.writeln('  - ${memory.content}');
      }
    }

    buffer.writeln('[/用户记忆]');
    return buffer.toString().trim();
  }

  /// 估算 token 数量（粗略估算：中文约1.5字/token，英文约4字符/token）
  static int estimateTokens(List<UserMemoryEntity> memories) {
    final totalChars = memories.fold<int>(0, (sum, m) => sum + m.content.length);
    return (totalChars / 2).ceil();
  }
}
