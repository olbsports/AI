/// Breeding recommendation model for "poulinage" feature
class BreedingRecommendation {
  final String id;
  final String mareId;
  final String mareName;
  final String? stallionId;
  final String stallionName;
  final String stallionStudbook;
  final double compatibilityScore; // 0-100
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> expectedTraits;
  final Map<String, double> disciplineScores; // discipline -> expected score
  final String? reasoning;
  final DateTime createdAt;

  BreedingRecommendation({
    required this.id,
    required this.mareId,
    required this.mareName,
    this.stallionId,
    required this.stallionName,
    required this.stallionStudbook,
    required this.compatibilityScore,
    this.strengths = const [],
    this.weaknesses = const [],
    this.expectedTraits = const [],
    this.disciplineScores = const {},
    this.reasoning,
    required this.createdAt,
  });

  factory BreedingRecommendation.fromJson(Map<String, dynamic> json) {
    return BreedingRecommendation(
      id: json['id'] as String? ?? '',
      mareId: json['mareId'] as String? ?? '',
      mareName: json['mareName'] as String? ?? '',
      stallionId: json['stallionId'] as String?,
      stallionName: json['stallionName'] as String? ?? '',
      stallionStudbook: json['stallionStudbook'] as String? ?? '',
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
      strengths: (json['strengths'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      weaknesses: (json['weaknesses'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      expectedTraits: (json['expectedTraits'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      disciplineScores: (json['disciplineScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0)) ??
          {},
      reasoning: json['reasoning'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Mare profile for breeding analysis
class MareProfile {
  final String id;
  final String name;
  final String breed;
  final String? studbook; // SIRE, SF, AA, PS, etc.
  final String? sireId;
  final String? sireName;
  final String? damId;
  final String? damName;
  final String? damSireId;
  final String? damSireName;
  final int? birthYear;
  final int? heightCm;
  final String? color;
  final List<String> conformationStrengths;
  final List<String> conformationWeaknesses;
  final List<String> performanceHistory;
  final BreedingGoal breedingGoal;
  final List<String> targetDisciplines;
  final String? geneticProfile; // If DNA tested
  final Map<String, dynamic>? healthData;

  MareProfile({
    required this.id,
    required this.name,
    required this.breed,
    this.studbook,
    this.sireId,
    this.sireName,
    this.damId,
    this.damName,
    this.damSireId,
    this.damSireName,
    this.birthYear,
    this.heightCm,
    this.color,
    this.conformationStrengths = const [],
    this.conformationWeaknesses = const [],
    this.performanceHistory = const [],
    this.breedingGoal = BreedingGoal.sport,
    this.targetDisciplines = const [],
    this.geneticProfile,
    this.healthData,
  });

  factory MareProfile.fromJson(Map<String, dynamic> json) {
    return MareProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? 'Inconnu',
      studbook: json['studbook'] as String?,
      sireId: json['sireId'] as String?,
      sireName: json['sireName'] as String?,
      damId: json['damId'] as String?,
      damName: json['damName'] as String?,
      damSireId: json['damSireId'] as String?,
      damSireName: json['damSireName'] as String?,
      birthYear: (json['birthYear'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toInt(),
      color: json['color'] as String?,
      conformationStrengths: (json['conformationStrengths'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      conformationWeaknesses: (json['conformationWeaknesses'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      performanceHistory: (json['performanceHistory'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      breedingGoal: BreedingGoal.fromString(json['breedingGoal'] as String? ?? 'sport'),
      targetDisciplines: (json['targetDisciplines'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      geneticProfile: json['geneticProfile'] as String?,
      healthData: json['healthData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'studbook': studbook,
      'sireId': sireId,
      'sireName': sireName,
      'damId': damId,
      'damName': damName,
      'damSireId': damSireId,
      'damSireName': damSireName,
      'birthYear': birthYear,
      'heightCm': heightCm,
      'color': color,
      'conformationStrengths': conformationStrengths,
      'conformationWeaknesses': conformationWeaknesses,
      'performanceHistory': performanceHistory,
      'breedingGoal': breedingGoal.name,
      'targetDisciplines': targetDisciplines,
      'geneticProfile': geneticProfile,
      'healthData': healthData,
    };
  }
}

/// Stallion from database
class Stallion {
  final String id;
  final String name;
  final String breed;
  final String studbook;
  final String? sireId;
  final String sireName;
  final String? damSireId;
  final String damSireName;
  final int? birthYear;
  final int? heightCm;
  final String? color;
  final String? stationName; // Breeding station
  final String? stationLocation;
  final int? studFee; // Prix de saillie
  final bool freshSemen;
  final bool frozenSemen;
  final bool naturalService;
  final List<String> disciplines;
  final Map<String, double> indices; // ISO, IDR, etc.
  final int? offspringCount;
  final List<String> notableOffspring;
  final String? photoUrl;
  final String? videoUrl;
  final String? description;

  Stallion({
    required this.id,
    required this.name,
    required this.breed,
    required this.studbook,
    this.sireId,
    required this.sireName,
    this.damSireId,
    required this.damSireName,
    this.birthYear,
    this.heightCm,
    this.color,
    this.stationName,
    this.stationLocation,
    this.studFee,
    this.freshSemen = false,
    this.frozenSemen = false,
    this.naturalService = false,
    this.disciplines = const [],
    this.indices = const {},
    this.offspringCount,
    this.notableOffspring = const [],
    this.photoUrl,
    this.videoUrl,
    this.description,
  });

  String get availabilityText {
    final options = <String>[];
    if (freshSemen) options.add('Frais');
    if (frozenSemen) options.add('Congelé');
    if (naturalService) options.add('Monte naturelle');
    return options.isEmpty ? 'Non disponible' : options.join(', ');
  }

  factory Stallion.fromJson(Map<String, dynamic> json) {
    return Stallion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      studbook: json['studbook'] as String? ?? '',
      sireId: json['sireId'] as String?,
      sireName: json['sireName'] as String? ?? 'Inconnu',
      damSireId: json['damSireId'] as String?,
      damSireName: json['damSireName'] as String? ?? 'Inconnu',
      birthYear: (json['birthYear'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toInt(),
      color: json['color'] as String?,
      stationName: json['stationName'] as String?,
      stationLocation: json['stationLocation'] as String?,
      studFee: (json['studFee'] as num?)?.toInt(),
      freshSemen: json['freshSemen'] as bool? ?? false,
      frozenSemen: json['frozenSemen'] as bool? ?? false,
      naturalService: json['naturalService'] as bool? ?? false,
      disciplines: (json['disciplines'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      indices: (json['indices'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0)) ??
          {},
      offspringCount: (json['offspringCount'] as num?)?.toInt(),
      notableOffspring: (json['notableOffspring'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      photoUrl: json['photoUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Breeding goal
enum BreedingGoal {
  sport,      // Performance sportive
  loisir,     // Leisure riding
  elevage,    // Breeding stock
  competition; // High-level competition

  String get displayName {
    switch (this) {
      case BreedingGoal.sport:
        return 'Sport';
      case BreedingGoal.loisir:
        return 'Loisir';
      case BreedingGoal.elevage:
        return 'Élevage';
      case BreedingGoal.competition:
        return 'Haute compétition';
    }
  }

  static BreedingGoal fromString(String value) {
    return BreedingGoal.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BreedingGoal.sport,
    );
  }
}

/// Common French studbooks
class Studbook {
  static const String sf = 'SF';        // Selle Français
  static const String aa = 'AA';        // Anglo-Arabe
  static const String ps = 'PS';        // Pur-Sang
  static const String ar = 'AR';        // Arabe
  static const String co = 'CO';        // Connemara
  static const String pfs = 'PFS';      // Poney Français de Selle
  static const String kwpn = 'KWPN';    // Dutch Warmblood
  static const String bwp = 'BWP';      // Belgian Warmblood
  static const String holst = 'HOLST';  // Holsteiner
  static const String hann = 'HANN';    // Hanoverian
  static const String oldb = 'OLDB';    // Oldenburg
  static const String westf = 'WESTF';  // Westphalian

  static const List<String> all = [
    sf, aa, ps, ar, co, pfs, kwpn, bwp, holst, hann, oldb, westf
  ];

  static String getDisplayName(String code) {
    switch (code) {
      case sf: return 'Selle Français';
      case aa: return 'Anglo-Arabe';
      case ps: return 'Pur-Sang';
      case ar: return 'Arabe';
      case co: return 'Connemara';
      case pfs: return 'Poney Français de Selle';
      case kwpn: return 'KWPN (Hollandais)';
      case bwp: return 'BWP (Belge)';
      case holst: return 'Holsteiner';
      case hann: return 'Hanovrien';
      case oldb: return 'Oldenburg';
      case westf: return 'Westphalien';
      default: return code;
    }
  }
}
