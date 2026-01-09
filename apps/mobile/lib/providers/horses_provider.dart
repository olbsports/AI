import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../models/health.dart';
import '../services/api_service.dart';

final horsesProvider = FutureProvider.autoDispose<List<Horse>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getHorses();
});

final horseProvider = FutureProvider.autoDispose.family<Horse, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getHorse(id);
});

// ==================== PEDIGREE ====================

/// Pedigree data for a horse
final horsePedigreeProvider = FutureProvider.autoDispose.family<PedigreeData, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/pedigree');
    return PedigreeData.fromJson(response);
  } catch (e) {
    // If API fails, try to build from horse data
    final horse = await ref.watch(horseProvider(horseId).future);
    return PedigreeData.fromHorse(horse);
  }
});

/// Offspring/descendants for a horse
final horseOffspringProvider = FutureProvider.autoDispose.family<List<Horse>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/offspring');
    return ((response as List?) ?? []).map((e) => Horse.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

// ==================== PERFORMANCE ====================

/// Competition results for a horse
final competitionResultsProvider = FutureProvider.autoDispose.family<List<CompetitionResult>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/competitions');
    return ((response as List?) ?? []).map((e) => CompetitionResult.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Training sessions for a horse
final trainingSessionsProvider = FutureProvider.autoDispose.family<List<TrainingSession>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/training');
    return ((response as List?) ?? []).map((e) => TrainingSession.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Performance summary for a horse
final performanceSummaryProvider = FutureProvider.autoDispose.family<PerformanceSummary, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/performance/summary');
    return PerformanceSummary.fromJson(response);
  } catch (e) {
    // Build summary from local data if API fails
    final competitions = await ref.watch(competitionResultsProvider(horseId).future);
    final training = await ref.watch(trainingSessionsProvider(horseId).future);

    return PerformanceSummary(
      horseId: horseId,
      totalCompetitions: competitions.length,
      victories: competitions.where((c) => c.rank == 1).length,
      podiums: competitions.where((c) => c.isPodium).length,
      totalTrainingSessions: training.length,
      totalTrainingMinutes: training.fold(0, (sum, t) => sum + t.durationMinutes),
      recentResults: competitions.take(5).toList(),
      recentTraining: training.take(5).toList(),
      lastCompetition: competitions.isNotEmpty ? competitions.first.date : null,
      lastTraining: training.isNotEmpty ? training.first.date : null,
    );
  }
});

class HorsesNotifier extends StateNotifier<AsyncValue<List<Horse>>> {
  final ApiService _api;

  HorsesNotifier(this._api) : super(const AsyncValue.loading()) {
    loadHorses();
  }

  Future<void> loadHorses({String? search, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final horses = await _api.getHorses(search: search, status: status);
      state = AsyncValue.data(horses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Horse?> createHorse(Map<String, dynamic> data) async {
    try {
      final horse = await _api.createHorse(data);
      state = state.whenData((horses) => [horse, ...horses]);
      return horse;
    } catch (e) {
      return null;
    }
  }

  Future<Horse?> updateHorse(String id, Map<String, dynamic> data) async {
    try {
      final horse = await _api.updateHorse(id, data);
      state = state.whenData(
        (horses) => horses.map((h) => h.id == id ? horse : h).toList(),
      );
      return horse;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteHorse(String id) async {
    try {
      await _api.deleteHorse(id);
      state = state.whenData(
        (horses) => horses.where((h) => h.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload a photo for a horse
  /// Returns the URL if successful
  /// Throws an exception with error message on failure
  Future<String> uploadPhoto(String horseId, File file) async {
    return await _api.uploadHorsePhoto(horseId, file);
  }
}

final horsesNotifierProvider =
    StateNotifierProvider<HorsesNotifier, AsyncValue<List<Horse>>>((ref) {
  return HorsesNotifier(ref.watch(apiServiceProvider));
});

// ==================== PERFORMANCE NOTIFIER ====================

/// Notifier for managing performance-related data
class PerformanceNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  PerformanceNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Add a competition result
  Future<CompetitionResult?> addCompetitionResult(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/competitions', data);
      _ref.invalidate(competitionResultsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return CompetitionResult.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a competition result
  Future<bool> updateCompetitionResult(String horseId, String resultId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/horses/$horseId/competitions/$resultId', data);
      _ref.invalidate(competitionResultsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a competition result
  Future<bool> deleteCompetitionResult(String horseId, String resultId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/horses/$horseId/competitions/$resultId');
      _ref.invalidate(competitionResultsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add a training session
  Future<TrainingSession?> addTrainingSession(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/training', data);
      _ref.invalidate(trainingSessionsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return TrainingSession.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a training session
  Future<bool> updateTrainingSession(String horseId, String sessionId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/horses/$horseId/training/$sessionId', data);
      _ref.invalidate(trainingSessionsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a training session
  Future<bool> deleteTrainingSession(String horseId, String sessionId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/horses/$horseId/training/$sessionId');
      _ref.invalidate(trainingSessionsProvider(horseId));
      _ref.invalidate(performanceSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final performanceNotifierProvider =
    StateNotifierProvider<PerformanceNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PerformanceNotifier(api, ref);
});

// ==================== HEALTH (for horse detail screen) ====================

/// Health records for a horse (used in horse detail screen)
final horseHealthRecordsProvider = FutureProvider.autoDispose.family<List<HealthRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/health');
    return ((response as List?) ?? []).map((e) => HealthRecord.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Health summary for a horse
final healthSummaryProvider = FutureProvider.autoDispose.family<HealthSummary, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/health/summary');
    return HealthSummary.fromJson(response);
  } catch (e) {
    // Build summary from records if API fails
    final records = await ref.watch(horseHealthRecordsProvider(horseId).future);
    return _buildHealthSummaryFromRecords(horseId, records);
  }
});

/// Weight records for a horse (used in horse detail screen)
final horseWeightRecordsProvider = FutureProvider.autoDispose.family<List<WeightRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/weight');
    return ((response as List?) ?? []).map((e) => WeightRecord.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Body condition records for a horse (used in horse detail screen)
final horseBodyConditionRecordsProvider = FutureProvider.autoDispose.family<List<BodyConditionRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/body-condition');
    return ((response as List?) ?? []).map((e) => BodyConditionRecord.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Nutrition plans for a horse
final nutritionPlansProvider = FutureProvider.autoDispose.family<List<NutritionPlan>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/nutrition');
    return ((response as List?) ?? []).map((e) => NutritionPlan.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Active nutrition plan for a horse
final activeNutritionPlanProvider = FutureProvider.autoDispose.family<NutritionPlan?, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/nutrition/active');
    if (response == null) return null;
    return NutritionPlan.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// Health notifier for managing health data (used in horse detail screen)
class HorseHealthNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  HorseHealthNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Add a health record
  Future<HealthRecord?> addHealthRecord(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/health', data);
      _ref.invalidate(horseHealthRecordsProvider(horseId));
      _ref.invalidate(healthSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return HealthRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a health record
  Future<bool> updateHealthRecord(String horseId, String recordId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/horses/$horseId/health/$recordId', data);
      _ref.invalidate(horseHealthRecordsProvider(horseId));
      _ref.invalidate(healthSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a health record
  Future<bool> deleteHealthRecord(String horseId, String recordId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/horses/$horseId/health/$recordId');
      _ref.invalidate(horseHealthRecordsProvider(horseId));
      _ref.invalidate(healthSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add a weight record
  Future<WeightRecord?> addWeightRecord(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/weight', data);
      _ref.invalidate(horseWeightRecordsProvider(horseId));
      _ref.invalidate(horseProvider(horseId));
      state = const AsyncValue.data(null);
      return WeightRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Add a body condition record
  Future<BodyConditionRecord?> addBodyConditionRecord(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/body-condition', data);
      _ref.invalidate(horseBodyConditionRecordsProvider(horseId));
      state = const AsyncValue.data(null);
      return BodyConditionRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Add/update a nutrition plan
  Future<NutritionPlan?> saveNutritionPlan(String horseId, Map<String, dynamic> data, {String? planId}) async {
    state = const AsyncValue.loading();
    try {
      final response = planId != null
          ? await _api.put('/horses/$horseId/nutrition/$planId', data)
          : await _api.post('/horses/$horseId/nutrition', data);
      _ref.invalidate(nutritionPlansProvider(horseId));
      _ref.invalidate(activeNutritionPlanProvider(horseId));
      state = const AsyncValue.data(null);
      return NutritionPlan.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final horseHealthNotifierProvider =
    StateNotifierProvider<HorseHealthNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return HorseHealthNotifier(api, ref);
});

/// Helper function to build health summary from records
HealthSummary _buildHealthSummaryFromRecords(String horseId, List<HealthRecord> records) {
  DateTime? lastVaccination;
  DateTime? lastDeworming;
  DateTime? lastFarrier;
  DateTime? lastDentist;
  DateTime? lastVetVisit;

  final overdueReminders = <HealthReminder>[];
  final upcomingReminders = <HealthReminder>[];

  for (final record in records) {
    switch (record.type) {
      case HealthRecordType.vaccination:
        if (lastVaccination == null || record.date.isAfter(lastVaccination)) {
          lastVaccination = record.date;
        }
        break;
      case HealthRecordType.deworming:
        if (lastDeworming == null || record.date.isAfter(lastDeworming)) {
          lastDeworming = record.date;
        }
        break;
      case HealthRecordType.farrier:
        if (lastFarrier == null || record.date.isAfter(lastFarrier)) {
          lastFarrier = record.date;
        }
        break;
      case HealthRecordType.dentist:
        if (lastDentist == null || record.date.isAfter(lastDentist)) {
          lastDentist = record.date;
        }
        break;
      case HealthRecordType.veterinaryVisit:
        if (lastVetVisit == null || record.date.isAfter(lastVetVisit)) {
          lastVetVisit = record.date;
        }
        break;
      default:
        break;
    }

    // Check for reminders
    if (record.nextDueDate != null) {
      final reminder = HealthReminder(
        id: record.id,
        horseId: horseId,
        horseName: record.horseName,
        type: record.type,
        title: record.title,
        dueDate: record.nextDueDate!,
        relatedRecordId: record.id,
      );

      if (record.isOverdue) {
        overdueReminders.add(reminder);
      } else if (record.isDueSoon) {
        upcomingReminders.add(reminder);
      }
    }
  }

  // Determine overall status
  HealthStatus overallStatus = HealthStatus.good;
  if (overdueReminders.isNotEmpty) {
    overallStatus = overdueReminders.length > 2 ? HealthStatus.critical : HealthStatus.needsAttention;
  } else if (upcomingReminders.isEmpty && records.isNotEmpty) {
    overallStatus = HealthStatus.excellent;
  }

  return HealthSummary(
    horseId: horseId,
    totalRecords: records.length,
    lastVaccination: lastVaccination,
    lastDeworming: lastDeworming,
    lastFarrier: lastFarrier,
    lastDentist: lastDentist,
    lastVetVisit: lastVetVisit,
    overdueReminders: overdueReminders,
    upcomingReminders: upcomingReminders,
    overallStatus: overallStatus,
  );
}
