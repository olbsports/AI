enum AnalysisType {
  videoPerformance,
  videoCourse,
  radiological,
  locomotion,
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
  });

  String get typeLabel {
    switch (type) {
      case AnalysisType.videoPerformance:
        return 'Performance vidéo';
      case AnalysisType.videoCourse:
        return 'Parcours CSO';
      case AnalysisType.radiological:
        return 'Radiologique';
      case AnalysisType.locomotion:
        return 'Locomotion';
    }
  }

  String get statusLabel {
    switch (status) {
      case AnalysisStatus.pending:
        return 'En attente';
      case AnalysisStatus.processing:
        return 'En cours';
      case AnalysisStatus.completed:
        return 'Terminée';
      case AnalysisStatus.failed:
        return 'Échouée';
      case AnalysisStatus.cancelled:
        return 'Annulée';
    }
  }

  bool get isProcessing =>
      status == AnalysisStatus.pending || status == AnalysisStatus.processing;

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'] as String,
      title: json['title'] as String,
      type: _parseAnalysisType(json['type'] as String),
      status: AnalysisStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AnalysisStatus.pending,
      ),
      horseId: json['horseId'] as String,
      horseName: json['horse']?['name'] as String?,
      horsePhotoUrl: json['horse']?['photoUrl'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['rider']?['name'] as String?,
      inputMediaUrls: List<String>.from(json['inputMediaUrls'] ?? []),
      progress: json['progress'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      results: json['results'] as Map<String, dynamic>?,
      reportId: json['reportId'] as String?,
      tokensCost: json['tokensCost'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
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
      default:
        return AnalysisType.locomotion;
    }
  }

  String get typeApiValue {
    switch (type) {
      case AnalysisType.videoPerformance:
        return 'video_performance';
      case AnalysisType.videoCourse:
        return 'video_course';
      case AnalysisType.radiological:
        return 'radiological';
      case AnalysisType.locomotion:
        return 'locomotion';
    }
  }
}
