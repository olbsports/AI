import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/breeding.dart';
import '../services/api_service.dart';

/// Breeding search filters
class BreedingSearchFilters {
  final String? studbook;
  final List<String>? disciplines;
  final int? minPrice;
  final int? maxPrice;
  final bool? freshSemen;
  final bool? frozenSemen;
  final bool? naturalService;
  final String? location;
  final double? maxDistance;
  final String? sortBy;

  BreedingSearchFilters({
    this.studbook,
    this.disciplines,
    this.minPrice,
    this.maxPrice,
    this.freshSemen,
    this.frozenSemen,
    this.naturalService,
    this.location,
    this.maxDistance,
    this.sortBy,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (studbook != null) params['studbook'] = studbook!;
    if (disciplines != null && disciplines!.isNotEmpty) {
      params['disciplines'] = disciplines!.join(',');
    }
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (freshSemen == true) params['freshSemen'] = 'true';
    if (frozenSemen == true) params['frozenSemen'] = 'true';
    if (naturalService == true) params['naturalService'] = 'true';
    if (location != null) params['location'] = location!;
    if (maxDistance != null) params['maxDistance'] = maxDistance.toString();
    if (sortBy != null) params['sortBy'] = sortBy!;
    return params;
  }
}

/// Current breeding search filters
final breedingSearchFiltersProvider = StateProvider<BreedingSearchFilters>((ref) {
  return BreedingSearchFilters();
});

/// Search stallions
final stallionSearchProvider =
    FutureProvider.family<List<Stallion>, BreedingSearchFilters>((ref, filters) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions', queryParams: filters.toQueryParams());
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Stallion.fromJson(e as Map<String, dynamic>)).toList();
});

/// All stallions (paginated)
final stallionsProvider = FutureProvider<List<Stallion>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Stallion.fromJson(e as Map<String, dynamic>)).toList();
});

/// Stallion by ID
final stallionProvider =
    FutureProvider.family<Stallion, String>((ref, stallionId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions/$stallionId');
  return Stallion.fromJson(response);
});

/// Stallions by studbook
final stallionsByStudbookProvider =
    FutureProvider.family<List<Stallion>, String>((ref, studbook) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions', queryParams: {'studbook': studbook});
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Stallion.fromJson(e as Map<String, dynamic>)).toList();
});

/// Featured stallions
final featuredStallionsProvider = FutureProvider<List<Stallion>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions/featured');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => Stallion.fromJson(e as Map<String, dynamic>)).toList();
});

/// Mare profile by horse ID
final mareProfileProvider =
    FutureProvider.family<MareProfile, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/mares/$horseId');
  return MareProfile.fromJson(response);
});

/// User's mares (for breeding)
final myMaresProvider = FutureProvider<List<MareProfile>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/my-mares');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => MareProfile.fromJson(e as Map<String, dynamic>)).toList();
});

/// Breeding recommendations for a mare
final breedingRecommendationsProvider =
    FutureProvider.family<List<BreedingRecommendation>, String>((ref, mareId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/recommendations/$mareId');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => BreedingRecommendation.fromJson(e as Map<String, dynamic>)).toList();
});

/// Get AI-generated breeding recommendations
final aiBreedingRecommendationsProvider =
    FutureProvider.family<List<BreedingRecommendation>, ({String mareId, BreedingGoal goal, List<String> disciplines})>(
        (ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.post('/breeding/ai-recommendations', {
    'mareId': params.mareId,
    'goal': params.goal.name,
    'disciplines': params.disciplines,
  });
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => BreedingRecommendation.fromJson(e as Map<String, dynamic>)).toList();
});

/// Stallion offspring
final stallionOffspringProvider =
    FutureProvider.family<List<StallionOffspring>, String>((ref, stallionId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stallions/$stallionId/offspring');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => StallionOffspring.fromJson(e as Map<String, dynamic>)).toList();
});

/// Stallion offspring model
class StallionOffspring {
  final String id;
  final String name;
  final String? breed;
  final int? birthYear;
  final String? damName;
  final String? photoUrl;
  final List<String> achievements;
  final double? performanceScore;

  StallionOffspring({
    required this.id,
    required this.name,
    this.breed,
    this.birthYear,
    this.damName,
    this.photoUrl,
    this.achievements = const [],
    this.performanceScore,
  });

  factory StallionOffspring.fromJson(Map<String, dynamic> json) {
    return StallionOffspring(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String?,
      birthYear: json['birthYear'] as int?,
      damName: json['damName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      performanceScore: (json['performanceScore'] as num?)?.toDouble(),
    );
  }
}

/// Breeding stations
final breedingStationsProvider = FutureProvider<List<BreedingStation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/stations');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => BreedingStation.fromJson(e as Map<String, dynamic>)).toList();
});

/// Breeding station model
class BreedingStation {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final int stallionCount;
  final List<String> services;
  final String? photoUrl;

  BreedingStation({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.stallionCount = 0,
    this.services = const [],
    this.photoUrl,
  });

  factory BreedingStation.fromJson(Map<String, dynamic> json) {
    return BreedingStation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      stallionCount: json['stallionCount'] as int? ?? 0,
      services: (json['services'] as List?)?.cast<String>() ?? [],
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// Breeding notifier for CRUD operations
class BreedingNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  BreedingNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Save mare profile
  Future<MareProfile?> saveMareProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/breeding/mares', data);
      _ref.invalidate(myMaresProvider);
      state = const AsyncValue.data(null);
      return MareProfile.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update mare profile
  Future<bool> updateMareProfile(String mareId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/breeding/mares/$mareId', data);
      _ref.invalidate(mareProfileProvider(mareId));
      _ref.invalidate(myMaresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Save stallion to favorites
  Future<bool> saveStallion(String stallionId) async {
    try {
      await _api.post('/breeding/stallions/$stallionId/save', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Contact breeding station
  Future<bool> contactStation(String stationId, String message) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/breeding/stations/$stationId/contact', {'message': message});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Request breeding recommendation
  Future<List<BreedingRecommendation>> getRecommendations({
    required String mareId,
    required BreedingGoal goal,
    required List<String> targetDisciplines,
    String? preferredStudbook,
    int? maxPrice,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/breeding/ai-recommendations', {
        'mareId': mareId,
        'goal': goal.name,
        'targetDisciplines': targetDisciplines,
        'preferredStudbook': preferredStudbook,
        'maxPrice': maxPrice,
      });
      state = const AsyncValue.data(null);
      if (response == null) return [];
      final list = response is List ? response : (response['items'] as List? ?? []);
      return list.map((e) => BreedingRecommendation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Reserve breeding slot
  Future<BreedingReservation?> reserveBreeding({
    required String stallionId,
    required String mareId,
    required DateTime preferredDate,
    required String semenType, // fresh, frozen, natural
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/breeding/reservations', {
        'stallionId': stallionId,
        'mareId': mareId,
        'preferredDate': preferredDate.toIso8601String(),
        'semenType': semenType,
        'notes': notes,
      });
      state = const AsyncValue.data(null);
      return BreedingReservation.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Breeding reservation model
class BreedingReservation {
  final String id;
  final String stallionId;
  final String stallionName;
  final String mareId;
  final String mareName;
  final DateTime preferredDate;
  final String semenType;
  final ReservationStatus status;
  final String? stationName;
  final int? price;
  final String? notes;
  final DateTime createdAt;

  BreedingReservation({
    required this.id,
    required this.stallionId,
    required this.stallionName,
    required this.mareId,
    required this.mareName,
    required this.preferredDate,
    required this.semenType,
    required this.status,
    this.stationName,
    this.price,
    this.notes,
    required this.createdAt,
  });

  factory BreedingReservation.fromJson(Map<String, dynamic> json) {
    return BreedingReservation(
      id: json['id'] as String,
      stallionId: json['stallionId'] as String,
      stallionName: json['stallionName'] as String,
      mareId: json['mareId'] as String,
      mareName: json['mareName'] as String,
      preferredDate: DateTime.parse(json['preferredDate'] as String),
      semenType: json['semenType'] as String,
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      stationName: json['stationName'] as String?,
      price: json['price'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Reservation status
enum ReservationStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }
}

final breedingNotifierProvider =
    StateNotifierProvider<BreedingNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return BreedingNotifier(api, ref);
});

/// User's breeding reservations
final myBreedingReservationsProvider = FutureProvider<List<BreedingReservation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/breeding/my-reservations');
  if (response == null) return [];
  final list = response is List ? response : (response['items'] as List? ?? []);
  return list.map((e) => BreedingReservation.fromJson(e as Map<String, dynamic>)).toList();
});

/// Breeding compatibility calculator
class BreedingCompatibilityCalculator {
  /// Calculate compatibility score between mare and stallion
  static BreedingCompatibilityResult calculate({
    required MareProfile mare,
    required Stallion stallion,
    required BreedingGoal goal,
    required List<String> targetDisciplines,
  }) {
    double score = 50.0; // Base score
    final strengths = <String>[];
    final concerns = <String>[];
    final expectedTraits = <String>[];

    // Studbook compatibility
    if (mare.studbook == stallion.studbook) {
      score += 10;
      strengths.add('Même studbook (${mare.studbook})');
    } else if (_areStudbooksCompatible(mare.studbook, stallion.studbook)) {
      score += 5;
      strengths.add('Studbooks compatibles');
    }

    // Discipline alignment
    final commonDisciplines = stallion.disciplines
        .where((d) => targetDisciplines.contains(d))
        .toList();
    if (commonDisciplines.isNotEmpty) {
      score += commonDisciplines.length * 5;
      strengths.add('Étalon performant en ${commonDisciplines.join(", ")}');
    }

    // Indices check
    if (stallion.indices.isNotEmpty) {
      final isoIndex = stallion.indices['ISO'] ?? 0;
      final idrIndex = stallion.indices['IDR'] ?? 0;

      if (isoIndex > 140) {
        score += 10;
        strengths.add('Excellent indice ISO (${isoIndex.toStringAsFixed(0)})');
        expectedTraits.add('Potentiel élevé en saut d\'obstacles');
      }
      if (idrIndex > 140) {
        score += 10;
        strengths.add('Excellent indice IDR (${idrIndex.toStringAsFixed(0)})');
        expectedTraits.add('Potentiel élevé en dressage');
      }
    }

    // Offspring performance
    if (stallion.offspringCount != null && stallion.offspringCount! > 50) {
      score += 5;
      strengths.add('Production prouvée (${stallion.offspringCount} produits)');
    }

    // Conformation compensation
    for (final weakness in mare.conformationWeaknesses) {
      // Check if stallion can compensate
      // This would need actual data from stallion conformation
      concerns.add('À surveiller: $weakness');
    }

    // Height compatibility
    if (mare.heightCm != null && stallion.heightCm != null) {
      final heightDiff = (stallion.heightCm! - mare.heightCm!).abs();
      if (heightDiff > 15) {
        score -= 5;
        concerns.add('Différence de taille importante ($heightDiff cm)');
      }
    }

    // Inbreeding check (simplified)
    if (mare.sireId == stallion.id ||
        mare.damSireId == stallion.id ||
        mare.sireId == stallion.sireId) {
      score -= 20;
      concerns.add('Risque de consanguinité élevé');
    }

    // Goal alignment
    switch (goal) {
      case BreedingGoal.sport:
      case BreedingGoal.competition:
        if (stallion.indices.isNotEmpty) {
          score += 5;
          expectedTraits.add('Produit orienté performance');
        }
        break;
      case BreedingGoal.loisir:
        if (stallion.naturalService) {
          score += 3;
          strengths.add('Monte naturelle disponible');
        }
        break;
      case BreedingGoal.elevage:
        if (stallion.offspringCount != null && stallion.notableOffspring.isNotEmpty) {
          score += 10;
          strengths.add('Lignée remarquable');
        }
        break;
    }

    return BreedingCompatibilityResult(
      score: score.clamp(0, 100),
      strengths: strengths,
      concerns: concerns,
      expectedTraits: expectedTraits,
      disciplinePotential: _calculateDisciplinePotential(stallion, targetDisciplines),
    );
  }

  static bool _areStudbooksCompatible(String? studbook1, String? studbook2) {
    if (studbook1 == null || studbook2 == null) return true;

    // Define compatible studbooks
    final warmbloods = ['SF', 'KWPN', 'BWP', 'HOLST', 'HANN', 'OLDB', 'WESTF'];
    final arabians = ['AR', 'AA', 'PS'];
    final ponies = ['PFS', 'CO', 'WELSH'];

    if (warmbloods.contains(studbook1) && warmbloods.contains(studbook2)) return true;
    if (arabians.contains(studbook1) && arabians.contains(studbook2)) return true;
    if (ponies.contains(studbook1) && ponies.contains(studbook2)) return true;

    return false;
  }

  static Map<String, double> _calculateDisciplinePotential(
    Stallion stallion,
    List<String> targetDisciplines,
  ) {
    final potential = <String, double>{};

    for (final discipline in targetDisciplines) {
      double score = 50.0;

      // Check stallion's own performance
      if (stallion.disciplines.contains(discipline)) {
        score += 20;
      }

      // Check indices
      switch (discipline.toLowerCase()) {
        case 'cso':
        case 'showjumping':
          final iso = stallion.indices['ISO'] ?? 100;
          score += ((iso - 100) * 0.3).clamp(-20, 30);
          break;
        case 'dressage':
          final idr = stallion.indices['IDR'] ?? 100;
          score += ((idr - 100) * 0.3).clamp(-20, 30);
          break;
        case 'cce':
        case 'eventing':
          final icc = stallion.indices['ICC'] ?? 100;
          score += ((icc - 100) * 0.3).clamp(-20, 30);
          break;
      }

      potential[discipline] = score.clamp(0, 100);
    }

    return potential;
  }
}

/// Breeding compatibility result
class BreedingCompatibilityResult {
  final double score;
  final List<String> strengths;
  final List<String> concerns;
  final List<String> expectedTraits;
  final Map<String, double> disciplinePotential;

  BreedingCompatibilityResult({
    required this.score,
    required this.strengths,
    required this.concerns,
    required this.expectedTraits,
    required this.disciplinePotential,
  });

  String get scoreLabel {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }
}
