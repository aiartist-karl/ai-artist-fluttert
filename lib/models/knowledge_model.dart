import 'dart:convert';

/// 知识库文档分片
/// 对应 Android: KnowledgeChunk
class KnowledgeChunk {
  final String id;
  final String content;
  final List<double>? embedding;
  final String sourceDocumentId;
  final int index;

  const KnowledgeChunk({
    required this.id,
    required this.content,
    this.embedding,
    this.sourceDocumentId = '',
    this.index = 0,
  });

  factory KnowledgeChunk.fromJson(Map<String, dynamic> json) {
    return KnowledgeChunk(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      sourceDocumentId: json['sourceDocumentId'] as String? ?? '',
      index: json['index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'embedding': embedding,
        'sourceDocumentId': sourceDocumentId,
        'index': index,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KnowledgeChunk && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 知识库
/// 对应 Android: KnowledgeBase
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

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      documentIds: (json['documentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      chunkCount: json['chunkCount'] as int? ?? 0,
      createdAt: json['createdAt'] as int?,
    );
  }

  factory KnowledgeBase.fromJsonString(String jsonString) {
    return KnowledgeBase.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'documentIds': documentIds,
        'chunkCount': chunkCount,
        'createdAt': createdAt,
      };

  String toJsonString() => jsonEncode(toJson());

  KnowledgeBase copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? documentIds,
    int? chunkCount,
    int? createdAt,
  }) {
    return KnowledgeBase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      documentIds: documentIds ?? this.documentIds,
      chunkCount: chunkCount ?? this.chunkCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String generateId() => 'kb_${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KnowledgeBase && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 知识库文档
/// 对应 Android: KnowledgeDocument
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

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      knowledgeBaseId: json['knowledgeBaseId'] as String? ?? '',
      chunkCount: json['chunkCount'] as int? ?? 0,
      createdAt: json['createdAt'] as int?,
    );
  }

  factory KnowledgeDocument.fromJsonString(String jsonString) {
    return KnowledgeDocument.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'knowledgeBaseId': knowledgeBaseId,
        'chunkCount': chunkCount,
        'createdAt': createdAt,
      };

  String toJsonString() => jsonEncode(toJson());

  KnowledgeDocument copyWith({
    String? id,
    String? name,
    String? content,
    String? knowledgeBaseId,
    int? chunkCount,
    int? createdAt,
  }) {
    return KnowledgeDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      chunkCount: chunkCount ?? this.chunkCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String generateDocId() => 'doc_${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KnowledgeDocument && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
