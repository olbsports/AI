enum HorseGender { male, female, gelding }

enum HorseStatus { active, retired, sold, deceased }

class Horse {
  final String id;
  final String name;
  final String? breed;
  final HorseGender gender;
  final String? color;
  final DateTime? birthDate;
  final int? heightCm;
  final int? weight;
  final String? photoUrl;
  final String? ueln;
  final String? microchip;
  final String? passportNumber;
  final HorseStatus status;
  final String? notes;
  final String? riderId;
  final String? riderName;
  final String? sireId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int analysisCount;
  final int reportCount;

  Horse({
    required this.id,
    required this.name,
    this.breed,
    required this.gender,
    this.color,
    this.birthDate,
    this.heightCm,
    this.weight,
    this.photoUrl,
    this.ueln,
    this.microchip,
    this.passportNumber,
    required this.status,
    this.notes,
    this.riderId,
    this.riderName,
    this.sireId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.analysisCount = 0,
    this.reportCount = 0,
  });

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  String get genderLabel => switch (gender) {
    HorseGender.male => 'Étalon',
    HorseGender.female => 'Jument',
    HorseGender.gelding => 'Hongre',
  };

  String get statusLabel => switch (status) {
    HorseStatus.active => 'Actif',
    HorseStatus.retired => 'Retraité',
    HorseStatus.sold => 'Vendu',
    HorseStatus.deceased => 'Décédé',
  };

  factory Horse.fromJson(Map<String, dynamic> json) {
    return Horse(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String?,
      gender: HorseGender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => HorseGender.gelding,
      ),
      color: json['color'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      heightCm: json['heightCm'] as int?,
      weight: json['weight'] as int?,
      photoUrl: json['photoUrl'] as String?,
      ueln: json['ueln'] as String?,
      microchip: json['microchip'] as String?,
      passportNumber: json['passportNumber'] as String?,
      status: HorseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HorseStatus.active,
      ),
      notes: json['notes'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      sireId: json['sireId'] as String?,
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      analysisCount: json['_count']?['analyses'] as int? ?? 0,
      reportCount: json['_count']?['reports'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'gender': gender.name,
      'color': color,
      'birthDate': birthDate?.toIso8601String(),
      'heightCm': heightCm,
      'weight': weight,
      'photoUrl': photoUrl,
      'ueln': ueln,
      'microchip': microchip,
      'passportNumber': passportNumber,
      'status': status.name,
      'notes': notes,
      'riderId': riderId,
    };
  }
}
