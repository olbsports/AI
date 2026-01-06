import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/admin_api_service.dart';

// ==================== Dashboard ====================

/// Dashboard statistics
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/dashboard/stats');
  return DashboardStats.fromJson(response);
});

/// Real-time metrics
final realtimeMetricsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  // Would connect to WebSocket for real-time updates
  yield {};
});

// ==================== Users ====================

/// User search/filter state
class UserFilters {
  final String? search;
  final UserStatus? status;
  final String? plan;
  final String? sortBy;
  final bool sortDesc;
  final int page;
  final int limit;

  UserFilters({
    this.search,
    this.status,
    this.plan,
    this.sortBy,
    this.sortDesc = true,
    this.page = 1,
    this.limit = 25,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (status != null) params['status'] = status!.name;
    if (plan != null) params['plan'] = plan!;
    if (sortBy != null) {
      params['sortBy'] = sortBy!;
      params['sortDir'] = sortDesc ? 'desc' : 'asc';
    }
    return params;
  }

  UserFilters copyWith({
    String? search,
    UserStatus? status,
    String? plan,
    String? sortBy,
    bool? sortDesc,
    int? page,
    int? limit,
  }) {
    return UserFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      sortBy: sortBy ?? this.sortBy,
      sortDesc: sortDesc ?? this.sortDesc,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final userFiltersProvider = StateProvider<UserFilters>((ref) => UserFilters());

/// Users list (paginated)
final usersProvider = FutureProvider<UserListResponse>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final filters = ref.watch(userFiltersProvider);
  final response = await api.get('/users', queryParams: filters.toQueryParams());
  return UserListResponse.fromJson(response);
});

/// User list response
class UserListResponse {
  final List<AppUser> users;
  final int total;
  final int page;
  final int totalPages;

  UserListResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      users: (json['users'] as List).map((e) => AppUser.fromJson(e)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Single user detail
final userDetailProvider =
    FutureProvider.family<AppUser, String>((ref, userId) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/users/$userId');
  return AppUser.fromJson(response);
});

/// User activity log
final userActivityProvider =
    FutureProvider.family<List<AuditLog>, String>((ref, userId) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/users/$userId/activity');
  return (response as List).map((e) => AuditLog.fromJson(e)).toList();
});

// ==================== Subscriptions ====================

/// Subscription filters
class SubscriptionFilters {
  final SubscriptionStatus? status;
  final String? planId;
  final String? sortBy;
  final int page;
  final int limit;

  SubscriptionFilters({
    this.status,
    this.planId,
    this.sortBy,
    this.page = 1,
    this.limit = 25,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status!.name;
    if (planId != null) params['planId'] = planId!;
    if (sortBy != null) params['sortBy'] = sortBy!;
    return params;
  }
}

final subscriptionFiltersProvider = StateProvider<SubscriptionFilters>(
  (ref) => SubscriptionFilters(),
);

/// Subscriptions list
final subscriptionsProvider = FutureProvider<SubscriptionListResponse>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final filters = ref.watch(subscriptionFiltersProvider);
  final response = await api.get('/subscriptions', queryParams: filters.toQueryParams());
  return SubscriptionListResponse.fromJson(response);
});

class SubscriptionListResponse {
  final List<Subscription> subscriptions;
  final int total;
  final int page;
  final int totalPages;

  SubscriptionListResponse({
    required this.subscriptions,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory SubscriptionListResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionListResponse(
      subscriptions: (json['subscriptions'] as List)
          .map((e) => Subscription.fromJson(e))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Subscription plans
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/subscriptions/plans');
  return (response as List).map((e) => SubscriptionPlan.fromJson(e)).toList();
});

/// Revenue statistics
final revenueStatsProvider = FutureProvider<RevenueStats>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/subscriptions/revenue');
  return RevenueStats.fromJson(response);
});

class RevenueStats {
  final double mrr;
  final double arr;
  final double mrrGrowth;
  final double ltv;
  final double churnRate;
  final int trialConversions;
  final List<TimeSeriesData> revenueHistory;
  final Map<String, double> revenueByPlan;

  RevenueStats({
    required this.mrr,
    required this.arr,
    required this.mrrGrowth,
    required this.ltv,
    required this.churnRate,
    required this.trialConversions,
    required this.revenueHistory,
    required this.revenueByPlan,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      mrr: (json['mrr'] as num).toDouble(),
      arr: (json['arr'] as num).toDouble(),
      mrrGrowth: (json['mrrGrowth'] as num).toDouble(),
      ltv: (json['ltv'] as num).toDouble(),
      churnRate: (json['churnRate'] as num).toDouble(),
      trialConversions: json['trialConversions'] as int,
      revenueHistory: (json['revenueHistory'] as List?)
              ?.map((e) => TimeSeriesData.fromJson(e))
              .toList() ??
          [],
      revenueByPlan: (json['revenueByPlan'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
    );
  }
}

// ==================== Moderation ====================

/// Content reports
final contentReportsProvider = FutureProvider<List<ContentReport>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/moderation/reports');
  return (response as List).map((e) => ContentReport.fromJson(e)).toList();
});

/// Pending reports count
final pendingReportsCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/moderation/reports/pending-count');
  return response['count'] as int;
});

/// Report detail
final reportDetailProvider =
    FutureProvider.family<ContentReport, String>((ref, reportId) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/moderation/reports/$reportId');
  return ContentReport.fromJson(response);
});

// ==================== Support ====================

/// Support tickets
final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/support/tickets');
  return (response as List).map((e) => SupportTicket.fromJson(e)).toList();
});

/// Open tickets count
final openTicketsCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/support/tickets/open-count');
  return response['count'] as int;
});

/// Ticket detail
final ticketDetailProvider =
    FutureProvider.family<SupportTicket, String>((ref, ticketId) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/support/tickets/$ticketId');
  return SupportTicket.fromJson(response);
});

// ==================== Analytics ====================

/// Analytics data
final analyticsProvider =
    FutureProvider.family<AnalyticsData, ({String metric, String period})>(
        (ref, params) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/analytics/${params.metric}', queryParams: {
    'period': params.period,
  });
  return AnalyticsData.fromJson(response);
});

class AnalyticsData {
  final String metric;
  final double currentValue;
  final double previousValue;
  final double changePercent;
  final List<TimeSeriesData> history;
  final Map<String, dynamic>? breakdown;

  AnalyticsData({
    required this.metric,
    required this.currentValue,
    required this.previousValue,
    required this.changePercent,
    required this.history,
    this.breakdown,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      metric: json['metric'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
      previousValue: (json['previousValue'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      history: (json['history'] as List?)
              ?.map((e) => TimeSeriesData.fromJson(e))
              .toList() ??
          [],
      breakdown: json['breakdown'] as Map<String, dynamic>?,
    );
  }
}

/// User retention cohort
final retentionCohortProvider = FutureProvider<List<RetentionCohort>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/analytics/retention');
  return (response as List).map((e) => RetentionCohort.fromJson(e)).toList();
});

class RetentionCohort {
  final String cohortMonth;
  final int totalUsers;
  final List<double> retentionRates;

  RetentionCohort({
    required this.cohortMonth,
    required this.totalUsers,
    required this.retentionRates,
  });

  factory RetentionCohort.fromJson(Map<String, dynamic> json) {
    return RetentionCohort(
      cohortMonth: json['cohortMonth'] as String,
      totalUsers: json['totalUsers'] as int,
      retentionRates: (json['retentionRates'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

// ==================== Settings ====================

/// System settings
final systemSettingsProvider = FutureProvider<SystemSettings>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/settings');
  return SystemSettings.fromJson(response);
});

/// Audit logs
final auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  final response = await api.get('/audit-logs');
  return (response as List).map((e) => AuditLog.fromJson(e)).toList();
});

// ==================== Admin Actions Notifier ====================

class AdminActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminApiService _api;
  final Ref _ref;

  AdminActionsNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  // User actions
  Future<bool> updateUserStatus(String userId, UserStatus status, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/users/$userId/status', {
        'status': status.name,
        'reason': reason,
      });
      _ref.invalidate(usersProvider);
      _ref.invalidate(userDetailProvider(userId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> banUser(String userId, String reason) async {
    return updateUserStatus(userId, UserStatus.banned, reason: reason);
  }

  Future<bool> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/users/$userId');
      _ref.invalidate(usersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> impersonateUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/users/$userId/impersonate', {});
      state = const AsyncValue.data(null);
      return response['token'] != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Subscription actions
  Future<bool> cancelSubscription(String subscriptionId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/subscriptions/$subscriptionId/cancel', {'reason': reason});
      _ref.invalidate(subscriptionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> refundSubscription(String subscriptionId, double amount, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/subscriptions/$subscriptionId/refund', {
        'amount': amount,
        'reason': reason,
      });
      _ref.invalidate(subscriptionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> extendSubscription(String subscriptionId, int days) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/subscriptions/$subscriptionId/extend', {'days': days});
      _ref.invalidate(subscriptionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Plan actions
  Future<bool> updatePlan(String planId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/subscriptions/plans/$planId', data);
      _ref.invalidate(subscriptionPlansProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Moderation actions
  Future<bool> resolveReport(String reportId, String action, String? notes) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/moderation/reports/$reportId/resolve', {
        'action': action,
        'notes': notes,
      });
      _ref.invalidate(contentReportsProvider);
      _ref.invalidate(pendingReportsCountProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteContent(String contentType, String contentId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/moderation/content/$contentType/$contentId');
      _ref.invalidate(contentReportsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Support actions
  Future<bool> assignTicket(String ticketId, String assigneeId) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/support/tickets/$ticketId/assign', {'assigneeId': assigneeId});
      _ref.invalidate(supportTicketsProvider);
      _ref.invalidate(ticketDetailProvider(ticketId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> replyToTicket(String ticketId, String message) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/support/tickets/$ticketId/reply', {'message': message});
      _ref.invalidate(ticketDetailProvider(ticketId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> closeTicket(String ticketId) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/support/tickets/$ticketId/close', {});
      _ref.invalidate(supportTicketsProvider);
      _ref.invalidate(ticketDetailProvider(ticketId));
      _ref.invalidate(openTicketsCountProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Settings actions
  Future<bool> updateSettings(SystemSettings settings) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/settings', settings.toJson());
      _ref.invalidate(systemSettingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleMaintenanceMode(bool enabled, String? message) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/settings/maintenance', {
        'enabled': enabled,
        'message': message,
      });
      _ref.invalidate(systemSettingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleFeatureFlag(String feature, bool enabled) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/settings/features/$feature', {'enabled': enabled});
      _ref.invalidate(systemSettingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Export data
  Future<String?> exportData(String type, Map<String, dynamic> filters) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/export/$type', filters);
      state = const AsyncValue.data(null);
      return response['downloadUrl'] as String?;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final adminActionsProvider =
    StateNotifierProvider<AdminActionsNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(adminApiServiceProvider);
  return AdminActionsNotifier(api, ref);
});
