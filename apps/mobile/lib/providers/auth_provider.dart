import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Represents the current 2FA state in the login flow
enum TwoFactorState {
  notRequired,
  required,
  verifying,
  verified,
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  // 2FA related state
  final TwoFactorState twoFactorState;
  final String? tempToken;
  final String? pendingEmail;

  // Rate limiting state
  final bool isRateLimited;
  final int? rateLimitRetryAfter;
  final DateTime? rateLimitEndTime;

  // Session state
  final List<UserSession> activeSessions;
  final List<TrustedDevice> trustedDevices;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.twoFactorState = TwoFactorState.notRequired,
    this.tempToken,
    this.pendingEmail,
    this.isRateLimited = false,
    this.rateLimitRetryAfter,
    this.rateLimitEndTime,
    this.activeSessions = const [],
    this.trustedDevices = const [],
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    TwoFactorState? twoFactorState,
    String? tempToken,
    String? pendingEmail,
    bool? isRateLimited,
    int? rateLimitRetryAfter,
    DateTime? rateLimitEndTime,
    List<UserSession>? activeSessions,
    List<TrustedDevice>? trustedDevices,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      twoFactorState: twoFactorState ?? this.twoFactorState,
      tempToken: tempToken ?? this.tempToken,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      rateLimitRetryAfter: rateLimitRetryAfter ?? this.rateLimitRetryAfter,
      rateLimitEndTime: rateLimitEndTime ?? this.rateLimitEndTime,
      activeSessions: activeSessions ?? this.activeSessions,
      trustedDevices: trustedDevices ?? this.trustedDevices,
    );
  }

  /// Check if rate limit has expired
  bool get isStillRateLimited {
    if (!isRateLimited || rateLimitEndTime == null) return false;
    return DateTime.now().isBefore(rateLimitEndTime!);
  }

  /// Get remaining seconds for rate limit
  int get rateLimitRemainingSeconds {
    if (!isStillRateLimited || rateLimitEndTime == null) return 0;
    return rateLimitEndTime!.difference(DateTime.now()).inSeconds;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final StorageService _storage;

  AuthNotifier(this._api, this._storage) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      state = state.copyWith(isLoading: true);
      try {
        final user = await _api.getProfile();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } catch (e) {
        await _storage.clearAll();
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    }
  }

  /// Standard login - returns LoginResult with 2FA info if required
  Future<LoginResult> login(String email, String password, {bool rememberDevice = false}) async {
    // Check if still rate limited
    if (state.isStillRateLimited) {
      final remaining = state.rateLimitRemainingSeconds;
      return LoginResult.rateLimited(remaining);
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      isRateLimited: false,
    );

    try {
      // SECURITY: Do not log email or password
      debugPrint('AUTH: Attempting login');
      final result = await _api.loginWithDevice(email, password, rememberDevice: rememberDevice);

      // Check if 2FA is required
      if (result.requires2FA) {
        debugPrint('AUTH: 2FA required');
        state = state.copyWith(
          isLoading: false,
          twoFactorState: TwoFactorState.required,
          tempToken: result.tempToken,
          pendingEmail: email,
        );
        return LoginResult.requires2FA(result.tempToken ?? '');
      }

      debugPrint('AUTH: Login successful');
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUserId(result.user.id);

      // Save token expiry if provided
      if (result.expiresAt != null) {
        await _storage.saveTokenExpiry(result.expiresAt!);
      }

      state = state.copyWith(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
        twoFactorState: TwoFactorState.notRequired,
        tempToken: null,
        pendingEmail: null,
      );
      return LoginResult.success(result);
    } catch (e) {
      // SECURITY: Log error without exposing sensitive details
      debugPrint('AUTH: Login failed');

      final errorMessage = _getErrorMessage(e);
      final retryAfter = _extractRateLimitRetryAfter(e);

      if (retryAfter != null) {
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isRateLimited: true,
          rateLimitRetryAfter: retryAfter,
          rateLimitEndTime: DateTime.now().add(Duration(seconds: retryAfter)),
        );
        return LoginResult.rateLimited(retryAfter);
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return LoginResult.error(errorMessage);
    }
  }

  /// Verify 2FA code after initial login
  Future<bool> verify2FACode(String code, {bool trustDevice = false}) async {
    if (state.tempToken == null) {
      state = state.copyWith(error: 'Session expirée. Veuillez vous reconnecter.');
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      twoFactorState: TwoFactorState.verifying,
    );

    try {
      debugPrint('AUTH: Verifying 2FA code');
      final response = await _api.verify2FALogin(
        state.tempToken!,
        code,
        trustDevice: trustDevice,
      );

      debugPrint('AUTH: 2FA verification successful');
      await _storage.saveTokens(response.accessToken, response.refreshToken);
      await _storage.saveUserId(response.user.id);

      if (response.expiresAt != null) {
        await _storage.saveTokenExpiry(response.expiresAt!);
      }

      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
        twoFactorState: TwoFactorState.verified,
        tempToken: null,
        pendingEmail: null,
      );
      return true;
    } catch (e) {
      debugPrint('AUTH: 2FA verification failed');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
        twoFactorState: TwoFactorState.required,
      );
      return false;
    }
  }

  /// Cancel 2FA flow and return to login
  void cancel2FA() {
    state = state.copyWith(
      twoFactorState: TwoFactorState.notRequired,
      tempToken: null,
      pendingEmail: null,
      error: null,
    );
  }

  /// Enable 2FA for the current user
  Future<TwoFactorSetupResponse?> enable2FA() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.enable2FA();
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return null;
    }
  }

  /// Confirm 2FA setup with verification code
  Future<bool> confirm2FASetup(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.confirm2FASetup(code);
      // Refresh user to update mfaEnabled status
      await refreshUser();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Disable 2FA for the current user
  Future<bool> disable2FA(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.disable2FA(code);
      // Refresh user to update mfaEnabled status
      await refreshUser();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Get active sessions
  Future<void> loadActiveSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _api.getActiveSessions();
      state = state.copyWith(
        isLoading: false,
        activeSessions: sessions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Revoke a specific session
  Future<bool> revokeSession(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.revokeSession(sessionId);
      // Refresh sessions list
      await loadActiveSessions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Revoke all sessions except current
  Future<bool> revokeAllSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.revokeAllSessions();
      // Refresh sessions list
      await loadActiveSessions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Get trusted devices
  Future<void> loadTrustedDevices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final devices = await _api.getTrustedDevices();
      state = state.copyWith(
        isLoading: false,
        trustedDevices: devices,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Remove a trusted device
  Future<bool> removeTrustedDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.removeTrustedDevice(deviceId);
      // Refresh devices list
      await loadTrustedDevices();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Get backup codes for 2FA
  Future<List<BackupCode>> getBackupCodes() async {
    try {
      final codesData = await _api.getBackupCodes();
      return codesData.map((json) => BackupCode.fromJson(json)).toList();
    } catch (e) {
      debugPrint('AUTH: Failed to get backup codes');
      rethrow;
    }
  }

  /// Regenerate backup codes for 2FA
  Future<List<BackupCode>> regenerateBackupCodes() async {
    try {
      final newCodes = await _api.regenerateBackupCodes();
      return newCodes.map((code) => BackupCode(code: code, used: false)).toList();
    } catch (e) {
      debugPrint('AUTH: Failed to regenerate backup codes');
      rethrow;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String organizationName,
    required bool acceptTerms,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        organizationName: organizationName,
        acceptTerms: acceptTerms,
      );
      await _storage.saveTokens(response.accessToken, response.refreshToken);
      await _storage.saveUserId(response.user.id);

      // Save token expiry if provided
      if (response.expiresAt != null) {
        await _storage.saveTokenExpiry(response.expiresAt!);
      }

      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Clear local state first
    state = AuthState(isLoading: true);

    try {
      // Try to notify backend of logout
      await _api.logout();
      debugPrint('AUTH: Logout successful');
    } catch (e) {
      // Log error but continue with logout - user should be logged out locally even if backend fails
      debugPrint('AUTH: Backend logout failed, continuing with local logout');
    }

    try {
      // Clear local storage
      await _storage.clearAll();
    } catch (e) {
      debugPrint('AUTH: Failed to clear storage');
    }

    // Reset state
    state = AuthState();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _api.getProfile();
      state = state.copyWith(user: user);
      debugPrint('AUTH: User profile refreshed');
    } catch (e) {
      debugPrint('AUTH: Failed to refresh user profile');
      // Don't update state on error, keep current user
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear rate limit state (called after timer expires)
  void clearRateLimit() {
    state = state.copyWith(
      isRateLimited: false,
      rateLimitRetryAfter: null,
      rateLimitEndTime: null,
    );
  }

  String _getErrorMessage(dynamic e) {
    final errorString = e.toString();

    if (errorString.contains('401')) {
      return 'Email ou mot de passe incorrect';
    }
    if (errorString.contains('409')) {
      return 'Cet email est deja utilise';
    }
    if (errorString.contains('429')) {
      return 'Trop de tentatives. Veuillez reessayer plus tard.';
    }
    if (errorString.contains('invalid_code') || errorString.contains('invalid code')) {
      return 'Code de verification invalide';
    }
    if (errorString.contains('expired')) {
      return 'Session expiree. Veuillez vous reconnecter.';
    }
    if (errorString.contains('SocketException')) {
      return 'Erreur de connexion. Verifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez reessayer.';
  }

  /// Extract rate limit retry-after seconds from error
  int? _extractRateLimitRetryAfter(dynamic e) {
    final errorString = e.toString();
    if (errorString.contains('429')) {
      // Try to extract retry-after value from error
      final match = RegExp(r'(\d+)\s*(?:seconds?|sec|s)').firstMatch(errorString);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
      // Default to 15 minutes as per spec
      return 15 * 60;
    }
    return null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
