/// Complete Health Tracking System for Horse Tempo

import 'package:flutter/material.dart';

// ============================================
// VETERINARY RECORDS
// ============================================

/// Complete health record for a horse
class HealthRecord {
  final String id;
  final String horseId;
  final String horseName;
  final HealthRecordType type;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? nextDueDate;
  final String? veterinarian;
  final String? clinic;
  final String? phone;
  final double? cost;
  final List<String> attachments; // Photos, documents
  final Map<String, dynamic>? metadata;
  final bool isAlert;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HealthRecord({
    required this.id,
    required this.horseId,
    required this.horseName,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.nextDueDate,
    this.veterinarian,
    this.clinic,
    this.phone,
    this.cost,
    this.attachments = const [],
    this.metadata,
    this.isAlert = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue => nextDueDate != null && DateTime.now().isAfter(nextDueDate!);
  bool get isDueSoon => nextDueDate != null &&
      nextDueDate!.difference(DateTime.now()).inDays <= 7 &&
      !isOverdue;

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      type: HealthRecordType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
      veterinarian: json['veterinarian'] as String?,
      clinic: json['clinic'] as String?,
      phone: json['phone'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      isAlert: json['isAlert'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'type': type.name,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'clinic': clinic,
      'phone': phone,
      'cost': cost,
      'attachments': attachments,
      'metadata': metadata,
      'isAlert': isAlert,
    };
  }
}

/// Types of health records
enum HealthRecordType {
  vaccination,      // Vaccins
  deworming,        // Vermifuge
  farrier,          // Maréchalerie
  dentist,          // Dentiste
  osteopath,        // Ostéopathe
  veterinaryVisit,  // Visite véto
  surgery,          // Chirurgie
  injury,           // Blessure
  illness,          // Maladie
  medication,       // Médicament
  supplement,       // Complément
  examination,      // Examen (radio, écho, etc.)
  other;

  String get displayName {
    switch (this) {
      case HealthRecordType.vaccination: return 'Vaccination';
      case HealthRecordType.deworming: return 'Vermifuge';
      case HealthRecordType.farrier: return 'Maréchalerie';
      case HealthRecordType.dentist: return 'Dentiste';
      case HealthRecordType.osteopath: return 'Ostéopathe';
      case HealthRecordType.veterinaryVisit: return 'Visite vétérinaire';
      case HealthRecordType.surgery: return 'Chirurgie';
      case HealthRecordType.injury: return 'Blessure';
      case HealthRecordType.illness: return 'Maladie';
      case HealthRecordType.medication: return 'Médicament';
      case HealthRecordType.supplement: return 'Complément';
      case HealthRecordType.examination: return 'Examen';
      case HealthRecordType.other: return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthRecordType.vaccination: return Icons.vaccines;
      case HealthRecordType.deworming: return Icons.bug_report;
      case HealthRecordType.farrier: return Icons.handyman;
      case HealthRecordType.dentist: return Icons.medical_services;
      case HealthRecordType.osteopath: return Icons.accessibility_new;
      case HealthRecordType.veterinaryVisit: return Icons.local_hospital;
      case HealthRecordType.surgery: return Icons.healing;
      case HealthRecordType.injury: return Icons.personal_injury;
      case HealthRecordType.illness: return Icons.sick;
      case HealthRecordType.medication: return Icons.medication;
      case HealthRecordType.supplement: return Icons.spa;
      case HealthRecordType.examination: return Icons.biotech;
      case HealthRecordType.other: return Icons.note_add;
    }
  }

  int get color {
    switch (this) {
      case HealthRecordType.vaccination: return 0xFF4CAF50;
      case HealthRecordType.deworming: return 0xFFFF9800;
      case HealthRecordType.farrier: return 0xFF795548;
      case HealthRecordType.dentist: return 0xFF00BCD4;
      case HealthRecordType.osteopath: return 0xFF9C27B0;
      case HealthRecordType.veterinaryVisit: return 0xFF2196F3;
      case HealthRecordType.surgery: return 0xFFF44336;
      case HealthRecordType.injury: return 0xFFE91E63;
      case HealthRecordType.illness: return 0xFFFF5722;
      case HealthRecordType.medication: return 0xFF3F51B5;
      case HealthRecordType.supplement: return 0xFF8BC34A;
      case HealthRecordType.examination: return 0xFF607D8B;
      case HealthRecordType.other: return 0xFF9E9E9E;
    }
  }

  /// Standard intervals in days between treatments
  int? get standardInterval {
    switch (this) {
      case HealthRecordType.vaccination: return 365; // Annual
      case HealthRecordType.deworming: return 90;    // Quarterly
      case HealthRecordType.farrier: return 42;      // 6 weeks
      case HealthRecordType.dentist: return 365;     // Annual
      case HealthRecordType.osteopath: return 180;   // 6 months
      default: return null;
    }
  }

  static HealthRecordType fromString(String value) {
    return HealthRecordType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthRecordType.other,
    );
  }
}

// ============================================
// VACCINATIONS
// ============================================

/// Specific vaccination record
class VaccinationRecord extends HealthRecord {
  final String vaccineName;
  final String? batchNumber;
  final String? manufacturer;
  final VaccinationType vaccinationType;

  VaccinationRecord({
    required super.id,
    required super.horseId,
    required super.horseName,
    required super.title,
    super.description,
    required super.date,
    super.nextDueDate,
    super.veterinarian,
    super.clinic,
    super.phone,
    super.cost,
    super.attachments,
    super.metadata,
    super.isAlert,
    required super.createdAt,
    super.updatedAt,
    required this.vaccineName,
    this.batchNumber,
    this.manufacturer,
    required this.vaccinationType,
  }) : super(type: HealthRecordType.vaccination);
}

enum VaccinationType {
  grippe,           // Influenza
  tetanos,          // Tetanus
  rhinopneumonie,   // Rhinopneumonitis
  rage,             // Rabies
  westNile,         // West Nile
  strangles,        // Gourme
  other;

  String get displayName {
    switch (this) {
      case VaccinationType.grippe: return 'Grippe équine';
      case VaccinationType.tetanos: return 'Tétanos';
      case VaccinationType.rhinopneumonie: return 'Rhinopneumonie';
      case VaccinationType.rage: return 'Rage';
      case VaccinationType.westNile: return 'West Nile';
      case VaccinationType.strangles: return 'Gourme';
      case VaccinationType.other: return 'Autre';
    }
  }

  /// Required interval in days
  int get requiredInterval {
    switch (this) {
      case VaccinationType.grippe: return 180; // 6 months for competition
      case VaccinationType.tetanos: return 365;
      case VaccinationType.rhinopneumonie: return 180;
      case VaccinationType.rage: return 365;
      case VaccinationType.westNile: return 365;
      case VaccinationType.strangles: return 365;
      case VaccinationType.other: return 365;
    }
  }

  static VaccinationType fromString(String value) {
    return VaccinationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VaccinationType.other,
    );
  }
}

// ============================================
// WEIGHT & GROWTH TRACKING
// ============================================

/// Weight measurement
class WeightRecord {
  final String id;
  final String horseId;
  final double weight; // kg
  final DateTime date;
  final String? notes;
  final MeasurementMethod method;

  WeightRecord({
    required this.id,
    required this.horseId,
    required this.weight,
    required this.date,
    this.notes,
    this.method = MeasurementMethod.scale,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      method: MeasurementMethod.fromString(json['method'] as String? ?? 'scale'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
      'method': method.name,
    };
  }
}

enum MeasurementMethod {
  scale,        // Balance
  tape,         // Ruban de pesée
  estimation;   // Estimation

  String get displayName {
    switch (this) {
      case MeasurementMethod.scale: return 'Balance';
      case MeasurementMethod.tape: return 'Ruban de pesée';
      case MeasurementMethod.estimation: return 'Estimation';
    }
  }

  static MeasurementMethod fromString(String value) {
    return MeasurementMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeasurementMethod.estimation,
    );
  }
}

/// Body condition score
class BodyConditionRecord {
  final String id;
  final String horseId;
  final int score; // 1-9 Henneke scale
  final DateTime date;
  final String? notes;
  final Map<String, int>? detailedScores; // Per body area

  BodyConditionRecord({
    required this.id,
    required this.horseId,
    required this.score,
    required this.date,
    this.notes,
    this.detailedScores,
  });

  String get scoreDescription {
    if (score <= 2) return 'Très maigre';
    if (score <= 3) return 'Maigre';
    if (score <= 4) return 'Légèrement maigre';
    if (score <= 5) return 'Idéal';
    if (score <= 6) return 'Légèrement gras';
    if (score <= 7) return 'Gras';
    if (score <= 8) return 'Obèse';
    return 'Très obèse';
  }

  factory BodyConditionRecord.fromJson(Map<String, dynamic> json) {
    return BodyConditionRecord(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      score: json['score'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      detailedScores: (json['detailedScores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
    );
  }
}

// ============================================
// NUTRITION
// ============================================

/// Daily nutrition/feeding plan
class NutritionPlan {
  final String id;
  final String horseId;
  final String name;
  final List<FeedingItem> items;
  final int totalCalories;
  final double totalProtein; // g
  final double totalFiber; // g
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  NutritionPlan({
    required this.id,
    required this.horseId,
    required this.name,
    required this.items,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalFiber = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      name: json['name'] as String,
      items: (json['items'] as List)
          .map((i) => FeedingItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalCalories: json['totalCalories'] as int? ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalFiber: (json['totalFiber'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Single feeding item
class FeedingItem {
  final String id;
  final String name;
  final FeedType type;
  final double quantity; // kg
  final FeedingTime feedingTime;
  final int? calories;
  final String? notes;

  FeedingItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.feedingTime,
    this.calories,
    this.notes,
  });

  factory FeedingItem.fromJson(Map<String, dynamic> json) {
    return FeedingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: FeedType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      feedingTime: FeedingTime.fromString(json['feedingTime'] as String),
      calories: json['calories'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

enum FeedType {
  hay,          // Foin
  haylage,      // Enrubanné
  grass,        // Herbe
  grain,        // Céréales
  pellets,      // Granulés
  mash,         // Mash
  supplement,   // Complément
  treat,        // Friandise
  other;

  String get displayName {
    switch (this) {
      case FeedType.hay: return 'Foin';
      case FeedType.haylage: return 'Enrubanné';
      case FeedType.grass: return 'Herbe';
      case FeedType.grain: return 'Céréales';
      case FeedType.pellets: return 'Granulés';
      case FeedType.mash: return 'Mash';
      case FeedType.supplement: return 'Complément';
      case FeedType.treat: return 'Friandise';
      case FeedType.other: return 'Autre';
    }
  }

  static FeedType fromString(String value) {
    return FeedType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeedType.other,
    );
  }
}

enum FeedingTime {
  morning,
  midday,
  evening,
  night,
  freeAccess;

  String get displayName {
    switch (this) {
      case FeedingTime.morning: return 'Matin';
      case FeedingTime.midday: return 'Midi';
      case FeedingTime.evening: return 'Soir';
      case FeedingTime.night: return 'Nuit';
      case FeedingTime.freeAccess: return 'Libre accès';
    }
  }

  static FeedingTime fromString(String value) {
    return FeedingTime.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeedingTime.morning,
    );
  }
}

// ============================================
// NUTRITION CALCULATOR
// ============================================

/// Nutrition recommendation based on horse profile
class NutritionRecommendation {
  final String horseId;
  final double recommendedCalories;
  final double recommendedProtein; // g
  final double recommendedFiber; // kg
  final double recommendedWater; // L
  final ActivityLevel activityLevel;
  final List<String> recommendations;
  final List<String> warnings;
  final DateTime calculatedAt;

  NutritionRecommendation({
    required this.horseId,
    required this.recommendedCalories,
    required this.recommendedProtein,
    required this.recommendedFiber,
    required this.recommendedWater,
    required this.activityLevel,
    this.recommendations = const [],
    this.warnings = const [],
    required this.calculatedAt,
  });

  factory NutritionRecommendation.fromJson(Map<String, dynamic> json) {
    return NutritionRecommendation(
      horseId: json['horseId'] as String,
      recommendedCalories: (json['recommendedCalories'] as num).toDouble(),
      recommendedProtein: (json['recommendedProtein'] as num).toDouble(),
      recommendedFiber: (json['recommendedFiber'] as num).toDouble(),
      recommendedWater: (json['recommendedWater'] as num).toDouble(),
      activityLevel: ActivityLevel.fromString(json['activityLevel'] as String),
      recommendations: (json['recommendations'] as List?)?.cast<String>() ?? [],
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  /// Calculate nutrition needs based on horse data
  static NutritionRecommendation calculate({
    required String horseId,
    required double weight, // kg
    required ActivityLevel activityLevel,
    int? age,
    bool isPregnant = false,
    bool isLactating = false,
    bool isGrowing = false,
  }) {
    // Base energy requirement: ~33 Mcal DE per 500kg horse at maintenance
    double baseCalories = weight * 0.033 * 1000; // Convert to kcal

    // Activity multiplier
    double multiplier = activityLevel.calorieMultiplier;
    if (isPregnant) multiplier += 0.1;
    if (isLactating) multiplier += 0.3;
    if (isGrowing) multiplier += 0.2;

    double calories = baseCalories * multiplier;

    // Protein: ~10-14% of diet
    double protein = (calories * 0.12) / 4; // 4 kcal per gram protein

    // Fiber: 1.5-2% of body weight in forage
    double fiber = weight * 0.0175;

    // Water: ~5L per 100kg + activity adjustment
    double water = (weight / 100) * 5 * (1 + (multiplier - 1) * 0.5);

    List<String> recommendations = [];
    List<String> warnings = [];

    if (activityLevel == ActivityLevel.intense || activityLevel == ActivityLevel.veryIntense) {
      recommendations.add('Augmentez les apports en électrolytes');
      recommendations.add('Fractionnez les repas de concentrés');
    }

    if (isPregnant) {
      recommendations.add('Augmentez progressivement la ration au dernier tiers');
      warnings.add('Évitez les aliments moisis');
    }

    if (weight < 400 && age != null && age > 3) {
      warnings.add('Poids potentiellement insuffisant - consultez un vétérinaire');
    }

    return NutritionRecommendation(
      horseId: horseId,
      recommendedCalories: calories,
      recommendedProtein: protein,
      recommendedFiber: fiber,
      recommendedWater: water,
      activityLevel: activityLevel,
      recommendations: recommendations,
      warnings: warnings,
      calculatedAt: DateTime.now(),
    );
  }
}

enum ActivityLevel {
  rest,         // Au repos / convalescence
  light,        // Travail léger (balade)
  moderate,     // Travail modéré (club)
  intense,      // Travail intense (compétition amateur)
  veryIntense;  // Travail très intense (compétition pro)

  String get displayName {
    switch (this) {
      case ActivityLevel.rest: return 'Repos';
      case ActivityLevel.light: return 'Léger';
      case ActivityLevel.moderate: return 'Modéré';
      case ActivityLevel.intense: return 'Intense';
      case ActivityLevel.veryIntense: return 'Très intense';
    }
  }

  double get calorieMultiplier {
    switch (this) {
      case ActivityLevel.rest: return 0.9;
      case ActivityLevel.light: return 1.0;
      case ActivityLevel.moderate: return 1.25;
      case ActivityLevel.intense: return 1.5;
      case ActivityLevel.veryIntense: return 1.75;
    }
  }

  static ActivityLevel fromString(String value) {
    return ActivityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityLevel.moderate,
    );
  }
}

// ============================================
// HEALTH ALERTS & REMINDERS
// ============================================

/// Health reminder/alert
class HealthReminder {
  final String id;
  final String horseId;
  final String horseName;
  final HealthRecordType type;
  final String title;
  final String? description;
  final DateTime dueDate;
  final ReminderPriority priority;
  final bool isDismissed;
  final bool isCompleted;
  final String? relatedRecordId;

  HealthReminder({
    required this.id,
    required this.horseId,
    required this.horseName,
    required this.type,
    required this.title,
    this.description,
    required this.dueDate,
    this.priority = ReminderPriority.medium,
    this.isDismissed = false,
    this.isCompleted = false,
    this.relatedRecordId,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isCompleted;
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  factory HealthReminder.fromJson(Map<String, dynamic> json) {
    return HealthReminder(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      type: HealthRecordType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: ReminderPriority.fromString(json['priority'] as String? ?? 'medium'),
      isDismissed: json['isDismissed'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      relatedRecordId: json['relatedRecordId'] as String?,
    );
  }
}

enum ReminderPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case ReminderPriority.low: return 'Basse';
      case ReminderPriority.medium: return 'Moyenne';
      case ReminderPriority.high: return 'Haute';
      case ReminderPriority.urgent: return 'Urgente';
    }
  }

  int get color {
    switch (this) {
      case ReminderPriority.low: return 0xFF9E9E9E;
      case ReminderPriority.medium: return 0xFF2196F3;
      case ReminderPriority.high: return 0xFFFF9800;
      case ReminderPriority.urgent: return 0xFFF44336;
    }
  }

  static ReminderPriority fromString(String value) {
    return ReminderPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderPriority.medium,
    );
  }
}

// ============================================
// HEALTH SUMMARY
// ============================================

/// Overall health summary for a horse
class HealthSummary {
  final String horseId;
  final int totalRecords;
  final DateTime? lastVaccination;
  final DateTime? lastDeworming;
  final DateTime? lastFarrier;
  final DateTime? lastDentist;
  final DateTime? lastVetVisit;
  final List<HealthReminder> upcomingReminders;
  final List<HealthReminder> overdueReminders;
  final double? lastWeight;
  final int? lastBodyCondition;
  final HealthStatus overallStatus;

  HealthSummary({
    required this.horseId,
    this.totalRecords = 0,
    this.lastVaccination,
    this.lastDeworming,
    this.lastFarrier,
    this.lastDentist,
    this.lastVetVisit,
    this.upcomingReminders = const [],
    this.overdueReminders = const [],
    this.lastWeight,
    this.lastBodyCondition,
    this.overallStatus = HealthStatus.good,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      horseId: json['horseId'] as String,
      totalRecords: json['totalRecords'] as int? ?? 0,
      lastVaccination: json['lastVaccination'] != null
          ? DateTime.parse(json['lastVaccination'] as String)
          : null,
      lastDeworming: json['lastDeworming'] != null
          ? DateTime.parse(json['lastDeworming'] as String)
          : null,
      lastFarrier: json['lastFarrier'] != null
          ? DateTime.parse(json['lastFarrier'] as String)
          : null,
      lastDentist: json['lastDentist'] != null
          ? DateTime.parse(json['lastDentist'] as String)
          : null,
      lastVetVisit: json['lastVetVisit'] != null
          ? DateTime.parse(json['lastVetVisit'] as String)
          : null,
      upcomingReminders: (json['upcomingReminders'] as List?)
          ?.map((r) => HealthReminder.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      overdueReminders: (json['overdueReminders'] as List?)
          ?.map((r) => HealthReminder.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      lastWeight: (json['lastWeight'] as num?)?.toDouble(),
      lastBodyCondition: json['lastBodyCondition'] as int?,
      overallStatus: HealthStatus.fromString(json['overallStatus'] as String? ?? 'good'),
    );
  }
}

enum HealthStatus {
  excellent,
  good,
  needsAttention,
  critical;

  String get displayName {
    switch (this) {
      case HealthStatus.excellent: return 'Excellent';
      case HealthStatus.good: return 'Bon';
      case HealthStatus.needsAttention: return 'À surveiller';
      case HealthStatus.critical: return 'Critique';
    }
  }

  int get color {
    switch (this) {
      case HealthStatus.excellent: return 0xFF4CAF50;
      case HealthStatus.good: return 0xFF8BC34A;
      case HealthStatus.needsAttention: return 0xFFFF9800;
      case HealthStatus.critical: return 0xFFF44336;
    }
  }

  static HealthStatus fromString(String value) {
    return HealthStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthStatus.good,
    );
  }
}
