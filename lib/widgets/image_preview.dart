import 'dart:math';
import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onDismiss;
  final List<Widget>? actions;

  const ImagePreview({
    super.key,
    required this.imageUrl,
    this.onDismiss,
    this.actions,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();

  static void show(BuildContext context, String imageUrl, {List<Widget>? actions}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ImagePreview(
          imageUrl: imageUrl,
          onDismiss: () => Navigator.of(context).pop(),
          actions: actions,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _ImagePreviewState extends State<ImagePreview> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onDismiss?.call(),
      onScaleStart: (details) {
        _baseScale = _scale;
        _baseOffset = _offset;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_baseScale * details.scale).clamp(0.5, 5.0);
          if (details.scale == 1.0) {
            _offset = _baseOffset + details.focalPointDelta;
          }
        });
      },
      onScaleEnd: (details) {
        if (_scale < 1.0) {
          setState(() { _scale = 1.0; _offset = Offset.zero; });
        }
      },
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Stack(
          children: [
            // Image
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(_offset.dx, _offset.dy)
                  ..scale(_scale),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 64),
                        SizedBox(height: 16),
                        Text('图片加载失败', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    if (widget.actions != null)
                      Row(children: widget.actions!),
                    // Scale indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_scale * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail version for inline use
class ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const ImageThumbnail({super.key, required this.imageUrl, this.size = 80, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => ImagePreview.show(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                  width: size, height: size,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                )),
      ),
    );
  }
}
