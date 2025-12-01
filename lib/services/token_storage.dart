import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles secure persistence of the auth token with seamless migration
/// from legacy SharedPreferences storage.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _legacyKey = 'token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Persist token securely and remove legacy value.
  static Future<void> save(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }

  /// Retrieve token, migrating from SharedPreferences if needed.
  static Future<String?> read() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) return token;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_legacyKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await save(legacyToken);
      return legacyToken;
    }
    return null;
  }

  static Future<void> delete() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }
}

