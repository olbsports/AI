enum AnalysisType {
  videoPerformance,
  videoCourse,
  radiological,
  locomotion,
  // Legacy values for compatibility
  jump,
  posture,
  conformation,
  course,
  video,
}

enum AnalysisStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class Analysis {
  final String id;
  final String title;
  final AnalysisType type;
  final AnalysisStatus status;
  final String horseId;
  final String? horseName;
  final String? horsePhotoUrl;
  final String? riderId;
  final String? riderName;
  final List<String> inputMediaUrls;
  final int progress;
  final String? errorMessage;
  final Map<String, dynamic>? results;
  final String? reportId;
  final int tokensCost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  // Additional fields for screens
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? notes;

  Analysis({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.horseId,
    this.horseName,
    this.horsePhotoUrl,
    this.riderId,
    this.riderName,
    required this.inputMediaUrls,
    this.progress = 0,
    this.errorMessage,
    this.results,
    this.reportId,
    this.tokensCost = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.thumbnailUrl,
    this.videoUrl,
    this.notes,
  });

  String get typeLabel => switch (type) {
    AnalysisType.videoPerformance => 'Performance vidéo',
    AnalysisType.videoCourse => 'Parcours CSO',
    AnalysisType.radiological => 'Radiologique',
    AnalysisType.locomotion => 'Locomotion',
    AnalysisType.jump => 'Saut',
    AnalysisType.posture => 'Posture',
    AnalysisType.conformation => 'Conformation',
    AnalysisType.course => 'Parcours',
    AnalysisType.video => 'Vidéo',
  };

  String get statusLabel => switch (status) {
    AnalysisStatus.pending => 'En attente',
    AnalysisStatus.processing => 'En cours',
    AnalysisStatus.completed => 'Terminée',
    AnalysisStatus.failed => 'Échouée',
    AnalysisStatus.cancelled => 'Annulée',
  };

  bool get isProcessing =>
      status == AnalysisStatus.pending || status == AnalysisStatus.processing;

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: _parseAnalysisType(json['type'] as String? ?? 'locomotion'),
      status: AnalysisStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => AnalysisStatus.pending,
      ),
      horseId: json['horseId'] as String? ?? '',
      horseName: json['horse']?['name'] as String?,
      horsePhotoUrl: json['horse']?['photoUrl'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['rider']?['name'] as String?,
      inputMediaUrls: (json['inputMediaUrls'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      results: json['results'] as Map<String, dynamic>?,
      reportId: json['reportId'] as String?,
      tokensCost: (json['tokensCost'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now() : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static AnalysisType _parseAnalysisType(String type) {
    switch (type) {
      case 'video_performance':
        return AnalysisType.videoPerformance;
      case 'video_course':
        return AnalysisType.videoCourse;
      case 'radiological':
        return AnalysisType.radiological;
      case 'locomotion':
        return AnalysisType.locomotion;
      case 'jump':
        return AnalysisType.jump;
      case 'posture':
        return AnalysisType.posture;
      case 'conformation':
        return AnalysisType.conformation;
      case 'course':
        return AnalysisType.course;
      case 'video':
        return AnalysisType.video;
      default:
        return AnalysisType.locomotion;
    }
  }

  String get typeApiValue => switch (type) {
    AnalysisType.videoPerformance => 'video_performance',
    AnalysisType.videoCourse => 'video_course',
    AnalysisType.radiological => 'radiological',
    AnalysisType.locomotion => 'locomotion',
    AnalysisType.jump => 'jump',
    AnalysisType.posture => 'posture',
    AnalysisType.conformation => 'conformation',
    AnalysisType.course => 'course',
    AnalysisType.video => 'video',
  };
}
