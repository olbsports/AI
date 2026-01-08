import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    ref.watch(sharedPreferencesProvider),
    const FlutterSecureStorage(),
  );
});

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService(this._prefs, this._secureStorage);

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _onboardingKey = 'onboarding_completed';

  // ==================== Secure Storage ====================

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // SECURITY: Token expiry stored in secure storage (moved from SharedPreferences)
  Future<void> saveTokenExpiry(int expiresAt) async {
    await _secureStorage.write(key: _tokenExpiryKey, value: expiresAt.toString());
  }

  Future<int?> getAccessTokenExpiry() async {
    final value = await _secureStorage.read(key: _tokenExpiryKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<bool> isAccessTokenExpired() async {
    final expiresAt = await getAccessTokenExpiry();
    if (expiresAt == null) return false;

    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTimestamp >= expiresAt;
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
  }

  // ==================== Secure User Data ====================

  // SECURITY: User ID stored in secure storage (moved from SharedPreferences)
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeKey, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setLocale(String locale) async {
    await _prefs.setString(_localeKey, locale);
  }

  String getLocale() {
    return _prefs.getString(_localeKey) ?? 'fr';
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  // ==================== Clear All ====================

  Future<void> clearAll() async {
    await clearTokens();
    await _secureStorage.delete(key: _userIdKey);
  }
}
