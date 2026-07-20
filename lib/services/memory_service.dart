import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 记忆分类
enum MemoryCategory {
  general('通用'),
  stylePreference('风格偏好'),
  parameterPreference('参数偏好'),
  workflowHabit('工作流习惯'),
  userFact('用户信息'),
  technicalNote('技术备注');

  final String displayName;
  const MemoryCategory(this.displayName);
}

/// 记忆重要度
enum MemoryImportance {
  low(1),
  medium(5),
  high(8),
  critical(10);

  final int weight;
  const MemoryImportance(this.weight);

  static MemoryImportance fromWeight(int w) {
    if (w >= 10) return critical;
    if (w >= 8) return high;
    if (w >= 5) return medium;
    return low;
  }
}

/// 用户记忆实体
class UserMemory {
  final int id;
  final String content;
  final MemoryCategory category;
  final MemoryImportance importance;
  final String source; // observation, conversation, tool_call
  final String context;
  final int createdAt;
  final int lastAccessed;
  final int accessCount;
  final bool active;
  final int expiresAt; // 0 = never
  final String note;

  UserMemory({
    required this.id,
    required this.content,
    this.category = MemoryCategory.general,
    this.importance = MemoryImportance.medium,
    this.source = 'observation',
    this.context = '',
    int? createdAt,
    int? lastAccessed,
    this.accessCount = 0,
    this.active = true,
    this.expiresAt = 0,
    this.note = '',
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        lastAccessed = lastAccessed ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'category': category.name,
        'importance': importance.weight,
        'source': source,
        'context': context,
        'createdAt': createdAt,
        'lastAccessed': lastAccessed,
        'accessCount': accessCount,
        'active': active,
        'expiresAt': expiresAt,
        'note': note,
      };

  factory UserMemory.fromJson(Map<String, dynamic> json) => UserMemory(
        id: json['id'] as int? ?? 0,
        content: json['content'] as String? ?? '',
        category: _parseCategory(json['category'] as String?),
        importance: MemoryImportance.fromWeight(json['importance'] as int? ?? 5),
        source: json['source'] as String? ?? 'observation',
        context: json['context'] as String? ?? '',
        createdAt: json['createdAt'] as int?,
        lastAccessed: json['lastAccessed'] as int?,
        accessCount: json['accessCount'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
        expiresAt: json['expiresAt'] as int? ?? 0,
        note: json['note'] as String? ?? '',
      );

  static MemoryCategory _parseCategory(String? s) {
    try {
      return MemoryCategory.values.firstWhere((e) => e.name == s);
    } catch (_) {
      return MemoryCategory.general;
    }
  }
}

/// 记忆上下文（注入用）
class MemoryContext {
  final List<UserMemory> memories;
  final String systemPrompt;
  final int tokenEstimate;

  MemoryContext({
    required this.memories,
    required this.systemPrompt,
    required this.tokenEstimate,
  });

  /// 格式化为系统提示词
  static String formatForSystemPrompt(List<UserMemory> memories) {
    if (memories.isEmpty) return '';
    final buf = StringBuffer('[用户记忆]\n');
    for (final m in memories) {
      buf.writeln('- [${m.category.displayName}] ${m.content}');
    }
    return buf.toString();
  }

  /// 粗略估算 token 数
  static int estimateTokens(List<UserMemory> memories) {
    var chars = 0;
    for (final m in memories) {
      chars += m.content.length;
    }
    return (chars / 3.5).ceil(); // rough estimate for CJK
  }
}

/// 记忆统计
class MemoryStats {
  final int totalMemories;
  final int activeMemories;
  final Map<MemoryCategory, int> byCategory;
  final MemoryCategory? mostAccessedCategory;
  final int recentMemoryCount; // last 7 days

  MemoryStats({
    required this.totalMemories,
    required this.activeMemories,
    required this.byCategory,
    this.mostAccessedCategory,
    required this.recentMemoryCount,
  });
}

/// 记忆管理服务
/// 所有数据存储在 SharedPreferences 中
class MemoryService {
  static const String _prefsKey = 'user_memories_json';
  static const int maxInjectionMemories = 10;
  static const int maxInjectionTokens = 800;
  static const int memoryDecayDays = 90;
  static const int maxTotalMemories = 500;

  SharedPreferences? _prefs;
  List<UserMemory> _memories = [];
  int _nextId = 1;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final jsonStr = _prefs?.getString(_prefsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _memories = [];
      _nextId = 1;
      return;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _memories = list
          .map((e) => UserMemory.fromJson(e as Map<String, dynamic>))
          .toList();
      _nextId = _memories.isEmpty
          ? 1
          : _memories.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _memories = [];
      _nextId = 1;
    }
  }

  Future<void> _saveToPrefs() async {
    final jsonStr = jsonEncode(_memories.map((e) => e.toJson()).toList());
    await _prefs?.setString(_prefsKey, jsonStr);
  }

  // ─── CRUD ───

  Future<int> addMemory({
    required String content,
    MemoryCategory category = MemoryCategory.general,
    MemoryImportance importance = MemoryImportance.medium,
    String source = 'observation',
    String context = '',
    int expiresAtDays = 0,
  }) async {
    // 检查总量限制
    if (_memories.where((m) => m.active).length >= maxTotalMemories) {
      await _evictLowPriorityMemories();
    }

    final expiresAt = expiresAtDays > 0
        ? DateTime.now().millisecondsSinceEpoch +
            Duration(days: expiresAtDays).inMilliseconds
        : 0;

    final memory = UserMemory(
      id: _nextId++,
      content: content.trim(),
      category: category,
      importance: importance,
      source: source,
      context: context,
      expiresAt: expiresAt,
    );
    _memories.add(memory);
    await _saveToPrefs();
    return memory.id;
  }

  Future<bool> updateMemory(UserMemory updated) async {
    final idx = _memories.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return false;
    _memories[idx] = updated;
    await _saveToPrefs();
    return true;
  }

  /// 软删除
  Future<bool> deleteMemory(int memoryId) async {
    final idx = _memories.indexWhere((m) => m.id == memoryId);
    if (idx == -1) return false;
    final m = _memories[idx];
    _memories[idx] = UserMemory(
      id: m.id,
      content: m.content,
      category: m.category,
      importance: m.importance,
      source: m.source,
      context: m.context,
      createdAt: m.createdAt,
      lastAccessed: m.lastAccessed,
      accessCount: m.accessCount,
      active: false,
      expiresAt: m.expiresAt,
      note: m.note,
    );
    await _saveToPrefs();
    return true;
  }

  /// 彻底删除
  Future<bool> permanentlyDeleteMemory(int memoryId) async {
    _memories.removeWhere((m) => m.id == memoryId);
    await _saveToPrefs();
    return true;
  }

  UserMemory? getMemory(int memoryId) {
    try {
      return _memories.firstWhere((m) => m.id == memoryId);
    } catch (_) {
      return null;
    }
  }

  // ─── 查询 ───

  List<UserMemory> get allActiveMemories =>
      _memories.where((m) => m.active).toList();

  List<UserMemory> getByCategory(MemoryCategory category) =>
      _memories.where((m) => m.active && m.category == category).toList();

  List<UserMemory> getAllMemories({bool includeInactive = false}) {
    if (includeInactive) return List.unmodifiable(_memories);
    return _memories.where((m) => m.active).toList();
  }

  List<UserMemory> searchMemories(String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return [];
    return _memories
        .where((m) => m.active && m.content.toLowerCase().contains(keyword))
        .toList();
  }

  // ─── 记忆注入 ───

  MemoryContext getRelevantMemoriesForContext(
    String userMessage, {
    int maxMemories = maxInjectionMemories,
  }) {
    final activeMemories = _memories.where((m) => m.active).toList();

    // 清理过期记忆
    _cleanExpiredMemories();

    if (activeMemories.isEmpty) {
      return MemoryContext(memories: [], systemPrompt: '', tokenEstimate: 0);
    }

    // 基于关键词匹配评分
    final queryTokens = _tokenize(userMessage);
    final scored = activeMemories.map((m) {
      final score = _calculateRelevanceScore(m, queryTokens);
      return (memory: m, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // 选择 top-N 记忆
    final selected = <UserMemory>[];
    var tokenBudget = maxInjectionTokens;

    for (final entry in scored.take(maxMemories * 2)) {
      final m = entry.memory;
      final tokens = (m.content.length / 3.5).ceil();
      if (tokens <= tokenBudget) {
        selected.add(m);
        tokenBudget -= tokens;
      }
      if (selected.length >= maxMemories) break;
    }

    final systemPrompt = MemoryContext.formatForSystemPrompt(selected);
    return MemoryContext(
      memories: selected,
      systemPrompt: systemPrompt,
      tokenEstimate: maxInjectionTokens - tokenBudget,
    );
  }

  // ─── 自动学习 ───

  Future<List<int>> learnFromConversation(
    String userMessage,
    String assistantResponse,
  ) async {
    final learnedIds = <int>[];
    try {
      final extracted = _extractPreferences(userMessage);
      for (final (content, category, importance) in extracted) {
        // 去重
        final existing = searchMemories(content.substring(0, content.length.clamp(0, 20)));
        final isDuplicate = existing.any((m) => _similarity(m.content, content) > 0.7);
        if (!isDuplicate) {
          final id = await addMemory(
            content: content,
            category: category,
            importance: importance,
            source: 'conversation',
          );
          if (id > 0) learnedIds.add(id);
        }
      }
    } catch (_) {}
    return learnedIds;
  }

  List<(String, MemoryCategory, MemoryImportance)> _extractPreferences(
    String message,
  ) {
    final results = <(String, MemoryCategory, MemoryImportance)>[];
    final lower = message.toLowerCase();

    // 显式声明的偏好
    if (message.contains('记住') || message.contains('记下') || message.contains('以后')) {
      var cleaned = message
          .replaceAll(RegExp(r'^(请|帮我|帮我)?(记住|记下|记录)(一下|下来)?'), '')
          .replaceAll(RegExp(r'^(以后|每次|总是)(都要|请|记得)?'), '')
          .trim();
      if (cleaned.length >= 3 && cleaned.length <= 200) {
        results.add((cleaned, MemoryCategory.general, MemoryImportance.high));
      }
    }

    return results;
  }

  // ─── 统计 ───

  MemoryStats getStats() {
    final all = _memories.where((m) => m.active).toList();
    final byCategory = <MemoryCategory, int>{};
    for (final cat in MemoryCategory.values) {
      byCategory[cat] = all.where((m) => m.category == cat).length;
    }

    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final recentCount = all.where((m) => m.createdAt > sevenDaysAgo).length;

    MemoryCategory? mostAccessed;
    var maxCount = 0;
    byCategory.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        mostAccessed = cat;
      }
    });

    return MemoryStats(
      totalMemories: _memories.length,
      activeMemories: all.length,
      byCategory: byCategory,
      mostAccessedCategory: mostAccessed,
      recentMemoryCount: recentCount,
    );
  }

  // ─── 批量操作 ───

  Future<int> deleteMemories(List<int> memoryIds) async {
    var count = 0;
    for (final id in memoryIds) {
      final idx = _memories.indexWhere((m) => m.id == id);
      if (idx != -1) {
        final m = _memories[idx];
        _memories[idx] = UserMemory(
          id: m.id,
          content: m.content,
          category: m.category,
          importance: m.importance,
          source: m.source,
          context: m.context,
          createdAt: m.createdAt,
          lastAccessed: m.lastAccessed,
          accessCount: m.accessCount,
          active: false,
          expiresAt: m.expiresAt,
          note: m.note,
        );
        count++;
      }
    }
    await _saveToPrefs();
    return count;
  }

  Future<bool> clearAllMemories() async {
    _memories = _memories
        .map((m) => UserMemory(
              id: m.id,
              content: m.content,
              category: m.category,
              importance: m.importance,
              source: m.source,
              context: m.context,
              createdAt: m.createdAt,
              lastAccessed: m.lastAccessed,
              accessCount: m.accessCount,
              active: false,
              expiresAt: m.expiresAt,
              note: m.note,
            ))
        .toList();
    await _saveToPrefs();
    return true;
  }

  String exportMemories() {
    final active = _memories.where((m) => m.active).toList();
    return jsonEncode(active.map((m) => m.toJson()).toList());
  }

  // ─── 内部方法 ───

  double _calculateRelevanceScore(
    UserMemory memory,
    Set<String> queryTokens,
  ) {
    final contentTokens = _tokenize(memory.content);
    if (queryTokens.isEmpty || contentTokens.isEmpty) return 0.0;

    final intersection = queryTokens.intersection(contentTokens);
    final matchScore =
        queryTokens.isNotEmpty ? intersection.length / queryTokens.length : 0.0;

    var contextBonus = 0.0;
    if (memory.context.isNotEmpty) {
      final contextTokens = _tokenize(memory.context);
      contextBonus = queryTokens.intersection(contextTokens).length * 0.1;
    }

    final importanceMultiplier =
        memory.importance.weight / MemoryImportance.medium.weight;

    final ageDays = (DateTime.now().millisecondsSinceEpoch - memory.createdAt) /
        Duration.millisecondsPerDay;
    final decayFactor = ageDays > memoryDecayDays ? 0.5 : 1.0;

    final accessBonus = (memory.accessCount * 0.05).clamp(0.0, 0.3);

    return (matchScore + contextBonus + accessBonus) * importanceMultiplier * decayFactor;
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.length > 1)
        .toSet();
  }

  double _similarity(String a, String b) {
    final tokensA = _tokenize(a);
    final tokensB = _tokenize(b);
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    final intersection = tokensA.intersection(tokensB).length;
    final union = (tokensA.union(tokensB)).length;
    return intersection / union;
  }

  void _cleanExpiredMemories() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _memories.removeWhere((m) => m.expiresAt > 0 && m.expiresAt < now);
  }

  Future<void> _evictLowPriorityMemories() async {
    final active = _memories.where((m) => m.active).toList()
      ..sort((a, b) {
        final cmp = a.importance.weight.compareTo(b.importance.weight);
        if (cmp != 0) return cmp;
        return a.lastAccessed.compareTo(b.lastAccessed);
      });
    final toRemove = active.take(10);
    for (final m in toRemove) {
      final idx = _memories.indexWhere((e) => e.id == m.id);
      if (idx != -1) {
        _memories[idx] = UserMemory(
          id: m.id,
          content: m.content,
          category: m.category,
          importance: m.importance,
          source: m.source,
          context: m.context,
          createdAt: m.createdAt,
          lastAccessed: m.lastAccessed,
          accessCount: m.accessCount,
          active: false,
          expiresAt: m.expiresAt,
          note: m.note,
        );
      }
    }
    await _saveToPrefs();
  }
}
