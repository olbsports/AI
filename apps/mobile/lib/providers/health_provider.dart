import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/health.dart';
import '../services/api_service.dart';

/// Health records for a horse
final healthRecordsProvider =
    FutureProvider.family<List<HealthRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$horseId/health');
  return ((response as List?) ?? []).map((e) => HealthRecord.fromJson(e)).toList();
});

/// Health records by type
final healthRecordsByTypeProvider =
    FutureProvider.family<List<HealthRecord>, ({String horseId, HealthRecordType type})>(
        (ref, params) async {
  final records = await ref.watch(healthRecordsProvider(params.horseId).future);
  return records.where((r) => r.type == params.type).toList();
});

/// Weight records for a horse
final weightRecordsProvider =
    FutureProvider.family<List<WeightRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$horseId/weight');
  return ((response as List?) ?? []).map((e) => WeightRecord.fromJson(e)).toList();
});

/// Body condition records
final bodyConditionRecordsProvider =
    FutureProvider.family<List<BodyConditionRecord>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$horseId/body-condition');
  return ((response as List?) ?? []).map((e) => BodyConditionRecord.fromJson(e)).toList();
});

/// Active nutrition plan for a horse
final nutritionPlanProvider =
    FutureProvider.family<NutritionPlan?, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/nutrition/active');
    return NutritionPlan.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// All nutrition plans for a horse
final nutritionPlansProvider =
    FutureProvider.family<List<NutritionPlan>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$horseId/nutrition');
  return ((response as List?) ?? []).map((e) => NutritionPlan.fromJson(e)).toList();
});

/// Health reminders for all horses
final healthRemindersProvider = FutureProvider<List<HealthReminder>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/health/reminders');
  return ((response as List?) ?? []).map((e) => HealthReminder.fromJson(e)).toList();
});

/// Overdue reminders
final overdueRemindersProvider = FutureProvider<List<HealthReminder>>((ref) async {
  final reminders = await ref.watch(healthRemindersProvider.future);
  return reminders.where((r) => r.isOverdue).toList();
});

/// Upcoming reminders (next 7 days)
final upcomingRemindersProvider = FutureProvider<List<HealthReminder>>((ref) async {
  final reminders = await ref.watch(healthRemindersProvider.future);
  final now = DateTime.now();
  final weekFromNow = now.add(const Duration(days: 7));
  return reminders
      .where((r) => !r.isOverdue && r.dueDate.isBefore(weekFromNow))
      .toList();
});

/// Health summary for a horse
final healthSummaryProvider =
    FutureProvider.family<HealthSummary, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/horses/$horseId/health/summary');
  return HealthSummary.fromJson(response);
});

/// Calculate nutrition recommendation
final nutritionRecommendationProvider =
    FutureProvider.family<NutritionRecommendation, ({String horseId, double weight, ActivityLevel activity})>(
        (ref, params) async {
  return NutritionRecommendation.calculate(
    horseId: params.horseId,
    weight: params.weight,
    activityLevel: params.activity,
  );
});

/// Health notifier for CRUD operations
class HealthNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  HealthNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Add a health record
  Future<HealthRecord?> addHealthRecord(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/health', data);
      _ref.invalidate(healthRecordsProvider(horseId));
      _ref.invalidate(healthSummaryProvider(horseId));
      _ref.invalidate(healthRemindersProvider);
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
      _ref.invalidate(healthRecordsProvider(horseId));
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
      _ref.invalidate(healthRecordsProvider(horseId));
      _ref.invalidate(healthSummaryProvider(horseId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add weight record
  Future<WeightRecord?> addWeightRecord(String horseId, double weight, MeasurementMethod method, String? notes) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/weight', {
        'weight': weight,
        'method': method.name,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });
      _ref.invalidate(weightRecordsProvider(horseId));
      state = const AsyncValue.data(null);
      return WeightRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Add body condition score
  Future<BodyConditionRecord?> addBodyCondition(String horseId, int score, String? notes) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/body-condition', {
        'score': score,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });
      _ref.invalidate(bodyConditionRecordsProvider(horseId));
      state = const AsyncValue.data(null);
      return BodyConditionRecord.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Create nutrition plan
  Future<NutritionPlan?> createNutritionPlan(String horseId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/horses/$horseId/nutrition', data);
      _ref.invalidate(nutritionPlansProvider(horseId));
      _ref.invalidate(nutritionPlanProvider(horseId));
      state = const AsyncValue.data(null);
      return NutritionPlan.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Dismiss reminder
  Future<bool> dismissReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/health/reminders/$reminderId/dismiss', {});
      _ref.invalidate(healthRemindersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Complete reminder
  Future<bool> completeReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/health/reminders/$reminderId/complete', {});
      _ref.invalidate(healthRemindersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final healthNotifierProvider =
    StateNotifierProvider<HealthNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return HealthNotifier(api, ref);
});
