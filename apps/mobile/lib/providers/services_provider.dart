import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/services.dart';
import '../services/api_service.dart';

/// Search service providers
final searchProvidersProvider =
    FutureProvider.family<List<ServiceProvider>, ServiceSearchFilters>((ref, filters) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/search', queryParams: filters.toQueryParams());
    return ((response as List?) ?? []).map((e) => ServiceProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Providers by type
final providersByTypeProvider =
    FutureProvider.family<List<ServiceProvider>, ServiceType>((ref, type) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services', queryParams: {'type': type.name});
    return ((response as List?) ?? []).map((e) => ServiceProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Provider by ID
final providerProvider =
    FutureProvider.family<ServiceProvider, String>((ref, providerId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/services/$providerId');
  return ServiceProvider.fromJson(response);
});

/// Provider reviews
final providerReviewsProvider =
    FutureProvider.family<List<ServiceReview>, String>((ref, providerId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/$providerId/reviews');
    return ((response as List?) ?? []).map((e) => ServiceReview.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Nearby providers
final nearbyProvidersProvider =
    FutureProvider.family<List<ServiceProvider>, ({double lat, double lng, double radius, ServiceType? type})>(
        (ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final queryParams = {
    'lat': params.lat.toString(),
    'lng': params.lng.toString(),
    'radius': params.radius.toString(),
  };
  if (params.type != null) {
    queryParams['type'] = params.type!.name;
  }
  try {
    final response = await api.get('/services/nearby', queryParams: queryParams);
    return ((response as List?) ?? []).map((e) => ServiceProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Saved providers
final savedProvidersProvider = FutureProvider<List<SavedProvider>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/saved');
    return ((response as List?) ?? []).map((e) => SavedProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// User appointments
final appointmentsProvider = FutureProvider<List<ServiceAppointment>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/appointments');
    return ((response as List?) ?? []).map((e) => ServiceAppointment.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Upcoming appointments
final upcomingAppointmentsProvider = FutureProvider<List<ServiceAppointment>>((ref) async {
  final appointments = await ref.watch(appointmentsProvider.future);
  final now = DateTime.now();
  return appointments
      .where((a) => a.appointmentDate.isAfter(now) &&
                    a.status != AppointmentStatus.cancelled &&
                    a.status != AppointmentStatus.completed)
      .toList()
    ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
});

/// Past appointments
final pastAppointmentsProvider = FutureProvider<List<ServiceAppointment>>((ref) async {
  final appointments = await ref.watch(appointmentsProvider.future);
  return appointments
      .where((a) => a.isPast || a.status == AppointmentStatus.completed)
      .toList()
    ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
});

/// Emergency contacts
final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/emergency-contacts');
    return ((response as List?) ?? []).map((e) => EmergencyContact.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Service statistics
final serviceStatsProvider = FutureProvider<ServiceStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/services/stats');
  return ServiceStats.fromJson(response);
});

/// Featured providers
final featuredProvidersProvider = FutureProvider<List<ServiceProvider>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/featured');
    return ((response as List?) ?? []).map((e) => ServiceProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Services notifier for CRUD operations
class ServicesNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  ServicesNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Create appointment
  Future<ServiceAppointment?> createAppointment(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/appointments', data);
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(upcomingAppointmentsProvider);
      state = const AsyncValue.data(null);
      return ServiceAppointment.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update appointment
  Future<bool> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/appointments/$appointmentId', data);
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(upcomingAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String? reason) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/appointments/$appointmentId/cancel', {'reason': reason});
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(upcomingAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Rate appointment
  Future<bool> rateAppointment(String appointmentId, int rating, String? feedback) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/appointments/$appointmentId/rate', {
        'rating': rating,
        'feedback': feedback,
      });
      _ref.invalidate(appointmentsProvider);
      _ref.invalidate(pastAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add review
  Future<ServiceReview?> addReview(String providerId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/services/$providerId/reviews', data);
      _ref.invalidate(providerReviewsProvider(providerId));
      _ref.invalidate(providerProvider(providerId));
      state = const AsyncValue.data(null);
      return ServiceReview.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update review
  Future<bool> updateReview(String providerId, String reviewId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/services/$providerId/reviews/$reviewId', data);
      _ref.invalidate(providerReviewsProvider(providerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String providerId, String reviewId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/services/$providerId/reviews/$reviewId');
      _ref.invalidate(providerReviewsProvider(providerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Save provider
  Future<bool> saveProvider(String providerId, String? notes) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/services/$providerId/save', {'notes': notes});
      _ref.invalidate(savedProvidersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Remove saved provider
  Future<bool> removeSavedProvider(String providerId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/services/$providerId/save');
      _ref.invalidate(savedProvidersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add emergency contact
  Future<EmergencyContact?> addEmergencyContact(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/services/emergency-contacts', data);
      _ref.invalidate(emergencyContactsProvider);
      state = const AsyncValue.data(null);
      return EmergencyContact.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update emergency contact
  Future<bool> updateEmergencyContact(String contactId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/services/emergency-contacts/$contactId', data);
      _ref.invalidate(emergencyContactsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/services/emergency-contacts/$contactId');
      _ref.invalidate(emergencyContactsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String providerId, String reviewId) async {
    try {
      await _api.post('/services/$providerId/reviews/$reviewId/helpful', {});
      _ref.invalidate(providerReviewsProvider(providerId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Report provider
  Future<bool> reportProvider(String providerId, String reason, String? details) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/services/$providerId/report', {
        'reason': reason,
        'details': details,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final servicesNotifierProvider =
    StateNotifierProvider<ServicesNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ServicesNotifier(api, ref);
});

/// Current location provider (to be set from location service)
final currentLocationProvider = StateProvider<({double lat, double lng})?>((_) => null);

/// Nearby emergency vets (using current location)
final nearbyEmergencyVetsProvider = FutureProvider<List<ServiceProvider>>((ref) async {
  final location = ref.watch(currentLocationProvider);
  if (location == null) return [];

  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/services/nearby', queryParams: {
      'lat': location.lat.toString(),
      'lng': location.lng.toString(),
      'radius': '50',
      'type': ServiceType.veterinarian.name,
      'emergency': 'true',
    });
    return ((response as List?) ?? []).map((e) => ServiceProvider.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});
