/// Leaderboard entry for riders
class RiderLeaderboardEntry {
  final String id;
  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final int galopLevel; // 1-7 in France
  final int rank;
  final int previousRank;
  final int score;
  final int analysisCount;
  final int horseCount;
  final int streakDays; // Consecutive active days
  final double progressRate; // Improvement percentage
  final List<String> badges;
  final DateTime lastActivityAt;

  RiderLeaderboardEntry({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderPhotoUrl,
    required this.galopLevel,
    required this.rank,
    this.previousRank = 0,
    required this.score,
    this.analysisCount = 0,
    this.horseCount = 0,
    this.streakDays = 0,
    this.progressRate = 0,
    this.badges = const [],
    required this.lastActivityAt,
  });

  int get rankChange => previousRank > 0 ? previousRank - rank : 0;
  bool get isRankUp => rankChange > 0;
  bool get isRankDown => rankChange < 0;

  factory RiderLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return RiderLeaderboardEntry(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderPhotoUrl: json['riderPhotoUrl'] as String?,
      galopLevel: json['galopLevel'] as int? ?? 1,
      rank: json['rank'] as int,
      previousRank: json['previousRank'] as int? ?? 0,
      score: json['score'] as int,
      analysisCount: json['analysisCount'] as int? ?? 0,
      horseCount: json['horseCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      progressRate: (json['progressRate'] as num?)?.toDouble() ?? 0,
      badges: (json['badges'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      lastActivityAt: DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Leaderboard entry for horses
class HorseLeaderboardEntry {
  final String id;
  final String horseId;
  final String horseName;
  final String? horsePhotoUrl;
  final String? breed;
  final HorseCategory category;
  final HorseDiscipline discipline;
  final int rank;
  final int previousRank;
  final int score;
  final int analysisCount;
  final double averageScore; // Average analysis score
  final double progressRate;
  final List<String> achievements;
  final DateTime lastAnalysisAt;

  HorseLeaderboardEntry({
    required this.id,
    required this.horseId,
    required this.horseName,
    this.horsePhotoUrl,
    this.breed,
    required this.category,
    required this.discipline,
    required this.rank,
    this.previousRank = 0,
    required this.score,
    this.analysisCount = 0,
    this.averageScore = 0,
    this.progressRate = 0,
    this.achievements = const [],
    required this.lastAnalysisAt,
  });

  int get rankChange => previousRank > 0 ? previousRank - rank : 0;

  factory HorseLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return HorseLeaderboardEntry(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String,
      horsePhotoUrl: json['horsePhotoUrl'] as String?,
      breed: json['breed'] as String?,
      category: HorseCategory.fromString(json['category'] as String? ?? 'club'),
      discipline: HorseDiscipline.fromString(json['discipline'] as String? ?? 'other'),
      rank: json['rank'] as int,
      previousRank: json['previousRank'] as int? ?? 0,
      score: json['score'] as int,
      analysisCount: json['analysisCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      progressRate: (json['progressRate'] as num?)?.toDouble() ?? 0,
      achievements: (json['achievements'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      lastAnalysisAt: DateTime.tryParse(json['lastAnalysisAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Horse category by level
enum HorseCategory {
  poulain, // Foal (0-3 years)
  jeune,   // Young (3-6 years)
  club,    // Club level
  amateur, // Amateur level
  pro;     // Professional level

  String get displayName {
    switch (this) {
      case HorseCategory.poulain:
        return 'Poulain';
      case HorseCategory.jeune:
        return 'Jeune cheval';
      case HorseCategory.club:
        return 'Club';
      case HorseCategory.amateur:
        return 'Amateur';
      case HorseCategory.pro:
        return 'Pro';
    }
  }

  static HorseCategory fromString(String value) {
    return HorseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HorseCategory.club,
    );
  }
}

/// Horse discipline
enum HorseDiscipline {
  dressage,
  cso,        // Show jumping
  cce,        // Eventing
  endurance,
  western,
  attelage,   // Driving
  voltige,    // Vaulting
  polo,
  course,     // Racing
  hobbyHorse, // Hobby Horse
  hunter,     // Hunter
  reining,
  trec,       // TREC
  ponyGames,  // Pony Games
  horseBall,  // Horse Ball
  other;

  String get displayName {
    switch (this) {
      case HorseDiscipline.dressage:
        return 'Dressage';
      case HorseDiscipline.cso:
        return 'CSO (Saut d\'obstacles)';
      case HorseDiscipline.cce:
        return 'CCE (Complet)';
      case HorseDiscipline.endurance:
        return 'Endurance';
      case HorseDiscipline.western:
        return 'Western';
      case HorseDiscipline.attelage:
        return 'Attelage';
      case HorseDiscipline.voltige:
        return 'Voltige';
      case HorseDiscipline.polo:
        return 'Polo';
      case HorseDiscipline.course:
        return 'Course';
      case HorseDiscipline.hobbyHorse:
        return 'Hobby Horse';
      case HorseDiscipline.hunter:
        return 'Hunter';
      case HorseDiscipline.reining:
        return 'Reining';
      case HorseDiscipline.trec:
        return 'TREC';
      case HorseDiscipline.ponyGames:
        return 'Pony Games';
      case HorseDiscipline.horseBall:
        return 'Horse Ball';
      case HorseDiscipline.other:
        return 'Autre';
    }
  }

  static HorseDiscipline fromString(String value) {
    return HorseDiscipline.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HorseDiscipline.other,
    );
  }
}

/// Leaderboard time period
enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime;

  String get displayName {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'Cette semaine';
      case LeaderboardPeriod.monthly:
        return 'Ce mois';
      case LeaderboardPeriod.allTime:
        return 'Tous les temps';
    }
  }
}
