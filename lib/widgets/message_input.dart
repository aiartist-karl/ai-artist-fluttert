import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageInput extends StatefulWidget {
  final FocusNode focusNode;
  final String inputText;
  final ValueChanged<String> onInputChange;
  final QuotedMessage? quotedMessage;
  final VoidCallback? onQuoteRemove;
  final bool isLoading;
  final VoidCallback? onStop;
  final VoidCallback? onSend;
  final VoidCallback? onImagePick;
  final bool speechInputEnabled;
  final VoidCallback? onMicClick;
  final String? recognizedText;
  final VoidCallback? onUseRecognizedText;

  const MessageInput({
    super.key,
    required this.focusNode,
    required this.inputText,
    required this.onInputChange,
    this.quotedMessage,
    this.onQuoteRemove,
    this.isLoading = false,
    this.onStop,
    this.onSend,
    this.onImagePick,
    this.speechInputEnabled = false,
    this.onMicClick,
    this.recognizedText,
    this.onUseRecognizedText,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.inputText);
  }

  @override
  void didUpdateWidget(MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputText != _controller.text && widget.inputText != oldWidget.inputText) {
      _controller.text = widget.inputText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quoted message preview
          if (widget.quotedMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '回复: ${widget.quotedMessage!.content}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onQuoteRemove,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),

          // Recognized speech preview
          if (widget.recognizedText != null && widget.recognizedText!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.recognizedText!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: widget.onUseRecognizedText,
                    child: const Icon(Icons.check, size: 16, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),

          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              IconButton(
                onPressed: widget.onImagePick,
                icon: const Icon(Icons.attach_file),
                iconSize: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    onChanged: widget.onInputChange,
                    onSubmitted: (_) {
                      if (_controller.text.trim().isNotEmpty) widget.onSend?.call();
                    },
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              // Mic button
              if (widget.speechInputEnabled)
                IconButton(
                  onPressed: widget.onMicClick,
                  icon: const Icon(Icons.mic),
                  iconSize: 22,
                  color: theme.colorScheme.primary,
                ),

              // Send / Stop button
              const SizedBox(width: 4),
              if (widget.isLoading)
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade400,
                  ),
                  child: IconButton(
                    onPressed: widget.onStop,
                    icon: const Icon(Icons.stop, color: Colors.white, size: 20),
                  ),
                )
              else
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: IconButton(
                    onPressed: widget.onSend,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
