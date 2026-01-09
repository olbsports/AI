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
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
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
  final bool mfaEnabled;
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
    this.mfaEnabled = false,
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
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: orgName,
      emailVerified: json['emailVerified'] as bool? ?? false,
      mfaEnabled: json['mfaEnabled'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
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
      'mfaEnabled': mfaEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

/// Response for login when 2FA is required
class TwoFactorRequiredResponse {
  final String tempToken;
  final String message;

  TwoFactorRequiredResponse({
    required this.tempToken,
    required this.message,
  });

  factory TwoFactorRequiredResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorRequiredResponse(
      tempToken: json['tempToken'] as String? ?? '',
      message: json['message'] as String? ?? '2FA required',
    );
  }
}

/// Response for enabling 2FA - contains QR code and secret
class TwoFactorSetupResponse {
  final String secret;
  final String qrCodeUrl;
  final List<String> backupCodes;

  TwoFactorSetupResponse({
    required this.secret,
    required this.qrCodeUrl,
    required this.backupCodes,
  });

  factory TwoFactorSetupResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetupResponse(
      secret: json['secret'] as String? ?? '',
      qrCodeUrl: json['qrCodeUrl'] as String? ?? '',
      backupCodes: (json['backupCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Active session information
class UserSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final String? location;
  final String? userAgent;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  UserSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress,
    this.location,
    this.userAgent,
    required this.isCurrent,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      deviceType: json['deviceType'] as String? ?? 'unknown',
      ipAddress: json['ipAddress'] as String?,
      location: json['location'] as String?,
      userAgent: json['userAgent'] as String?,
      isCurrent: json['isCurrent'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'location': location,
      'userAgent': userAgent,
      'isCurrent': isCurrent,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }
}

/// Trusted device information
class TrustedDevice {
  final String id;
  final String deviceName;
  final String deviceType;
  final String? fingerprint;
  final DateTime createdAt;
  final DateTime? expiresAt;

  TrustedDevice({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.fingerprint,
    required this.createdAt,
    this.expiresAt,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      deviceType: json['deviceType'] as String? ?? 'unknown',
      fingerprint: json['fingerprint'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'fingerprint': fingerprint,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final Organization? organization;
  final int? expiresAt;
  final bool requires2FA;
  final String? tempToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.organization,
    this.expiresAt,
    this.requires2FA = false,
    this.tempToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Check if this is a 2FA required response
    final requires2FA = json['requires2FA'] as bool? ??
                        json['requiresTwoFactor'] as bool? ??
                        false;

    if (requires2FA) {
      return AuthResponse(
        user: User(
          id: '',
          email: json['email'] as String? ?? '',
          role: 'user',
          organizationId: '',
          emailVerified: false,
          createdAt: DateTime.now(),
        ),
        accessToken: '',
        refreshToken: '',
        requires2FA: true,
        tempToken: json['tempToken'] as String? ?? json['token'] as String?,
      );
    }

    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      expiresAt: (json['expiresAt'] as num?)?.toInt(),
      requires2FA: false,
    );
  }
}

/// Backup code for 2FA recovery
class BackupCode {
  final String code;
  final bool used;
  final DateTime? usedAt;

  BackupCode({
    required this.code,
    this.used = false,
    this.usedAt,
  });

  factory BackupCode.fromJson(Map<String, dynamic> json) {
    return BackupCode(
      code: json['code'] as String? ?? '',
      used: json['used'] as bool? ?? false,
      usedAt: json['usedAt'] != null
          ? DateTime.tryParse(json['usedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'used': used,
      'usedAt': usedAt?.toIso8601String(),
    };
  }
}

/// Login result that can be either success, 2FA required, or rate limited
class LoginResult {
  final bool success;
  final AuthResponse? authResponse;
  final bool requires2FA;
  final String? tempToken;
  final String? error;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  LoginResult({
    required this.success,
    this.authResponse,
    this.requires2FA = false,
    this.tempToken,
    this.error,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  factory LoginResult.success(AuthResponse response) {
    return LoginResult(
      success: true,
      authResponse: response,
    );
  }

  factory LoginResult.requires2FA(String tempToken) {
    return LoginResult(
      success: false,
      requires2FA: true,
      tempToken: tempToken,
    );
  }

  factory LoginResult.rateLimited(int retryAfterSeconds) {
    return LoginResult(
      success: false,
      isRateLimited: true,
      retryAfterSeconds: retryAfterSeconds,
      error: 'Trop de tentatives. Veuillez reessayer dans $retryAfterSeconds secondes.',
    );
  }

  factory LoginResult.error(String message) {
    return LoginResult(
      success: false,
      error: message,
    );
  }
}
