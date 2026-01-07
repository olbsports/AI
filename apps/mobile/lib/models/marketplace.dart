import 'leaderboard.dart';

/// Marketplace listing types
enum ListingType {
  mareForBreeding,    // Jument disponible pour poulinage
  stallionSemen,      // Semence d'étalon disponible
  horseForSale,       // Cheval à vendre
  horseForLease,      // Cheval à louer
  foalForSale,        // Poulain à vendre
  embryo;             // Embryon disponible

  String get displayName {
    switch (this) {
      case ListingType.mareForBreeding:
        return 'Jument pour poulinage';
      case ListingType.stallionSemen:
        return 'Semence d\'étalon';
      case ListingType.horseForSale:
        return 'Cheval à vendre';
      case ListingType.horseForLease:
        return 'Cheval à louer';
      case ListingType.foalForSale:
        return 'Poulain à vendre';
      case ListingType.embryo:
        return 'Embryon';
    }
  }

  String get icon {
    switch (this) {
      case ListingType.mareForBreeding:
        return '🐴♀️';
      case ListingType.stallionSemen:
        return '🧬';
      case ListingType.horseForSale:
        return '🏷️';
      case ListingType.horseForLease:
        return '📋';
      case ListingType.foalForSale:
        return '🐎';
      case ListingType.embryo:
        return '🥚';
    }
  }
}

/// Listing status
enum ListingStatus {
  draft,
  active,
  pending,     // En attente de validation
  reserved,    // Réservé
  sold,        // Vendu
  expired,
  cancelled;

  String get displayName {
    switch (this) {
      case ListingStatus.draft:
        return 'Brouillon';
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.pending:
        return 'En attente';
      case ListingStatus.reserved:
        return 'Réservé';
      case ListingStatus.sold:
        return 'Vendu';
      case ListingStatus.expired:
        return 'Expirée';
      case ListingStatus.cancelled:
        return 'Annulée';
    }
  }
}

/// Base marketplace listing
class MarketplaceListing {
  final String id;
  final ListingType type;
  final ListingStatus status;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String? sellerLocation;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final String title;
  final String description;
  final int? price; // null = sur demande
  final bool priceNegotiable;
  final String? currency;
  final List<String> mediaUrls;
  final String? videoUrl;
  final int viewCount;
  final int favoriteCount;
  final int contactCount;
  final bool isFavorited;
  final bool isVerified; // Annonce vérifiée
  final bool isPremium;  // Mise en avant
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  MarketplaceListing({
    required this.id,
    required this.type,
    this.status = ListingStatus.active,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    this.sellerLocation,
    this.sellerLatitude,
    this.sellerLongitude,
    required this.title,
    required this.description,
    this.price,
    this.priceNegotiable = false,
    this.currency = 'EUR',
    this.mediaUrls = const [],
    this.videoUrl,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.contactCount = 0,
    this.isFavorited = false,
    this.isVerified = false,
    this.isPremium = false,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  String get priceDisplay {
    if (price == null) return 'Sur demande';
    return '$price €${priceNegotiable ? ' (négociable)' : ''}';
  }

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      type: ListingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ListingType.horseForSale,
      ),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ListingStatus.active,
      ),
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      sellerPhotoUrl: json['sellerPhotoUrl'] as String?,
      sellerLocation: json['sellerLocation'] as String?,
      sellerLatitude: (json['sellerLatitude'] as num?)?.toDouble(),
      sellerLongitude: (json['sellerLongitude'] as num?)?.toDouble(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int?,
      priceNegotiable: json['priceNegotiable'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'EUR',
      mediaUrls: (json['mediaUrls'] as List?)?.cast<String>() ?? [],
      videoUrl: json['videoUrl'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      favoriteCount: json['favoriteCount'] as int? ?? json['_count']?['favorites'] as int? ?? 0,
      contactCount: json['contactCount'] as int? ?? 0,
      isFavorited: json['isFavorited'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Horse listing for sale with Argus & Histovec
class HorseSaleListing extends MarketplaceListing {
  final String horseId;
  final String horseName;
  final String? breed;
  final String? studbook;
  final int? birthYear;
  final String? gender;
  final int? heightCm;
  final String? color;
  final String? sireId;
  final String? sireName;
  final String? damId;
  final String? damName;
  final List<HorseDiscipline> disciplines;
  final String? level; // Club, Amateur, Pro
  final HorseArgus? argus;
  final HorseHistovec? histovec;
  final HorseAIProfile? aiProfile;

  HorseSaleListing({
    required super.id,
    required super.type,
    super.status,
    required super.sellerId,
    required super.sellerName,
    super.sellerPhotoUrl,
    super.sellerLocation,
    super.sellerLatitude,
    super.sellerLongitude,
    required super.title,
    required super.description,
    super.price,
    super.priceNegotiable,
    super.currency,
    super.mediaUrls,
    super.videoUrl,
    super.viewCount,
    super.favoriteCount,
    super.contactCount,
    super.isFavorited,
    super.isVerified,
    super.isPremium,
    required super.createdAt,
    super.expiresAt,
    super.metadata,
    required this.horseId,
    required this.horseName,
    this.breed,
    this.studbook,
    this.birthYear,
    this.gender,
    this.heightCm,
    this.color,
    this.sireId,
    this.sireName,
    this.damId,
    this.damName,
    this.disciplines = const [],
    this.level,
    this.argus,
    this.histovec,
    this.aiProfile,
  });

  int? get age => birthYear != null ? DateTime.now().year - birthYear! : null;
}

/// Breeding listing (mare or stallion semen)
class BreedingListing extends MarketplaceListing {
  final String horseId;
  final String horseName;
  final String? breed;
  final String? studbook;
  final int? birthYear;
  final String? color;
  final String? sireId;
  final String? sireName;
  final String? damId;
  final String? damName;
  final String? damSireId;
  final String? damSireName;
  // For stallions
  final bool freshSemen;
  final bool frozenSemen;
  final bool naturalService;
  final Map<String, double>? indices; // ISO, IDR, ICC
  final int? offspringCount;
  final List<String>? notableOffspring;
  // For mares
  final int? previousFoals;
  final bool embryoTransfer;
  final String? lastFoalingDate;
  // AI Analysis
  final HorseAIProfile? aiProfile;
  final List<String>? targetDisciplines;

  BreedingListing({
    required super.id,
    required super.type,
    super.status,
    required super.sellerId,
    required super.sellerName,
    super.sellerPhotoUrl,
    super.sellerLocation,
    super.sellerLatitude,
    super.sellerLongitude,
    required super.title,
    required super.description,
    super.price,
    super.priceNegotiable,
    super.currency,
    super.mediaUrls,
    super.videoUrl,
    super.viewCount,
    super.favoriteCount,
    super.contactCount,
    super.isFavorited,
    super.isVerified,
    super.isPremium,
    required super.createdAt,
    super.expiresAt,
    super.metadata,
    required this.horseId,
    required this.horseName,
    this.breed,
    this.studbook,
    this.birthYear,
    this.color,
    this.sireId,
    this.sireName,
    this.damId,
    this.damName,
    this.damSireId,
    this.damSireName,
    this.freshSemen = false,
    this.frozenSemen = false,
    this.naturalService = false,
    this.indices,
    this.offspringCount,
    this.notableOffspring,
    this.previousFoals,
    this.embryoTransfer = false,
    this.lastFoalingDate,
    this.aiProfile,
    this.targetDisciplines,
  });
}

/// Horse Argus - Price estimation like car Argus
class HorseArgus {
  final String id;
  final String horseId;
  final int estimatedMinPrice;
  final int estimatedMaxPrice;
  final int marketAveragePrice;
  final double confidenceScore; // 0-100
  final ArgusFactors factors;
  final List<ComparableHorse> comparables;
  final String? marketTrend; // up, down, stable
  final DateTime calculatedAt;
  final String? notes;

  HorseArgus({
    required this.id,
    required this.horseId,
    required this.estimatedMinPrice,
    required this.estimatedMaxPrice,
    required this.marketAveragePrice,
    required this.confidenceScore,
    required this.factors,
    this.comparables = const [],
    this.marketTrend,
    required this.calculatedAt,
    this.notes,
  });

  int get estimatedPrice => (estimatedMinPrice + estimatedMaxPrice) ~/ 2;

  String get priceRange => '$estimatedMinPrice € - $estimatedMaxPrice €';

  factory HorseArgus.fromJson(Map<String, dynamic> json) {
    return HorseArgus(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      estimatedMinPrice: json['estimatedMinPrice'] as int,
      estimatedMaxPrice: json['estimatedMaxPrice'] as int,
      marketAveragePrice: json['marketAveragePrice'] as int,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      factors: ArgusFactors.fromJson(json['factors'] as Map<String, dynamic>),
      comparables: (json['comparables'] as List?)
              ?.map((c) => ComparableHorse.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      marketTrend: json['marketTrend'] as String?,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}

/// Factors affecting Argus valuation
class ArgusFactors {
  final int ageImpact;           // -20% to +10%
  final int breedImpact;         // -10% to +30%
  final int levelImpact;         // -10% to +50%
  final int lineageImpact;       // 0% to +40%
  final int healthImpact;        // -30% to +10%
  final int conformationImpact;  // -20% to +20%
  final int locomotionImpact;    // -20% to +30%
  final int characterImpact;     // -15% to +15%
  final int competitionImpact;   // 0% to +50%
  final int trainingImpact;      // 0% to +20%

  ArgusFactors({
    this.ageImpact = 0,
    this.breedImpact = 0,
    this.levelImpact = 0,
    this.lineageImpact = 0,
    this.healthImpact = 0,
    this.conformationImpact = 0,
    this.locomotionImpact = 0,
    this.characterImpact = 0,
    this.competitionImpact = 0,
    this.trainingImpact = 0,
  });

  int get totalImpact =>
      ageImpact +
      breedImpact +
      levelImpact +
      lineageImpact +
      healthImpact +
      conformationImpact +
      locomotionImpact +
      characterImpact +
      competitionImpact +
      trainingImpact;

  factory ArgusFactors.fromJson(Map<String, dynamic> json) {
    return ArgusFactors(
      ageImpact: json['ageImpact'] as int? ?? 0,
      breedImpact: json['breedImpact'] as int? ?? 0,
      levelImpact: json['levelImpact'] as int? ?? 0,
      lineageImpact: json['lineageImpact'] as int? ?? 0,
      healthImpact: json['healthImpact'] as int? ?? 0,
      conformationImpact: json['conformationImpact'] as int? ?? 0,
      locomotionImpact: json['locomotionImpact'] as int? ?? 0,
      characterImpact: json['characterImpact'] as int? ?? 0,
      competitionImpact: json['competitionImpact'] as int? ?? 0,
      trainingImpact: json['trainingImpact'] as int? ?? 0,
    );
  }
}

/// Comparable horse for Argus
class ComparableHorse {
  final String id;
  final String name;
  final String? breed;
  final int? age;
  final String? level;
  final int soldPrice;
  final DateTime soldDate;
  final double similarityScore;

  ComparableHorse({
    required this.id,
    required this.name,
    this.breed,
    this.age,
    this.level,
    required this.soldPrice,
    required this.soldDate,
    required this.similarityScore,
  });

  factory ComparableHorse.fromJson(Map<String, dynamic> json) {
    return ComparableHorse(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String?,
      age: json['age'] as int?,
      level: json['level'] as String?,
      soldPrice: json['soldPrice'] as int,
      soldDate: DateTime.parse(json['soldDate'] as String),
      similarityScore: (json['similarityScore'] as num).toDouble(),
    );
  }
}

/// Horse Histovec - Complete history like vehicle Histovec
class HorseHistovec {
  final String id;
  final String horseId;
  final String ueln; // Unique ID
  final String? microchip;
  final String? passportNumber;
  final List<OwnershipRecord> ownershipHistory;
  final List<VeterinaryRecord> veterinaryHistory;
  final List<CompetitionRecord> competitionHistory;
  final List<TrainingRecord> trainingHistory;
  final List<AnalysisRecord> analysisHistory;
  final List<String> certifications;
  final List<String> alerts; // Red flags
  final bool isClean; // Pas d'alertes
  final DateTime lastUpdated;

  HorseHistovec({
    required this.id,
    required this.horseId,
    required this.ueln,
    this.microchip,
    this.passportNumber,
    this.ownershipHistory = const [],
    this.veterinaryHistory = const [],
    this.competitionHistory = const [],
    this.trainingHistory = const [],
    this.analysisHistory = const [],
    this.certifications = const [],
    this.alerts = const [],
    this.isClean = true,
    required this.lastUpdated,
  });

  int get ownerCount => ownershipHistory.length;

  factory HorseHistovec.fromJson(Map<String, dynamic> json) {
    return HorseHistovec(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      ueln: json['ueln'] as String,
      microchip: json['microchip'] as String?,
      passportNumber: json['passportNumber'] as String?,
      ownershipHistory: (json['ownershipHistory'] as List?)
              ?.map((o) => OwnershipRecord.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      veterinaryHistory: (json['veterinaryHistory'] as List?)
              ?.map((v) => VeterinaryRecord.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      competitionHistory: (json['competitionHistory'] as List?)
              ?.map((c) => CompetitionRecord.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      trainingHistory: (json['trainingHistory'] as List?)
              ?.map((t) => TrainingRecord.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      analysisHistory: (json['analysisHistory'] as List?)
              ?.map((a) => AnalysisRecord.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      certifications: (json['certifications'] as List?)?.cast<String>() ?? [],
      alerts: (json['alerts'] as List?)?.cast<String>() ?? [],
      isClean: json['isClean'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Ownership record
class OwnershipRecord {
  final String id;
  final String? ownerName;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final String? reason; // Achat, Don, Succession

  OwnershipRecord({
    required this.id,
    this.ownerName,
    this.location,
    required this.startDate,
    this.endDate,
    this.reason,
  });

  factory OwnershipRecord.fromJson(Map<String, dynamic> json) {
    return OwnershipRecord(
      id: json['id'] as String,
      ownerName: json['ownerName'] as String?,
      location: json['location'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      reason: json['reason'] as String?,
    );
  }
}

/// Veterinary record
class VeterinaryRecord {
  final String id;
  final String type; // Vaccination, Vermifuge, Ferrure, Soins, Opération
  final String description;
  final String? veterinarian;
  final DateTime date;
  final DateTime? nextDue;
  final String? notes;
  final bool isAlert; // Problème de santé majeur

  VeterinaryRecord({
    required this.id,
    required this.type,
    required this.description,
    this.veterinarian,
    required this.date,
    this.nextDue,
    this.notes,
    this.isAlert = false,
  });

  factory VeterinaryRecord.fromJson(Map<String, dynamic> json) {
    return VeterinaryRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      veterinarian: json['veterinarian'] as String?,
      date: DateTime.parse(json['date'] as String),
      nextDue: json['nextDue'] != null ? DateTime.parse(json['nextDue'] as String) : null,
      notes: json['notes'] as String?,
      isAlert: json['isAlert'] as bool? ?? false,
    );
  }
}

/// Competition record
class CompetitionRecord {
  final String id;
  final String name;
  final String discipline;
  final String level;
  final DateTime date;
  final String? location;
  final int? ranking;
  final int? participants;
  final double? score;
  final String? notes;

  CompetitionRecord({
    required this.id,
    required this.name,
    required this.discipline,
    required this.level,
    required this.date,
    this.location,
    this.ranking,
    this.participants,
    this.score,
    this.notes,
  });

  String get resultDisplay {
    if (ranking == null) return 'Participé';
    if (participants != null) return '$ranking/$participants';
    return '$ranking${_getOrdinalSuffix(ranking!)}';
  }

  String _getOrdinalSuffix(int n) {
    if (n == 1) return 'er';
    return 'ème';
  }

  factory CompetitionRecord.fromJson(Map<String, dynamic> json) {
    return CompetitionRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      discipline: json['discipline'] as String,
      level: json['level'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String?,
      ranking: json['ranking'] as int?,
      participants: json['participants'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Training record
class TrainingRecord {
  final String id;
  final String type; // Débourrage, Formation, Stage
  final String description;
  final String? trainer;
  final DateTime startDate;
  final DateTime? endDate;
  final String? level;
  final String? notes;

  TrainingRecord({
    required this.id,
    required this.type,
    required this.description,
    this.trainer,
    required this.startDate,
    this.endDate,
    this.level,
    this.notes,
  });

  factory TrainingRecord.fromJson(Map<String, dynamic> json) {
    return TrainingRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      trainer: json['trainer'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      level: json['level'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// AI Analysis record from Horse Tempo
class AnalysisRecord {
  final String id;
  final String type; // locomotion, conformation, video
  final DateTime date;
  final double? overallScore;
  final Map<String, double>? scores;
  final List<String>? strengths;
  final List<String>? areasToImprove;
  final String? summary;

  AnalysisRecord({
    required this.id,
    required this.type,
    required this.date,
    this.overallScore,
    this.scores,
    this.strengths,
    this.areasToImprove,
    this.summary,
  });

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      scores: (json['scores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      strengths: (json['strengths'] as List?)?.cast<String>(),
      areasToImprove: (json['areasToImprove'] as List?)?.cast<String>(),
      summary: json['summary'] as String?,
    );
  }
}

/// AI-generated horse profile from video analyses
class HorseAIProfile {
  final String id;
  final String horseId;
  // Character traits from AI analysis
  final CharacterProfile character;
  // Physical traits
  final ConformationProfile conformation;
  // Locomotion analysis
  final LocomotionProfile locomotion;
  // Performance potential
  final Map<String, double> disciplinePotential;
  // Overall scores
  final double overallScore;
  final double breedingScore;
  final double performanceScore;
  // Compatibility
  final List<String> idealRiderProfiles;
  final List<String> idealDisciplines;
  // Trust
  final int analysisCount;
  final double confidenceLevel;
  final DateTime lastAnalysisAt;

  HorseAIProfile({
    required this.id,
    required this.horseId,
    required this.character,
    required this.conformation,
    required this.locomotion,
    this.disciplinePotential = const {},
    this.overallScore = 0,
    this.breedingScore = 0,
    this.performanceScore = 0,
    this.idealRiderProfiles = const [],
    this.idealDisciplines = const [],
    this.analysisCount = 0,
    this.confidenceLevel = 0,
    required this.lastAnalysisAt,
  });

  factory HorseAIProfile.fromJson(Map<String, dynamic> json) {
    return HorseAIProfile(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      character: CharacterProfile.fromJson(json['character'] as Map<String, dynamic>),
      conformation: ConformationProfile.fromJson(json['conformation'] as Map<String, dynamic>),
      locomotion: LocomotionProfile.fromJson(json['locomotion'] as Map<String, dynamic>),
      disciplinePotential: (json['disciplinePotential'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      breedingScore: (json['breedingScore'] as num?)?.toDouble() ?? 0,
      performanceScore: (json['performanceScore'] as num?)?.toDouble() ?? 0,
      idealRiderProfiles: (json['idealRiderProfiles'] as List?)?.cast<String>() ?? [],
      idealDisciplines: (json['idealDisciplines'] as List?)?.cast<String>() ?? [],
      analysisCount: json['analysisCount'] as int? ?? 0,
      confidenceLevel: (json['confidenceLevel'] as num?)?.toDouble() ?? 0,
      lastAnalysisAt: DateTime.parse(json['lastAnalysisAt'] as String),
    );
  }
}

/// Character traits detected by AI
class CharacterProfile {
  final double temperament; // 0 = très froid, 100 = très chaud
  final double sensitivity; // 0 = peu sensible, 100 = très sensible
  final double reactivity;  // 0 = calme, 100 = très réactif
  final double focus;       // 0 = distrait, 100 = très concentré
  final double willingness; // 0 = difficile, 100 = très volontaire
  final double confidence;  // 0 = peureux, 100 = très confiant
  final double sociability; // 0 = solitaire, 100 = très sociable
  final List<String> traits; // Tags: "Courageux", "Sensible", etc.

  CharacterProfile({
    this.temperament = 50,
    this.sensitivity = 50,
    this.reactivity = 50,
    this.focus = 50,
    this.willingness = 50,
    this.confidence = 50,
    this.sociability = 50,
    this.traits = const [],
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    return CharacterProfile(
      temperament: (json['temperament'] as num?)?.toDouble() ?? 50,
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 50,
      reactivity: (json['reactivity'] as num?)?.toDouble() ?? 50,
      focus: (json['focus'] as num?)?.toDouble() ?? 50,
      willingness: (json['willingness'] as num?)?.toDouble() ?? 50,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 50,
      sociability: (json['sociability'] as num?)?.toDouble() ?? 50,
      traits: (json['traits'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Conformation traits detected by AI
class ConformationProfile {
  final double frame;        // Cadre
  final double balance;      // Équilibre
  final double topline;      // Ligne du dessus
  final double limbs;        // Membres/Aplombs
  final double feet;         // Pieds
  final double neck;         // Encolure
  final double shoulder;     // Épaule
  final double hindquarters; // Arrière-main
  final List<String> strengths;
  final List<String> weaknesses;

  ConformationProfile({
    this.frame = 0,
    this.balance = 0,
    this.topline = 0,
    this.limbs = 0,
    this.feet = 0,
    this.neck = 0,
    this.shoulder = 0,
    this.hindquarters = 0,
    this.strengths = const [],
    this.weaknesses = const [],
  });

  double get overallScore =>
      (frame + balance + topline + limbs + feet + neck + shoulder + hindquarters) / 8;

  factory ConformationProfile.fromJson(Map<String, dynamic> json) {
    return ConformationProfile(
      frame: (json['frame'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      topline: (json['topline'] as num?)?.toDouble() ?? 0,
      limbs: (json['limbs'] as num?)?.toDouble() ?? 0,
      feet: (json['feet'] as num?)?.toDouble() ?? 0,
      neck: (json['neck'] as num?)?.toDouble() ?? 0,
      shoulder: (json['shoulder'] as num?)?.toDouble() ?? 0,
      hindquarters: (json['hindquarters'] as num?)?.toDouble() ?? 0,
      strengths: (json['strengths'] as List?)?.cast<String>() ?? [],
      weaknesses: (json['weaknesses'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Locomotion traits detected by AI
class LocomotionProfile {
  final double walk;
  final double trot;
  final double canter;
  final double regularity;
  final double impulsion;
  final double suppleness;
  final double balance;
  final double engagement;
  final List<String> observations;

  LocomotionProfile({
    this.walk = 0,
    this.trot = 0,
    this.canter = 0,
    this.regularity = 0,
    this.impulsion = 0,
    this.suppleness = 0,
    this.balance = 0,
    this.engagement = 0,
    this.observations = const [],
  });

  double get overallScore =>
      (walk + trot + canter + regularity + impulsion + suppleness + balance + engagement) / 8;

  factory LocomotionProfile.fromJson(Map<String, dynamic> json) {
    return LocomotionProfile(
      walk: (json['walk'] as num?)?.toDouble() ?? 0,
      trot: (json['trot'] as num?)?.toDouble() ?? 0,
      canter: (json['canter'] as num?)?.toDouble() ?? 0,
      regularity: (json['regularity'] as num?)?.toDouble() ?? 0,
      impulsion: (json['impulsion'] as num?)?.toDouble() ?? 0,
      suppleness: (json['suppleness'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      engagement: (json['engagement'] as num?)?.toDouble() ?? 0,
      observations: (json['observations'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Match for breeding compatibility
class BreedingMatch {
  final String mareListingId;
  final String stallionListingId;
  final String mareName;
  final String stallionName;
  final double compatibilityScore;
  final List<String> strengths;
  final List<String> concerns;
  final Map<String, double> offspringPotential; // By discipline
  final String? aiRecommendation;

  BreedingMatch({
    required this.mareListingId,
    required this.stallionListingId,
    required this.mareName,
    required this.stallionName,
    required this.compatibilityScore,
    this.strengths = const [],
    this.concerns = const [],
    this.offspringPotential = const {},
    this.aiRecommendation,
  });

  factory BreedingMatch.fromJson(Map<String, dynamic> json) {
    return BreedingMatch(
      mareListingId: json['mareListingId'] as String,
      stallionListingId: json['stallionListingId'] as String,
      mareName: json['mareName'] as String,
      stallionName: json['stallionName'] as String,
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      strengths: (json['strengths'] as List?)?.cast<String>() ?? [],
      concerns: (json['concerns'] as List?)?.cast<String>() ?? [],
      offspringPotential: (json['offspringPotential'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      aiRecommendation: json['aiRecommendation'] as String?,
    );
  }
}
