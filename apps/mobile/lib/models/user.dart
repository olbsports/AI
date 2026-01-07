class Organization {
  final String id;
  final String name;
  final String? logo;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.name,
    this.logo,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? phone;
  final String role;
  final String organizationId;
  final String? organizationName;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phone,
    required this.role,
    required this.organizationId,
    this.organizationName,
    required this.emailVerified,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle organization name from either organizationName field or organization.name
    String? orgName;
    if (json['organizationName'] != null) {
      orgName = json['organizationName'] as String?;
    } else if (json['organization'] != null && json['organization'] is Map) {
      final org = json['organization'] as Map<String, dynamic>;
      orgName = org['name'] as String?;
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      organizationId: json['organizationId'] as String,
      organizationName: orgName,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'role': role,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final Organization? organization;
  final int? expiresAt;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.organization,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      expiresAt: json['expiresAt'] as int?,
    );
  }
}
