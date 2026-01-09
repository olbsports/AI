import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planning.dart';
import '../services/api_service.dart';

// ============================================
// CALENDAR VIEW STATE
// ============================================

/// Current calendar view mode
enum CalendarViewMode { day, week, month, agenda }

/// Calendar view state
class CalendarViewState {
  final CalendarViewMode viewMode;
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Set<EventType> selectedFilters;
  final String? selectedHorseId;

  const CalendarViewState({
    this.viewMode = CalendarViewMode.month,
    required this.selectedDate,
    required this.focusedMonth,
    this.selectedFilters = const {},
    this.selectedHorseId,
  });

  CalendarViewState copyWith({
    CalendarViewMode? viewMode,
    DateTime? selectedDate,
    DateTime? focusedMonth,
    Set<EventType>? selectedFilters,
    String? selectedHorseId,
  }) {
    return CalendarViewState(
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      selectedHorseId: selectedHorseId ?? this.selectedHorseId,
    );
  }
}

/// Calendar view state provider
class CalendarViewNotifier extends StateNotifier<CalendarViewState> {
  CalendarViewNotifier()
      : super(CalendarViewState(
          selectedDate: DateTime.now(),
          focusedMonth: DateTime.now(),
        ));

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: month);
  }

  void toggleFilter(EventType type) {
    final filters = Set<EventType>.from(state.selectedFilters);
    if (filters.contains(type)) {
      filters.remove(type);
    } else {
      filters.add(type);
    }
    state = state.copyWith(selectedFilters: filters);
  }

  void clearFilters() {
    state = state.copyWith(selectedFilters: {});
  }

  void selectHorse(String? horseId) {
    state = state.copyWith(selectedHorseId: horseId);
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedDate: now,
      focusedMonth: now,
    );
  }

  void nextPeriod() {
    switch (state.viewMode) {
      case CalendarViewMode.day:
        state = state.copyWith(
          selectedDate: state.selectedDate.add(const Duration(days: 1)),
        );
        break;
      case CalendarViewMode.week:
        state = state.copyWith(
          selectedDate: state.selectedDate.add(const Duration(days: 7)),
        );
        break;
      case CalendarViewMode.month:
      case CalendarViewMode.agenda:
        final next = DateTime(
          state.focusedMonth.year,
          state.focusedMonth.month + 1,
        );
        state = state.copyWith(focusedMonth: next);
        break;
    }
  }

  void previousPeriod() {
    switch (state.viewMode) {
      case CalendarViewMode.day:
        state = state.copyWith(
          selectedDate: state.selectedDate.subtract(const Duration(days: 1)),
        );
        break;
      case CalendarViewMode.week:
        state = state.copyWith(
          selectedDate: state.selectedDate.subtract(const Duration(days: 7)),
        );
        break;
      case CalendarViewMode.month:
      case CalendarViewMode.agenda:
        final prev = DateTime(
          state.focusedMonth.year,
          state.focusedMonth.month - 1,
        );
        state = state.copyWith(focusedMonth: prev);
        break;
    }
  }
}

final calendarViewProvider =
    StateNotifierProvider<CalendarViewNotifier, CalendarViewState>((ref) {
  return CalendarViewNotifier();
});

// ============================================
// HEALTH REMINDERS
// ============================================

/// All health reminders
final healthRemindersProvider =
    FutureProvider.autoDispose<List<HealthReminder>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/health-reminders');
    return ((response as List?) ?? [])
        .map((e) => HealthReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Health reminders for a specific horse
final horseHealthRemindersProvider = FutureProvider.autoDispose
    .family<List<HealthReminder>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/health-reminders', queryParams: {
      'horseId': horseId,
    });
    return ((response as List?) ?? [])
        .map((e) => HealthReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Upcoming health reminders (due within 30 days)
final upcomingHealthRemindersProvider =
    FutureProvider.autoDispose<List<HealthReminder>>((ref) async {
  final reminders = await ref.watch(healthRemindersProvider.future);
  return reminders.where((r) => r.daysUntilDue <= 30 && r.isActive).toList()
    ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));
});

/// Overdue health reminders
final overdueHealthRemindersProvider =
    FutureProvider.autoDispose<List<HealthReminder>>((ref) async {
  final reminders = await ref.watch(healthRemindersProvider.future);
  return reminders.where((r) => r.isOverdue && r.isActive).toList()
    ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));
});

// ============================================
// NOTIFICATION SETTINGS
// ============================================

/// User notification settings
final notificationSettingsProvider =
    FutureProvider.autoDispose<CalendarNotificationSettings>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/notification-settings');
    return CalendarNotificationSettings.fromJson(
        response as Map<String, dynamic>);
  } catch (e) {
    return const CalendarNotificationSettings();
  }
});

// ============================================
// EVENT CATEGORIES
// ============================================

/// Available event categories
final eventCategoriesProvider =
    FutureProvider.autoDispose<List<EventCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/calendar/categories');
    return ((response as List?) ?? [])
        .map((e) => EventCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return EventCategory.defaults;
  }
});

// ============================================
// CALENDAR EVENTS
// ============================================

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

  // ==================== CALENDAR EVENTS ====================

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

  /// Create recurring event
  Future<CalendarEvent?> createRecurringEvent({
    required Map<String, dynamic> eventData,
    required RecurrenceRule recurrence,
  }) async {
    state = const AsyncValue.loading();
    try {
      final data = {
        ...eventData,
        'recurrence': recurrence.toJson(),
      };
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

  /// Update event reminders
  Future<bool> updateEventReminders(
      String eventId, List<EventReminder> reminders) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/calendar/events/$eventId/reminders', {
        'reminders': reminders.map((r) => r.toJson()).toList(),
      });
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete event series (for recurring events)
  Future<bool> deleteEventSeries(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/calendar/events/$eventId/series');
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Respond to event invitation
  Future<bool> respondToInvitation(String eventId, String response) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/calendar/events/$eventId/respond', {
        'response': response, // 'accepted', 'declined', 'tentative'
      });
      _ref.invalidate(todayEventsProvider);
      _ref.invalidate(upcomingEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // ==================== HEALTH REMINDERS ====================

  /// Create health reminder
  Future<HealthReminder?> createHealthReminder(
      Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/calendar/health-reminders', data);
      _ref.invalidate(healthRemindersProvider);
      _ref.invalidate(upcomingHealthRemindersProvider);
      _ref.invalidate(overdueHealthRemindersProvider);
      state = const AsyncValue.data(null);
      return HealthReminder.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update health reminder
  Future<bool> updateHealthReminder(
      String reminderId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/calendar/health-reminders/$reminderId', data);
      _ref.invalidate(healthRemindersProvider);
      _ref.invalidate(upcomingHealthRemindersProvider);
      _ref.invalidate(overdueHealthRemindersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete health reminder
  Future<bool> deleteHealthReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/calendar/health-reminders/$reminderId');
      _ref.invalidate(healthRemindersProvider);
      _ref.invalidate(upcomingHealthRemindersProvider);
      _ref.invalidate(overdueHealthRemindersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mark health reminder as done
  Future<bool> markHealthReminderDone(String reminderId,
      {DateTime? doneAt}) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/calendar/health-reminders/$reminderId/done', {
        'doneAt': (doneAt ?? DateTime.now()).toIso8601String(),
      });
      _ref.invalidate(healthRemindersProvider);
      _ref.invalidate(upcomingHealthRemindersProvider);
      _ref.invalidate(overdueHealthRemindersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================

  /// Update notification settings
  Future<bool> updateNotificationSettings(
      CalendarNotificationSettings settings) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/calendar/notification-settings', settings.toJson());
      _ref.invalidate(notificationSettingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
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
