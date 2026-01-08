/// Plan nutritionnel généré par IA
class NutritionPlan {
  final String id;
  final String horseId;
  final String horseName;
  final DateTime generatedAt;
  final NutritionProfile profile;
  final DailyRation dailyRation;
  final List<NutritionRecommendation> recommendations;
  final Map<String, dynamic>? aiAnalysis;

  NutritionPlan({
    required this.id,
    required this.horseId,
    required this.horseName,
    required this.generatedAt,
    required this.profile,
    required this.dailyRation,
    this.recommendations = const [],
    this.aiAnalysis,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? 'Cheval',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      profile: NutritionProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
      dailyRation: DailyRation.fromJson(json['dailyRation'] as Map<String, dynamic>? ?? {}),
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => NutritionRecommendation.fromJson(e))
              .toList() ??
          [],
      aiAnalysis: json['aiAnalysis'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horseId': horseId,
      'horseName': horseName,
      'generatedAt': generatedAt.toIso8601String(),
      'profile': profile.toJson(),
      'dailyRation': dailyRation.toJson(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'aiAnalysis': aiAnalysis,
    };
  }
}

/// Profil nutritionnel du cheval
class NutritionProfile {
  final double weightKg;
  final int ageYears;
  final ActivityLevel activityLevel;
  final PhysiologicalState physiologicalState;
  final double? bodyConditionScore; // 1-9 scale
  final List<String> healthConditions;
  final String? specialNeeds;

  NutritionProfile({
    this.weightKg = 500,
    this.ageYears = 10,
    this.activityLevel = ActivityLevel.moderate,
    this.physiologicalState = PhysiologicalState.maintenance,
    this.bodyConditionScore,
    this.healthConditions = const [],
    this.specialNeeds,
  });

  factory NutritionProfile.fromJson(Map<String, dynamic> json) {
    return NutritionProfile(
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 500,
      ageYears: (json['ageYears'] as num?)?.toInt() ?? 10,
      activityLevel: _parseActivityLevel(json['activityLevel']),
      physiologicalState: _parsePhysiologicalState(json['physiologicalState']),
      bodyConditionScore: (json['bodyConditionScore'] as num?)?.toDouble(),
      healthConditions: (json['healthConditions'] as List?)?.cast<String>() ?? [],
      specialNeeds: json['specialNeeds'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'ageYears': ageYears,
      'activityLevel': activityLevel.name,
      'physiologicalState': physiologicalState.name,
      'bodyConditionScore': bodyConditionScore,
      'healthConditions': healthConditions,
      'specialNeeds': specialNeeds,
    };
  }

  static ActivityLevel _parseActivityLevel(dynamic value) {
    if (value == null) return ActivityLevel.moderate;
    if (value is ActivityLevel) return value;
    if (value is String) {
      return ActivityLevel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ActivityLevel.moderate,
      );
    }
    return ActivityLevel.moderate;
  }

  static PhysiologicalState _parsePhysiologicalState(dynamic value) {
    if (value == null) return PhysiologicalState.maintenance;
    if (value is PhysiologicalState) return value;
    if (value is String) {
      return PhysiologicalState.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PhysiologicalState.maintenance,
      );
    }
    return PhysiologicalState.maintenance;
  }
}

enum ActivityLevel {
  rest,      // Repos/Convalescence
  light,     // Travail léger
  moderate,  // Travail modéré
  intense,   // Travail intense
  competition, // Compétition
}

extension ActivityLevelExtension on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.rest:
        return 'Repos';
      case ActivityLevel.light:
        return 'Travail léger';
      case ActivityLevel.moderate:
        return 'Travail modéré';
      case ActivityLevel.intense:
        return 'Travail intense';
      case ActivityLevel.competition:
        return 'Compétition';
    }
  }

  double get energyMultiplier {
    switch (this) {
      case ActivityLevel.rest:
        return 1.0;
      case ActivityLevel.light:
        return 1.25;
      case ActivityLevel.moderate:
        return 1.5;
      case ActivityLevel.intense:
        return 1.75;
      case ActivityLevel.competition:
        return 2.0;
    }
  }
}

enum PhysiologicalState {
  maintenance,  // Entretien
  growth,       // Croissance (poulain)
  gestation,    // Gestation
  lactation,    // Lactation
  senior,       // Senior (>15 ans)
  recovery,     // Convalescence
}

extension PhysiologicalStateExtension on PhysiologicalState {
  String get displayName {
    switch (this) {
      case PhysiologicalState.maintenance:
        return 'Entretien';
      case PhysiologicalState.growth:
        return 'Croissance';
      case PhysiologicalState.gestation:
        return 'Gestation';
      case PhysiologicalState.lactation:
        return 'Lactation';
      case PhysiologicalState.senior:
        return 'Senior';
      case PhysiologicalState.recovery:
        return 'Convalescence';
    }
  }
}

/// Ration quotidienne calculée
class DailyRation {
  final double forageTotalKg;
  final double concentrateTotalKg;
  final List<FeedItem> forageItems;
  final List<FeedItem> concentrateItems;
  final List<FeedItem> supplements;
  final double waterLiters;
  final NutrientTotals nutrients;

  DailyRation({
    this.forageTotalKg = 0,
    this.concentrateTotalKg = 0,
    this.forageItems = const [],
    this.concentrateItems = const [],
    this.supplements = const [],
    this.waterLiters = 0,
    NutrientTotals? nutrients,
  }) : nutrients = nutrients ?? NutrientTotals();

  factory DailyRation.fromJson(Map<String, dynamic> json) {
    return DailyRation(
      forageTotalKg: (json['forageTotalKg'] as num?)?.toDouble() ?? 0,
      concentrateTotalKg: (json['concentrateTotalKg'] as num?)?.toDouble() ?? 0,
      forageItems: (json['forageItems'] as List?)
              ?.map((e) => FeedItem.fromJson(e))
              .toList() ??
          [],
      concentrateItems: (json['concentrateItems'] as List?)
              ?.map((e) => FeedItem.fromJson(e))
              .toList() ??
          [],
      supplements: (json['supplements'] as List?)
              ?.map((e) => FeedItem.fromJson(e))
              .toList() ??
          [],
      waterLiters: (json['waterLiters'] as num?)?.toDouble() ?? 0,
      nutrients: json['nutrients'] != null
          ? NutrientTotals.fromJson(json['nutrients'])
          : NutrientTotals(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forageTotalKg': forageTotalKg,
      'concentrateTotalKg': concentrateTotalKg,
      'forageItems': forageItems.map((e) => e.toJson()).toList(),
      'concentrateItems': concentrateItems.map((e) => e.toJson()).toList(),
      'supplements': supplements.map((e) => e.toJson()).toList(),
      'waterLiters': waterLiters,
      'nutrients': nutrients.toJson(),
    };
  }
}

/// Élément alimentaire
class FeedItem {
  final String name;
  final double quantityKg;
  final String? frequency; // "matin", "soir", "3x/jour"
  final String? notes;

  FeedItem({
    required this.name,
    required this.quantityKg,
    this.frequency,
    this.notes,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      name: json['name'] as String? ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0,
      frequency: json['frequency'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantityKg': quantityKg,
      'frequency': frequency,
      'notes': notes,
    };
  }
}

/// Totaux nutritionnels
class NutrientTotals {
  final double energyMcal;    // Énergie digestible
  final double proteinCPg;    // Protéines brutes
  final double calciumG;
  final double phosphorusG;
  final double fiberNDFg;     // Fibres

  NutrientTotals({
    this.energyMcal = 0,
    this.proteinCPg = 0,
    this.calciumG = 0,
    this.phosphorusG = 0,
    this.fiberNDFg = 0,
  });

  factory NutrientTotals.fromJson(Map<String, dynamic> json) {
    return NutrientTotals(
      energyMcal: (json['energyMcal'] as num?)?.toDouble() ?? 0,
      proteinCPg: (json['proteinCPg'] as num?)?.toDouble() ?? 0,
      calciumG: (json['calciumG'] as num?)?.toDouble() ?? 0,
      phosphorusG: (json['phosphorusG'] as num?)?.toDouble() ?? 0,
      fiberNDFg: (json['fiberNDFg'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energyMcal': energyMcal,
      'proteinCPg': proteinCPg,
      'calciumG': calciumG,
      'phosphorusG': phosphorusG,
      'fiberNDFg': fiberNDFg,
    };
  }
}

/// Recommandation nutritionnelle IA
class NutritionRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String? action;

  NutritionRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.priority = RecommendationPriority.medium,
    this.action,
  });

  factory NutritionRecommendation.fromJson(Map<String, dynamic> json) {
    return NutritionRecommendation(
      id: json['id'] as String? ?? '',
      type: _parseType(json['type']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: _parsePriority(json['priority']),
      action: json['action'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'action': action,
    };
  }

  static RecommendationType _parseType(dynamic value) {
    if (value == null) return RecommendationType.general;
    if (value is RecommendationType) return value;
    if (value is String) {
      return RecommendationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RecommendationType.general,
      );
    }
    return RecommendationType.general;
  }

  static RecommendationPriority _parsePriority(dynamic value) {
    if (value == null) return RecommendationPriority.medium;
    if (value is RecommendationPriority) return value;
    if (value is String) {
      return RecommendationPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RecommendationPriority.medium,
      );
    }
    return RecommendationPriority.medium;
  }
}

enum RecommendationType {
  general,
  forage,
  concentrate,
  supplement,
  hydration,
  warning,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.low:
        return 'Faible';
      case RecommendationPriority.medium:
        return 'Moyen';
      case RecommendationPriority.high:
        return 'Élevé';
      case RecommendationPriority.critical:
        return 'Critique';
    }
  }

  int get colorValue {
    switch (this) {
      case RecommendationPriority.low:
        return 0xFF4CAF50; // Green
      case RecommendationPriority.medium:
        return 0xFFFFC107; // Amber
      case RecommendationPriority.high:
        return 0xFFFF9800; // Orange
      case RecommendationPriority.critical:
        return 0xFFF44336; // Red
    }
  }
}

/// Historique alimentaire
class FeedingLog {
  final String id;
  final String horseId;
  final DateTime feedingTime;
  final String feedType; // "forage", "concentrate", "supplement"
  final String feedName;
  final double quantityKg;
  final String? notes;
  final String? fedBy;

  FeedingLog({
    required this.id,
    required this.horseId,
    required this.feedingTime,
    required this.feedType,
    required this.feedName,
    required this.quantityKg,
    this.notes,
    this.fedBy,
  });

  factory FeedingLog.fromJson(Map<String, dynamic> json) {
    return FeedingLog(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      feedingTime: DateTime.parse(json['feedingTime'] as String),
      feedType: json['feedType'] as String,
      feedName: json['feedName'] as String,
      quantityKg: (json['quantityKg'] as num).toDouble(),
      notes: json['notes'] as String?,
      fedBy: json['fedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horseId': horseId,
      'feedingTime': feedingTime.toIso8601String(),
      'feedType': feedType,
      'feedName': feedName,
      'quantityKg': quantityKg,
      'notes': notes,
      'fedBy': fedBy,
    };
  }
}
