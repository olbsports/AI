/// Complete Gestation & Birth Tracking System for Horse Tempo

import 'package:flutter/material.dart';

// ============================================
// GESTATION TRACKING
// ============================================

/// Complete gestation record for a mare
class GestationRecord {
  final String id;
  final String mareId;
  final String mareName;
  final String? stallionId;
  final String? stallionName;
  final String? stallionUeln;
  final ConceptionMethod conceptionMethod;
  final DateTime conceptionDate;
  final DateTime expectedDueDate;
  final DateTime? actualBirthDate;
  final GestationStatus status;
  final int currentDayOfGestation;
  final List<GestationCheckup> checkups;
  final List<GestationMilestone> milestones;
  final List<GestationNote> notes;
  final String? veterinarianId;
  final String? veterinarianName;
  final String? clinicName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GestationRecord({
    required this.id,
    required this.mareId,
    required this.mareName,
    this.stallionId,
    this.stallionName,
    this.stallionUeln,
    required this.conceptionMethod,
    required this.conceptionDate,
    required this.expectedDueDate,
    this.actualBirthDate,
    this.status = GestationStatus.confirmed,
    this.currentDayOfGestation = 0,
    this.checkups = const [],
    this.milestones = const [],
    this.notes = const [],
    this.veterinarianId,
    this.veterinarianName,
    this.clinicName,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Standard gestation period is 340 days (11 months)
  static const int standardGestationDays = 340;
  static const int minGestationDays = 320;
  static const int maxGestationDays = 370;

  int get daysRemaining => expectedDueDate.difference(DateTime.now()).inDays;
  int get daysOfGestation => DateTime.now().difference(conceptionDate).inDays;
  double get progressPercent => (daysOfGestation / standardGestationDays).clamp(0, 1);
  int get currentMonth => (daysOfGestation / 30).ceil();
  int get currentWeek => (daysOfGestation / 7).ceil();
  bool get isOverdue => daysRemaining < 0 && status == GestationStatus.confirmed;

  String get trimester {
    if (currentMonth <= 4) return 'Premier trimestre';
    if (currentMonth <= 8) return 'Deuxième trimestre';
    return 'Troisième trimestre';
  }

  factory GestationRecord.fromJson(Map<String, dynamic> json) {
    return GestationRecord(
      id: json['id'] as String,
      mareId: json['mareId'] as String,
      mareName: json['mareName'] as String? ?? '',
      stallionId: json['stallionId'] as String?,
      stallionName: json['stallionName'] as String?,
      stallionUeln: json['stallionUeln'] as String?,
      conceptionMethod: ConceptionMethod.fromString(json['conceptionMethod'] as String),
      conceptionDate: DateTime.parse(json['conceptionDate'] as String),
      expectedDueDate: DateTime.parse(json['expectedDueDate'] as String),
      actualBirthDate: json['actualBirthDate'] != null
          ? DateTime.parse(json['actualBirthDate'] as String)
          : null,
      status: GestationStatus.fromString(json['status'] as String? ?? 'confirmed'),
      currentDayOfGestation: json['currentDayOfGestation'] as int? ?? 0,
      checkups: (json['checkups'] as List?)
          ?.map((c) => GestationCheckup.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      milestones: (json['milestones'] as List?)
          ?.map((m) => GestationMilestone.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      notes: (json['notes'] as List?)
          ?.map((n) => GestationNote.fromJson(n as Map<String, dynamic>))
          .toList() ?? [],
      veterinarianId: json['veterinarianId'] as String?,
      veterinarianName: json['veterinarianName'] as String?,
      clinicName: json['clinicName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mareId': mareId,
      'stallionId': stallionId,
      'stallionName': stallionName,
      'stallionUeln': stallionUeln,
      'conceptionMethod': conceptionMethod.name,
      'conceptionDate': conceptionDate.toIso8601String(),
      'expectedDueDate': expectedDueDate.toIso8601String(),
      'actualBirthDate': actualBirthDate?.toIso8601String(),
      'status': status.name,
      'veterinarianId': veterinarianId,
      'clinicName': clinicName,
      'metadata': metadata,
    };
  }
}

/// Conception methods
enum ConceptionMethod {
  naturalBreeding,   // Monte naturelle
  artificialFresh,   // Insémination fraîche
  artificialFrozen,  // Insémination congelée
  embryoTransfer;    // Transfert d'embryon

  String get displayName {
    switch (this) {
      case ConceptionMethod.naturalBreeding: return 'Monte naturelle';
      case ConceptionMethod.artificialFresh: return 'IA fraîche';
      case ConceptionMethod.artificialFrozen: return 'IA congelée';
      case ConceptionMethod.embryoTransfer: return 'Transfert d\'embryon';
    }
  }

  static ConceptionMethod fromString(String value) {
    return ConceptionMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConceptionMethod.naturalBreeding,
    );
  }
}

/// Gestation status
enum GestationStatus {
  suspected,   // Suspectée
  confirmed,   // Confirmée
  atRisk,      // À risque
  loss,        // Perte
  born;        // Naissance

  String get displayName {
    switch (this) {
      case GestationStatus.suspected: return 'Suspectée';
      case GestationStatus.confirmed: return 'Confirmée';
      case GestationStatus.atRisk: return 'À risque';
      case GestationStatus.loss: return 'Perte';
      case GestationStatus.born: return 'Naissance';
    }
  }

  int get color {
    switch (this) {
      case GestationStatus.suspected: return 0xFFFF9800;
      case GestationStatus.confirmed: return 0xFF4CAF50;
      case GestationStatus.atRisk: return 0xFFF44336;
      case GestationStatus.loss: return 0xFF9E9E9E;
      case GestationStatus.born: return 0xFF2196F3;
    }
  }

  static GestationStatus fromString(String value) {
    return GestationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GestationStatus.suspected,
    );
  }
}

// ============================================
// GESTATION CHECKUPS
// ============================================

/// Veterinary checkup during gestation
class GestationCheckup {
  final String id;
  final String gestationId;
  final DateTime date;
  final GestationCheckupType type;
  final String? veterinarianName;
  final String? clinicName;
  final CheckupResult result;
  final String? notes;
  final List<String> attachments;
  final Map<String, dynamic>? measurements;
  final DateTime? nextCheckupDate;
  final double? cost;

  GestationCheckup({
    required this.id,
    required this.gestationId,
    required this.date,
    required this.type,
    this.veterinarianName,
    this.clinicName,
    this.result = CheckupResult.normal,
    this.notes,
    this.attachments = const [],
    this.measurements,
    this.nextCheckupDate,
    this.cost,
  });

  factory GestationCheckup.fromJson(Map<String, dynamic> json) {
    return GestationCheckup(
      id: json['id'] as String,
      gestationId: json['gestationId'] as String,
      date: DateTime.parse(json['date'] as String),
      type: GestationCheckupType.fromString(json['type'] as String),
      veterinarianName: json['veterinarianName'] as String?,
      clinicName: json['clinicName'] as String?,
      result: CheckupResult.fromString(json['result'] as String? ?? 'normal'),
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      measurements: json['measurements'] as Map<String, dynamic>?,
      nextCheckupDate: json['nextCheckupDate'] != null
          ? DateTime.parse(json['nextCheckupDate'] as String)
          : null,
      cost: (json['cost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gestationId': gestationId,
      'date': date.toIso8601String(),
      'type': type.name,
      'veterinarianName': veterinarianName,
      'clinicName': clinicName,
      'result': result.name,
      'notes': notes,
      'attachments': attachments,
      'measurements': measurements,
      'nextCheckupDate': nextCheckupDate?.toIso8601String(),
      'cost': cost,
    };
  }
}

/// Types of gestation checkups
enum GestationCheckupType {
  pregnancy14Days,   // Diagnostic 14-16 jours (écho)
  pregnancy30Days,   // Confirmation 30 jours
  pregnancy45Days,   // Contrôle 45 jours
  pregnancy90Days,   // Contrôle 3 mois
  pregnancy5Months,  // Contrôle 5 mois
  pregnancy7Months,  // Contrôle 7 mois
  pregnancy9Months,  // Contrôle 9 mois
  prefoaling,        // Contrôle pré-poulinage
  emergency,         // Urgence
  routine;           // Contrôle de routine

  String get displayName {
    switch (this) {
      case GestationCheckupType.pregnancy14Days: return 'Diagnostic 14 jours';
      case GestationCheckupType.pregnancy30Days: return 'Confirmation 30 jours';
      case GestationCheckupType.pregnancy45Days: return 'Contrôle 45 jours';
      case GestationCheckupType.pregnancy90Days: return 'Contrôle 3 mois';
      case GestationCheckupType.pregnancy5Months: return 'Contrôle 5 mois';
      case GestationCheckupType.pregnancy7Months: return 'Contrôle 7 mois';
      case GestationCheckupType.pregnancy9Months: return 'Contrôle 9 mois';
      case GestationCheckupType.prefoaling: return 'Pré-poulinage';
      case GestationCheckupType.emergency: return 'Urgence';
      case GestationCheckupType.routine: return 'Routine';
    }
  }

  /// Recommended day of gestation for this checkup
  int? get recommendedDay {
    switch (this) {
      case GestationCheckupType.pregnancy14Days: return 14;
      case GestationCheckupType.pregnancy30Days: return 30;
      case GestationCheckupType.pregnancy45Days: return 45;
      case GestationCheckupType.pregnancy90Days: return 90;
      case GestationCheckupType.pregnancy5Months: return 150;
      case GestationCheckupType.pregnancy7Months: return 210;
      case GestationCheckupType.pregnancy9Months: return 270;
      case GestationCheckupType.prefoaling: return 320;
      default: return null;
    }
  }

  static GestationCheckupType fromString(String value) {
    return GestationCheckupType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GestationCheckupType.routine,
    );
  }
}

/// Checkup result
enum CheckupResult {
  normal,
  concern,
  abnormal,
  critical;

  String get displayName {
    switch (this) {
      case CheckupResult.normal: return 'Normal';
      case CheckupResult.concern: return 'À surveiller';
      case CheckupResult.abnormal: return 'Anormal';
      case CheckupResult.critical: return 'Critique';
    }
  }

  int get color {
    switch (this) {
      case CheckupResult.normal: return 0xFF4CAF50;
      case CheckupResult.concern: return 0xFFFF9800;
      case CheckupResult.abnormal: return 0xFFFF5722;
      case CheckupResult.critical: return 0xFFF44336;
    }
  }

  static CheckupResult fromString(String value) {
    return CheckupResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CheckupResult.normal,
    );
  }
}

// ============================================
// GESTATION MILESTONES
// ============================================

/// Development milestone during gestation
class GestationMilestone {
  final String id;
  final int dayOfGestation;
  final String title;
  final String description;
  final MilestoneCategory category;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  GestationMilestone({
    required this.id,
    required this.dayOfGestation,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  factory GestationMilestone.fromJson(Map<String, dynamic> json) {
    return GestationMilestone(
      id: json['id'] as String,
      dayOfGestation: json['dayOfGestation'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: MilestoneCategory.fromString(json['category'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

enum MilestoneCategory {
  development,  // Développement fœtal
  checkup,      // Contrôle vétérinaire
  nutrition,    // Alimentation
  preparation,  // Préparation poulinage
  vaccination;  // Vaccination

  String get displayName {
    switch (this) {
      case MilestoneCategory.development: return 'Développement';
      case MilestoneCategory.checkup: return 'Contrôle';
      case MilestoneCategory.nutrition: return 'Nutrition';
      case MilestoneCategory.preparation: return 'Préparation';
      case MilestoneCategory.vaccination: return 'Vaccination';
    }
  }

  static MilestoneCategory fromString(String value) {
    return MilestoneCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MilestoneCategory.development,
    );
  }
}

/// Standard gestation milestones
class GestationMilestones {
  static final List<Map<String, dynamic>> standard = [
    {'day': 14, 'title': 'Diagnostic échographique', 'category': 'checkup', 'description': 'Première échographie pour confirmer la gestation'},
    {'day': 21, 'title': 'Battements cardiaques', 'category': 'development', 'description': 'Le cœur du fœtus commence à battre'},
    {'day': 30, 'title': 'Confirmation gestation', 'category': 'checkup', 'description': 'Échographie de confirmation, vérification des jumeaux'},
    {'day': 45, 'title': 'Fin période critique', 'category': 'development', 'description': 'Fin de la période à haut risque de perte'},
    {'day': 60, 'title': 'Sexage possible', 'category': 'checkup', 'description': 'Le sexe du poulain peut être déterminé par échographie'},
    {'day': 90, 'title': 'Contrôle 3 mois', 'category': 'checkup', 'description': 'Contrôle de routine, mesures de croissance'},
    {'day': 100, 'title': 'Augmentation ration', 'category': 'nutrition', 'description': 'Commencer à augmenter progressivement la ration'},
    {'day': 150, 'title': 'Contrôle 5 mois', 'category': 'checkup', 'description': 'Échographie de contrôle mi-gestation'},
    {'day': 210, 'title': 'Contrôle 7 mois', 'category': 'checkup', 'description': 'Vérification du développement fœtal'},
    {'day': 270, 'title': 'Vaccin grippe-tétanos', 'category': 'vaccination', 'description': 'Rappel vaccinal pour transmettre les anticorps au poulain'},
    {'day': 300, 'title': 'Préparation box poulinage', 'category': 'preparation', 'description': 'Préparer le box de poulinage, caméra de surveillance'},
    {'day': 310, 'title': 'Bandage queue', 'category': 'preparation', 'description': 'Commencer le bandage de la queue'},
    {'day': 320, 'title': 'Surveillance rapprochée', 'category': 'preparation', 'description': 'Surveillance 24h/24, test de sécrétion mammaire'},
    {'day': 330, 'title': 'Signes pré-poulinage', 'category': 'preparation', 'description': 'Observer relâchement des ligaments, développement mamelle'},
  ];
}

// ============================================
// GESTATION NOTES
// ============================================

/// Note about the gestation
class GestationNote {
  final String id;
  final String gestationId;
  final String content;
  final NoteType type;
  final String? authorId;
  final String? authorName;
  final List<String> attachments;
  final DateTime createdAt;

  GestationNote({
    required this.id,
    required this.gestationId,
    required this.content,
    this.type = NoteType.general,
    this.authorId,
    this.authorName,
    this.attachments = const [],
    required this.createdAt,
  });

  factory GestationNote.fromJson(Map<String, dynamic> json) {
    return GestationNote(
      id: json['id'] as String,
      gestationId: json['gestationId'] as String,
      content: json['content'] as String,
      type: NoteType.fromString(json['type'] as String? ?? 'general'),
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum NoteType {
  general,
  observation,
  medical,
  feeding,
  behavior,
  alert;

  IconData get icon {
    switch (this) {
      case NoteType.general: return Icons.note;
      case NoteType.observation: return Icons.visibility;
      case NoteType.medical: return Icons.medical_services;
      case NoteType.feeding: return Icons.restaurant;
      case NoteType.behavior: return Icons.psychology;
      case NoteType.alert: return Icons.warning;
    }
  }

  static NoteType fromString(String value) {
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.general,
    );
  }
}

// ============================================
// BIRTH RECORDS
// ============================================

/// Complete birth record
class BirthRecord {
  final String id;
  final String gestationId;
  final String mareId;
  final String mareName;
  final String? stallionId;
  final String? stallionName;
  final String? foalId;
  final String foalName;
  final DateTime birthDate;
  final TimeOfDay? birthTime;
  final int gestationDays;
  final FoalSex sex;
  final String? color;
  final double? birthWeight; // kg
  final double? height; // cm
  final BirthType birthType;
  final BirthDifficulty difficulty;
  final bool assistanceRequired;
  final String? assistedBy;
  final String? veterinarianName;
  final List<BirthComplication> complications;
  final FoalHealth initialHealth;
  final String? notes;
  final List<String> photos;
  final DateTime? firstStandTime;
  final DateTime? firstNursingTime;
  final DateTime? placentaPassedTime;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  BirthRecord({
    required this.id,
    required this.gestationId,
    required this.mareId,
    required this.mareName,
    this.stallionId,
    this.stallionName,
    this.foalId,
    required this.foalName,
    required this.birthDate,
    this.birthTime,
    required this.gestationDays,
    required this.sex,
    this.color,
    this.birthWeight,
    this.height,
    this.birthType = BirthType.vaginal,
    this.difficulty = BirthDifficulty.normal,
    this.assistanceRequired = false,
    this.assistedBy,
    this.veterinarianName,
    this.complications = const [],
    this.initialHealth = FoalHealth.excellent,
    this.notes,
    this.photos = const [],
    this.firstStandTime,
    this.firstNursingTime,
    this.placentaPassedTime,
    this.metadata,
    required this.createdAt,
  });

  /// Foal should stand within 1 hour
  bool get stoodOnTime => firstStandTime != null &&
      firstStandTime!.difference(birthDate).inMinutes <= 60;

  /// Foal should nurse within 2 hours
  bool get nursedOnTime => firstNursingTime != null &&
      firstNursingTime!.difference(birthDate).inMinutes <= 120;

  /// Placenta should pass within 3 hours
  bool get placentaPassedOnTime => placentaPassedTime != null &&
      placentaPassedTime!.difference(birthDate).inMinutes <= 180;

  factory BirthRecord.fromJson(Map<String, dynamic> json) {
    return BirthRecord(
      id: json['id'] as String,
      gestationId: json['gestationId'] as String,
      mareId: json['mareId'] as String,
      mareName: json['mareName'] as String? ?? '',
      stallionId: json['stallionId'] as String?,
      stallionName: json['stallionName'] as String?,
      foalId: json['foalId'] as String?,
      foalName: json['foalName'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthTime: json['birthTime'] != null
          ? TimeOfDay(
              hour: int.parse((json['birthTime'] as String).split(':')[0]),
              minute: int.parse((json['birthTime'] as String).split(':')[1]),
            )
          : null,
      gestationDays: json['gestationDays'] as int,
      sex: FoalSex.fromString(json['sex'] as String),
      color: json['color'] as String?,
      birthWeight: (json['birthWeight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      birthType: BirthType.fromString(json['birthType'] as String? ?? 'vaginal'),
      difficulty: BirthDifficulty.fromString(json['difficulty'] as String? ?? 'normal'),
      assistanceRequired: json['assistanceRequired'] as bool? ?? false,
      assistedBy: json['assistedBy'] as String?,
      veterinarianName: json['veterinarianName'] as String?,
      complications: (json['complications'] as List?)
          ?.map((c) => BirthComplication.fromString(c as String))
          .toList() ?? [],
      initialHealth: FoalHealth.fromString(json['initialHealth'] as String? ?? 'excellent'),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      firstStandTime: json['firstStandTime'] != null
          ? DateTime.parse(json['firstStandTime'] as String)
          : null,
      firstNursingTime: json['firstNursingTime'] != null
          ? DateTime.parse(json['firstNursingTime'] as String)
          : null,
      placentaPassedTime: json['placentaPassedTime'] != null
          ? DateTime.parse(json['placentaPassedTime'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gestationId': gestationId,
      'mareId': mareId,
      'stallionId': stallionId,
      'foalId': foalId,
      'foalName': foalName,
      'birthDate': birthDate.toIso8601String(),
      'birthTime': birthTime != null ? '${birthTime!.hour}:${birthTime!.minute}' : null,
      'gestationDays': gestationDays,
      'sex': sex.name,
      'color': color,
      'birthWeight': birthWeight,
      'height': height,
      'birthType': birthType.name,
      'difficulty': difficulty.name,
      'assistanceRequired': assistanceRequired,
      'assistedBy': assistedBy,
      'veterinarianName': veterinarianName,
      'complications': complications.map((c) => c.name).toList(),
      'initialHealth': initialHealth.name,
      'notes': notes,
      'photos': photos,
      'firstStandTime': firstStandTime?.toIso8601String(),
      'firstNursingTime': firstNursingTime?.toIso8601String(),
      'placentaPassedTime': placentaPassedTime?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Foal sex
enum FoalSex {
  male,     // Mâle
  female;   // Femelle

  String get displayName {
    switch (this) {
      case FoalSex.male: return 'Mâle';
      case FoalSex.female: return 'Femelle';
    }
  }

  static FoalSex fromString(String value) {
    return FoalSex.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FoalSex.male,
    );
  }
}

/// Birth type
enum BirthType {
  vaginal,        // Naissance naturelle
  assistedVaginal, // Naissance assistée
  cesarean;       // Césarienne

  String get displayName {
    switch (this) {
      case BirthType.vaginal: return 'Naturelle';
      case BirthType.assistedVaginal: return 'Assistée';
      case BirthType.cesarean: return 'Césarienne';
    }
  }

  static BirthType fromString(String value) {
    return BirthType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BirthType.vaginal,
    );
  }
}

/// Birth difficulty
enum BirthDifficulty {
  easy,       // Facile
  normal,     // Normal
  difficult,  // Difficile
  emergency;  // Urgence

  String get displayName {
    switch (this) {
      case BirthDifficulty.easy: return 'Facile';
      case BirthDifficulty.normal: return 'Normal';
      case BirthDifficulty.difficult: return 'Difficile';
      case BirthDifficulty.emergency: return 'Urgence';
    }
  }

  int get color {
    switch (this) {
      case BirthDifficulty.easy: return 0xFF4CAF50;
      case BirthDifficulty.normal: return 0xFF8BC34A;
      case BirthDifficulty.difficult: return 0xFFFF9800;
      case BirthDifficulty.emergency: return 0xFFF44336;
    }
  }

  static BirthDifficulty fromString(String value) {
    return BirthDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BirthDifficulty.normal,
    );
  }
}

/// Birth complications
enum BirthComplication {
  dystocia,           // Dystocie
  malpresentation,    // Mauvaise présentation
  premature,          // Prématuré
  placentaRetention,  // Rétention placentaire
  hemorrhage,         // Hémorragie
  laceration,         // Lacération
  weakFoal,           // Poulain faible
  meconiumAspiration, // Aspiration méconium
  failure,            // Échec allaitement
  hypothermia,        // Hypothermie
  infection,          // Infection
  other;

  String get displayName {
    switch (this) {
      case BirthComplication.dystocia: return 'Dystocie';
      case BirthComplication.malpresentation: return 'Mauvaise présentation';
      case BirthComplication.premature: return 'Prématuré';
      case BirthComplication.placentaRetention: return 'Rétention placentaire';
      case BirthComplication.hemorrhage: return 'Hémorragie';
      case BirthComplication.laceration: return 'Lacération';
      case BirthComplication.weakFoal: return 'Poulain faible';
      case BirthComplication.meconiumAspiration: return 'Aspiration méconium';
      case BirthComplication.failure: return 'Échec allaitement';
      case BirthComplication.hypothermia: return 'Hypothermie';
      case BirthComplication.infection: return 'Infection';
      case BirthComplication.other: return 'Autre';
    }
  }

  static BirthComplication fromString(String value) {
    return BirthComplication.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BirthComplication.other,
    );
  }
}

/// Initial foal health assessment
enum FoalHealth {
  excellent,
  good,
  fair,
  poor,
  critical;

  String get displayName {
    switch (this) {
      case FoalHealth.excellent: return 'Excellent';
      case FoalHealth.good: return 'Bon';
      case FoalHealth.fair: return 'Moyen';
      case FoalHealth.poor: return 'Faible';
      case FoalHealth.critical: return 'Critique';
    }
  }

  int get color {
    switch (this) {
      case FoalHealth.excellent: return 0xFF4CAF50;
      case FoalHealth.good: return 0xFF8BC34A;
      case FoalHealth.fair: return 0xFFFF9800;
      case FoalHealth.poor: return 0xFFFF5722;
      case FoalHealth.critical: return 0xFFF44336;
    }
  }

  static FoalHealth fromString(String value) {
    return FoalHealth.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FoalHealth.good,
    );
  }
}

// ============================================
// FOAL DEVELOPMENT TRACKING
// ============================================

/// Foal development record
class FoalDevelopment {
  final String id;
  final String foalId;
  final String foalName;
  final DateTime recordDate;
  final int ageInDays;
  final double? weight;
  final double? height;
  final double? chestGirth;
  final double? cannonBone;
  final DevelopmentStatus status;
  final List<String> achievements;
  final String? notes;
  final List<String> photos;
  final DateTime createdAt;

  FoalDevelopment({
    required this.id,
    required this.foalId,
    required this.foalName,
    required this.recordDate,
    required this.ageInDays,
    this.weight,
    this.height,
    this.chestGirth,
    this.cannonBone,
    this.status = DevelopmentStatus.onTrack,
    this.achievements = const [],
    this.notes,
    this.photos = const [],
    required this.createdAt,
  });

  int get ageInWeeks => ageInDays ~/ 7;
  int get ageInMonths => ageInDays ~/ 30;

  factory FoalDevelopment.fromJson(Map<String, dynamic> json) {
    return FoalDevelopment(
      id: json['id'] as String,
      foalId: json['foalId'] as String,
      foalName: json['foalName'] as String? ?? '',
      recordDate: DateTime.parse(json['recordDate'] as String),
      ageInDays: json['ageInDays'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      chestGirth: (json['chestGirth'] as num?)?.toDouble(),
      cannonBone: (json['cannonBone'] as num?)?.toDouble(),
      status: DevelopmentStatus.fromString(json['status'] as String? ?? 'onTrack'),
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum DevelopmentStatus {
  excellent,
  onTrack,
  slightlyBehind,
  needsAttention,
  critical;

  String get displayName {
    switch (this) {
      case DevelopmentStatus.excellent: return 'Excellent';
      case DevelopmentStatus.onTrack: return 'Normal';
      case DevelopmentStatus.slightlyBehind: return 'Légèrement en retard';
      case DevelopmentStatus.needsAttention: return 'À surveiller';
      case DevelopmentStatus.critical: return 'Critique';
    }
  }

  static DevelopmentStatus fromString(String value) {
    return DevelopmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DevelopmentStatus.onTrack,
    );
  }
}

/// Standard foal development milestones
class FoalMilestones {
  static final List<Map<String, dynamic>> standard = [
    {'ageMinutes': 30, 'title': 'Se lève', 'description': 'Le poulain se met debout pour la première fois'},
    {'ageMinutes': 120, 'title': 'Première tétée', 'description': 'Le poulain tète le colostrum'},
    {'ageHours': 4, 'title': 'Expulsion méconium', 'description': 'Premier crottin (méconium)'},
    {'ageDays': 1, 'title': 'Examen vétérinaire', 'description': 'Premier examen néonatal'},
    {'ageDays': 7, 'title': 'Premiers pas dehors', 'description': 'Première sortie en paddock'},
    {'ageDays': 14, 'title': 'Début alimentation', 'description': 'Commence à goûter le foin/herbe'},
    {'ageWeeks': 4, 'title': 'Première vermifugation', 'description': 'Premier traitement antiparasitaire'},
    {'ageMonths': 2, 'title': 'Manipulation', 'description': 'Début manipulation pied, licol'},
    {'ageMonths': 4, 'title': 'Sevrage possible', 'description': 'Âge minimum pour le sevrage'},
    {'ageMonths': 6, 'title': 'Sevrage recommandé', 'description': 'Âge optimal pour le sevrage'},
    {'ageMonths': 6, 'title': 'Vaccination', 'description': 'Premières vaccinations'},
  ];
}

// ============================================
// BREEDING STATISTICS
// ============================================

/// Breeding statistics for a user/stable
class BreedingStats {
  final String userId;
  final int totalGestations;
  final int activeGestations;
  final int successfulBirths;
  final int lostPregnancies;
  final double successRate;
  final int totalFoals;
  final int maleFoals;
  final int femaleFoals;
  final double averageGestationDays;
  final Map<String, int> birthsByYear;
  final DateTime calculatedAt;

  BreedingStats({
    required this.userId,
    this.totalGestations = 0,
    this.activeGestations = 0,
    this.successfulBirths = 0,
    this.lostPregnancies = 0,
    this.successRate = 0,
    this.totalFoals = 0,
    this.maleFoals = 0,
    this.femaleFoals = 0,
    this.averageGestationDays = 340,
    this.birthsByYear = const {},
    required this.calculatedAt,
  });

  factory BreedingStats.fromJson(Map<String, dynamic> json) {
    return BreedingStats(
      userId: json['userId'] as String,
      totalGestations: json['totalGestations'] as int? ?? 0,
      activeGestations: json['activeGestations'] as int? ?? 0,
      successfulBirths: json['successfulBirths'] as int? ?? 0,
      lostPregnancies: json['lostPregnancies'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0,
      totalFoals: json['totalFoals'] as int? ?? 0,
      maleFoals: json['maleFoals'] as int? ?? 0,
      femaleFoals: json['femaleFoals'] as int? ?? 0,
      averageGestationDays: (json['averageGestationDays'] as num?)?.toDouble() ?? 340,
      birthsByYear: (json['birthsByYear'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {},
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}
