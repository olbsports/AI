import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/admin_api_service.dart';

/// Admin authentication state
class AdminAuthState {
  final AdminUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AdminAuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AdminAuthState copyWith({
    AdminUser? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AdminAuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Admin auth notifier
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminApiService _api;

  AdminAuthNotifier(this._api) : super(AdminAuthState()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _api.getStoredToken();
      if (token != null) {
        final user = await _api.getCurrentAdmin();
        if (user != null) {
          state = AdminAuthState(user: user, token: token);
          return;
        }
      }
    } catch (e) {
      // Token invalid or expired
    }
    state = AdminAuthState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.login(email, password);
      if (response['success'] == true) {
        state = AdminAuthState(
          user: response['user'],
          token: response['token'],
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response['error'] ?? 'Identifiants invalides',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = AdminAuthState();
  }

  bool hasPermission(String permission) {
    if (state.user == null) return false;
    if (state.user!.permissions.contains('*')) return true;
    return state.user!.permissions.contains(permission);
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final api = ref.watch(adminApiServiceProvider);
  return AdminAuthNotifier(api);
});
