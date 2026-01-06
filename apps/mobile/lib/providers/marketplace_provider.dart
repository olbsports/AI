import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

/// Marketplace search filters
class MarketplaceFilters {
  final ListingType? type;
  final String? breed;
  final int? minPrice;
  final int? maxPrice;
  final int? minAge;
  final int? maxAge;
  final String? location;
  final double? maxDistance;
  final HorseDiscipline? discipline;
  final String? sortBy;
  final bool? hasEquiCote;
  final bool? hasEquiTrace;
  final bool? hasVideo;

  MarketplaceFilters({
    this.type,
    this.breed,
    this.minPrice,
    this.maxPrice,
    this.minAge,
    this.maxAge,
    this.location,
    this.maxDistance,
    this.discipline,
    this.sortBy,
    this.hasEquiCote,
    this.hasEquiTrace,
    this.hasVideo,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (type != null) params['type'] = type!.name;
    if (breed != null) params['breed'] = breed!;
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (minAge != null) params['minAge'] = minAge.toString();
    if (maxAge != null) params['maxAge'] = maxAge.toString();
    if (location != null) params['location'] = location!;
    if (maxDistance != null) params['maxDistance'] = maxDistance.toString();
    if (discipline != null) params['discipline'] = discipline!.name;
    if (sortBy != null) params['sortBy'] = sortBy!;
    if (hasEquiCote == true) params['hasEquiCote'] = 'true';
    if (hasEquiTrace == true) params['hasEquiTrace'] = 'true';
    if (hasVideo == true) params['hasVideo'] = 'true';
    return params;
  }
}

/// Current marketplace filters
final marketplaceFiltersProvider = StateProvider<MarketplaceFilters>((ref) {
  return MarketplaceFilters();
});

/// Search marketplace listings
final marketplaceSearchProvider =
    FutureProvider.family<List<MarketplaceListing>, MarketplaceFilters>((ref, filters) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/search', queryParams: filters.toQueryParams());
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// Listings by type
final listingsByTypeProvider =
    FutureProvider.family<List<MarketplaceListing>, ListingType>((ref, type) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace', queryParams: {'type': type.name});
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// Listing detail by ID
final listingDetailProvider =
    FutureProvider.family<MarketplaceListing, String>((ref, listingId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/$listingId');
  return MarketplaceListing.fromJson(response);
});

/// Horse sale listing with EquiCote/EquiTrace
final horseSaleListingProvider =
    FutureProvider.family<HorseSaleListing, String>((ref, listingId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/horses/$listingId');
  return HorseSaleListing(
    id: response['id'],
    type: ListingType.values.firstWhere(
      (e) => e.name == response['type'],
      orElse: () => ListingType.horseForSale,
    ),
    sellerId: response['sellerId'],
    sellerName: response['sellerName'],
    title: response['title'],
    description: response['description'] ?? '',
    createdAt: DateTime.parse(response['createdAt']),
    horseId: response['horseId'],
    horseName: response['horseName'],
    breed: response['breed'],
    studbook: response['studbook'],
    birthYear: response['birthYear'],
    gender: response['gender'],
    heightCm: response['heightCm'],
    color: response['color'],
    disciplines: (response['disciplines'] as List?)
            ?.map((d) => HorseDiscipline.fromString(d as String))
            .toList() ??
        [],
    level: response['level'],
    argus: response['argus'] != null ? HorseArgus.fromJson(response['argus']) : null,
    histovec: response['histovec'] != null ? HorseHistovec.fromJson(response['histovec']) : null,
    aiProfile: response['aiProfile'] != null ? HorseAIProfile.fromJson(response['aiProfile']) : null,
  );
});

/// Get EquiCote valuation for a horse
final horseEquiCoteProvider =
    FutureProvider.family<HorseEquiCote, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/equicote/horse/$horseId/valuations');
  final valuations = response as List;
  if (valuations.isEmpty) throw Exception('No valuation found');
  return HorseEquiCote.fromJson(valuations.first);
});

/// Get EquiTrace history for a horse
final horseEquiTraceProvider =
    FutureProvider.family<HorseEquiTrace, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/equitrace/timeline/$horseId');
  return HorseEquiTrace.fromJson(response);
});

/// Get AI profile for a horse
final horseAIProfileProvider =
    FutureProvider.family<HorseAIProfile, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/ai-profile/$horseId');
  return HorseAIProfile.fromJson(response);
});

/// Breeding listings (mares and stallions)
final breedingListingsProvider =
    FutureProvider.family<List<BreedingListing>, ({ListingType type, String? breed})>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final queryParams = <String, String>{'type': params.type.name};
  if (params.breed != null) queryParams['breed'] = params.breed!;
  final response = await api.get('/marketplace/breeding', queryParams: queryParams);
  return (response as List).map((e) {
    final json = e as Map<String, dynamic>;
    return BreedingListing(
      id: json['id'],
      type: ListingType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ListingType.mareForBreeding,
      ),
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      title: json['title'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      horseId: json['horseId'],
      horseName: json['horseName'],
      breed: json['breed'],
      studbook: json['studbook'],
      birthYear: json['birthYear'],
      color: json['color'],
      freshSemen: json['freshSemen'] ?? false,
      frozenSemen: json['frozenSemen'] ?? false,
      naturalService: json['naturalService'] ?? false,
      indices: (json['indices'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      offspringCount: json['offspringCount'],
      notableOffspring: (json['notableOffspring'] as List?)?.cast<String>() ?? [],
      previousFoals: json['previousFoals'],
      embryoTransfer: json['embryoTransfer'] ?? false,
    );
  }).toList();
});

/// User's own listings
final myListingsProvider = FutureProvider<List<MarketplaceListing>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/my-listings');
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// User's favorite listings
final favoriteListingsProvider = FutureProvider<List<MarketplaceListing>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/favorites');
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// Featured listings
final featuredListingsProvider = FutureProvider<List<MarketplaceListing>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/featured');
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// Recent listings
final recentListingsProvider = FutureProvider<List<MarketplaceListing>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/recent');
  return (response as List).map((e) => MarketplaceListing.fromJson(e)).toList();
});

/// Breeding matches for a mare
final breedingMatchesProvider =
    FutureProvider.family<List<BreedingMatch>, String>((ref, mareId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/breeding-matches/$mareId');
  return (response as List).map((e) => BreedingMatch.fromJson(e)).toList();
});

/// Comparable horses for pricing
final comparableHorsesProvider =
    FutureProvider.family<List<ComparableHorse>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/equicote/comparables/$horseId');
  return (response as List).map((e) => ComparableHorse.fromJson(e)).toList();
});

/// Marketplace statistics
final marketplaceStatsProvider = FutureProvider<MarketplaceStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/marketplace/stats');
  return MarketplaceStats.fromJson(response);
});

/// Marketplace statistics model
class MarketplaceStats {
  final int totalListings;
  final int activeListings;
  final int soldListings;
  final double averagePrice;
  final int averageDaysOnMarket;
  final Map<String, int> listingsByType;
  final Map<String, int> listingsByBreed;
  final List<PriceTrend> priceTrends;

  MarketplaceStats({
    required this.totalListings,
    required this.activeListings,
    required this.soldListings,
    required this.averagePrice,
    required this.averageDaysOnMarket,
    required this.listingsByType,
    required this.listingsByBreed,
    required this.priceTrends,
  });

  factory MarketplaceStats.fromJson(Map<String, dynamic> json) {
    return MarketplaceStats(
      totalListings: json['totalListings'] as int? ?? 0,
      activeListings: json['activeListings'] as int? ?? 0,
      soldListings: json['soldListings'] as int? ?? 0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0,
      averageDaysOnMarket: json['averageDaysOnMarket'] as int? ?? 0,
      listingsByType: (json['listingsByType'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      listingsByBreed: (json['listingsByBreed'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      priceTrends: (json['priceTrends'] as List?)
              ?.map((e) => PriceTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Price trend data
class PriceTrend {
  final DateTime date;
  final double averagePrice;
  final int listingCount;

  PriceTrend({
    required this.date,
    required this.averagePrice,
    required this.listingCount,
  });

  factory PriceTrend.fromJson(Map<String, dynamic> json) {
    return PriceTrend(
      date: DateTime.parse(json['date'] as String),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      listingCount: json['listingCount'] as int,
    );
  }
}

/// Marketplace notifier for CRUD operations
class MarketplaceNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  MarketplaceNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Create listing
  Future<MarketplaceListing?> createListing(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/marketplace', data);
      _ref.invalidate(myListingsProvider);
      _ref.invalidate(recentListingsProvider);
      state = const AsyncValue.data(null);
      return MarketplaceListing.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update listing
  Future<bool> updateListing(String listingId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/marketplace/$listingId', data);
      _ref.invalidate(listingDetailProvider(listingId));
      _ref.invalidate(myListingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete listing
  Future<bool> deleteListing(String listingId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/marketplace/$listingId');
      _ref.invalidate(myListingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mark listing as sold
  Future<bool> markAsSold(String listingId, int? soldPrice) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/marketplace/$listingId/sold', {'soldPrice': soldPrice});
      _ref.invalidate(listingDetailProvider(listingId));
      _ref.invalidate(myListingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(String listingId) async {
    try {
      await _api.post('/marketplace/$listingId/favorite', {});
      _ref.invalidate(listingDetailProvider(listingId));
      _ref.invalidate(favoriteListingsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Contact seller
  Future<bool> contactSeller(String listingId, String message) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/marketplace/$listingId/contact', {'message': message});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Request EquiCote valuation
  Future<HorseEquiCote?> requestEquiCoteValuation(String horseId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/equicote/valuate/$horseId', {});
      _ref.invalidate(horseEquiCoteProvider(horseId));
      state = const AsyncValue.data(null);
      return HorseEquiCote.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Request EquiTrace report
  Future<HorseEquiTrace?> requestEquiTraceReport(String horseId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/equitrace/report/$horseId', {});
      _ref.invalidate(horseEquiTraceProvider(horseId));
      state = const AsyncValue.data(null);
      return HorseEquiTrace.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Request AI profile analysis from video
  Future<HorseAIProfile?> requestAIAnalysis(String horseId, String videoUrl) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/marketplace/ai-profile/analyze', {
        'horseId': horseId,
        'videoUrl': videoUrl,
      });
      _ref.invalidate(horseAIProfileProvider(horseId));
      state = const AsyncValue.data(null);
      return HorseAIProfile.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Report listing
  Future<bool> reportListing(String listingId, String reason, String? details) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/marketplace/$listingId/report', {
        'reason': reason,
        'details': details,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Promote listing (premium)
  Future<bool> promoteListing(String listingId, int days) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/marketplace/$listingId/promote', {'days': days});
      _ref.invalidate(listingDetailProvider(listingId));
      _ref.invalidate(myListingsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final marketplaceNotifierProvider =
    StateNotifierProvider<MarketplaceNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return MarketplaceNotifier(api, ref);
});

/// EquiCote calculator - Local estimation algorithm
class EquiCoteCalculator {
  /// Calculate estimated price based on horse characteristics
  static EquiCoteEstimation calculate({
    required String breed,
    required int age,
    required String level,
    String? discipline,
    int? heightCm,
    bool hasCompetitionResults = false,
    int? competitionWins,
    bool isHealthy = true,
    bool hasLineage = false,
    String? sire,
    String? dam,
  }) {
    // Base prices by breed (in EUR)
    final basePrices = {
      'SF': 15000,
      'KWPN': 25000,
      'BWP': 20000,
      'HOLST': 22000,
      'HANN': 20000,
      'AA': 12000,
      'PS': 30000,
      'AR': 8000,
      'PFS': 5000,
      'CO': 6000,
    };

    int basePrice = basePrices[breed] ?? 10000;

    // Age factor
    double ageFactor = 1.0;
    if (age < 3) {
      ageFactor = 0.6; // Young, untrained
    } else if (age >= 3 && age <= 6) {
      ageFactor = 1.2; // Prime training age
    } else if (age >= 7 && age <= 12) {
      ageFactor = 1.0; // Mature
    } else if (age >= 13 && age <= 16) {
      ageFactor = 0.7; // Aging
    } else {
      ageFactor = 0.4; // Senior
    }

    // Level factor
    double levelFactor = 1.0;
    switch (level.toLowerCase()) {
      case 'pro':
      case 'professionnel':
        levelFactor = 3.0;
        break;
      case 'amateur':
        levelFactor = 1.8;
        break;
      case 'club':
        levelFactor = 1.0;
        break;
      case 'loisir':
        levelFactor = 0.7;
        break;
      case 'jeune':
        levelFactor = 0.8;
        break;
    }

    // Competition results factor
    double competitionFactor = 1.0;
    if (hasCompetitionResults) {
      competitionFactor = 1.2;
      if (competitionWins != null && competitionWins > 0) {
        competitionFactor += (competitionWins * 0.05).clamp(0, 0.5);
      }
    }

    // Health factor
    double healthFactor = isHealthy ? 1.0 : 0.6;

    // Lineage factor
    double lineageFactor = 1.0;
    if (hasLineage) {
      lineageFactor = 1.15;
      // Could add specific sire/dam bonuses here
    }

    // Calculate final price
    double calculatedPrice = basePrice *
        ageFactor *
        levelFactor *
        competitionFactor *
        healthFactor *
        lineageFactor;

    // Price range (±20%)
    int minPrice = (calculatedPrice * 0.8).round();
    int maxPrice = (calculatedPrice * 1.2).round();

    // Round to nearest 500
    minPrice = (minPrice / 500).round() * 500;
    maxPrice = (maxPrice / 500).round() * 500;

    // Calculate confidence based on data completeness
    double confidence = 60.0;
    if (heightCm != null) confidence += 5;
    if (hasCompetitionResults) confidence += 10;
    if (hasLineage) confidence += 10;
    if (isHealthy) confidence += 5;
    if (discipline != null) confidence += 5;

    return EquiCoteEstimation(
      minPrice: minPrice,
      maxPrice: maxPrice,
      confidence: confidence.clamp(0, 100),
      factors: {
        'age': ageFactor,
        'level': levelFactor,
        'competition': competitionFactor,
        'health': healthFactor,
        'lineage': lineageFactor,
      },
    );
  }
}

/// EquiCote estimation result
class EquiCoteEstimation {
  final int minPrice;
  final int maxPrice;
  final double confidence;
  final Map<String, double> factors;

  EquiCoteEstimation({
    required this.minPrice,
    required this.maxPrice,
    required this.confidence,
    required this.factors,
  });

  int get averagePrice => (minPrice + maxPrice) ~/ 2;
  String get priceRange => '$minPrice € - $maxPrice €';
}

/// HorseEquiCote model for API responses
class HorseEquiCote {
  final String id;
  final int minPrice;
  final int maxPrice;
  final int averagePrice;
  final double confidence;
  final Map<String, double> factors;
  final String? marketTrend;
  final double? demandIndex;
  final String? aiAnalysis;
  final List<String> aiRecommendations;
  final List<String> dataSources;
  final DateTime validUntil;
  final DateTime createdAt;

  HorseEquiCote({
    required this.id,
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
    required this.confidence,
    required this.factors,
    this.marketTrend,
    this.demandIndex,
    this.aiAnalysis,
    required this.aiRecommendations,
    required this.dataSources,
    required this.validUntil,
    required this.createdAt,
  });

  factory HorseEquiCote.fromJson(Map<String, dynamic> json) {
    return HorseEquiCote(
      id: json['id'] as String,
      minPrice: json['minPrice'] as int,
      maxPrice: json['maxPrice'] as int,
      averagePrice: json['averagePrice'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      factors: (json['factors'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      marketTrend: json['marketTrend'] as String?,
      demandIndex: (json['demandIndex'] as num?)?.toDouble(),
      aiAnalysis: json['aiAnalysis'] as String?,
      aiRecommendations: (json['aiRecommendations'] as List?)?.cast<String>() ?? [],
      dataSources: (json['dataSources'] as List?)?.cast<String>() ?? [],
      validUntil: DateTime.parse(json['validUntil'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get priceRange => '$minPrice € - $maxPrice €';
  bool get isExpired => DateTime.now().isAfter(validUntil);
}

/// HorseEquiTrace model for API responses
class HorseEquiTrace {
  final String horseId;
  final List<EquiTraceEntry> entries;
  final EquiTraceStats stats;
  final List<String> dataSources;
  final DateTime lastUpdated;

  HorseEquiTrace({
    required this.horseId,
    required this.entries,
    required this.stats,
    required this.dataSources,
    required this.lastUpdated,
  });

  factory HorseEquiTrace.fromJson(Map<String, dynamic> json) {
    return HorseEquiTrace(
      horseId: json['horseId'] as String,
      entries: (json['entries'] as List?)
              ?.map((e) => EquiTraceEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? EquiTraceStats.fromJson(json['stats'] as Map<String, dynamic>)
          : EquiTraceStats.empty(),
      dataSources: (json['dataSources'] as List?)?.cast<String>() ?? [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}

/// EquiTrace entry model
class EquiTraceEntry {
  final String id;
  final String type;
  final DateTime date;
  final String title;
  final String? description;
  final String source;
  final String? sourceUrl;
  final bool verified;
  final Map<String, dynamic>? metadata;

  EquiTraceEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    this.description,
    required this.source,
    this.sourceUrl,
    required this.verified,
    this.metadata,
  });

  factory EquiTraceEntry.fromJson(Map<String, dynamic> json) {
    return EquiTraceEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      verified: json['verified'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// EquiTrace statistics
class EquiTraceStats {
  final int totalCompetitions;
  final int wins;
  final int podiums;
  final int ownershipChanges;
  final int healthEvents;
  final DateTime? firstCompetition;
  final DateTime? lastCompetition;
  final List<String> disciplines;
  final String? highestLevel;
  final int verifiedEntries;
  final int totalEntries;

  EquiTraceStats({
    required this.totalCompetitions,
    required this.wins,
    required this.podiums,
    required this.ownershipChanges,
    required this.healthEvents,
    this.firstCompetition,
    this.lastCompetition,
    required this.disciplines,
    this.highestLevel,
    required this.verifiedEntries,
    required this.totalEntries,
  });

  factory EquiTraceStats.fromJson(Map<String, dynamic> json) {
    return EquiTraceStats(
      totalCompetitions: json['totalCompetitions'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      podiums: json['podiums'] as int? ?? 0,
      ownershipChanges: json['ownershipChanges'] as int? ?? 0,
      healthEvents: json['healthEvents'] as int? ?? 0,
      firstCompetition: json['firstCompetition'] != null
          ? DateTime.parse(json['firstCompetition'] as String)
          : null,
      lastCompetition: json['lastCompetition'] != null
          ? DateTime.parse(json['lastCompetition'] as String)
          : null,
      disciplines: (json['disciplines'] as List?)?.cast<String>() ?? [],
      highestLevel: json['highestLevel'] as String?,
      verifiedEntries: json['verifiedEntries'] as int? ?? 0,
      totalEntries: json['totalEntries'] as int? ?? 0,
    );
  }

  factory EquiTraceStats.empty() {
    return EquiTraceStats(
      totalCompetitions: 0,
      wins: 0,
      podiums: 0,
      ownershipChanges: 0,
      healthEvents: 0,
      disciplines: [],
      verifiedEntries: 0,
      totalEntries: 0,
    );
  }
}
