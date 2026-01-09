/// Performance tracking models for Horse Tempo
/// Includes competition results and training progress

import 'package:flutter/material.dart';

// ============================================
// COMPETITION RESULTS
// ============================================

/// Competition result for a horse
class CompetitionResult {
  final String id;
  final String horseId;
  final String horseName;
  final String? riderId;
  final String? riderName;
  final String competitionName;
  final String? venue;
  final DateTime date;
  final CompetitionType type;
  final CompetitionDiscipline discipline;
  final String? level; // e.g., "Amateur 1", "Pro 2", "CSI 3*"
  final int? rank;
  final int? totalParticipants;
  final double? score;
  final double? time; // in seconds for timed events
  final int? penalties; // faults/penalties
  final bool qualified; // qualified for next round
  final String? notes;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CompetitionResult({
    required this.id,
    required this.horseId,
    required this.horseName,
    this.riderId,
    this.riderName,
    required this.competitionName,
    this.venue,
    required this.date,
    required this.type,
    required this.discipline,
    this.level,
    this.rank,
    this.totalParticipants,
    this.score,
    this.time,
    this.penalties,
    this.qualified = false,
    this.notes,
    this.photoUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if this was a podium finish
  bool get isPodium => rank != null && rank! <= 3;

  /// Check if this was a victory
  bool get isVictory => rank == 1;

  /// Get the percentage score if applicable
  double? get percentageScore {
    if (discipline == CompetitionDiscipline.dressage && score != null) {
      return score;
    }
    return null;
  }

  /// Get formatted rank text
  String get rankText {
    if (rank == null) return '-';
    if (rank == 1) return '1er';
    if (rank == 2) return '2e';
    if (rank == 3) return '3e';
    return '${rank}e';
  }

  factory CompetitionResult.fromJson(Map<String, dynamic> json) {
    return CompetitionResult(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      competitionName: json['competitionName'] as String,
      venue: json['venue'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: CompetitionType.fromString(json['type'] as String),
      discipline: CompetitionDiscipline.fromString(json['discipline'] as String),
      level: json['level'] as String?,
      rank: json['rank'] as int?,
      totalParticipants: json['totalParticipants'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      time: (json['time'] as num?)?.toDouble(),
      penalties: json['penalties'] as int?,
      qualified: json['qualified'] as bool? ?? false,
      notes: json['notes'] as String?,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'riderId': riderId,
      'competitionName': competitionName,
      'venue': venue,
      'date': date.toIso8601String(),
      'type': type.name,
      'discipline': discipline.name,
      'level': level,
      'rank': rank,
      'totalParticipants': totalParticipants,
      'score': score,
      'time': time,
      'penalties': penalties,
      'qualified': qualified,
      'notes': notes,
      'photoUrls': photoUrls,
    };
  }
}

/// Types of competitions
enum CompetitionType {
  official,    // Official FFE/FEI competition
  club,        // Club-level competition
  training,    // Training show
  friendly,    // Friendly/amateur event
  championship, // Championship event
  qualifier,   // Qualifier for larger event
  other;

  String get displayName {
    switch (this) {
      case CompetitionType.official: return 'Officielle';
      case CompetitionType.club: return 'Club';
      case CompetitionType.training: return 'Entrainement';
      case CompetitionType.friendly: return 'Amicale';
      case CompetitionType.championship: return 'Championnat';
      case CompetitionType.qualifier: return 'Qualificative';
      case CompetitionType.other: return 'Autre';
    }
  }

  static CompetitionType fromString(String value) {
    return CompetitionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompetitionType.other,
    );
  }
}

/// Competition disciplines
enum CompetitionDiscipline {
  jumping,       // Saut d'obstacles (CSO)
  dressage,      // Dressage
  eventing,      // Concours complet (CCE)
  endurance,     // Endurance
  western,       // Western
  driving,       // Attelage
  vaulting,      // Voltige
  reining,       // Reining
  polo,          // Polo
  horseball,     // Horse-ball
  trec,          // TREC
  hunter,        // Hunter
  other;

  String get displayName {
    switch (this) {
      case CompetitionDiscipline.jumping: return 'Saut d\'obstacles';
      case CompetitionDiscipline.dressage: return 'Dressage';
      case CompetitionDiscipline.eventing: return 'Concours complet';
      case CompetitionDiscipline.endurance: return 'Endurance';
      case CompetitionDiscipline.western: return 'Western';
      case CompetitionDiscipline.driving: return 'Attelage';
      case CompetitionDiscipline.vaulting: return 'Voltige';
      case CompetitionDiscipline.reining: return 'Reining';
      case CompetitionDiscipline.polo: return 'Polo';
      case CompetitionDiscipline.horseball: return 'Horse-ball';
      case CompetitionDiscipline.trec: return 'TREC';
      case CompetitionDiscipline.hunter: return 'Hunter';
      case CompetitionDiscipline.other: return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case CompetitionDiscipline.jumping: return Icons.sports;
      case CompetitionDiscipline.dressage: return Icons.sports_score;
      case CompetitionDiscipline.eventing: return Icons.stars;
      case CompetitionDiscipline.endurance: return Icons.timer;
      case CompetitionDiscipline.western: return Icons.yard;
      case CompetitionDiscipline.driving: return Icons.directions_car;
      case CompetitionDiscipline.vaulting: return Icons.accessibility_new;
      case CompetitionDiscipline.reining: return Icons.rotate_right;
      case CompetitionDiscipline.polo: return Icons.sports_cricket;
      case CompetitionDiscipline.horseball: return Icons.sports_handball;
      case CompetitionDiscipline.trec: return Icons.map;
      case CompetitionDiscipline.hunter: return Icons.nature;
      case CompetitionDiscipline.other: return Icons.emoji_events;
    }
  }

  int get color {
    switch (this) {
      case CompetitionDiscipline.jumping: return 0xFF2196F3;
      case CompetitionDiscipline.dressage: return 0xFF9C27B0;
      case CompetitionDiscipline.eventing: return 0xFF4CAF50;
      case CompetitionDiscipline.endurance: return 0xFFFF9800;
      case CompetitionDiscipline.western: return 0xFF795548;
      case CompetitionDiscipline.driving: return 0xFF607D8B;
      case CompetitionDiscipline.vaulting: return 0xFFE91E63;
      case CompetitionDiscipline.reining: return 0xFF00BCD4;
      case CompetitionDiscipline.polo: return 0xFF3F51B5;
      case CompetitionDiscipline.horseball: return 0xFFFF5722;
      case CompetitionDiscipline.trec: return 0xFF8BC34A;
      case CompetitionDiscipline.hunter: return 0xFF009688;
      case CompetitionDiscipline.other: return 0xFF9E9E9E;
    }
  }

  static CompetitionDiscipline fromString(String value) {
    return CompetitionDiscipline.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompetitionDiscipline.other,
    );
  }
}

// ============================================
// TRAINING SESSIONS
// ============================================

/// Training session record
class TrainingSession {
  final String id;
  final String horseId;
  final String horseName;
  final String? riderId;
  final String? riderName;
  final String? trainerId;
  final String? trainerName;
  final DateTime date;
  final int durationMinutes;
  final TrainingType type;
  final TrainingIntensity intensity;
  final List<String> focusAreas;
  final int? qualityRating; // 1-5 stars
  final String? notes;
  final String? videoUrl;
  final List<String> photoUrls;
  final Map<String, dynamic>? metrics; // Custom metrics
  final DateTime createdAt;

  TrainingSession({
    required this.id,
    required this.horseId,
    required this.horseName,
    this.riderId,
    this.riderName,
    this.trainerId,
    this.trainerName,
    required this.date,
    required this.durationMinutes,
    required this.type,
    required this.intensity,
    this.focusAreas = const [],
    this.qualityRating,
    this.notes,
    this.videoUrl,
    this.photoUrls = const [],
    this.metrics,
    required this.createdAt,
  });

  /// Get duration as a formatted string
  String get durationText {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''}';
    }
    return '${minutes}min';
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      trainerId: json['trainerId'] as String?,
      trainerName: json['trainerName'] as String?,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      type: TrainingType.fromString(json['type'] as String),
      intensity: TrainingIntensity.fromString(json['intensity'] as String),
      focusAreas: (json['focusAreas'] as List?)?.cast<String>() ?? [],
      qualityRating: json['qualityRating'] as int?,
      notes: json['notes'] as String?,
      videoUrl: json['videoUrl'] as String?,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      metrics: json['metrics'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'riderId': riderId,
      'trainerId': trainerId,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'type': type.name,
      'intensity': intensity.name,
      'focusAreas': focusAreas,
      'qualityRating': qualityRating,
      'notes': notes,
      'videoUrl': videoUrl,
      'photoUrls': photoUrls,
      'metrics': metrics,
    };
  }
}

/// Types of training
enum TrainingType {
  flatwork,     // Travail sur le plat
  jumping,      // Saut
  dressage,     // Dressage
  hacking,      // Balade/exterieur
  lunging,      // Longe
  groundwork,   // Travail a pied
  liberty,      // Liberte
  poles,        // Barres au sol
  cavaletti,    // Cavaletti
  crossCountry, // Cross
  swimming,     // Nage
  walker,       // Marcheur
  paddock,      // Paddock
  other;

  String get displayName {
    switch (this) {
      case TrainingType.flatwork: return 'Travail sur le plat';
      case TrainingType.jumping: return 'Saut';
      case TrainingType.dressage: return 'Dressage';
      case TrainingType.hacking: return 'Balade';
      case TrainingType.lunging: return 'Longe';
      case TrainingType.groundwork: return 'Travail a pied';
      case TrainingType.liberty: return 'Liberte';
      case TrainingType.poles: return 'Barres au sol';
      case TrainingType.cavaletti: return 'Cavaletti';
      case TrainingType.crossCountry: return 'Cross';
      case TrainingType.swimming: return 'Natation';
      case TrainingType.walker: return 'Marcheur';
      case TrainingType.paddock: return 'Paddock';
      case TrainingType.other: return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case TrainingType.flatwork: return Icons.straighten;
      case TrainingType.jumping: return Icons.sports;
      case TrainingType.dressage: return Icons.sports_score;
      case TrainingType.hacking: return Icons.nature;
      case TrainingType.lunging: return Icons.rotate_right;
      case TrainingType.groundwork: return Icons.accessibility;
      case TrainingType.liberty: return Icons.waves;
      case TrainingType.poles: return Icons.view_column;
      case TrainingType.cavaletti: return Icons.view_stream;
      case TrainingType.crossCountry: return Icons.terrain;
      case TrainingType.swimming: return Icons.pool;
      case TrainingType.walker: return Icons.directions_walk;
      case TrainingType.paddock: return Icons.grass;
      case TrainingType.other: return Icons.fitness_center;
    }
  }

  static TrainingType fromString(String value) {
    return TrainingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrainingType.other,
    );
  }
}

/// Training intensity levels
enum TrainingIntensity {
  rest,       // Repos
  light,      // Leger
  moderate,   // Modere
  intense,    // Intense
  maximum;    // Maximum

  String get displayName {
    switch (this) {
      case TrainingIntensity.rest: return 'Repos';
      case TrainingIntensity.light: return 'Leger';
      case TrainingIntensity.moderate: return 'Modere';
      case TrainingIntensity.intense: return 'Intense';
      case TrainingIntensity.maximum: return 'Maximum';
    }
  }

  int get color {
    switch (this) {
      case TrainingIntensity.rest: return 0xFF9E9E9E;
      case TrainingIntensity.light: return 0xFF4CAF50;
      case TrainingIntensity.moderate: return 0xFF2196F3;
      case TrainingIntensity.intense: return 0xFFFF9800;
      case TrainingIntensity.maximum: return 0xFFF44336;
    }
  }

  static TrainingIntensity fromString(String value) {
    return TrainingIntensity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrainingIntensity.moderate,
    );
  }
}

// ============================================
// PERFORMANCE SUMMARY
// ============================================

/// Overall performance summary for a horse
class PerformanceSummary {
  final String horseId;
  final int totalCompetitions;
  final int victories;
  final int podiums;
  final int totalTrainingSessions;
  final int totalTrainingMinutes;
  final double? averageCompetitionScore;
  final Map<CompetitionDiscipline, int> competitionsByDiscipline;
  final Map<TrainingType, int> trainingsByType;
  final List<CompetitionResult> recentResults;
  final List<TrainingSession> recentTraining;
  final DateTime? lastCompetition;
  final DateTime? lastTraining;

  PerformanceSummary({
    required this.horseId,
    this.totalCompetitions = 0,
    this.victories = 0,
    this.podiums = 0,
    this.totalTrainingSessions = 0,
    this.totalTrainingMinutes = 0,
    this.averageCompetitionScore,
    this.competitionsByDiscipline = const {},
    this.trainingsByType = const {},
    this.recentResults = const [],
    this.recentTraining = const [],
    this.lastCompetition,
    this.lastTraining,
  });

  /// Get victory rate
  double get victoryRate {
    if (totalCompetitions == 0) return 0;
    return (victories / totalCompetitions) * 100;
  }

  /// Get podium rate
  double get podiumRate {
    if (totalCompetitions == 0) return 0;
    return (podiums / totalCompetitions) * 100;
  }

  /// Get average training duration in minutes
  double get averageTrainingDuration {
    if (totalTrainingSessions == 0) return 0;
    return totalTrainingMinutes / totalTrainingSessions;
  }

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      horseId: json['horseId'] as String,
      totalCompetitions: json['totalCompetitions'] as int? ?? 0,
      victories: json['victories'] as int? ?? 0,
      podiums: json['podiums'] as int? ?? 0,
      totalTrainingSessions: json['totalTrainingSessions'] as int? ?? 0,
      totalTrainingMinutes: json['totalTrainingMinutes'] as int? ?? 0,
      averageCompetitionScore: (json['averageCompetitionScore'] as num?)?.toDouble(),
      competitionsByDiscipline: (json['competitionsByDiscipline'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                    CompetitionDiscipline.fromString(k),
                    v as int,
                  )) ??
          {},
      trainingsByType: (json['trainingsByType'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(
                    TrainingType.fromString(k),
                    v as int,
                  )) ??
          {},
      recentResults: (json['recentResults'] as List?)
              ?.map((e) => CompetitionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentTraining: (json['recentTraining'] as List?)
              ?.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastCompetition: json['lastCompetition'] != null
          ? DateTime.parse(json['lastCompetition'] as String)
          : null,
      lastTraining: json['lastTraining'] != null
          ? DateTime.parse(json['lastTraining'] as String)
          : null,
    );
  }
}

// ============================================
// PEDIGREE DATA
// ============================================

/// Extended pedigree information for a horse
class PedigreeData {
  final String horseId;
  final String horseName;

  // Parents
  final PedigreeEntry? sire;
  final PedigreeEntry? dam;

  // Grandparents
  final PedigreeEntry? siresSire;
  final PedigreeEntry? siresDam;
  final PedigreeEntry? damsSire;
  final PedigreeEntry? damsDam;

  // Descendants
  final List<PedigreeEntry> offspring;

  PedigreeData({
    required this.horseId,
    required this.horseName,
    this.sire,
    this.dam,
    this.siresSire,
    this.siresDam,
    this.damsSire,
    this.damsDam,
    this.offspring = const [],
  });

  /// Check if any pedigree data is available
  bool get hasPedigree =>
      sire != null ||
      dam != null ||
      siresSire != null ||
      siresDam != null ||
      damsSire != null ||
      damsDam != null;

  factory PedigreeData.fromJson(Map<String, dynamic> json) {
    return PedigreeData(
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      sire: json['sire'] != null
          ? PedigreeEntry.fromJson(json['sire'] as Map<String, dynamic>)
          : null,
      dam: json['dam'] != null
          ? PedigreeEntry.fromJson(json['dam'] as Map<String, dynamic>)
          : null,
      siresSire: json['siresSire'] != null
          ? PedigreeEntry.fromJson(json['siresSire'] as Map<String, dynamic>)
          : null,
      siresDam: json['siresDam'] != null
          ? PedigreeEntry.fromJson(json['siresDam'] as Map<String, dynamic>)
          : null,
      damsSire: json['damsSire'] != null
          ? PedigreeEntry.fromJson(json['damsSire'] as Map<String, dynamic>)
          : null,
      damsDam: json['damsDam'] != null
          ? PedigreeEntry.fromJson(json['damsDam'] as Map<String, dynamic>)
          : null,
      offspring: (json['offspring'] as List?)
              ?.map((e) => PedigreeEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create from a Horse object
  factory PedigreeData.fromHorse(dynamic horse) {
    return PedigreeData(
      horseId: horse.id,
      horseName: horse.name,
      sire: horse.sireName != null
          ? PedigreeEntry(name: horse.sireName!)
          : null,
      dam: horse.damName != null
          ? PedigreeEntry(name: horse.damName!)
          : null,
      siresSire: horse.siresSireName != null
          ? PedigreeEntry(name: horse.siresSireName!)
          : null,
      siresDam: horse.siresDamName != null
          ? PedigreeEntry(name: horse.siresDamName!)
          : null,
      damsSire: horse.damsSireName != null
          ? PedigreeEntry(name: horse.damsSireName!)
          : null,
      damsDam: horse.damsDamName != null
          ? PedigreeEntry(name: horse.damsDamName!)
          : null,
    );
  }
}

/// Single entry in a pedigree
class PedigreeEntry {
  final String? id;
  final String name;
  final String? breed;
  final String? color;
  final int? birthYear;
  final String? photoUrl;
  final String? ueln;
  final bool isLinked; // true if this entry links to an actual horse in the system

  PedigreeEntry({
    this.id,
    required this.name,
    this.breed,
    this.color,
    this.birthYear,
    this.photoUrl,
    this.ueln,
    this.isLinked = false,
  });

  factory PedigreeEntry.fromJson(Map<String, dynamic> json) {
    return PedigreeEntry(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Inconnu',
      breed: json['breed'] as String?,
      color: json['color'] as String?,
      birthYear: json['birthYear'] as int?,
      photoUrl: json['photoUrl'] as String?,
      ueln: json['ueln'] as String?,
      isLinked: json['isLinked'] as bool? ?? false,
    );
  }
}
