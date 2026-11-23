import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user_model.dart';
import 'api_config.dart';

class AuthService extends ChangeNotifier {
  static const String _keyToken = 'agaram_auth_token';
  static const String _keyUser = 'agaram_auth_user';

  AuthUserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthUserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  AuthService() {
    loadSession();
  }

  /// Load session from SharedPreferences
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final userJsonStr = prefs.getString(_keyUser);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        _currentUser = AuthUserModel.fromJson(userMap, token: _token);
      }

      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error loading auth session: $e');
      return false;
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    final candidates = ApiConfig.candidateBaseUrls;
    http.Response? response;

    final Map<String, dynamic> bodyPayload = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      bodyPayload['phone'] = phone.trim();
    }

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/users/register');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyPayload),
        ).timeout(const Duration(seconds: 12));

        ApiConfig.setWorkingBaseUrl(base);
        response = res;
        break;
      } on SocketException catch (_) {
        continue;
      } on TimeoutException catch (_) {
        continue;
      } catch (_) {
        continue;
      }
    }

    if (response == null) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        'சேவையகத்துடன் இணைக்க முடியவில்லை. இணைய இணைப்பை சரிபார்க்கவும்.',
      );
    }

    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final userMap = data['user'] as Map<String, dynamic>;
        final user = AuthUserModel.fromJson(userMap, token: token);

        await _persistSession(token, user);
        _isLoading = false;
        notifyListeners();

        return AuthResult.success(user, 'பதிவு வெற்றிகரமாக முடிந்தது!');
      } else if (response.statusCode == 409) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(
          'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.',
        );
      } else {
        _isLoading = false;
        notifyListeners();
        final msg = responseData['message']?.toString() ?? 'பதிவு செய்வதில் சிக்கல் ஏற்பட்டது';
        return AuthResult.failure(_translateError(msg));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('சேவையில் தற்காலிக சிக்கல் ஏற்பட்டுள்ளது.');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final candidates = ApiConfig.candidateBaseUrls;
    http.Response? response;

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/users/login');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        ).timeout(const Duration(seconds: 12));

        ApiConfig.setWorkingBaseUrl(base);
        response = res;
        break;
      } on SocketException catch (_) {
        continue;
      } on TimeoutException catch (_) {
        continue;
      } catch (_) {
        continue;
      }
    }

    if (response == null) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        'சேவையகத்துடன் இணைக்க முடியவில்லை. இணைய இணைப்பை சரிபார்க்கவும்.',
      );
    }

    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final userMap = data['user'] as Map<String, dynamic>;
        final user = AuthUserModel.fromJson(userMap, token: token);

        await _persistSession(token, user);
        _isLoading = false;
        notifyListeners();

        return AuthResult.success(user, 'உள்நுழைவு வெற்றிகரமாக முடிந்தது!');
      } else if (response.statusCode == 401) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure('மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது.');
      } else {
        _isLoading = false;
        notifyListeners();
        final msg = responseData['message']?.toString() ?? 'உள்நுழைவு தோல்வியடைந்தது';
        return AuthResult.failure(_translateError(msg));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('சேவையில் தற்காலிக சிக்கல் ஏற்பட்டுள்ளது.');
    }
  }

  /// Google Sign-In (Opens native Google account selector popup)
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Force Google account chooser so user can select or switch account
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled popup
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure('Google உள்நுழைவு ரத்து செய்யப்பட்டது.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final Map<String, dynamic> payload = {
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl ?? 'assets/images/welcome.png',
        'googleId': googleUser.id,
      };

      final candidates = ApiConfig.candidateBaseUrls;
      http.Response? response;

      for (final base in candidates) {
        try {
          final url = Uri.parse('$base/users/google-login');
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 12));

          ApiConfig.setWorkingBaseUrl(base);
          response = res;
          break;
        } on SocketException catch (_) {
          continue;
        } on TimeoutException catch (_) {
          continue;
        } catch (_) {
          continue;
        }
      }

      if (response == null) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(
          'சேவையகத்துடன் இணைக்க முடியவில்லை. இணைய இணைப்பை சரிபார்க்கவும்.',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final userMap = data['user'] as Map<String, dynamic>;
        final user = AuthUserModel.fromJson(userMap, token: token);

        await _persistSession(token, user);
        _isLoading = false;
        notifyListeners();

        return AuthResult.success(user, 'Google மூலம் வெற்றிகரமாக உள்நுழைந்துவிட்டது!');
      } else {
        _isLoading = false;
        notifyListeners();
        final msg = responseData['message']?.toString() ?? 'Google உள்நுழைவு தோல்வியடைந்தது';
        return AuthResult.failure(_translateError(msg));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google Sign-In Error: $e');
      return AuthResult.failure('Google உள்நுழைவில் பிழை ஏற்பட்டது: $e');
    }
  }

  /// Logout and clear storage
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    } finally {
      _token = null;
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _persistSession(String token, AuthUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    _token = token;
    _currentUser = user;
  }

  String _translateError(String raw) {
    if (raw.contains('already registered') || raw.contains('ஏற்கனவே பதிவு')) {
      return 'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.';
    }
    if (raw.contains('Invalid credentials') || raw.contains('தவறாக உள்ளது')) {
      return 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது.';
    }
    if (raw.contains('Email') && raw.contains('required')) {
      return 'மின்னஞ்சல் முகவரி தேவை.';
    }
    if (raw.contains('Password') && raw.contains('required')) {
      return 'கடவுச்சொல் தேவை.';
    }
    if (raw.contains('at least 6 characters')) {
      return 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்.';
    }
    return raw;
  }
}

class AuthResult {
  final bool isSuccess;
  final AuthUserModel? user;
  final String message;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    required this.message,
  });

  factory AuthResult.success(AuthUserModel user, [String message = '']) {
    return AuthResult._(isSuccess: true, user: user, message: message);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(isSuccess: false, message: errorMessage);
  }
}
