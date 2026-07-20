import 'dart:convert';

/// 角色卡模型
/// 对应 Android: CharacterCard
class CharacterCard {
  final String id;
  final String name;
  final String description;
  final String promptPrefix;
  final String negativePrompt;
  final String? referenceImageBase64;
  final List<String> styleTags;
  final int createdAt;

  CharacterCard({
    required this.id,
    required this.name,
    this.description = '',
    this.promptPrefix = '',
    this.negativePrompt = '',
    this.referenceImageBase64,
    this.styleTags = const [],
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory CharacterCard.fromJson(Map<String, dynamic> json) {
    final refImage = json['referenceImageBase64'] as String? ?? '';
    return CharacterCard(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      promptPrefix: json['promptPrefix'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      referenceImageBase64: refImage.isNotEmpty ? refImage : null,
      styleTags: (json['styleTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] as int?,
    );
  }

  factory CharacterCard.fromJsonString(String jsonString) {
    return CharacterCard.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'promptPrefix': promptPrefix,
        'negativePrompt': negativePrompt,
        'referenceImageBase64': referenceImageBase64 ?? '',
        'styleTags': styleTags,
        'createdAt': createdAt,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 是否有参考图
  bool get hasReferenceImage =>
      referenceImageBase64 != null && referenceImageBase64!.isNotEmpty;

  /// 创建时间
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  static String generateId() => 'char_${DateTime.now().millisecondsSinceEpoch}';

  CharacterCard copyWith({
    String? id,
    String? name,
    String? description,
    String? promptPrefix,
    String? negativePrompt,
    String? referenceImageBase64,
    List<String>? styleTags,
    int? createdAt,
  }) {
    return CharacterCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      promptPrefix: promptPrefix ?? this.promptPrefix,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      referenceImageBase64: referenceImageBase64 ?? this.referenceImageBase64,
      styleTags: styleTags ?? this.styleTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CharacterCard && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CharacterCard(id: $id, name: $name, tags: ${styleTags.length})';
}
