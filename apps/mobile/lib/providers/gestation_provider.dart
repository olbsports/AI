import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/gestation.dart';
import '../services/api_service.dart';

/// All gestation records
final gestationsProvider = FutureProvider<List<GestationRecord>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gestations');
  return (response as List).map((e) => GestationRecord.fromJson(e)).toList();
});

/// Active gestations
final activeGestationsProvider = FutureProvider<List<GestationRecord>>((ref) async {
  final gestations = await ref.watch(gestationsProvider.future);
  return gestations.where((g) =>
    g.status == GestationStatus.confirmed ||
    g.status == GestationStatus.suspected ||
    g.status == GestationStatus.atRisk
  ).toList();
});

/// Gestation by ID
final gestationProvider =
    FutureProvider.family<GestationRecord, String>((ref, gestationId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gestations/$gestationId');
  return GestationRecord.fromJson(response);
});

/// Gestations for a mare
final mareGestationsProvider =
    FutureProvider.family<List<GestationRecord>, String>((ref, mareId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$mareId/gestations');
  return (response as List).map((e) => GestationRecord.fromJson(e)).toList();
});

/// Gestation checkups
final gestationCheckupsProvider =
    FutureProvider.family<List<GestationCheckup>, String>((ref, gestationId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gestations/$gestationId/checkups');
  return (response as List).map((e) => GestationCheckup.fromJson(e)).toList();
});

/// Gestation milestones
final gestationMilestonesProvider =
    FutureProvider.family<List<GestationMilestone>, String>((ref, gestationId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gestations/$gestationId/milestones');
  return (response as List).map((e) => GestationMilestone.fromJson(e)).toList();
});

/// Gestation notes
final gestationNotesProvider =
    FutureProvider.family<List<GestationNote>, String>((ref, gestationId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gestations/$gestationId/notes');
  return (response as List).map((e) => GestationNote.fromJson(e)).toList();
});

/// All birth records
final birthRecordsProvider = FutureProvider<List<BirthRecord>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/births');
  return (response as List).map((e) => BirthRecord.fromJson(e)).toList();
});

/// Birth record by ID
final birthRecordProvider =
    FutureProvider.family<BirthRecord, String>((ref, birthId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/births/$birthId');
  return BirthRecord.fromJson(response);
});

/// Foal development records
/// COMMENTED OUT: Endpoint /foals/:id/development does not exist
// final foalDevelopmentProvider =
//     FutureProvider.family<List<FoalDevelopment>, String>((ref, foalId) async {
//   final api = ref.watch(apiServiceProvider);
//   final response = await api.get('/foals/$foalId/development');
//   return (response as List).map((e) => FoalDevelopment.fromJson(e)).toList();
// });

/// Breeding statistics
final breedingStatsProvider = FutureProvider<BreedingStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stats');
  return BreedingStats.fromJson(response);
});

/// Upcoming checkups
/// COMMENTED OUT: Endpoint /gestations/checkups/upcoming does not exist
// final upcomingCheckupsProvider = FutureProvider<List<GestationCheckup>>((ref) async {
//   final api = ref.watch(apiServiceProvider);
//   final response = await api.get('/gestations/checkups/upcoming');
//   return (response as List).map((e) => GestationCheckup.fromJson(e)).toList();
// });

/// Gestations due soon (within 30 days)
final gestationsDueSoonProvider = FutureProvider<List<GestationRecord>>((ref) async {
  final activeGestations = await ref.watch(activeGestationsProvider.future);
  return activeGestations.where((g) => g.daysRemaining <= 30 && g.daysRemaining >= 0).toList();
});

/// Gestation notifier for CRUD operations
class GestationNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  GestationNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Create gestation record
  Future<GestationRecord?> createGestation(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gestations', data);
      _ref.invalidate(gestationsProvider);
      _ref.invalidate(activeGestationsProvider);
      _ref.invalidate(breedingStatsProvider);
      state = const AsyncValue.data(null);
      return GestationRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update gestation
  Future<bool> updateGestation(String gestationId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/gestations/$gestationId', data);
      _ref.invalidate(gestationProvider(gestationId));
      _ref.invalidate(gestationsProvider);
      _ref.invalidate(activeGestationsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update gestation status
  Future<bool> updateGestationStatus(String gestationId, GestationStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/gestations/$gestationId/status', {'status': status.name});
      _ref.invalidate(gestationProvider(gestationId));
      _ref.invalidate(gestationsProvider);
      _ref.invalidate(activeGestationsProvider);
      _ref.invalidate(breedingStatsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add checkup
  Future<GestationCheckup?> addCheckup(String gestationId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gestations/$gestationId/checkups', data);
      _ref.invalidate(gestationCheckupsProvider(gestationId));
      // _ref.invalidate(upcomingCheckupsProvider); // Provider commented out
      state = const AsyncValue.data(null);
      return GestationCheckup.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update checkup
  Future<bool> updateCheckup(String gestationId, String checkupId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/gestations/$gestationId/checkups/$checkupId', data);
      _ref.invalidate(gestationCheckupsProvider(gestationId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add note
  Future<GestationNote?> addNote(String gestationId, String content, NoteType type, List<String>? attachments) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gestations/$gestationId/notes', {
        'content': content,
        'type': type.name,
        'attachments': attachments ?? [],
      });
      _ref.invalidate(gestationNotesProvider(gestationId));
      state = const AsyncValue.data(null);
      return GestationNote.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Complete milestone
  Future<bool> completeMilestone(String gestationId, String milestoneId, String? notes) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gestations/$gestationId/milestones/$milestoneId/complete', {
        'notes': notes,
      });
      _ref.invalidate(gestationMilestonesProvider(gestationId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Record birth
  Future<BirthRecord?> recordBirth(String gestationId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gestations/$gestationId/birth', data);
      _ref.invalidate(gestationProvider(gestationId));
      _ref.invalidate(gestationsProvider);
      _ref.invalidate(activeGestationsProvider);
      _ref.invalidate(birthRecordsProvider);
      _ref.invalidate(breedingStatsProvider);
      state = const AsyncValue.data(null);
      return BirthRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update birth record
  Future<bool> updateBirthRecord(String birthId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/births/$birthId', data);
      _ref.invalidate(birthRecordProvider(birthId));
      _ref.invalidate(birthRecordsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add foal development record
  /// COMMENTED OUT: Endpoint /foals/:id/development does not exist
  // Future<FoalDevelopment?> addFoalDevelopment(String foalId, Map<String, dynamic> data) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final response = await _api.post('/foals/$foalId/development', data);
  //     _ref.invalidate(foalDevelopmentProvider(foalId));
  //     state = const AsyncValue.data(null);
  //     return FoalDevelopment.fromJson(response);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //     return null;
  //   }
  // }

  /// Mark gestation as lost
  Future<bool> markGestationLost(String gestationId, String? reason) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gestations/$gestationId/loss', {'reason': reason});
      _ref.invalidate(gestationProvider(gestationId));
      _ref.invalidate(gestationsProvider);
      _ref.invalidate(activeGestationsProvider);
      _ref.invalidate(breedingStatsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Calculate expected due date
  static DateTime calculateDueDate(DateTime conceptionDate) {
    return conceptionDate.add(const Duration(days: GestationRecord.standardGestationDays));
  }

  /// Get standard milestones for a gestation
  List<Map<String, dynamic>> getStandardMilestones(DateTime conceptionDate) {
    return GestationMilestones.standard.map((m) {
      final milestoneDate = conceptionDate.add(Duration(days: m['day'] as int));
      return {
        ...m,
        'date': milestoneDate.toIso8601String(),
        'isCompleted': DateTime.now().isAfter(milestoneDate),
      };
    }).toList();
  }
}

final gestationNotifierProvider =
    StateNotifierProvider<GestationNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return GestationNotifier(api, ref);
});
