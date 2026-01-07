enum ReportType {
  radiological,
  locomotion,
  courseAnalysis,
  purchaseExam,
  // Legacy values for compatibility
  progress,
  veterinary,
  training,
  competition,
  health,
}

enum ReportStatus {
  draft,
  submitted,
  approved,
  rejected,
  archived,
  // Legacy values for compatibility
  generating,
  ready,
  failed,
}

class Report {
  final String id;
  final String title;
  final ReportType type;
  final ReportStatus status;
  final String? analysisId;
  final String horseId;
  final String? horseName;
  final String? horsePhotoUrl;
  final String? summary;
  final Map<String, dynamic>? content;
  final List<String> mediaUrls;
  final String? shareToken;
  final DateTime? sharedAt;
  final DateTime? expiresAt;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Additional fields for screens
  final List<dynamic>? analyses;
  final DateTime? generatedAt;
  final String? pdfUrl;

  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.analysisId,
    required this.horseId,
    this.horseName,
    this.horsePhotoUrl,
    this.summary,
    this.content,
    required this.mediaUrls,
    this.shareToken,
    this.sharedAt,
    this.expiresAt,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.analyses,
    this.generatedAt,
    this.pdfUrl,
  });

  String get typeLabel => switch (type) {
    ReportType.radiological => 'Radiologique',
    ReportType.locomotion => 'Locomotion',
    ReportType.courseAnalysis => 'Analyse de parcours',
    ReportType.purchaseExam => 'Visite d\'achat',
    ReportType.progress => 'Progression',
    ReportType.veterinary => 'Vétérinaire',
    ReportType.training => 'Entraînement',
    ReportType.competition => 'Compétition',
    ReportType.health => 'Santé',
  };

  String get statusLabel => switch (status) {
    ReportStatus.draft => 'Brouillon',
    ReportStatus.submitted => 'Soumis',
    ReportStatus.approved => 'Approuvé',
    ReportStatus.rejected => 'Rejeté',
    ReportStatus.archived => 'Archivé',
    ReportStatus.generating => 'Génération en cours',
    ReportStatus.ready => 'Prêt',
    ReportStatus.failed => 'Échoué',
  };

  bool get isShared => shareToken != null && sharedAt != null;

  bool get isShareExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      title: json['title'] as String,
      type: _parseReportType(json['type'] as String),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.draft,
      ),
      analysisId: json['analysisId'] as String?,
      horseId: json['horseId'] as String,
      horseName: json['horse']?['name'] as String?,
      horsePhotoUrl: json['horse']?['photoUrl'] as String?,
      summary: json['summary'] as String?,
      content: json['content'] as Map<String, dynamic>?,
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      shareToken: json['shareToken'] as String?,
      sharedAt: json['sharedAt'] != null
          ? DateTime.parse(json['sharedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      analyses: json['analyses'] as List<dynamic>?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
      pdfUrl: json['pdfUrl'] as String?,
    );
  }

  static ReportType _parseReportType(String type) {
    switch (type) {
      case 'radiological':
        return ReportType.radiological;
      case 'locomotion':
        return ReportType.locomotion;
      case 'course_analysis':
        return ReportType.courseAnalysis;
      case 'purchase_exam':
        return ReportType.purchaseExam;
      case 'progress':
        return ReportType.progress;
      case 'veterinary':
        return ReportType.veterinary;
      case 'training':
        return ReportType.training;
      case 'competition':
        return ReportType.competition;
      case 'health':
        return ReportType.health;
      default:
        return ReportType.locomotion;
    }
  }
}
