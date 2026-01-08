/// Données IA persistantes pour chaque cheval
/// Ces données sont utilisées par toutes les fonctionnalités IA de l'application
class HorseAIData {
  final String horseId;
  final DateTime lastUpdated;

  // Données de santé IA
  final HealthAIData? healthData;

  // Données d'analyse IA (locomotion, saut, etc.)
  final AnalysisAIData? analysisData;

  // Données de gestation IA
  final GestationAIData? gestationData;

  // Données d'entraînement IA
  final TrainingAIData? trainingData;

  // Données de nutrition IA
  final NutritionAIData? nutritionData;

  // Données de conformation IA
  final ConformationAIData? conformationData;

  // Score global IA du cheval
  final double? globalAIScore;

  // Recommandations IA générales
  final List<AIRecommendation> recommendations;

  // Alertes IA actives
  final List<AIAlert> alerts;

  HorseAIData({
    required this.horseId,
    required this.lastUpdated,
    this.healthData,
    this.analysisData,
    this.gestationData,
    this.trainingData,
    this.nutritionData,
    this.conformationData,
    this.globalAIScore,
    this.recommendations = const [],
    this.alerts = const [],
  });

  factory HorseAIData.empty(String horseId) {
    return HorseAIData(
      horseId: horseId,
      lastUpdated: DateTime.now(),
    );
  }

  factory HorseAIData.fromJson(Map<String, dynamic> json) {
    return HorseAIData(
      horseId: json['horseId'] as String,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      healthData: json['healthData'] != null
          ? HealthAIData.fromJson(json['healthData'])
          : null,
      analysisData: json['analysisData'] != null
          ? AnalysisAIData.fromJson(json['analysisData'])
          : null,
      gestationData: json['gestationData'] != null
          ? GestationAIData.fromJson(json['gestationData'])
          : null,
      trainingData: json['trainingData'] != null
          ? TrainingAIData.fromJson(json['trainingData'])
          : null,
      nutritionData: json['nutritionData'] != null
          ? NutritionAIData.fromJson(json['nutritionData'])
          : null,
      conformationData: json['conformationData'] != null
          ? ConformationAIData.fromJson(json['conformationData'])
          : null,
      globalAIScore: (json['globalAIScore'] as num?)?.toDouble(),
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => AIRecommendation.fromJson(e))
              .toList() ??
          [],
      alerts: (json['alerts'] as List?)
              ?.map((e) => AIAlert.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'healthData': healthData?.toJson(),
      'analysisData': analysisData?.toJson(),
      'gestationData': gestationData?.toJson(),
      'trainingData': trainingData?.toJson(),
      'nutritionData': nutritionData?.toJson(),
      'conformationData': conformationData?.toJson(),
      'globalAIScore': globalAIScore,
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
    };
  }

  HorseAIData copyWith({
    String? horseId,
    DateTime? lastUpdated,
    HealthAIData? healthData,
    AnalysisAIData? analysisData,
    GestationAIData? gestationData,
    TrainingAIData? trainingData,
    NutritionAIData? nutritionData,
    ConformationAIData? conformationData,
    double? globalAIScore,
    List<AIRecommendation>? recommendations,
    List<AIAlert>? alerts,
  }) {
    return HorseAIData(
      horseId: horseId ?? this.horseId,
      lastUpdated: lastUpdated ?? DateTime.now(),
      healthData: healthData ?? this.healthData,
      analysisData: analysisData ?? this.analysisData,
      gestationData: gestationData ?? this.gestationData,
      trainingData: trainingData ?? this.trainingData,
      nutritionData: nutritionData ?? this.nutritionData,
      conformationData: conformationData ?? this.conformationData,
      globalAIScore: globalAIScore ?? this.globalAIScore,
      recommendations: recommendations ?? this.recommendations,
      alerts: alerts ?? this.alerts,
    );
  }
}

/// Données de santé analysées par IA
class HealthAIData {
  final double? overallHealthScore; // 0-100
  final String? healthStatus; // 'excellent', 'good', 'attention', 'critical'
  final List<HealthCondition> conditions;
  final List<String> riskFactors;
  final DateTime? lastVetCheck;
  final DateTime? nextRecommendedCheck;
  final Map<String, dynamic>? vetNotes;

  HealthAIData({
    this.overallHealthScore,
    this.healthStatus,
    this.conditions = const [],
    this.riskFactors = const [],
    this.lastVetCheck,
    this.nextRecommendedCheck,
    this.vetNotes,
  });

  factory HealthAIData.fromJson(Map<String, dynamic> json) {
    return HealthAIData(
      overallHealthScore: (json['overallHealthScore'] as num?)?.toDouble(),
      healthStatus: json['healthStatus'] as String?,
      conditions: (json['conditions'] as List?)
              ?.map((e) => HealthCondition.fromJson(e))
              .toList() ??
          [],
      riskFactors: (json['riskFactors'] as List?)?.cast<String>() ?? [],
      lastVetCheck: json['lastVetCheck'] != null
          ? DateTime.parse(json['lastVetCheck'] as String)
          : null,
      nextRecommendedCheck: json['nextRecommendedCheck'] != null
          ? DateTime.parse(json['nextRecommendedCheck'] as String)
          : null,
      vetNotes: json['vetNotes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallHealthScore': overallHealthScore,
      'healthStatus': healthStatus,
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'riskFactors': riskFactors,
      'lastVetCheck': lastVetCheck?.toIso8601String(),
      'nextRecommendedCheck': nextRecommendedCheck?.toIso8601String(),
      'vetNotes': vetNotes,
    };
  }
}

class HealthCondition {
  final String name;
  final String severity; // 'mild', 'moderate', 'severe'
  final DateTime detectedAt;
  final String? treatment;
  final bool isActive;

  HealthCondition({
    required this.name,
    required this.severity,
    required this.detectedAt,
    this.treatment,
    this.isActive = true,
  });

  factory HealthCondition.fromJson(Map<String, dynamic> json) {
    return HealthCondition(
      name: json['name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'mild',
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : DateTime.now(),
      treatment: json['treatment'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'detectedAt': detectedAt.toIso8601String(),
      'treatment': treatment,
      'isActive': isActive,
    };
  }
}

/// Données d'analyse de mouvement IA
class AnalysisAIData {
  final double? locomotionScore; // 0-100
  final double? symmetryScore; // 0-100
  final double? rhythmScore; // 0-100
  final double? jumpingScore; // 0-100
  final double? postureScore; // 0-100
  final String? gaitQuality;
  final List<String> strengths;
  final List<String> areasToImprove;
  final int totalAnalyses;
  final DateTime? lastAnalysis;
  final Map<String, dynamic>? detailedMetrics;

  AnalysisAIData({
    this.locomotionScore,
    this.symmetryScore,
    this.rhythmScore,
    this.jumpingScore,
    this.postureScore,
    this.gaitQuality,
    this.strengths = const [],
    this.areasToImprove = const [],
    this.totalAnalyses = 0,
    this.lastAnalysis,
    this.detailedMetrics,
  });

  factory AnalysisAIData.fromJson(Map<String, dynamic> json) {
    return AnalysisAIData(
      locomotionScore: (json['locomotionScore'] as num?)?.toDouble(),
      symmetryScore: (json['symmetryScore'] as num?)?.toDouble(),
      rhythmScore: (json['rhythmScore'] as num?)?.toDouble(),
      jumpingScore: (json['jumpingScore'] as num?)?.toDouble(),
      postureScore: (json['postureScore'] as num?)?.toDouble(),
      gaitQuality: json['gaitQuality'] as String?,
      strengths: (json['strengths'] as List?)?.cast<String>() ?? [],
      areasToImprove: (json['areasToImprove'] as List?)?.cast<String>() ?? [],
      totalAnalyses: json['totalAnalyses'] as int? ?? 0,
      lastAnalysis: json['lastAnalysis'] != null
          ? DateTime.parse(json['lastAnalysis'] as String)
          : null,
      detailedMetrics: json['detailedMetrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locomotionScore': locomotionScore,
      'symmetryScore': symmetryScore,
      'rhythmScore': rhythmScore,
      'jumpingScore': jumpingScore,
      'postureScore': postureScore,
      'gaitQuality': gaitQuality,
      'strengths': strengths,
      'areasToImprove': areasToImprove,
      'totalAnalyses': totalAnalyses,
      'lastAnalysis': lastAnalysis?.toIso8601String(),
      'detailedMetrics': detailedMetrics,
    };
  }
}

/// Données de gestation IA
class GestationAIData {
  final bool isPregnant;
  final DateTime? breedingDate;
  final DateTime? expectedFoalingDate;
  final int? gestationDay;
  final String? gestationStage; // 'early', 'mid', 'late'
  final double? healthRiskScore;
  final List<String> recommendations;
  final List<GestationCheckup> checkups;
  final Map<String, dynamic>? foalPredictions;

  GestationAIData({
    this.isPregnant = false,
    this.breedingDate,
    this.expectedFoalingDate,
    this.gestationDay,
    this.gestationStage,
    this.healthRiskScore,
    this.recommendations = const [],
    this.checkups = const [],
    this.foalPredictions,
  });

  factory GestationAIData.fromJson(Map<String, dynamic> json) {
    return GestationAIData(
      isPregnant: json['isPregnant'] as bool? ?? false,
      breedingDate: json['breedingDate'] != null
          ? DateTime.parse(json['breedingDate'] as String)
          : null,
      expectedFoalingDate: json['expectedFoalingDate'] != null
          ? DateTime.parse(json['expectedFoalingDate'] as String)
          : null,
      gestationDay: json['gestationDay'] as int?,
      gestationStage: json['gestationStage'] as String?,
      healthRiskScore: (json['healthRiskScore'] as num?)?.toDouble(),
      recommendations:
          (json['recommendations'] as List?)?.cast<String>() ?? [],
      checkups: (json['checkups'] as List?)
              ?.map((e) => GestationCheckup.fromJson(e))
              .toList() ??
          [],
      foalPredictions: json['foalPredictions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPregnant': isPregnant,
      'breedingDate': breedingDate?.toIso8601String(),
      'expectedFoalingDate': expectedFoalingDate?.toIso8601String(),
      'gestationDay': gestationDay,
      'gestationStage': gestationStage,
      'healthRiskScore': healthRiskScore,
      'recommendations': recommendations,
      'checkups': checkups.map((e) => e.toJson()).toList(),
      'foalPredictions': foalPredictions,
    };
  }
}

class GestationCheckup {
  final DateTime date;
  final String type; // 'ultrasound', 'blood_test', 'physical'
  final String result;
  final String? notes;

  GestationCheckup({
    required this.date,
    required this.type,
    required this.result,
    this.notes,
  });

  factory GestationCheckup.fromJson(Map<String, dynamic> json) {
    return GestationCheckup(
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String? ?? 'physical',
      result: json['result'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type,
      'result': result,
      'notes': notes,
    };
  }
}

/// Données d'entraînement IA
class TrainingAIData {
  final double? fitnessScore; // 0-100
  final double? performanceScore; // 0-100
  final String? currentPhase; // 'building', 'maintaining', 'peaking', 'recovery'
  final int? weeklyTrainingHours;
  final int? totalSessions;
  final List<String> skillsToWork;
  final List<String> achievements;
  final TrainingPlan? currentPlan;
  final Map<String, dynamic>? progressMetrics;

  TrainingAIData({
    this.fitnessScore,
    this.performanceScore,
    this.currentPhase,
    this.weeklyTrainingHours,
    this.totalSessions,
    this.skillsToWork = const [],
    this.achievements = const [],
    this.currentPlan,
    this.progressMetrics,
  });

  factory TrainingAIData.fromJson(Map<String, dynamic> json) {
    return TrainingAIData(
      fitnessScore: (json['fitnessScore'] as num?)?.toDouble(),
      performanceScore: (json['performanceScore'] as num?)?.toDouble(),
      currentPhase: json['currentPhase'] as String?,
      weeklyTrainingHours: json['weeklyTrainingHours'] as int?,
      totalSessions: json['totalSessions'] as int?,
      skillsToWork: (json['skillsToWork'] as List?)?.cast<String>() ?? [],
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      currentPlan: json['currentPlan'] != null
          ? TrainingPlan.fromJson(json['currentPlan'])
          : null,
      progressMetrics: json['progressMetrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fitnessScore': fitnessScore,
      'performanceScore': performanceScore,
      'currentPhase': currentPhase,
      'weeklyTrainingHours': weeklyTrainingHours,
      'totalSessions': totalSessions,
      'skillsToWork': skillsToWork,
      'achievements': achievements,
      'currentPlan': currentPlan?.toJson(),
      'progressMetrics': progressMetrics,
    };
  }
}

class TrainingPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String goal;
  final List<String> weeklySchedule;

  TrainingPlan({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.goal,
    this.weeklySchedule = const [],
  });

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      goal: json['goal'] as String? ?? '',
      weeklySchedule: (json['weeklySchedule'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'goal': goal,
      'weeklySchedule': weeklySchedule,
    };
  }
}

/// Données de nutrition IA
class NutritionAIData {
  final double? bodyConditionScore; // 1-9
  final double? idealWeight;
  final double? currentWeight;
  final String? dietType; // 'maintenance', 'weight_gain', 'weight_loss', 'performance'
  final double? dailyEnergyNeeds; // Mcal
  final double? dailyProteinNeeds; // g
  final List<String> dietaryRestrictions;
  final List<String> supplements;
  final String? currentPlanId;
  final DateTime? lastAssessment;
  final Map<String, dynamic>? feedingSchedule;

  NutritionAIData({
    this.bodyConditionScore,
    this.idealWeight,
    this.currentWeight,
    this.dietType,
    this.dailyEnergyNeeds,
    this.dailyProteinNeeds,
    this.dietaryRestrictions = const [],
    this.supplements = const [],
    this.currentPlanId,
    this.lastAssessment,
    this.feedingSchedule,
  });

  factory NutritionAIData.fromJson(Map<String, dynamic> json) {
    return NutritionAIData(
      bodyConditionScore: (json['bodyConditionScore'] as num?)?.toDouble(),
      idealWeight: (json['idealWeight'] as num?)?.toDouble(),
      currentWeight: (json['currentWeight'] as num?)?.toDouble(),
      dietType: json['dietType'] as String?,
      dailyEnergyNeeds: (json['dailyEnergyNeeds'] as num?)?.toDouble(),
      dailyProteinNeeds: (json['dailyProteinNeeds'] as num?)?.toDouble(),
      dietaryRestrictions:
          (json['dietaryRestrictions'] as List?)?.cast<String>() ?? [],
      supplements: (json['supplements'] as List?)?.cast<String>() ?? [],
      currentPlanId: json['currentPlanId'] as String?,
      lastAssessment: json['lastAssessment'] != null
          ? DateTime.parse(json['lastAssessment'] as String)
          : null,
      feedingSchedule: json['feedingSchedule'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyConditionScore': bodyConditionScore,
      'idealWeight': idealWeight,
      'currentWeight': currentWeight,
      'dietType': dietType,
      'dailyEnergyNeeds': dailyEnergyNeeds,
      'dailyProteinNeeds': dailyProteinNeeds,
      'dietaryRestrictions': dietaryRestrictions,
      'supplements': supplements,
      'currentPlanId': currentPlanId,
      'lastAssessment': lastAssessment?.toIso8601String(),
      'feedingSchedule': feedingSchedule,
    };
  }
}

/// Données de conformation IA
class ConformationAIData {
  final double? overallScore; // 0-100
  final Map<String, double>? bodyPartScores; // 'head', 'neck', 'back', 'legs', etc.
  final List<String> positiveTraits;
  final List<String> concernAreas;
  final String? breedTypicality;
  final DateTime? lastAssessment;
  final List<String> photoUrls;

  ConformationAIData({
    this.overallScore,
    this.bodyPartScores,
    this.positiveTraits = const [],
    this.concernAreas = const [],
    this.breedTypicality,
    this.lastAssessment,
    this.photoUrls = const [],
  });

  factory ConformationAIData.fromJson(Map<String, dynamic> json) {
    return ConformationAIData(
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      bodyPartScores: (json['bodyPartScores'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      positiveTraits: (json['positiveTraits'] as List?)?.cast<String>() ?? [],
      concernAreas: (json['concernAreas'] as List?)?.cast<String>() ?? [],
      breedTypicality: json['breedTypicality'] as String?,
      lastAssessment: json['lastAssessment'] != null
          ? DateTime.parse(json['lastAssessment'] as String)
          : null,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'bodyPartScores': bodyPartScores,
      'positiveTraits': positiveTraits,
      'concernAreas': concernAreas,
      'breedTypicality': breedTypicality,
      'lastAssessment': lastAssessment?.toIso8601String(),
      'photoUrls': photoUrls,
    };
  }
}

/// Recommandation IA générale
class AIRecommendation {
  final String id;
  final String category; // 'health', 'training', 'nutrition', 'general'
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final DateTime createdAt;
  final bool isDismissed;

  AIRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.priority = 'medium',
    required this.createdAt,
    this.isDismissed = false,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'isDismissed': isDismissed,
    };
  }
}

/// Alerte IA
class AIAlert {
  final String id;
  final String type; // 'warning', 'info', 'urgent'
  final String message;
  final String? actionRequired;
  final DateTime createdAt;
  final bool isRead;
  final bool isResolved;

  AIAlert({
    required this.id,
    required this.type,
    required this.message,
    this.actionRequired,
    required this.createdAt,
    this.isRead = false,
    this.isResolved = false,
  });

  factory AIAlert.fromJson(Map<String, dynamic> json) {
    return AIAlert(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      actionRequired: json['actionRequired'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'actionRequired': actionRequired,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isResolved': isResolved,
    };
  }
}
