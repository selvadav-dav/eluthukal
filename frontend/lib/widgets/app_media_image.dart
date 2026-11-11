import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../services/cloudinary_media.dart';

/// A high-performance image/GIF widget that prioritizes bundled local assets,
/// completely eliminating web CORS issues, network latency, and AbortError exceptions.
class AppMediaImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool gaplessPlayback;
  final Widget? fallback;
  final bool preferNetwork;

  const AppMediaImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.gaplessPlayback = true,
    this.fallback,
    this.preferNetwork = false,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }

    final rawPath = path!.trim();

    // 1. Direct HTTP/HTTPS Network URL
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return Image.network(
        rawPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    }

    // 2. Resolve normalized local asset path
    String assetCandidate = rawPath;
    if (!assetCandidate.startsWith('assets/')) {
      if (assetCandidate.startsWith('Gif/')) {
        assetCandidate = 'assets/$assetCandidate';
      } else if (assetCandidate.startsWith('images/')) {
        assetCandidate = 'assets/$assetCandidate';
      } else {
        assetCandidate = 'assets/images/$assetCandidate';
      }
    }

    // Prioritize Cloudinary CDN if preferNetwork is requested
    if (preferNetwork) {
      final cdnUrl = CloudinaryMedia.getUrl(rawPath) ??
          CloudinaryMedia.getUrl(assetCandidate) ??
          ApiConfig.resolveMediaUrl(rawPath);
      if (cdnUrl != null && (cdnUrl.startsWith('http://') || cdnUrl.startsWith('https://'))) {
        return Image.network(
          cdnUrl,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: gaplessPlayback,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              assetCandidate,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              gaplessPlayback: gaplessPlayback,
              errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
            );
          },
        );
      }
    }

    // 3. Otherwise prioritize instant, zero-latency local asset
    return Image.asset(
      assetCandidate,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (context, error, stackTrace) {
        // Fall back to Cloudinary CDN only if the local asset is not found
        final cdnUrl = CloudinaryMedia.getUrl(rawPath) ?? ApiConfig.resolveMediaUrl(rawPath);
        if (cdnUrl != null && (cdnUrl.startsWith('http://') || cdnUrl.startsWith('https://'))) {
          return Image.network(
            cdnUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            gaplessPlayback: gaplessPlayback,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
          );
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
