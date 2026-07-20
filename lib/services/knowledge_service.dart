import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 知识库文档块
class KnowledgeChunk {
  final String id;
  final String content;
  final List<double>? embedding;
  final String sourceDocumentId;
  final int index;

  KnowledgeChunk({
    required this.id,
    required this.content,
    this.embedding,
    this.sourceDocumentId = '',
    this.index = 0,
  });
}

/// 知识库
class KnowledgeBase {
  final String id;
  final String name;
  final String description;
  final List<String> documentIds;
  final int chunkCount;
  final int createdAt;

  KnowledgeBase({
    required this.id,
    required this.name,
    this.description = '',
    this.documentIds = const [],
    this.chunkCount = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'documentIds': documentIds,
        'chunkCount': chunkCount,
        'createdAt': createdAt,
      };

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) => KnowledgeBase(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        documentIds: (json['documentIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        chunkCount: json['chunkCount'] as int? ?? 0,
        createdAt: json['createdAt'] as int?,
      );
}

/// 知识库文档
class KnowledgeDocument {
  final String id;
  final String name;
  final String content;
  final String knowledgeBaseId;
  final int chunkCount;
  final int createdAt;

  KnowledgeDocument({
    required this.id,
    required this.name,
    this.content = '',
    this.knowledgeBaseId = '',
    this.chunkCount = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'knowledgeBaseId': knowledgeBaseId,
        'chunkCount': chunkCount,
        'createdAt': createdAt,
      };

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) =>
      KnowledgeDocument(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        content: json['content'] as String? ?? '',
        knowledgeBaseId: json['knowledgeBaseId'] as String? ?? '',
        chunkCount: json['chunkCount'] as int? ?? 0,
        createdAt: json['createdAt'] as int?,
      );
}

/// 知识库管理服务
/// 使用 SharedPreferences 持久化
class KnowledgeService {
  static const String _basesKey = 'knowledge_bases_json';
  static const String _docsKey = 'knowledge_docs_json';
  static const String _chunksPrefix = 'knowledge_chunks_';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── 知识库 CRUD ───

  List<KnowledgeBase> loadBases() {
    final jsonStr = _prefs?.getString(_basesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => KnowledgeBase.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBases(List<KnowledgeBase> bases) async {
    final jsonStr = jsonEncode(bases.map((e) => e.toJson()).toList());
    await _prefs?.setString(_basesKey, jsonStr);
  }

  Future<void> addBase(KnowledgeBase base) async {
    final bases = loadBases();
    bases.add(base);
    await saveBases(bases);
  }

  Future<void> deleteBase(String baseId) async {
    final bases = loadBases();
    bases.removeWhere((b) => b.id == baseId);
    await saveBases(bases);
    // Clean up chunks
    await _prefs?.remove('$_chunksPrefix$baseId');
  }

  // ─── 文档管理 ───

  List<KnowledgeDocument> loadDocs() {
    final jsonStr = _prefs?.getString(_docsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDocs(List<KnowledgeDocument> docs) async {
    final jsonStr = jsonEncode(docs.map((e) => e.toJson()).toList());
    await _prefs?.setString(_docsKey, jsonStr);
  }

  Future<void> addDoc(KnowledgeDocument doc) async {
    final docs = loadDocs();
    docs.add(doc);
    await saveDocs(docs);
  }

  Future<void> deleteDoc(String docId) async {
    final docs = loadDocs();
    docs.removeWhere((d) => d.id == docId);
    await saveDocs(docs);
  }

  List<KnowledgeDocument> getDocsForBase(String knowledgeBaseId) {
    return loadDocs().where((d) => d.knowledgeBaseId == knowledgeBaseId).toList();
  }

  // ─── 文档块管理 ───

  List<String> loadChunks(String knowledgeBaseId) {
    final jsonStr = _prefs?.getString('$_chunksPrefix$knowledgeBaseId');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChunks(String knowledgeBaseId, List<String> chunks) async {
    final jsonStr = jsonEncode(chunks);
    await _prefs?.setString('$_chunksPrefix$knowledgeBaseId', jsonStr);
  }

  /// 将文档内容切分为块
  List<String> chunkDocument(String content, {int chunkSize = 500, int overlap = 50}) {
    if (content.isEmpty) return [];
    final chunks = <String>[];
    var start = 0;
    while (start < content.length) {
      final end = (start + chunkSize).clamp(0, content.length);
      chunks.add(content.substring(start, end));
      start = end - overlap;
      if (start >= content.length) break;
    }
    return chunks;
  }

  /// 添加文档到知识库
  Future<String> addDocumentToBase({
    required String knowledgeBaseId,
    required String name,
    required String content,
  }) async {
    final docId = generateDocId();
    final chunks = chunkDocument(content);

    // Save document
    final doc = KnowledgeDocument(
      id: docId,
      name: name,
      content: content,
      knowledgeBaseId: knowledgeBaseId,
      chunkCount: chunks.length,
    );
    await addDoc(doc);

    // Save chunks
    await saveChunks(knowledgeBaseId, [
      ...loadChunks(knowledgeBaseId),
      ...chunks,
    ]);

    // Update base chunk count
    final bases = loadBases();
    final idx = bases.indexWhere((b) => b.id == knowledgeBaseId);
    if (idx != -1) {
      final base = bases[idx];
      bases[idx] = KnowledgeBase(
        id: base.id,
        name: base.name,
        description: base.description,
        documentIds: [...base.documentIds, docId],
        chunkCount: base.chunkCount + chunks.length,
        createdAt: base.createdAt,
      );
      await saveBases(bases);
    }

    return docId;
  }

  /// 基于关键词的简单搜索
  List<String> searchChunks(String knowledgeBaseId, String query, {int limit = 5}) {
    final chunks = loadChunks(knowledgeBaseId);
    final queryTokens = query.toLowerCase().split(RegExp(r'\s+')).toSet();

    final scored = chunks.map((chunk) {
      final chunkTokens = chunk.toLowerCase().split(RegExp(r'\s+')).toSet();
      final intersection = queryTokens.intersection(chunkTokens).length;
      return (chunk: chunk, score: intersection);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).where((e) => e.score > 0).map((e) => e.chunk).toList();
  }

  /// 获取所有知识库中匹配查询的内容
  List<String> searchAll(String query, {int limit = 10}) {
    final bases = loadBases();
    final allResults = <String>[];
    for (final base in bases) {
      allResults.addAll(searchChunks(base.id, query, limit: limit));
    }
    return allResults.take(limit).toList();
  }

  // ─── ID 生成 ───

  String generateId() => 'kb_${DateTime.now().millisecondsSinceEpoch}';
  String generateDocId() => 'doc_${DateTime.now().millisecondsSinceEpoch}';
}
