import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_level.dart';
import '../services/api_service.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

/// Provider pour le profil utilisateur actuel
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }

  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/me/profile');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    // Return default profile from auth state
    return UserProfile(
      id: authState.user!.id,
      email: authState.user!.email,
      firstName: authState.user!.firstName,
      lastName: authState.user!.lastName,
      photoUrl: authState.user!.photoUrl,
      accountType: UserAccountType.cavalier,
      createdAt: DateTime.now(),
    );
  }
});

/// Provider pour le type de compte actuel
final accountTypeProvider = Provider<UserAccountType>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.valueOrNull?.accountType ?? UserAccountType.cavalier;
});

/// Provider pour vérifier les permissions
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final profile = ref.watch(userProfileProvider);
  final accountType = profile.valueOrNull?.accountType ?? UserAccountType.cavalier;

  // Check specific permission
  final permissions = profile.valueOrNull?.permissions;
  if (permissions != null && permissions.containsKey(permission)) {
    return permissions[permission] as bool? ?? false;
  }

  // Check based on account type
  switch (permission) {
    case 'employees':
      return accountType.canManageEmployees;
    case 'breeding':
      return accountType.canManageBreeding;
    case 'nutrition_ai':
      return accountType.canUseNutritionAI;
    case 'advanced_ai':
      return accountType.hasAdvancedAI;
    default:
      return true;
  }
});

/// Provider pour les employés (pour écurie/haras)
final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final accountType = ref.watch(accountTypeProvider);
  if (!accountType.canManageEmployees) {
    return [];
  }

  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/organization/employees');
    return (response as List).map((e) => Employee.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Notifier pour la gestion du profil utilisateur
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ApiService _api;
  final Ref _ref;

  UserProfileNotifier(this._api, this._ref) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final response = await _api.get('/users/me/profile');
      state = AsyncValue.data(UserProfile.fromJson(response as Map<String, dynamic>));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateAccountType(UserAccountType type) async {
    try {
      await _api.patch('/users/me/profile', data: {
        'accountType': type.name,
      });

      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(accountType: type));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? organizationName,
    String? siret,
    String? phone,
    String? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (organizationName != null) data['organizationName'] = organizationName;
      if (siret != null) data['siret'] = siret;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;

      await _api.patch('/users/me/profile', data: data);
      await _loadProfile();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return UserProfileNotifier(api, ref);
});

/// Notifier pour la gestion des employés
class EmployeesNotifier extends StateNotifier<AsyncValue<List<Employee>>> {
  final ApiService _api;

  EmployeesNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await _api.get('/organization/employees');
      state = AsyncValue.data((response as List).map((e) => Employee.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addEmployee({
    required String name,
    required String email,
    required EmployeeRole role,
    String? phone,
  }) async {
    try {
      await _api.post('/organization/employees', data: {
        'name': name,
        'email': email,
        'role': role.name,
        'phone': phone,
      });
      await _loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployee(String id, {
    String? name,
    EmployeeRole? role,
    List<String>? permissions,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (role != null) data['role'] = role.name;
      if (permissions != null) data['permissions'] = permissions;
      if (isActive != null) data['isActive'] = isActive;

      await _api.patch('/organization/employees/$id', data: data);
      await _loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeEmployee(String id) async {
    try {
      await _api.delete('/organization/employees/$id');
      await _loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    _loadEmployees();
  }
}

final employeesNotifierProvider =
    StateNotifierProvider<EmployeesNotifier, AsyncValue<List<Employee>>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return EmployeesNotifier(api);
});
