import 'dart:convert';

/// 镜头类型枚举
/// 对应 Android: ShotType enum
enum ShotType {
  extremeWide('大远景'),
  wide('远景'),
  full('全景'),
  medium('中景'),
  mediumClose('中近景'),
  closeUp('特写'),
  extremeClose('大特写'),
  overShoulder('过肩镜头'),
  topDown('俯拍'),
  lowAngle('仰拍'),
  dutch('倾斜镜头'),
  pov('主观视角');

  final String displayName;
  const ShotType(this.displayName);

  static ShotType fromString(String value) {
    return ShotType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShotType.medium,
    );
  }
}

/// 分镜镜头
/// 对应 Android: StoryboardShot
class StoryboardShot {
  final int id;
  final String sceneDescription;
  final String characters;
  final String scene;
  final ShotType shotType;
  final double durationSeconds;
  final String dialogue;
  final String imagePrompt;
  final String? generatedImagePath;

  const StoryboardShot({
    this.id = 0,
    this.sceneDescription = '',
    this.characters = '',
    this.scene = '',
    this.shotType = ShotType.medium,
    this.durationSeconds = 3.0,
    this.dialogue = '',
    this.imagePrompt = '',
    this.generatedImagePath,
  });

  factory StoryboardShot.fromJson(Map<String, dynamic> json) {
    return StoryboardShot(
      id: json['id'] as int? ?? 0,
      sceneDescription: json['sceneDescription'] as String? ?? '',
      characters: json['characters'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
      shotType: ShotType.fromString(json['shotType'] as String? ?? 'MEDIUM'),
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 3.0,
      dialogue: json['dialogue'] as String? ?? '',
      imagePrompt: json['imagePrompt'] as String? ?? '',
      generatedImagePath: json['generatedImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sceneDescription': sceneDescription,
        'characters': characters,
        'scene': scene,
        'shotType': shotType.name,
        'durationSeconds': durationSeconds,
        'dialogue': dialogue,
        'imagePrompt': imagePrompt,
        if (generatedImagePath != null) 'generatedImagePath': generatedImagePath,
      };

  /// 是否有已生成的图片
  bool get hasGeneratedImage => generatedImagePath != null && generatedImagePath!.isNotEmpty;

  /// 是否有台词
  bool get hasDialogue => dialogue.isNotEmpty;

  StoryboardShot copyWith({
    int? id,
    String? sceneDescription,
    String? characters,
    String? scene,
    ShotType? shotType,
    double? durationSeconds,
    String? dialogue,
    String? imagePrompt,
    String? generatedImagePath,
  }) {
    return StoryboardShot(
      id: id ?? this.id,
      sceneDescription: sceneDescription ?? this.sceneDescription,
      characters: characters ?? this.characters,
      scene: scene ?? this.scene,
      shotType: shotType ?? this.shotType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      dialogue: dialogue ?? this.dialogue,
      imagePrompt: imagePrompt ?? this.imagePrompt,
      generatedImagePath: generatedImagePath ?? this.generatedImagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StoryboardShot && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StoryboardShot(id: $id, type: ${shotType.displayName}, duration: ${durationSeconds}s)';
}

/// 分镜脚本
/// 对应 Android: Storyboard
class Storyboard {
  final String title;
  final String synopsis;
  final String style;
  final String aspectRatio;
  final List<StoryboardShot> shots;
  final int createdAt;

  Storyboard({
    required this.title,
    required this.synopsis,
    this.style = 'anime',
    this.aspectRatio = '16:9',
    this.shots = const [],
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Storyboard.fromJson(Map<String, dynamic> json) {
    final shotsJson = json['shots'] as List<dynamic>? ?? [];
    return Storyboard(
      title: json['title'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      style: json['style'] as String? ?? 'anime',
      aspectRatio: json['aspectRatio'] as String? ?? '16:9',
      shots: shotsJson
          .map((e) => StoryboardShot.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as int?,
    );
  }

  factory Storyboard.fromJsonString(String jsonString) {
    return Storyboard.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'synopsis': synopsis,
        'style': style,
        'aspectRatio': aspectRatio,
        'createdAt': createdAt,
        'shots': shots.map((s) => s.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  /// 总时长（秒）
  double get totalDuration =>
      shots.fold<double>(0.0, (sum, shot) => sum + shot.durationSeconds);

  /// 镜头数量
  int get shotCount => shots.length;

  /// 创建时间
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 总时长格式化
  String get totalDurationFormatted {
    final total = totalDuration;
    final minutes = (total / 60).floor();
    final seconds = (total % 60).round();
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    }
    return '${seconds}秒';
  }

  Storyboard copyWith({
    String? title,
    String? synopsis,
    String? style,
    String? aspectRatio,
    List<StoryboardShot>? shots,
    int? createdAt,
  }) {
    return Storyboard(
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      style: style ?? this.style,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      shots: shots ?? this.shots,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Storyboard(title: $title, shots: $shotCount, duration: $totalDurationFormatted)';
}
