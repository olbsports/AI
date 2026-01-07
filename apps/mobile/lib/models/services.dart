/// Complete Service Directory for Horse Vision AI
/// Veterinarians, Farriers, Dentists, Osteopaths, and other equine professionals

import 'package:flutter/material.dart';

// ============================================
// SERVICE PROVIDERS
// ============================================

/// Professional service provider
class ServiceProvider {
  final String id;
  final String name;
  final ServiceType type;
  final String? businessName;
  final String? description;
  final String? photoUrl;
  final String? logoUrl;
  final String? phone;
  final String? email;
  final String? website;
  final Address? address;
  final double? latitude;
  final double? longitude;
  final double? serviceRadius; // km
  final List<String> specialties;
  final List<String> certifications;
  final List<WorkingHours> workingHours;
  final bool acceptsEmergency;
  final bool mobileService;
  final double? averageRating;
  final int reviewCount;
  final PriceRange? priceRange;
  final List<String> paymentMethods;
  final List<String> languages;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastActivity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.type,
    this.businessName,
    this.description,
    this.photoUrl,
    this.logoUrl,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.latitude,
    this.longitude,
    this.serviceRadius,
    this.specialties = const [],
    this.certifications = const [],
    this.workingHours = const [],
    this.acceptsEmergency = false,
    this.mobileService = true,
    this.averageRating,
    this.reviewCount = 0,
    this.priceRange,
    this.paymentMethods = const [],
    this.languages = const ['Français'],
    this.isVerified = false,
    this.isActive = true,
    this.lastActivity,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasRating => averageRating != null && reviewCount > 0;
  String get displayRating => averageRating?.toStringAsFixed(1) ?? '-';

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: ServiceType.fromString(json['type'] as String? ?? 'other'),
      businessName: json['businessName'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      specialties: (json['specialties'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      certifications: (json['certifications'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      workingHours: (json['workingHours'] as List?)
          ?.map((w) => WorkingHours.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      acceptsEmergency: json['acceptsEmergency'] as bool? ?? false,
      mobileService: json['mobileService'] as bool? ?? true,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      priceRange: json['priceRange'] != null
          ? PriceRange.fromJson(json['priceRange'] as Map<String, dynamic>)
          : null,
      paymentMethods: (json['paymentMethods'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      languages: (json['languages'] as List?)?.map((e) => e as String? ?? '').toList() ?? ['Français'],
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'] as String)
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'businessName': businessName,
      'description': description,
      'photoUrl': photoUrl,
      'logoUrl': logoUrl,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadius': serviceRadius,
      'specialties': specialties,
      'certifications': certifications,
      'workingHours': workingHours.map((w) => w.toJson()).toList(),
      'acceptsEmergency': acceptsEmergency,
      'mobileService': mobileService,
      'paymentMethods': paymentMethods,
      'languages': languages,
    };
  }
}

/// Service types
enum ServiceType {
  veterinarian,   // Vétérinaire
  farrier,        // Maréchal-ferrant
  dentist,        // Dentiste équin
  osteopath,      // Ostéopathe
  chiropractor,   // Chiropracteur
  physiotherapist, // Kinésithérapeute
  acupuncturist,  // Acupuncteur
  nutritionist,   // Nutritionniste
  behaviorist,    // Comportementaliste
  saddler,        // Sellier
  clipper,        // Tondeur
  transporter,    // Transporteur
  photographer,   // Photographe équin
  instructor,     // Moniteur/Enseignant
  trainer,        // Cavalier pro/Débourrage
  breeder,        // Éleveur
  other;

  String get displayName {
    switch (this) {
      case ServiceType.veterinarian: return 'Vétérinaire';
      case ServiceType.farrier: return 'Maréchal-ferrant';
      case ServiceType.dentist: return 'Dentiste équin';
      case ServiceType.osteopath: return 'Ostéopathe';
      case ServiceType.chiropractor: return 'Chiropracteur';
      case ServiceType.physiotherapist: return 'Kinésithérapeute';
      case ServiceType.acupuncturist: return 'Acupuncteur';
      case ServiceType.nutritionist: return 'Nutritionniste';
      case ServiceType.behaviorist: return 'Comportementaliste';
      case ServiceType.saddler: return 'Sellier';
      case ServiceType.clipper: return 'Tondeur';
      case ServiceType.transporter: return 'Transporteur';
      case ServiceType.photographer: return 'Photographe équin';
      case ServiceType.instructor: return 'Moniteur';
      case ServiceType.trainer: return 'Cavalier professionnel';
      case ServiceType.breeder: return 'Éleveur';
      case ServiceType.other: return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.veterinarian: return Icons.local_hospital;
      case ServiceType.farrier: return Icons.handyman;
      case ServiceType.dentist: return Icons.medical_services;
      case ServiceType.osteopath: return Icons.accessibility_new;
      case ServiceType.chiropractor: return Icons.airline_seat_legroom_extra;
      case ServiceType.physiotherapist: return Icons.fitness_center;
      case ServiceType.acupuncturist: return Icons.spa;
      case ServiceType.nutritionist: return Icons.restaurant;
      case ServiceType.behaviorist: return Icons.psychology;
      case ServiceType.saddler: return Icons.chair;
      case ServiceType.clipper: return Icons.content_cut;
      case ServiceType.transporter: return Icons.local_shipping;
      case ServiceType.photographer: return Icons.camera_alt;
      case ServiceType.instructor: return Icons.school;
      case ServiceType.trainer: return Icons.sports;
      case ServiceType.breeder: return Icons.pets;
      case ServiceType.other: return Icons.work;
    }
  }

  int get defaultColor {
    switch (this) {
      case ServiceType.veterinarian: return 0xFFF44336;
      case ServiceType.farrier: return 0xFF795548;
      case ServiceType.dentist: return 0xFF00BCD4;
      case ServiceType.osteopath: return 0xFF9C27B0;
      case ServiceType.chiropractor: return 0xFF673AB7;
      case ServiceType.physiotherapist: return 0xFF4CAF50;
      case ServiceType.acupuncturist: return 0xFF009688;
      case ServiceType.nutritionist: return 0xFFFF9800;
      case ServiceType.behaviorist: return 0xFFE91E63;
      case ServiceType.saddler: return 0xFF607D8B;
      case ServiceType.clipper: return 0xFF8BC34A;
      case ServiceType.transporter: return 0xFF2196F3;
      case ServiceType.photographer: return 0xFFFF5722;
      case ServiceType.instructor: return 0xFF3F51B5;
      case ServiceType.trainer: return 0xFF00BCD4;
      case ServiceType.breeder: return 0xFFFFC107;
      case ServiceType.other: return 0xFF9E9E9E;
    }
  }

  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ServiceType.other,
    );
  }
}

// ============================================
// ADDRESS
// ============================================

/// Address
class Address {
  final String? street;
  final String? complement;
  final String postalCode;
  final String city;
  final String? region;
  final String country;

  Address({
    this.street,
    this.complement,
    required this.postalCode,
    required this.city,
    this.region,
    this.country = 'France',
  });

  String get fullAddress {
    final parts = <String>[];
    if (street != null) parts.add(street!);
    if (complement != null) parts.add(complement!);
    parts.add('$postalCode $city');
    if (region != null) parts.add(region!);
    if (country != 'France') parts.add(country);
    return parts.join(', ');
  }

  String get shortAddress => '$city ($postalCode)';

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String?,
      complement: json['complement'] as String?,
      postalCode: json['postalCode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      region: json['region'] as String?,
      country: json['country'] as String? ?? 'France',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'complement': complement,
      'postalCode': postalCode,
      'city': city,
      'region': region,
      'country': country,
    };
  }
}

// ============================================
// WORKING HOURS
// ============================================

/// Working hours for a day
class WorkingHours {
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final bool isClosed;
  final String? openTime; // HH:mm
  final String? closeTime; // HH:mm
  final String? breakStart;
  final String? breakEnd;

  WorkingHours({
    required this.dayOfWeek,
    this.isClosed = false,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  String get dayName {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[dayOfWeek];
  }

  String get displayHours {
    if (isClosed) return 'Fermé';
    if (openTime == null || closeTime == null) return 'Horaires non définis';
    if (breakStart != null && breakEnd != null) {
      return '$openTime-$breakStart, $breakEnd-$closeTime';
    }
    return '$openTime-$closeTime';
  }

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      isClosed: json['isClosed'] as bool? ?? false,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      breakStart: json['breakStart'] as String?,
      breakEnd: json['breakEnd'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'isClosed': isClosed,
      'openTime': openTime,
      'closeTime': closeTime,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
    };
  }
}

// ============================================
// PRICE RANGE
// ============================================

/// Price range for a service
class PriceRange {
  final double minPrice;
  final double maxPrice;
  final String? currency;
  final String? unit; // per visit, per hour, etc.

  PriceRange({
    required this.minPrice,
    required this.maxPrice,
    this.currency = '€',
    this.unit,
  });

  String get displayRange {
    if (minPrice == maxPrice) {
      return '$currency${minPrice.toStringAsFixed(0)}${unit != null ? '/$unit' : ''}';
    }
    return '$currency${minPrice.toStringAsFixed(0)}-${maxPrice.toStringAsFixed(0)}${unit != null ? '/$unit' : ''}';
  }

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '€',
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'currency': currency,
      'unit': unit,
    };
  }
}

// ============================================
// REVIEWS
// ============================================

/// Review for a service provider
class ServiceReview {
  final String id;
  final String providerId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final int rating; // 1-5
  final String? title;
  final String? comment;
  final DateTime serviceDate;
  final String? serviceType;
  final String? horseName;
  final List<String> photos;
  final bool isVerified;
  final int helpfulCount;
  final ProviderResponse? response;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceReview({
    required this.id,
    required this.providerId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.rating,
    this.title,
    this.comment,
    required this.serviceDate,
    this.serviceType,
    this.horseName,
    this.photos = const [],
    this.isVerified = false,
    this.helpfulCount = 0,
    this.response,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    return ServiceReview(
      id: json['id'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      serviceDate: json['serviceDate'] != null ? DateTime.tryParse(json['serviceDate'] as String) ?? DateTime.now() : DateTime.now(),
      serviceType: json['serviceType'] as String?,
      horseName: json['horseName'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      isVerified: json['isVerified'] as bool? ?? false,
      helpfulCount: (json['helpfulCount'] as num?)?.toInt() ?? 0,
      response: json['response'] != null
          ? ProviderResponse.fromJson(json['response'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'serviceDate': serviceDate.toIso8601String(),
      'serviceType': serviceType,
      'horseName': horseName,
      'photos': photos,
    };
  }
}

/// Provider's response to a review
class ProviderResponse {
  final String content;
  final DateTime createdAt;

  ProviderResponse({
    required this.content,
    required this.createdAt,
  });

  factory ProviderResponse.fromJson(Map<String, dynamic> json) {
    return ProviderResponse(
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ============================================
// APPOINTMENTS
// ============================================

/// Appointment with a service provider
class ServiceAppointment {
  final String id;
  final String providerId;
  final String providerName;
  final ServiceType providerType;
  final String userId;
  final String? horseId;
  final String? horseName;
  final DateTime appointmentDate;
  final String? appointmentTime;
  final int? duration; // minutes
  final String? service;
  final String? notes;
  final String? location;
  final AppointmentStatus status;
  final double? estimatedCost;
  final double? actualCost;
  final String? feedback;
  final int? rating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceAppointment({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerType,
    required this.userId,
    this.horseId,
    this.horseName,
    required this.appointmentDate,
    this.appointmentTime,
    this.duration,
    this.service,
    this.notes,
    this.location,
    this.status = AppointmentStatus.requested,
    this.estimatedCost,
    this.actualCost,
    this.feedback,
    this.rating,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPast => appointmentDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
  }

  factory ServiceAppointment.fromJson(Map<String, dynamic> json) {
    return ServiceAppointment(
      id: json['id'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      providerType: ServiceType.fromString(json['providerType'] as String? ?? 'other'),
      userId: json['userId'] as String? ?? '',
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      appointmentDate: json['appointmentDate'] != null ? DateTime.tryParse(json['appointmentDate'] as String) ?? DateTime.now() : DateTime.now(),
      appointmentTime: json['appointmentTime'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      service: json['service'] as String?,
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      status: AppointmentStatus.fromString(json['status'] as String? ?? 'requested'),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      actualCost: (json['actualCost'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'horseId': horseId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'duration': duration,
      'service': service,
      'notes': notes,
      'location': location,
      'status': status.name,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Appointment status
enum AppointmentStatus {
  requested,
  confirmed,
  rescheduled,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case AppointmentStatus.requested: return 'Demandé';
      case AppointmentStatus.confirmed: return 'Confirmé';
      case AppointmentStatus.rescheduled: return 'Reporté';
      case AppointmentStatus.inProgress: return 'En cours';
      case AppointmentStatus.completed: return 'Terminé';
      case AppointmentStatus.cancelled: return 'Annulé';
      case AppointmentStatus.noShow: return 'Absent';
    }
  }

  int get color {
    switch (this) {
      case AppointmentStatus.requested: return 0xFFFF9800;
      case AppointmentStatus.confirmed: return 0xFF4CAF50;
      case AppointmentStatus.rescheduled: return 0xFF2196F3;
      case AppointmentStatus.inProgress: return 0xFF00BCD4;
      case AppointmentStatus.completed: return 0xFF8BC34A;
      case AppointmentStatus.cancelled: return 0xFF9E9E9E;
      case AppointmentStatus.noShow: return 0xFFF44336;
    }
  }

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppointmentStatus.requested,
    );
  }
}

// ============================================
// FAVORITES & SAVED PROVIDERS
// ============================================

/// Saved/favorite provider
class SavedProvider {
  final String id;
  final String userId;
  final String providerId;
  final String providerName;
  final ServiceType providerType;
  final String? providerPhotoUrl;
  final String? notes;
  final DateTime savedAt;

  SavedProvider({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.providerType,
    this.providerPhotoUrl,
    this.notes,
    required this.savedAt,
  });

  factory SavedProvider.fromJson(Map<String, dynamic> json) {
    return SavedProvider(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      providerType: ServiceType.fromString(json['providerType'] as String? ?? 'other'),
      providerPhotoUrl: json['providerPhotoUrl'] as String?,
      notes: json['notes'] as String?,
      savedAt: json['savedAt'] != null ? DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ============================================
// SEARCH & FILTERS
// ============================================

/// Search filters for service providers
class ServiceSearchFilters {
  final List<ServiceType>? types;
  final String? query;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final double? minRating;
  final bool? acceptsEmergency;
  final bool? mobileService;
  final bool? isVerified;
  final List<String>? specialties;
  final String? sortBy; // rating, distance, name

  ServiceSearchFilters({
    this.types,
    this.query,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.minRating,
    this.acceptsEmergency,
    this.mobileService,
    this.isVerified,
    this.specialties,
    this.sortBy,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (types != null && types!.isNotEmpty) {
      params['types'] = types!.map((t) => t.name).join(',');
    }
    if (query != null && query!.isNotEmpty) params['q'] = query;
    if (latitude != null) params['lat'] = latitude.toString();
    if (longitude != null) params['lng'] = longitude.toString();
    if (radiusKm != null) params['radius'] = radiusKm.toString();
    if (minRating != null) params['minRating'] = minRating.toString();
    if (acceptsEmergency == true) params['emergency'] = 'true';
    if (mobileService == true) params['mobile'] = 'true';
    if (isVerified == true) params['verified'] = 'true';
    if (specialties != null && specialties!.isNotEmpty) {
      params['specialties'] = specialties!.join(',');
    }
    if (sortBy != null) params['sort'] = sortBy;
    return params;
  }
}

// ============================================
// EMERGENCY CONTACTS
// ============================================

/// Emergency contact list
class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final ServiceType type;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? notes;
  final bool isDefault;
  final int priority; // 1 = highest
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.notes,
    this.isDefault = false,
    this.priority = 1,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: ServiceType.fromString(json['type'] as String? ?? 'veterinarian'),
      phone: json['phone'] as String? ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'notes': notes,
      'isDefault': isDefault,
      'priority': priority,
    };
  }
}

// ============================================
// SERVICE STATISTICS
// ============================================

/// Service usage statistics
class ServiceStats {
  final String userId;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double totalSpent;
  final Map<String, int> appointmentsByType;
  final Map<String, double> spendingByType;
  final List<ServiceProvider> frequentProviders;
  final DateTime? lastAppointmentDate;
  final DateTime calculatedAt;

  ServiceStats({
    required this.userId,
    this.totalAppointments = 0,
    this.completedAppointments = 0,
    this.cancelledAppointments = 0,
    this.totalSpent = 0,
    this.appointmentsByType = const {},
    this.spendingByType = const {},
    this.frequentProviders = const [],
    this.lastAppointmentDate,
    required this.calculatedAt,
  });

  factory ServiceStats.fromJson(Map<String, dynamic> json) {
    return ServiceStats(
      userId: json['userId'] as String? ?? '',
      totalAppointments: (json['totalAppointments'] as num?)?.toInt() ?? 0,
      completedAppointments: (json['completedAppointments'] as num?)?.toInt() ?? 0,
      cancelledAppointments: (json['cancelledAppointments'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      appointmentsByType: (json['appointmentsByType'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)) ?? {},
      spendingByType: (json['spendingByType'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0)) ?? {},
      frequentProviders: (json['frequentProviders'] as List?)
          ?.map((p) => ServiceProvider.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      lastAppointmentDate: json['lastAppointmentDate'] != null
          ? DateTime.tryParse(json['lastAppointmentDate'] as String)
          : null,
      calculatedAt: json['calculatedAt'] != null ? DateTime.tryParse(json['calculatedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ============================================
// COMMON SPECIALTIES
// ============================================

/// Common specialties for different service types
class ServiceSpecialties {
  static const Map<ServiceType, List<String>> byType = {
    ServiceType.veterinarian: [
      'Médecine générale',
      'Chirurgie',
      'Reproduction',
      'Dentisterie',
      'Ophtalmologie',
      'Locomotion',
      'Imagerie',
      'Urgences',
      'Médecine sportive',
      'Néonatologie',
    ],
    ServiceType.farrier: [
      'Ferrure classique',
      'Ferrure orthopédique',
      'Parage naturel',
      'Ferrure sport',
      'Ferrure pathologique',
      'Travail à chaud',
      'Travail à froid',
    ],
    ServiceType.dentist: [
      'Dentisterie préventive',
      'Odontologie',
      'Chirurgie buccale',
      'Radiographie dentaire',
    ],
    ServiceType.osteopath: [
      'Ostéopathie structurelle',
      'Ostéopathie crânienne',
      'Ostéopathie viscérale',
      'Rééducation',
    ],
    ServiceType.physiotherapist: [
      'Kinésithérapie',
      'Hydrothérapie',
      'Électrothérapie',
      'Laserthérapie',
      'Tapis roulant',
    ],
    ServiceType.instructor: [
      'Dressage',
      'Saut d\'obstacles',
      'Concours complet',
      'Western',
      'Endurance',
      'Voltige',
      'Baby poney',
    ],
    ServiceType.trainer: [
      'Débourrage',
      'Rééducation',
      'Préparation concours',
      'Travail jeunes chevaux',
      'Valorisation',
    ],
  };
}
