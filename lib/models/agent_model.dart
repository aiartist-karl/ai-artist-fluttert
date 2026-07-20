import 'dart:convert';

/// Agent 数据模型
/// 对应 Android: AgentRepository.kt - Agent data class
class Agent {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String systemPrompt;
  final String apiType;
  final String host;
  final String apiKey;
  final String model;

  Agent({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '🤖',
    this.systemPrompt = '',
    this.apiType = 'openai',
    this.host = '',
    this.apiKey = '',
    this.model = '',
  });

  factory Agent.defaultAgent() {
    return Agent(
      id: 'default',
      name: 'AI 智能体',
      description: '通用 AI 助手，可以回答问题、进行创意写作、翻译等',
      emoji: '🤖',
      systemPrompt: '',
      apiType: 'openai',
      host: '',
      apiKey: '',
      model: '',
    );
  }

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🤖',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      apiType: json['apiType'] as String? ?? 'openai',
      host: json['host'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
    );
  }

  factory Agent.fromJsonString(String jsonString) {
    return Agent.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'systemPrompt': systemPrompt,
      'apiType': apiType,
      'host': host,
      'apiKey': apiKey,
      'model': model,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  Agent copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    String? systemPrompt,
    String? apiType,
    String? host,
    String? apiKey,
    String? model,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      apiType: apiType ?? this.apiType,
      host: host ?? this.host,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  static String generateId() => 'agent_${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Agent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Agent(id: $id, name: $name, emoji: $emoji)';
}
