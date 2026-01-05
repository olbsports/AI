enum ReportType {
  radiological,
  locomotion,
  courseAnalysis,
  purchaseExam,
}

enum ReportStatus {
  draft,
  submitted,
  approved,
  rejected,
  archived,
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
  });

  String get typeLabel {
    switch (type) {
      case ReportType.radiological:
        return 'Radiologique';
      case ReportType.locomotion:
        return 'Locomotion';
      case ReportType.courseAnalysis:
        return 'Analyse de parcours';
      case ReportType.purchaseExam:
        return 'Visite d\'achat';
    }
  }

  String get statusLabel {
    switch (status) {
      case ReportStatus.draft:
        return 'Brouillon';
      case ReportStatus.submitted:
        return 'Soumis';
      case ReportStatus.approved:
        return 'Approuvé';
      case ReportStatus.rejected:
        return 'Rejeté';
      case ReportStatus.archived:
        return 'Archivé';
    }
  }

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
      default:
        return ReportType.locomotion;
    }
  }
}
