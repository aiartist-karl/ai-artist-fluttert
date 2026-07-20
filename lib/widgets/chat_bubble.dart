import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;
  final VoidCallback? onStopSpeak;
  final VoidCallback? onCopy;
  final VoidCallback? onQuote;
  final VoidCallback? onImageTap;
  final bool isSpeaking;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.onStopSpeak,
    this.onCopy,
    this.onQuote,
    this.onImageTap,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    if (message.isLoading) {
      return _buildLoadingBubble(theme);
    }

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[_buildAvatar(isUser: false), const SizedBox(width: 8)],
        Flexible(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Main bubble
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)])
                      : null,
                  color: isUser ? null : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrl != null) ...[
                      GestureDetector(
                        onTap: onImageTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(message.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message.imageBase64 != null && message.imageUrl == null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_decodeBase64(message.imageBase64!),
                            width: 200, height: 200, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message.content.isNotEmpty)
                      isUser
                          ? Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 15))
                          : MarkdownBody(
                              data: message.content,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                                code: TextStyle(
                                  backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                                  fontFamily: 'monospace', fontSize: 13, color: const Color(0xFFD63384),
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                blockquoteDecoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                                ),
                                h1: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
                                h2: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 17),
                                h3: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                  ],
                ),
              ),
              // Actions
              if (!isUser && message.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onCopy != null) _actionBtn(Icons.content_copy, '复制', onCopy!),
                      if (onQuote != null) _actionBtn(Icons.format_quote, '引用', onQuote!),
                      if (onSpeak != null)
                        _actionBtn(
                          isSpeaking ? Icons.stop : Icons.volume_up,
                          isSpeaking ? '停止' : '朗读',
                          isSpeaking ? (onStopSpeak ?? () {}) : onSpeak!,
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_formatTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF9E9EA6), fontSize: 10)),
              ),
            ],
          ),
        ),
        if (isUser) ...[const SizedBox(width: 8), _buildAvatar(isUser: true)],
      ],
    );
  }

  Widget _buildLoadingBubble(ThemeData theme) {
    return Row(
      children: [
        _buildAvatar(isUser: false),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('思考中...', style: TextStyle(color: Color(0xFFAEAEB2), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)])
            : const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
      ),
      alignment: Alignment.center,
      child: Icon(isUser ? Icons.person : Icons.smart_toy, color: Colors.white, size: 18),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Tooltip(message: tooltip, child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 14, color: const Color(0xFF9E9EA6)))),
    );
  }

  static Uint8List _decodeBase64(String base64Str) {
    try {
      final cleaned = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0);
    }
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
