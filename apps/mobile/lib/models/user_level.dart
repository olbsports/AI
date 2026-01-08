/// Types de compte utilisateur
enum UserAccountType {
  cavalier,   // Cavalier individuel
  ecurie,     // Écurie/Centre équestre
  haras,      // Haras/Élevage
  veterinaire, // Vétérinaire
  marechal,   // Maréchal-ferrant
  coach,      // Coach/Moniteur
}

extension UserAccountTypeExtension on UserAccountType {
  String get displayName {
    switch (this) {
      case UserAccountType.cavalier:
        return 'Cavalier';
      case UserAccountType.ecurie:
        return 'Écurie';
      case UserAccountType.haras:
        return 'Haras';
      case UserAccountType.veterinaire:
        return 'Vétérinaire';
      case UserAccountType.marechal:
        return 'Maréchal-ferrant';
      case UserAccountType.coach:
        return 'Coach';
    }
  }

  String get description {
    switch (this) {
      case UserAccountType.cavalier:
        return 'Gérez vos chevaux personnels';
      case UserAccountType.ecurie:
        return 'Gérez votre centre équestre et vos employés';
      case UserAccountType.haras:
        return 'Gérez votre élevage et vos reproductions';
      case UserAccountType.veterinaire:
        return 'Suivez vos patients équins';
      case UserAccountType.marechal:
        return 'Gérez vos interventions et plannings';
      case UserAccountType.coach:
        return 'Suivez vos élèves et leurs progrès';
    }
  }

  String get iconName {
    switch (this) {
      case UserAccountType.cavalier:
        return 'person';
      case UserAccountType.ecurie:
        return 'business';
      case UserAccountType.haras:
        return 'nature';
      case UserAccountType.veterinaire:
        return 'local_hospital';
      case UserAccountType.marechal:
        return 'construction';
      case UserAccountType.coach:
        return 'school';
    }
  }

  /// Nombre maximum de chevaux selon le type de compte
  int get maxHorses {
    switch (this) {
      case UserAccountType.cavalier:
        return 5;
      case UserAccountType.ecurie:
        return -1; // Illimité
      case UserAccountType.haras:
        return -1;
      case UserAccountType.veterinaire:
        return -1;
      case UserAccountType.marechal:
        return 0; // Pas de chevaux propres
      case UserAccountType.coach:
        return 10;
    }
  }

  /// Peut gérer des employés
  bool get canManageEmployees {
    switch (this) {
      case UserAccountType.cavalier:
        return false;
      case UserAccountType.ecurie:
        return true;
      case UserAccountType.haras:
        return true;
      case UserAccountType.veterinaire:
        return true;
      case UserAccountType.marechal:
        return false;
      case UserAccountType.coach:
        return false;
    }
  }

  /// Peut gérer la reproduction
  bool get canManageBreeding {
    switch (this) {
      case UserAccountType.cavalier:
        return false;
      case UserAccountType.ecurie:
        return true;
      case UserAccountType.haras:
        return true;
      case UserAccountType.veterinaire:
        return true;
      case UserAccountType.marechal:
        return false;
      case UserAccountType.coach:
        return false;
    }
  }

  /// Peut gérer la nutrition avec IA
  bool get canUseNutritionAI {
    switch (this) {
      case UserAccountType.cavalier:
        return true;
      case UserAccountType.ecurie:
        return true;
      case UserAccountType.haras:
        return true;
      case UserAccountType.veterinaire:
        return true;
      case UserAccountType.marechal:
        return false;
      case UserAccountType.coach:
        return true;
    }
  }

  /// Accès aux analyses IA avancées
  bool get hasAdvancedAI {
    switch (this) {
      case UserAccountType.cavalier:
        return false;
      case UserAccountType.ecurie:
        return true;
      case UserAccountType.haras:
        return true;
      case UserAccountType.veterinaire:
        return true;
      case UserAccountType.marechal:
        return false;
      case UserAccountType.coach:
        return true;
    }
  }

  /// Features disponibles selon le type de compte
  List<String> get features {
    switch (this) {
      case UserAccountType.cavalier:
        return [
          'Gestion de 5 chevaux max',
          'Suivi santé basique',
          'Analyses vidéo',
          'Planning personnel',
          'Accès communauté',
        ];
      case UserAccountType.ecurie:
        return [
          'Chevaux illimités',
          'Gestion des employés',
          'Planning multi-utilisateurs',
          'Suivi santé avancé',
          'Analyses IA complètes',
          'Gestion nutritionnelle IA',
          'Rapports détaillés',
          'Facturation clients',
        ];
      case UserAccountType.haras:
        return [
          'Chevaux illimités',
          'Gestion reproduction',
          'Suivi gestation complet',
          'Gestion génétique',
          'Analyses IA complètes',
          'Gestion nutritionnelle IA',
          'Gestion des employés',
          'Marketplace intégré',
        ];
      case UserAccountType.veterinaire:
        return [
          'Dossiers patients illimités',
          'Historique médical complet',
          'Analyses radiologiques IA',
          'Ordonnances numériques',
          'Planning rendez-vous',
          'Gestion des employés',
          'Rapports médicaux',
        ];
      case UserAccountType.marechal:
        return [
          'Planning interventions',
          'Historique ferrures',
          'Géolocalisation clients',
          'Facturation simplifiée',
          'Photos avant/après',
        ];
      case UserAccountType.coach:
        return [
          'Suivi élèves',
          'Gestion 10 chevaux',
          'Planning cours',
          'Analyses vidéo',
          'Progression élèves',
          'Recommandations IA',
        ];
    }
  }
}

/// Profil utilisateur avec niveau de compte
class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final UserAccountType accountType;
  final String? organizationName; // Pour écurie/haras
  final String? siret;            // Numéro SIRET pour pros
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? permissions;

  UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.accountType = UserAccountType.cavalier,
    this.organizationName,
    this.siret,
    this.phone,
    this.address,
    required this.createdAt,
    this.updatedAt,
    this.settings,
    this.permissions,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email.split('@').first;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accountType: _parseAccountType(json['accountType']),
      organizationName: json['organizationName'] as String?,
      siret: json['siret'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      settings: json['settings'] as Map<String, dynamic>?,
      permissions: json['permissions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'accountType': accountType.name,
      'organizationName': organizationName,
      'siret': siret,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'settings': settings,
      'permissions': permissions,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    UserAccountType? accountType,
    String? organizationName,
    String? siret,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? permissions,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      accountType: accountType ?? this.accountType,
      organizationName: organizationName ?? this.organizationName,
      siret: siret ?? this.siret,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      permissions: permissions ?? this.permissions,
    );
  }

  static UserAccountType _parseAccountType(dynamic value) {
    if (value == null) return UserAccountType.cavalier;
    if (value is UserAccountType) return value;
    if (value is String) {
      return UserAccountType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserAccountType.cavalier,
      );
    }
    return UserAccountType.cavalier;
  }
}

/// Employé d'une écurie/haras
class Employee {
  final String id;
  final String organizationId;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final EmployeeRole role;
  final List<String> permissions;
  final bool isActive;
  final DateTime hiredAt;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    required this.hiredAt,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: _parseRole(json['role']),
      permissions: (json['permissions'] as List?)?.cast<String>() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      hiredAt: json['hiredAt'] != null
          ? DateTime.parse(json['hiredAt'] as String)
          : DateTime.now(),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'permissions': permissions,
      'isActive': isActive,
      'hiredAt': hiredAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  static EmployeeRole _parseRole(dynamic value) {
    if (value == null) return EmployeeRole.groom;
    if (value is EmployeeRole) return value;
    if (value is String) {
      return EmployeeRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EmployeeRole.groom,
      );
    }
    return EmployeeRole.groom;
  }
}

enum EmployeeRole {
  admin,      // Administrateur
  manager,    // Responsable
  instructor, // Moniteur/Coach
  groom,      // Palefrenier/Soigneur
  veterinary, // Vétérinaire affilié
  farrier,    // Maréchal affilié
  secretary,  // Secrétaire
}

extension EmployeeRoleExtension on EmployeeRole {
  String get displayName {
    switch (this) {
      case EmployeeRole.admin:
        return 'Administrateur';
      case EmployeeRole.manager:
        return 'Responsable';
      case EmployeeRole.instructor:
        return 'Moniteur';
      case EmployeeRole.groom:
        return 'Palefrenier';
      case EmployeeRole.veterinary:
        return 'Vétérinaire';
      case EmployeeRole.farrier:
        return 'Maréchal-ferrant';
      case EmployeeRole.secretary:
        return 'Secrétaire';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case EmployeeRole.admin:
        return ['all'];
      case EmployeeRole.manager:
        return ['horses', 'employees', 'planning', 'reports', 'billing'];
      case EmployeeRole.instructor:
        return ['horses', 'planning', 'students'];
      case EmployeeRole.groom:
        return ['horses', 'health', 'feeding'];
      case EmployeeRole.veterinary:
        return ['horses', 'health', 'medical'];
      case EmployeeRole.farrier:
        return ['horses', 'farrier'];
      case EmployeeRole.secretary:
        return ['planning', 'billing', 'clients'];
    }
  }
}
