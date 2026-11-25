import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cloudinary_media.dart';

class ApiConfig {
  // Custom server IP override if testing on a physical phone on the same Wi-Fi network
  static String? customServerUrl;
  static String? _discoveredBaseUrl;

  /// Defaults to the local backend on this PC (port 5001).
  /// To use the live server instead:
  ///   flutter run --dart-define=API_BASE_URL=https://eluthukkal-api.macvelsoftware.com/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get _localBaseUrl => (!kIsWeb && Platform.isAndroid)
      ? 'http://10.0.2.2:5001/api/v1'
      : 'http://localhost:5001/api/v1';

  /// Candidate backend URLs for seamless connectivity across physical devices, emulators, and web
  static List<String> get candidateBaseUrls {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return [customServerUrl!.trim()];
    }
    if (_envBaseUrl.isNotEmpty) return [_envBaseUrl];
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return [_discoveredBaseUrl!];
    }
    return [
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:5001/api/v1',
      if (!kIsWeb && Platform.isAndroid) 'http://192.168.1.40:5001/api/v1',
      if (!kIsWeb && Platform.isAndroid) 'http://192.168.1.49:5001/api/v1',
      'http://localhost:5001/api/v1',
    ];
  }

  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return customServerUrl!.trim();
    }
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return _discoveredBaseUrl!;
    }
    return _localBaseUrl;
  }

  static void setWorkingBaseUrl(String url) {
    _discoveredBaseUrl = url;
  }

  static String get serverRoot {
    return baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  static String? resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // Check Cloudinary mapping first
    final cloudinaryUrl = CloudinaryMedia.getUrl(clean);
    if (cloudinaryUrl != null && (cloudinaryUrl.startsWith('http://') || cloudinaryUrl.startsWith('https://'))) {
      return cloudinaryUrl;
    }

    if (clean.startsWith('uploads/') || clean.startsWith('/uploads/')) {
      final sub = clean.startsWith('/') ? clean.substring(1) : clean;
      return '$serverRoot/$sub';
    }
    return clean;
  }
}

