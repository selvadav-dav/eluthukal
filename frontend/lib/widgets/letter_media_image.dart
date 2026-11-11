import 'package:flutter/material.dart';
import '../services/api_config.dart';

class LetterMediaImage extends StatelessWidget {
  final String? imagePath;
  final String iconEmoji;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? emojiSize;

  const LetterMediaImage({
    super.key,
    required this.imagePath,
    required this.iconEmoji,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.emojiSize,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    final rawPath = imagePath!.trim();
    final resolvedUrl = ApiConfig.resolveMediaUrl(rawPath);

    if (resolvedUrl == null) {
      return _buildPlaceholder();
    }

    // 1. If it's a bundled local asset, load directly from assets to prevent web CORS and AbortError
    if (rawPath.startsWith('assets/')) {
      return Image.asset(
        rawPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
            return Image.network(
              resolvedUrl,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
            );
          }
          return _buildPlaceholder();
        },
      );
    }

    if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
      return Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    // Otherwise treat as local asset
    return Image.asset(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    final size = emojiSize ?? ((height != null ? height! * 0.45 : 36.0).clamp(24.0, 60.0));
    if (iconEmoji.isNotEmpty && iconEmoji != '⭐') {
      return Center(
        child: Text(
          iconEmoji,
          style: TextStyle(fontSize: size),
        ),
      );
    }
    return Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: size,
        color: const Color(0xFFFF9F1C),
      ),
    );
  }
}

