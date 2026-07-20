import 'dart:convert';

/// 聊天消息模型
/// 对应 Android ChatScreen.kt - ChatMessage data class
class ChatMessage {
  final String role; // user, assistant, system
  final String content;
  final String? imageBase64;
  final String? imageUrl;
  final bool isLoading;
  final int timestamp;
  final List<ToolCallInfo>? toolCalls;

  ChatMessage({
    required this.role,
    required this.content,
    this.imageBase64,
    this.imageUrl,
    this.isLoading = false,
    int? timestamp,
    this.toolCalls,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  ChatMessage copyWith({
    String? role,
    String? content,
    String? imageBase64,
    String? imageUrl,
    bool? isLoading,
    int? timestamp,
    List<ToolCallInfo>? toolCalls,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageUrl: imageUrl ?? this.imageUrl,
      isLoading: isLoading ?? this.isLoading,
      timestamp: timestamp ?? this.timestamp,
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'timestamp': timestamp,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] as String? ?? 'assistant',
    content: json['content'] as String? ?? '',
    imageBase64: json['imageBase64'] as String?,
    imageUrl: json['imageUrl'] as String?,
    timestamp: json['timestamp'] as int?,
  );

  String toJsonString() => jsonEncode(toJson());
}

/// 工具调用信息
class ToolCallInfo {
  final String name;
  final String status; // running, done, error
  final String? detail;

  ToolCallInfo({required this.name, this.status = 'running', this.detail});
}

/// 引用的消息
class QuotedMessage {
  final String messageId;
  final String content;
  final bool isUser;

  QuotedMessage({required this.messageId, required this.content, required this.isUser});
}

/// 排队的消息
class QueuedMessage {
  final String content;
  final String? imageBase64;

  QueuedMessage({required this.content, this.imageBase64});
}
