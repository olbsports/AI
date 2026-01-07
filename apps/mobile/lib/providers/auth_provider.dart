import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
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

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // SECURITY: Do not log email or password
      debugPrint('AUTH: Attempting login');
      final response = await _api.login(email, password);
      debugPrint('AUTH: Login successful');
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
      // SECURITY: Log error without exposing sensitive details
      debugPrint('AUTH: Login failed');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
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

  String _getErrorMessage(dynamic e) {
    if (e.toString().contains('401')) {
      return 'Email ou mot de passe incorrect';
    }
    if (e.toString().contains('409')) {
      return 'Cet email est déjà utilisé';
    }
    if (e.toString().contains('SocketException')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
