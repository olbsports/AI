import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gamification.dart';
import '../services/api_service.dart';

// ============================================
// GAMIFICATION PROFILE PROVIDER
// ============================================

/// Complete gamification profile provider
final gamificationProfileProvider = FutureProvider.autoDispose<GamificationProfile>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/profile');
  return GamificationProfile.fromJson(response as Map<String, dynamic>);
});

// ============================================
// XP & LEVEL PROVIDERS
// ============================================

/// User level provider
final userLevelProvider = FutureProvider.autoDispose<UserLevel>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/level');
  return UserLevel.fromJson(response);
});

/// User XP transactions provider
final xpTransactionsProvider = FutureProvider.autoDispose<List<XpTransaction>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/xp/history');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => XpTransaction.fromJson(e as Map<String, dynamic>)).toList();
});

/// XP history with pagination
final xpHistoryProvider = FutureProvider.autoDispose.family<List<XpTransaction>, int>((ref, page) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/xp/history', queryParams: {
    'page': page,
    'pageSize': 20,
  });
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => XpTransaction.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================
// BADGE PROVIDERS
// ============================================

/// All badges provider
final allBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/badges');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Badge.fromJson(e as Map<String, dynamic>)).toList();
});

/// Earned badges provider
final earnedBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/badges/earned');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Badge.fromJson(e as Map<String, dynamic>)).toList();
});

/// Badges by category
final badgesByCategoryProvider =
    FutureProvider.autoDispose.family<List<Badge>, BadgeCategory>((ref, category) async {
  final allBadges = await ref.watch(allBadgesProvider.future);
  return allBadges.where((b) => b.category == category).toList();
});

/// Badges with progress (for badge grid showing locked/unlocked states)
final badgesWithProgressProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/badges/progress');
  if (response == null) {
    // Fallback to predefined badges with no progress
    return PredefinedBadges.all;
  }
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Badge.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================
// CHALLENGE PROVIDERS
// ============================================

/// Active challenges provider
final activeChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/challenges/active');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
});

/// Challenges by type
final challengesByTypeProvider =
    FutureProvider.autoDispose.family<List<Challenge>, ChallengeType>((ref, type) async {
  final challenges = await ref.watch(activeChallengesProvider.future);
  return challenges.where((c) => c.type == type).toList();
});

/// Daily challenges
final dailyChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  return ref.watch(challengesByTypeProvider(ChallengeType.daily).future);
});

/// Weekly challenges
final weeklyChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  return ref.watch(challengesByTypeProvider(ChallengeType.weekly).future);
});

/// Monthly challenges
final monthlyChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  return ref.watch(challengesByTypeProvider(ChallengeType.monthly).future);
});

/// Completed challenges history
final completedChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/challenges/completed');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================
// STREAK PROVIDER
// ============================================

/// User streak provider
final userStreakProvider = FutureProvider.autoDispose<UserStreak>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/streak');
  return UserStreak.fromJson(response);
});

// ============================================
// REWARD PROVIDERS
// ============================================

/// Available rewards provider
final availableRewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/rewards');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
});

/// Claimable rewards (completed but not yet claimed)
final claimableRewardsProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final challenges = await ref.watch(activeChallengesProvider.future);
  return challenges.where((c) => c.isCompleted && c.progress >= 1.0).toList();
});

// ============================================
// REFERRAL PROVIDERS
// ============================================

/// Referral stats provider
final referralStatsProvider = FutureProvider.autoDispose<ReferralStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/referrals/stats');
  return ReferralStats.fromJson(response);
});

/// List of referrals
final referralsListProvider = FutureProvider.autoDispose<List<Referral>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/referrals');
  if (response == null) return [];
  final list = response is List ? response : (response is Map ? (response['items'] as List? ?? []) : []);
  return list.map((e) => Referral.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================
// LEADERBOARD PROVIDERS
// ============================================

/// Leaderboard filter state
class LeaderboardFilter {
  final LeaderboardPeriod period;
  final LeaderboardScope scope;
  final String? discipline;
  final String? region;

  const LeaderboardFilter({
    this.period = LeaderboardPeriod.allTime,
    this.scope = LeaderboardScope.global,
    this.discipline,
    this.region,
  });

  LeaderboardFilter copyWith({
    LeaderboardPeriod? period,
    LeaderboardScope? scope,
    String? discipline,
    String? region,
  }) {
    return LeaderboardFilter(
      period: period ?? this.period,
      scope: scope ?? this.scope,
      discipline: discipline ?? this.discipline,
      region: region ?? this.region,
    );
  }
}

/// Leaderboard filter state provider
final leaderboardFilterProvider = StateProvider<LeaderboardFilter>((ref) {
  return const LeaderboardFilter();
});

/// Leaderboard provider with filters
final leaderboardProvider = FutureProvider.autoDispose<LeaderboardResponse>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final filter = ref.watch(leaderboardFilterProvider);

  final response = await api.get('/gamification/leaderboard', queryParams: {
    'period': filter.period.apiValue,
    'scope': filter.scope.name,
    if (filter.discipline != null) 'discipline': filter.discipline,
    if (filter.region != null) 'region': filter.region,
  });

  if (response is List) {
    return LeaderboardResponse(
      entries: response.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  return LeaderboardResponse.fromJson(response as Map<String, dynamic>);
});

/// XP leaderboard provider (simple list)
final xpLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/leaderboard');
  if (response is List) {
    return response.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
  if (response is Map<String, dynamic>) {
    final list = response['entries'] as List? ?? response['items'] as List? ?? [];
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});

// ============================================
// GAMIFICATION NOTIFIER (ACTIONS)
// ============================================

/// Gamification notifier for actions
class GamificationNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  GamificationNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Claim daily login XP
  Future<XpTransaction?> claimDailyLogin() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gamification/daily-login', {});
      final transaction = XpTransaction.fromJson(response);
      _ref.invalidate(userLevelProvider);
      _ref.invalidate(userStreakProvider);
      _ref.invalidate(gamificationProfileProvider);
      state = const AsyncValue.data(null);
      return transaction;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Complete a challenge
  Future<bool> completeChallenge(String challengeId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gamification/challenges/$challengeId/complete', {});
      _ref.invalidate(activeChallengesProvider);
      _ref.invalidate(userLevelProvider);
      _ref.invalidate(gamificationProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Claim challenge reward
  Future<ClaimRewardResponse?> claimChallengeReward(String challengeId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/gamification/challenges/$challengeId/claim', {});
      final claimResponse = ClaimRewardResponse.fromJson(response);
      _ref.invalidate(activeChallengesProvider);
      _ref.invalidate(userLevelProvider);
      _ref.invalidate(earnedBadgesProvider);
      _ref.invalidate(gamificationProfileProvider);
      state = const AsyncValue.data(null);
      return claimResponse;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Claim a reward
  Future<bool> claimReward(String rewardId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gamification/rewards/$rewardId/claim', {});
      _ref.invalidate(availableRewardsProvider);
      _ref.invalidate(userLevelProvider);
      _ref.invalidate(gamificationProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Send referral invite via email
  Future<bool> sendReferralInvite(String email) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gamification/referrals/invite', {'email': email});
      _ref.invalidate(referralStatsProvider);
      _ref.invalidate(referralsListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Get referral code
  Future<String?> getReferralCode() async {
    try {
      final response = await _api.get('/gamification/referrals/code');
      return response['code'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Share referral code via system share
  Future<void> shareReferralCode(String code, String referralLink) async {
    final message = '''
Rejoignez-moi sur Horse Tempo !

Utilisez mon code de parrainage: $code

Ou cliquez sur ce lien: $referralLink

Vous recevrez 200 XP + 20 tokens a l'inscription !
''';

    await Share.share(message, subject: 'Invitation Horse Tempo');
  }

  /// Copy referral code to clipboard
  Future<void> copyReferralCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
  }

  /// Refresh all gamification data
  Future<void> refreshAll() async {
    _ref.invalidate(gamificationProfileProvider);
    _ref.invalidate(userLevelProvider);
    _ref.invalidate(userStreakProvider);
    _ref.invalidate(allBadgesProvider);
    _ref.invalidate(earnedBadgesProvider);
    _ref.invalidate(activeChallengesProvider);
    _ref.invalidate(referralStatsProvider);
    _ref.invalidate(leaderboardProvider);
  }
}

final gamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return GamificationNotifier(api, ref);
});

// ============================================
// UTILITY PROVIDERS
// ============================================

/// Total badges count (earned / available)
final badgeCountsProvider = Provider.autoDispose<(int, int)>((ref) {
  final allBadges = ref.watch(allBadgesProvider);
  final earnedBadges = ref.watch(earnedBadgesProvider);

  final total = allBadges.whenOrNull(data: (data) => data.length) ?? PredefinedBadges.all.length;
  final earned = earnedBadges.whenOrNull(data: (data) => data.length) ?? 0;

  return (earned, total);
});

/// Check if user has completed daily login today
final hasCompletedDailyLoginProvider = Provider.autoDispose<bool>((ref) {
  final streak = ref.watch(userStreakProvider);
  return streak.whenOrNull(data: (data) => data.isActiveToday) ?? false;
});

/// Streak in danger (not logged in for 20+ hours)
final streakInDangerProvider = Provider.autoDispose<bool>((ref) {
  final streak = ref.watch(userStreakProvider);
  return streak.whenOrNull(data: (data) {
    if (data.isActiveToday) return false;
    if (data.lastActivityDate == null) return false;
    final hoursSinceLastActivity = DateTime.now().difference(data.lastActivityDate!).inHours;
    return hoursSinceLastActivity >= 20 && data.currentStreak > 0;
  }) ?? false;
});
