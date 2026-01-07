import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../services/api_service.dart';

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
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => XpTransaction.fromJson(e as Map<String, dynamic>)).toList();
});

/// All badges provider
final allBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/badges');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Badge.fromJson(e as Map<String, dynamic>)).toList();
});

/// Earned badges provider
final earnedBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/badges/earned');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Badge.fromJson(e as Map<String, dynamic>)).toList();
});

/// Active challenges provider
final activeChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/challenges/active');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
});

/// User streak provider
final userStreakProvider = FutureProvider.autoDispose<UserStreak>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/streak');
  return UserStreak.fromJson(response);
});

/// Available rewards provider
final availableRewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/rewards');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
});

/// Referral stats provider
final referralStatsProvider = FutureProvider.autoDispose<ReferralStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/referrals/stats');
  return ReferralStats.fromJson(response);
});

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
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Claim a reward
  Future<bool> claimReward(String rewardId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gamification/rewards/$rewardId/claim', {});
      _ref.invalidate(availableRewardsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Send referral invite
  Future<bool> sendReferralInvite(String email) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/gamification/referrals/invite', {'email': email});
      _ref.invalidate(referralStatsProvider);
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
}

final gamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return GamificationNotifier(api, ref);
});

/// Badges by category
final badgesByCategoryProvider =
    FutureProvider.autoDispose.family<List<Badge>, BadgeCategory>((ref, category) async {
  final allBadges = await ref.watch(allBadgesProvider.future);
  return allBadges.where((b) => b.category == category).toList();
});

/// Challenges by type
final challengesByTypeProvider =
    FutureProvider.autoDispose.family<List<Challenge>, ChallengeType>((ref, type) async {
  final challenges = await ref.watch(activeChallengesProvider.future);
  return challenges.where((c) => c.type == type).toList();
});

/// Leaderboard provider
final xpLeaderboardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/gamification/leaderboard');
  return (response as List).cast<Map<String, dynamic>>();
});
