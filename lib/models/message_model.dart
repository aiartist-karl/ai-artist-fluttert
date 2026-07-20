import 'dart:convert';

/// 生成历史记录模型
/// 对应 Android: db/HistoryEntity.kt
class HistoryEntity {
  final int id;
  final String modelId;
  final int timestamp;
  final String imagePath;
  final int width;
  final int height;
  final String mode;
  final double? denoiseStrength;
  final String? upscalerId;
  final int steps;
  final double cfg;
  final int? seed;
  final String prompt;
  final String negativePrompt;
  final String? generationTime;
  final String scheduler;
  final bool runOnCpu;
  final bool useOpenCL;
  final bool favorite;

  HistoryEntity({
    this.id = 0,
    required this.modelId,
    required this.timestamp,
    required this.imagePath,
    this.width = 512,
    this.height = 512,
    this.mode = 'txt2img',
    this.denoiseStrength,
    this.upscalerId,
    this.steps = 20,
    this.cfg = 7.0,
    this.seed,
    this.prompt = '',
    this.negativePrompt = '',
    this.generationTime,
    this.scheduler = 'euler_a',
    this.runOnCpu = false,
    this.useOpenCL = false,
    this.favorite = false,
  });

  factory HistoryEntity.fromJson(Map<String, dynamic> json) {
    return HistoryEntity(
      id: json['id'] as int? ?? 0,
      modelId: json['modelId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      imagePath: json['imagePath'] as String? ?? '',
      width: json['width'] as int? ?? 512,
      height: json['height'] as int? ?? 512,
      mode: json['mode'] as String? ?? 'txt2img',
      denoiseStrength: (json['denoiseStrength'] as num?)?.toDouble(),
      upscalerId: json['upscalerId'] as String?,
      steps: json['steps'] as int? ?? 20,
      cfg: (json['cfg'] as num?)?.toDouble() ?? 7.0,
      seed: json['seed'] as int?,
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      generationTime: json['generationTime'] as String?,
      scheduler: json['scheduler'] as String? ?? 'euler_a',
      runOnCpu: json['runOnCpu'] as bool? ?? false,
      useOpenCL: json['useOpenCL'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  factory HistoryEntity.fromJsonString(String jsonString) {
    return HistoryEntity.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelId': modelId,
        'timestamp': timestamp,
        'imagePath': imagePath,
        'width': width,
        'height': height,
        'mode': mode,
        'denoiseStrength': denoiseStrength,
        'upscalerId': upscalerId,
        'steps': steps,
        'cfg': cfg,
        'seed': seed,
        'prompt': prompt,
        'negativePrompt': negativePrompt,
        'generationTime': generationTime,
        'scheduler': scheduler,
        'runOnCpu': runOnCpu,
        'useOpenCL': useOpenCL,
        'favorite': favorite,
      };

  String toJsonString() => jsonEncode(toJson());

  HistoryEntity copyWith({
    int? id,
    String? modelId,
    int? timestamp,
    String? imagePath,
    int? width,
    int? height,
    String? mode,
    double? denoiseStrength,
    String? upscalerId,
    int? steps,
    double? cfg,
    int? seed,
    String? prompt,
    String? negativePrompt,
    String? generationTime,
    String? scheduler,
    bool? runOnCpu,
    bool? useOpenCL,
    bool? favorite,
  }) {
    return HistoryEntity(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      width: width ?? this.width,
      height: height ?? this.height,
      mode: mode ?? this.mode,
      denoiseStrength: denoiseStrength ?? this.denoiseStrength,
      upscalerId: upscalerId ?? this.upscalerId,
      steps: steps ?? this.steps,
      cfg: cfg ?? this.cfg,
      seed: seed ?? this.seed,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      generationTime: generationTime ?? this.generationTime,
      scheduler: scheduler ?? this.scheduler,
      runOnCpu: runOnCpu ?? this.runOnCpu,
      useOpenCL: useOpenCL ?? this.useOpenCL,
      favorite: favorite ?? this.favorite,
    );
  }

  /// 格式化的时间字符串
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// 宽高比描述
  String get resolution => '${width}x$height';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is HistoryEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HistoryEntity(id: $id, modelId: $modelId, mode: $mode, resolution: $resolution)';
}
