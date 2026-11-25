import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Content access (book purchase / scratch code / payment).
///
/// The user unlocks ONCE. The unlock is saved on the server against the user
/// account (`/users/access`) and cached locally, so on the next login (same
/// or another device) they go straight in and are never asked again.
///
/// SAMPLE MODE: the backend accepts any scratch code (>= 4 chars) and the
/// payment button unlocks without a real gateway.
/// TODO(server): set ACCESS_SAMPLE_MODE=false on the backend, add real
/// scratch-code validation + payment gateway, and set [sampleMode] = false.
class AccessService extends ChangeNotifier {
  AccessService._();
  static final AccessService instance = AccessService._();

  /// Shows the "skip for now" button in the dialog. Set false for production.
  static const bool sampleMode = true;

  /// Sample price shown in the payment option.
  static const int priceInRupees = 299;

  static const String _keyPrefix = 'agaram_content_unlocked_';
  static const String _keyUser = 'agaram_auth_user';
  static const String _keyToken = 'agaram_auth_token';
  static const Duration _timeout = Duration(seconds: 8);

  Future<(String userId, String? token)> _session() async {
    final prefs = await SharedPreferences.getInstance();
    var id = 'guest';
    try {
      final raw = prefs.getString(_keyUser);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        id = (map['id'] ?? map['email'] ?? 'guest').toString();
      }
    } catch (_) {}
    return (id, prefs.getString(_keyToken));
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> _cache(String userId, bool unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$userId', unlocked);
  }

  /// Whether the current user has already unlocked the content.
  Future<bool> hasAccess() async {
    final (userId, token) = await _session();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_keyPrefix$userId') == true) return true;

    // Not cached on this device -> ask the server (unlocked on another device / reinstall).
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/users/access'), headers: _headers(token))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final unlocked = body['data']?['unlocked'] == true;
        if (unlocked) await _cache(userId, true);
        return unlocked;
      }
    } catch (e) {
      debugPrint('AccessService.hasAccess: server check failed: $e');
    }
    return false;
  }

  /// Returns null on success, or an error message (Tamil) on failure.
  Future<String?> redeemScratchCode(String code) async {
    final cleaned = code.trim().toUpperCase();
    if (cleaned.isEmpty) return 'ஸ்கிராட்ச் குறியீட்டை உள்ளிடவும்';
    if (cleaned.length < 4) return 'குறியீடு சரியாக இல்லை';
    return _unlock({'method': 'scratch_code', 'code': cleaned});
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> purchase() async {
    // TODO(server): open payment gateway here and pass its reference as paymentRef.
    return _unlock({'method': 'payment', 'paymentRef': 'sample'});
  }

  Future<String?> _unlock(Map<String, dynamic> payload) async {
    final (userId, token) = await _session();
    if (token == null || token.isEmpty) {
      return 'மீண்டும் உள்நுழையவும் (Please login again)';
    }
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/access/unlock'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['data']?['unlocked'] == true) {
        await _cache(userId, true);
        notifyListeners();
        return null;
      }
      return (body['message'] ?? 'திறக்க முடியவில்லை').toString();
    } catch (e) {
      debugPrint('AccessService._unlock failed: $e');
      return 'சர்வருடன் இணைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்';
    }
  }
}
