class Rider {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? notes;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int horseCount;

  Rider({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.photoUrl,
    this.notes,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.horseCount = 0,
  });

  String get fullName => '$firstName $lastName';

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now() : DateTime.now(),
      horseCount: (json['_count']?['horses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'notes': notes,
    };
  }
}
