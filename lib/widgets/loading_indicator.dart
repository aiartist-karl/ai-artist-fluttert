import 'dart:math';
import 'package:flutter/material.dart';

/// Animated loading indicator with multiple dots
class ChatLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const ChatLoadingIndicator({
    super.key,
    this.color,
    this.dotSize = 8,
    this.spacing = 4,
  });

  @override
  State<ChatLoadingIndicator> createState() => _ChatLoadingIndicatorState();
}

class _ChatLoadingIndicatorState extends State<ChatLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * sin(t * pi);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.3 + 0.7 * scale),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Full-screen blocking overlay with progress
class BlockingProgressOverlay extends StatelessWidget {
  final String message;
  final double? progress;
  final Map<String, String>? toolProgress;

  const BlockingProgressOverlay({
    super.key,
    this.message = '处理中...',
    this.progress,
    this.toolProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null)
                  CircularProgressIndicator(value: progress)
                else
                  const ChatLoadingIndicator(dotSize: 12, spacing: 6),
                const SizedBox(height: 16),
                Text(message, style: Theme.of(context).textTheme.titleMedium),
                if (toolProgress != null && toolProgress!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...toolProgress!.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(e.value, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth animated gradient loading bar
class SmoothLoadingBar extends StatefulWidget {
  final Color? color;
  final double height;

  const SmoothLoadingBar({super.key, this.color, this.height = 3});

  @override
  State<SmoothLoadingBar> createState() => _SmoothLoadingBarState();
}

class _SmoothLoadingBarState extends State<SmoothLoadingBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.8),
                color.withOpacity(0.1),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
