import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

/// Helper to check if error is 404
bool _is404Error(Object error) {
  if (error is DioException) {
    return error.response?.statusCode == 404;
  }
  return false;
}

/// Current leaderboard period
final leaderboardPeriodProvider = StateProvider<LeaderboardPeriod>((ref) {
  return LeaderboardPeriod.weekly;
});

/// Current galop filter for rider leaderboard
final leaderboardGalopFilterProvider = StateProvider<int?>((ref) => null);

/// Current discipline filter for horse leaderboard
final leaderboardDisciplineFilterProvider = StateProvider<HorseDiscipline?>((ref) => null);

/// Current category filter for horse leaderboard
final leaderboardCategoryFilterProvider = StateProvider<HorseCategory?>((ref) => null);

/// Rider leaderboard
final riderLeaderboardProvider =
    FutureProvider.family<List<RiderLeaderboardEntry>, ({LeaderboardPeriod period, int? galopLevel})>(
        (ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final queryParams = <String, String>{
    'period': params.period.name,
  };
  if (params.galopLevel != null) {
    queryParams['galopLevel'] = params.galopLevel.toString();
  }
  try {
    final response = await api.get('/leaderboard/riders', queryParams: queryParams);
    return ((response as List?) ?? []).map((e) => RiderLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Horse leaderboard
final horseLeaderboardProvider =
    FutureProvider.family<List<HorseLeaderboardEntry>, ({
      LeaderboardPeriod period,
      HorseDiscipline? discipline,
      HorseCategory? category,
    })>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final queryParams = <String, String>{
    'period': params.period.name,
  };
  if (params.discipline != null) {
    queryParams['discipline'] = params.discipline!.name;
  }
  if (params.category != null) {
    queryParams['category'] = params.category!.name;
  }
  try {
    final response = await api.get('/leaderboard/horses', queryParams: queryParams);
    return ((response as List?) ?? []).map((e) => HorseLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Current user's rider ranking
final myRiderRankingProvider = FutureProvider<RiderLeaderboardEntry?>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/riders/me');
    return RiderLeaderboardEntry.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// Current user's horse rankings
final myHorseRankingsProvider = FutureProvider<List<HorseLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/horses/mine');
    return ((response as List?) ?? []).map((e) => HorseLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Top riders overall
final topRidersProvider = FutureProvider<List<RiderLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/riders/top');
    return ((response as List?) ?? []).map((e) => RiderLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Top horses overall
final topHorsesProvider = FutureProvider<List<HorseLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/horses/top');
    return ((response as List?) ?? []).map((e) => HorseLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Riders by galop level
final ridersByGalopProvider =
    FutureProvider.family<List<RiderLeaderboardEntry>, int>((ref, galopLevel) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/riders', queryParams: {
      'galopLevel': galopLevel.toString(),
    });
    return ((response as List?) ?? []).map((e) => RiderLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Horses by discipline
final horsesByDisciplineProvider =
    FutureProvider.family<List<HorseLeaderboardEntry>, HorseDiscipline>((ref, discipline) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/horses', queryParams: {
      'discipline': discipline.name,
    });
    return ((response as List?) ?? []).map((e) => HorseLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Rising riders (most improved)
final risingRidersProvider = FutureProvider<List<RiderLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/riders/rising');
    return ((response as List?) ?? []).map((e) => RiderLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Rising horses (most improved)
final risingHorsesProvider = FutureProvider<List<HorseLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/leaderboard/horses/rising');
    return ((response as List?) ?? []).map((e) => HorseLeaderboardEntry.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Leaderboard statistics
final leaderboardStatsProvider = FutureProvider<LeaderboardStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/leaderboard/stats');
  return LeaderboardStats.fromJson(response);
});

/// Leaderboard stats model
class LeaderboardStats {
  final int totalRiders;
  final int totalHorses;
  final int activeThisWeek;
  final int analysesThisWeek;
  final double averageScore;
  final Map<String, int> ridersByGalop;
  final Map<String, int> horsesByDiscipline;

  LeaderboardStats({
    required this.totalRiders,
    required this.totalHorses,
    required this.activeThisWeek,
    required this.analysesThisWeek,
    required this.averageScore,
    required this.ridersByGalop,
    required this.horsesByDiscipline,
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    return LeaderboardStats(
      totalRiders: json['totalRiders'] as int? ?? 0,
      totalHorses: json['totalHorses'] as int? ?? 0,
      activeThisWeek: json['activeThisWeek'] as int? ?? 0,
      analysesThisWeek: json['analysesThisWeek'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      ridersByGalop: (json['ridersByGalop'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      horsesByDiscipline: (json['horsesByDiscipline'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

/// Regional leaderboard (by location)
final regionalLeaderboardProvider =
    FutureProvider.family<RegionalLeaderboard, String>((ref, region) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/leaderboard/regional/$region');
  return RegionalLeaderboard.fromJson(response);
});

/// Regional leaderboard model
class RegionalLeaderboard {
  final String region;
  final List<RiderLeaderboardEntry> topRiders;
  final List<HorseLeaderboardEntry> topHorses;
  final int totalParticipants;

  RegionalLeaderboard({
    required this.region,
    required this.topRiders,
    required this.topHorses,
    required this.totalParticipants,
  });

  factory RegionalLeaderboard.fromJson(Map<String, dynamic> json) {
    return RegionalLeaderboard(
      region: json['region'] as String,
      topRiders: (json['topRiders'] as List?)
              ?.map((e) => RiderLeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      topHorses: (json['topHorses'] as List?)
              ?.map((e) => HorseLeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      totalParticipants: json['totalParticipants'] as int? ?? 0,
    );
  }
}

/// Club leaderboard
final clubLeaderboardProvider = FutureProvider<List<ClubLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/leaderboard/clubs');
  return (response as List).map((e) => ClubLeaderboardEntry.fromJson(e)).toList();
});

/// Club leaderboard entry model
class ClubLeaderboardEntry {
  final String id;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final int rank;
  final int previousRank;
  final int totalScore;
  final int memberCount;
  final int activeMembers;
  final int analysisCount;
  final double averageScore;

  ClubLeaderboardEntry({
    required this.id,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.rank,
    this.previousRank = 0,
    required this.totalScore,
    this.memberCount = 0,
    this.activeMembers = 0,
    this.analysisCount = 0,
    this.averageScore = 0,
  });

  int get rankChange => previousRank > 0 ? previousRank - rank : 0;

  factory ClubLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ClubLeaderboardEntry(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String,
      clubLogoUrl: json['clubLogoUrl'] as String?,
      rank: json['rank'] as int,
      previousRank: json['previousRank'] as int? ?? 0,
      totalScore: json['totalScore'] as int,
      memberCount: json['memberCount'] as int? ?? 0,
      activeMembers: json['activeMembers'] as int? ?? 0,
      analysisCount: json['analysisCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Leaderboard score calculator
class LeaderboardScoreCalculator {
  /// Calculate rider score based on activities
  static int calculateRiderScore({
    required int analysisCount,
    required double averageAnalysisScore,
    required int horseCount,
    required int streakDays,
    required int badgeCount,
    int? competitionWins,
  }) {
    int score = 0;

    // Base score from analyses
    score += analysisCount * 10;

    // Quality bonus
    score += (averageAnalysisScore * 5).round();

    // Horse management bonus
    score += horseCount * 20;

    // Consistency bonus
    score += streakDays * 5;

    // Achievement bonus
    score += badgeCount * 15;

    // Competition bonus
    if (competitionWins != null) {
      score += competitionWins * 50;
    }

    return score;
  }

  /// Calculate horse score based on analyses
  static int calculateHorseScore({
    required int analysisCount,
    required double averageScore,
    required double progressRate,
    int? competitionResults,
  }) {
    int score = 0;

    // Base score from analyses
    score += analysisCount * 15;

    // Quality score
    score += (averageScore * 8).round();

    // Progress bonus
    score += (progressRate * 20).round();

    // Competition bonus
    if (competitionResults != null) {
      score += competitionResults * 30;
    }

    return score;
  }

  /// Calculate rank change (positive = improved)
  static int calculateRankChange(int currentRank, int previousRank) {
    if (previousRank == 0) return 0;
    return previousRank - currentRank;
  }

  /// Get rank badge based on position
  static String getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  /// Get tier based on score
  static LeaderboardTier getTier(int score) {
    if (score >= 10000) return LeaderboardTier.legend;
    if (score >= 5000) return LeaderboardTier.master;
    if (score >= 2500) return LeaderboardTier.expert;
    if (score >= 1000) return LeaderboardTier.advanced;
    if (score >= 500) return LeaderboardTier.intermediate;
    return LeaderboardTier.beginner;
  }
}

/// Leaderboard tier
enum LeaderboardTier {
  beginner,
  intermediate,
  advanced,
  expert,
  master,
  legend;

  String get displayName {
    switch (this) {
      case LeaderboardTier.beginner:
        return 'Débutant';
      case LeaderboardTier.intermediate:
        return 'Intermédiaire';
      case LeaderboardTier.advanced:
        return 'Avancé';
      case LeaderboardTier.expert:
        return 'Expert';
      case LeaderboardTier.master:
        return 'Maître';
      case LeaderboardTier.legend:
        return 'Légende';
    }
  }

  int get colorValue {
    switch (this) {
      case LeaderboardTier.beginner:
        return 0xFF9E9E9E; // Grey
      case LeaderboardTier.intermediate:
        return 0xFF4CAF50; // Green
      case LeaderboardTier.advanced:
        return 0xFF2196F3; // Blue
      case LeaderboardTier.expert:
        return 0xFF9C27B0; // Purple
      case LeaderboardTier.master:
        return 0xFFFF9800; // Orange
      case LeaderboardTier.legend:
        return 0xFFFFD700; // Gold
    }
  }

  int get minScore {
    switch (this) {
      case LeaderboardTier.beginner:
        return 0;
      case LeaderboardTier.intermediate:
        return 500;
      case LeaderboardTier.advanced:
        return 1000;
      case LeaderboardTier.expert:
        return 2500;
      case LeaderboardTier.master:
        return 5000;
      case LeaderboardTier.legend:
        return 10000;
    }
  }
}

/// Leaderboard notifier for interactions
class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  // ignore: unused_field - Reserved for future use
  final Ref _ref;

  LeaderboardNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Challenge another rider
  Future<bool> challengeRider(String riderId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/leaderboard/challenge', {'riderId': riderId});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Share ranking
  Future<String?> shareRanking(String type, String id) async {
    try {
      final response = await _api.post('/leaderboard/share', {
        'type': type,
        'id': id,
      });
      return response['shareUrl'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Claim weekly reward
  Future<bool> claimWeeklyReward() async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/leaderboard/claim-reward', {});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final leaderboardNotifierProvider =
    StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return LeaderboardNotifier(api, ref);
});

/// Weekly rewards
final weeklyRewardsProvider = FutureProvider<WeeklyRewards>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/leaderboard/weekly-rewards');
  return WeeklyRewards.fromJson(response);
});

/// Weekly rewards model
class WeeklyRewards {
  final int rank;
  final int xpReward;
  final String? badgeId;
  final bool claimed;
  final DateTime weekEndDate;

  WeeklyRewards({
    required this.rank,
    required this.xpReward,
    this.badgeId,
    this.claimed = false,
    required this.weekEndDate,
  });

  factory WeeklyRewards.fromJson(Map<String, dynamic> json) {
    return WeeklyRewards(
      rank: json['rank'] as int,
      xpReward: json['xpReward'] as int,
      badgeId: json['badgeId'] as String?,
      claimed: json['claimed'] as bool? ?? false,
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
    );
  }
}
