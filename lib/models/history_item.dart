/// 历史项目模型
class HistoryItem {
  final int id;
  final String modelId;
  final int timestamp;
  final String imagePath;
  final int width;
  final int height;
  final String mode;
  final String prompt;
  final String negativePrompt;
  final bool favorite;
  final Map<String, dynamic> params;

  HistoryItem({
    this.id = 0,
    required this.modelId,
    required this.timestamp,
    required this.imagePath,
    this.width = 512,
    this.height = 512,
    this.mode = 'txt2img',
    this.prompt = '',
    this.negativePrompt = '',
    this.favorite = false,
    this.params = const {},
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'] as int? ?? 0,
    modelId: json['modelId'] as String? ?? '',
    timestamp: json['timestamp'] as int? ?? 0,
    imagePath: json['imagePath'] as String? ?? '',
    width: json['width'] as int? ?? 512,
    height: json['height'] as int? ?? 512,
    mode: json['mode'] as String? ?? 'txt2img',
    prompt: json['prompt'] as String? ?? '',
    negativePrompt: json['negativePrompt'] as String? ?? '',
    favorite: json['favorite'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'modelId': modelId,
    'timestamp': timestamp,
    'imagePath': imagePath,
    'width': width,
    'height': height,
    'mode': mode,
    'prompt': prompt,
    'negativePrompt': negativePrompt,
    'favorite': favorite,
  };
}
