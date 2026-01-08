import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planning.dart';
import '../services/api_service.dart';

/// Calendar events for a date range
final calendarEventsProvider =
    FutureProvider.autoDispose.family<List<CalendarEvent>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/events', queryParams: {
      'start': range.start.toIso8601String(),
      'end': range.end.toIso8601String(),
    });
    return ((response as List?) ?? []).map((e) => CalendarEvent.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Today's events
final todayEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(calendarEventsProvider((start: start, end: end)).future);
});

/// Upcoming events (next 7 days)
final upcomingEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 7));
  return ref.watch(calendarEventsProvider((start: start, end: end)).future);
});

/// Events by type
final eventsByTypeProvider =
    FutureProvider.autoDispose.family<List<CalendarEvent>, EventType>((ref, type) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/events', queryParams: {
      'type': type.name,
    });
    return ((response as List?) ?? []).map((e) => CalendarEvent.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Active goals
final activeGoalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/goals', queryParams: {'status': 'active'});
    return ((response as List?) ?? []).map((e) => Goal.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// All goals
final allGoalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/goals');
    return ((response as List?) ?? []).map((e) => Goal.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Goals by category
final goalsByCategoryProvider =
    FutureProvider.autoDispose.family<List<Goal>, GoalCategory>((ref, category) async {
  final goals = await ref.watch(allGoalsProvider.future);
  return goals.where((g) => g.category == category).toList();
});

/// Active training plan
final activeTrainingPlanProvider = FutureProvider.autoDispose<TrainingPlan?>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/training/plans/active');
    return TrainingPlan.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// All training plans
final trainingPlansProvider = FutureProvider.autoDispose<List<TrainingPlan>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/training/plans');
    return ((response as List?) ?? []).map((e) => TrainingPlan.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

/// Today's training session
final todaySessionProvider = FutureProvider.autoDispose<TrainingSession?>((ref) async {
  final plan = await ref.watch(activeTrainingPlanProvider.future);
  if (plan == null) return null;

  final today = DateTime.now().weekday;
  final currentWeek = plan.weeks.where((w) => w.weekNumber == plan.currentWeek).firstOrNull;
  if (currentWeek == null) return null;

  return currentWeek.sessions.where((s) => s.dayOfWeek == today).firstOrNull;
});

/// Training recommendations
final trainingRecommendationsProvider = FutureProvider.autoDispose<List<TrainingRecommendation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/training/recommendations');
    return (response as List).map((e) => TrainingRecommendation.fromJson(e)).toList();
  } catch (e) {
    // Return empty list if endpoint not available
    return [];
  }
});

/// Planning summary
final planningSummaryProvider = FutureProvider.autoDispose<PlanningSummary>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/planning/summary');
  return PlanningSummary.fromJson(response);
});

/// Planning notifier for CRUD operations
class PlanningNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  PlanningNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Create calendar event
  Future<CalendarEvent?> createEvent(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/calendar/events', data);
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return CalendarEvent.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update calendar event
  Future<bool> updateEvent(String eventId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/calendar/events/$eventId', data);
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete calendar event
  Future<bool> deleteEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/calendar/events/$eventId');
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create goal
  Future<Goal?> createGoal(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/calendar/goals', data);
      _ref.invalidate(activeGoalsProvider);
      _ref.invalidate(allGoalsProvider);
      state = const AsyncValue.data(null);
      return Goal.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update goal progress
  Future<bool> updateGoalProgress(String goalId, double value) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/calendar/goals/$goalId', {'currentValue': value});
      _ref.invalidate(activeGoalsProvider);
      _ref.invalidate(allGoalsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Complete goal
  Future<bool> completeGoal(String goalId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/calendar/goals/$goalId/complete', {});
      _ref.invalidate(activeGoalsProvider);
      _ref.invalidate(allGoalsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create training plan
  Future<TrainingPlan?> createTrainingPlan(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/training/plans', data);
      _ref.invalidate(trainingPlansProvider);
      _ref.invalidate(activeTrainingPlanProvider);
      state = const AsyncValue.data(null);
      return TrainingPlan.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Generate AI training plan
  Future<TrainingPlan?> generateAITrainingPlan({
    required String horseId,
    required TrainingDiscipline discipline,
    required TrainingLevel level,
    required int weeks,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/training/plans/generate', {
        'horseId': horseId,
        'discipline': discipline.name,
        'level': level.name,
        'weeks': weeks,
      });
      _ref.invalidate(trainingPlansProvider);
      _ref.invalidate(activeTrainingPlanProvider);
      state = const AsyncValue.data(null);
      return TrainingPlan.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Complete training session
  Future<bool> completeSession(String planId, String sessionId, {int? rating, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/training/plans/$planId/sessions/$sessionId/complete', {
        'rating': rating,
        'notes': notes,
      });
      _ref.invalidate(activeTrainingPlanProvider);
      _ref.invalidate(todaySessionProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Dismiss recommendation
  Future<bool> dismissRecommendation(String recommendationId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/training/recommendations/$recommendationId/dismiss', {});
      _ref.invalidate(trainingRecommendationsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final planningNotifierProvider =
    StateNotifierProvider<PlanningNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PlanningNotifier(api, ref);
});

/// Events for a specific horse
final horseEventsProvider =
    FutureProvider.autoDispose.family<List<CalendarEvent>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/events');
    return ((response as List?) ?? []).map((e) => CalendarEvent.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});
