/// Admin user model
class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.permissions = const [],
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    // Handle name: either 'name' field directly or combine firstName + lastName
    String name;
    if (json['name'] != null) {
      name = json['name'] as String;
    } else {
      final firstName = json['firstName'] as String? ?? '';
      final lastName = json['lastName'] as String? ?? '';
      name = '$firstName $lastName'.trim();
      if (name.isEmpty) {
        name = json['email'] as String? ?? 'Unknown';
      }
    }

    // Parse createdAt safely
    DateTime createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } else {
      createdAt = DateTime.now();
    }

    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: name,
      role: AdminRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AdminRole.support,
      ),
      permissions: (json['permissions'] as List?)?.cast<String>() ?? [],
      createdAt: createdAt,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }
}

/// Admin roles
enum AdminRole {
  superAdmin,
  admin,
  moderator,
  support,
  analyst;

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Administrateur';
      case AdminRole.moderator:
        return 'Modérateur';
      case AdminRole.support:
        return 'Support';
      case AdminRole.analyst:
        return 'Analyste';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case AdminRole.superAdmin:
        return ['*'];
      case AdminRole.admin:
        return [
          'users:read', 'users:write', 'users:delete',
          'subscriptions:read', 'subscriptions:write',
          'content:read', 'content:write', 'content:delete',
          'moderation:read', 'moderation:write',
          'analytics:read',
          'settings:read', 'settings:write',
        ];
      case AdminRole.moderator:
        return [
          'users:read',
          'content:read', 'content:write', 'content:delete',
          'moderation:read', 'moderation:write',
        ];
      case AdminRole.support:
        return [
          'users:read',
          'subscriptions:read',
          'support:read', 'support:write',
        ];
      case AdminRole.analyst:
        return [
          'analytics:read',
          'users:read',
        ];
    }
  }
}

/// App user (managed by admin)
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? phone;
  final UserStatus status;
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiresAt;
  final int horseCount;
  final int analysisCount;
  final int loginCount;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isVerified;
  final bool isBanned;
  final String? banReason;
  final List<String> flags;
  final Map<String, dynamic>? metadata;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phone,
    this.status = UserStatus.active,
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
    this.horseCount = 0,
    this.analysisCount = 0,
    this.loginCount = 0,
    required this.createdAt,
    this.lastActiveAt,
    this.isVerified = false,
    this.isBanned = false,
    this.banReason,
    this.flags = const [],
    this.metadata,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.parse(json['subscriptionExpiresAt'] as String)
          : null,
      horseCount: json['horseCount'] as int? ?? json['_count']?['horses'] as int? ?? 0,
      analysisCount: json['analysisCount'] as int? ?? json['_count']?['analyses'] as int? ?? 0,
      loginCount: json['loginCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      banReason: json['banReason'] as String?,
      flags: (json['flags'] as List?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// User status
enum UserStatus {
  active,
  inactive,
  suspended,
  banned,
  deleted;

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Actif';
      case UserStatus.inactive:
        return 'Inactif';
      case UserStatus.suspended:
        return 'Suspendu';
      case UserStatus.banned:
        return 'Banni';
      case UserStatus.deleted:
        return 'Supprimé';
    }
  }

  int get colorValue {
    switch (this) {
      case UserStatus.active:
        return 0xFF4CAF50;
      case UserStatus.inactive:
        return 0xFF9E9E9E;
      case UserStatus.suspended:
        return 0xFFFF9800;
      case UserStatus.banned:
        return 0xFFF44336;
      case UserStatus.deleted:
        return 0xFF757575;
    }
  }
}

/// Subscription model
class Subscription {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String planId;
  final String planName;
  final SubscriptionStatus status;
  final double amount;
  final String currency;
  final BillingInterval interval;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? nextBillingDate;
  final int invoiceCount;
  final double totalPaid;
  final String? stripeSubscriptionId;
  final Map<String, dynamic>? metadata;

  Subscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.planId,
    required this.planName,
    required this.status,
    required this.amount,
    this.currency = 'EUR',
    required this.interval,
    required this.startDate,
    this.endDate,
    this.cancelledAt,
    this.cancellationReason,
    this.nextBillingDate,
    this.invoiceCount = 0,
    this.totalPaid = 0,
    this.stripeSubscriptionId,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      interval: BillingInterval.values.firstWhere(
        (e) => e.name == json['interval'],
        orElse: () => BillingInterval.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      nextBillingDate: json['nextBillingDate'] != null
          ? DateTime.parse(json['nextBillingDate'] as String)
          : null,
      invoiceCount: json['invoiceCount'] as int? ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Subscription status
enum SubscriptionStatus {
  active,
  trialing,
  pastDue,
  cancelled,
  expired,
  paused;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.trialing:
        return 'Période d\'essai';
      case SubscriptionStatus.pastDue:
        return 'Impayée';
      case SubscriptionStatus.cancelled:
        return 'Annulée';
      case SubscriptionStatus.expired:
        return 'Expirée';
      case SubscriptionStatus.paused:
        return 'En pause';
    }
  }

  int get colorValue {
    switch (this) {
      case SubscriptionStatus.active:
        return 0xFF4CAF50;
      case SubscriptionStatus.trialing:
        return 0xFF2196F3;
      case SubscriptionStatus.pastDue:
        return 0xFFFF9800;
      case SubscriptionStatus.cancelled:
        return 0xFF9E9E9E;
      case SubscriptionStatus.expired:
        return 0xFFF44336;
      case SubscriptionStatus.paused:
        return 0xFF9E9E9E;
    }
  }
}

/// Billing interval
enum BillingInterval {
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case BillingInterval.monthly:
        return 'Mensuel';
      case BillingInterval.quarterly:
        return 'Trimestriel';
      case BillingInterval.yearly:
        return 'Annuel';
    }
  }
}

/// Subscription plan
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final int maxHorses;
  final int maxAnalysesPerMonth;
  final bool isActive;
  final int subscriberCount;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.maxHorses,
    required this.maxAnalysesPerMonth,
    this.isActive = true,
    this.subscriberCount = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
      features: (json['features'] as List).cast<String>(),
      maxHorses: json['maxHorses'] as int,
      maxAnalysesPerMonth: json['maxAnalysesPerMonth'] as int,
      isActive: json['isActive'] as bool? ?? true,
      subscriberCount: json['subscriberCount'] as int? ?? 0,
    );
  }
}

/// Content report (moderation)
class ContentReport {
  final String id;
  final String contentType; // note, comment, listing, user
  final String contentId;
  final String? contentPreview;
  final String reporterId;
  final String reporterName;
  final String reportReason;
  final String? reportDetails;
  final ReportStatus status;
  final String? moderatorId;
  final String? moderatorNotes;
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ContentReport({
    required this.id,
    required this.contentType,
    required this.contentId,
    this.contentPreview,
    required this.reporterId,
    required this.reporterName,
    required this.reportReason,
    this.reportDetails,
    this.status = ReportStatus.pending,
    this.moderatorId,
    this.moderatorNotes,
    this.actionTaken,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'] as String,
      contentType: json['contentType'] as String,
      contentId: json['contentId'] as String,
      contentPreview: json['contentPreview'] as String?,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      reportReason: json['reportReason'] as String,
      reportDetails: json['reportDetails'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      moderatorId: json['moderatorId'] as String?,
      moderatorNotes: json['moderatorNotes'] as String?,
      actionTaken: json['actionTaken'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }
}

/// Report status
enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed,
  escalated;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'En attente';
      case ReportStatus.reviewing:
        return 'En cours';
      case ReportStatus.resolved:
        return 'Résolu';
      case ReportStatus.dismissed:
        return 'Rejeté';
      case ReportStatus.escalated:
        return 'Escaladé';
    }
  }

  int get colorValue {
    switch (this) {
      case ReportStatus.pending:
        return 0xFFFF9800;
      case ReportStatus.reviewing:
        return 0xFF2196F3;
      case ReportStatus.resolved:
        return 0xFF4CAF50;
      case ReportStatus.dismissed:
        return 0xFF9E9E9E;
      case ReportStatus.escalated:
        return 0xFFF44336;
    }
  }
}

/// Support ticket
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assigneeId;
  final String? assigneeName;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int responseCount;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.category,
    this.priority = TicketPriority.normal,
    this.status = TicketStatus.open,
    this.assigneeId,
    this.assigneeName,
    this.messages = const [],
    required this.createdAt,
    this.resolvedAt,
    this.responseCount = 0,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: TicketCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TicketPriority.normal,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      assigneeId: json['assigneeId'] as String?,
      assigneeName: json['assigneeName'] as String?,
      messages: (json['messages'] as List?)
              ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      responseCount: json['responseCount'] as int? ?? 0,
    );
  }
}

/// Ticket message
class TicketMessage {
  final String id;
  final String authorId;
  final String authorName;
  final bool isStaff;
  final String content;
  final List<String> attachments;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.isStaff,
    required this.content,
    this.attachments = const [],
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      isStaff: json['isStaff'] as bool? ?? false,
      content: json['content'] as String,
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Ticket category
enum TicketCategory {
  billing,
  technical,
  account,
  feature,
  bug,
  other;

  String get displayName {
    switch (this) {
      case TicketCategory.billing:
        return 'Facturation';
      case TicketCategory.technical:
        return 'Technique';
      case TicketCategory.account:
        return 'Compte';
      case TicketCategory.feature:
        return 'Fonctionnalité';
      case TicketCategory.bug:
        return 'Bug';
      case TicketCategory.other:
        return 'Autre';
    }
  }
}

/// Ticket priority
enum TicketPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Basse';
      case TicketPriority.normal:
        return 'Normale';
      case TicketPriority.high:
        return 'Haute';
      case TicketPriority.urgent:
        return 'Urgente';
    }
  }

  int get colorValue {
    switch (this) {
      case TicketPriority.low:
        return 0xFF9E9E9E;
      case TicketPriority.normal:
        return 0xFF2196F3;
      case TicketPriority.high:
        return 0xFFFF9800;
      case TicketPriority.urgent:
        return 0xFFF44336;
    }
  }
}

/// Ticket status
enum TicketStatus {
  open,
  inProgress,
  waitingForUser,
  resolved,
  closed;

  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Ouvert';
      case TicketStatus.inProgress:
        return 'En cours';
      case TicketStatus.waitingForUser:
        return 'Attente utilisateur';
      case TicketStatus.resolved:
        return 'Résolu';
      case TicketStatus.closed:
        return 'Fermé';
    }
  }

  int get colorValue {
    switch (this) {
      case TicketStatus.open:
        return 0xFFFF9800;
      case TicketStatus.inProgress:
        return 0xFF2196F3;
      case TicketStatus.waitingForUser:
        return 0xFF9C27B0;
      case TicketStatus.resolved:
        return 0xFF4CAF50;
      case TicketStatus.closed:
        return 0xFF9E9E9E;
    }
  }
}

/// Dashboard statistics
class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final int totalHorses;
  final int totalAnalyses;
  final int analysesToday;
  final int activeSubscriptions;
  final double mrr; // Monthly Recurring Revenue
  final double arr; // Annual Recurring Revenue
  final double churnRate;
  final int pendingReports;
  final int openTickets;
  final List<TimeSeriesData> userGrowth;
  final List<TimeSeriesData> revenueGrowth;
  final List<TimeSeriesData> analysisGrowth;
  final Map<String, int> usersByPlan;
  final Map<String, int> usersByCountry;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.totalHorses,
    required this.totalAnalyses,
    required this.analysesToday,
    required this.activeSubscriptions,
    required this.mrr,
    required this.arr,
    required this.churnRate,
    required this.pendingReports,
    required this.openTickets,
    required this.userGrowth,
    required this.revenueGrowth,
    required this.analysisGrowth,
    required this.usersByPlan,
    required this.usersByCountry,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      newUsersToday: json['newUsersToday'] as int? ?? 0,
      newUsersThisWeek: json['newUsersThisWeek'] as int? ?? 0,
      newUsersThisMonth: json['newUsersThisMonth'] as int? ?? 0,
      totalHorses: json['totalHorses'] as int? ?? 0,
      totalAnalyses: json['totalAnalyses'] as int? ?? 0,
      analysesToday: json['analysesToday'] as int? ?? 0,
      activeSubscriptions: json['activeSubscriptions'] as int? ?? 0,
      mrr: (json['mrr'] as num?)?.toDouble() ?? 0,
      arr: (json['arr'] as num?)?.toDouble() ?? 0,
      churnRate: (json['churnRate'] as num?)?.toDouble() ?? 0,
      pendingReports: json['pendingReports'] as int? ?? 0,
      openTickets: json['openTickets'] as int? ?? 0,
      userGrowth: (json['userGrowth'] as List?)
              ?.map((e) => TimeSeriesData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      revenueGrowth: (json['revenueGrowth'] as List?)
              ?.map((e) => TimeSeriesData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analysisGrowth: (json['analysisGrowth'] as List?)
              ?.map((e) => TimeSeriesData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usersByPlan: (json['usersByPlan'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      usersByCountry: (json['usersByCountry'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

/// Time series data point
class TimeSeriesData {
  final DateTime date;
  final double value;

  TimeSeriesData({
    required this.date,
    required this.value,
  });

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

/// System settings
class SystemSettings {
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool registrationEnabled;
  final bool freeTrialEnabled;
  final int freeTrialDays;
  final double analysisPrice;
  final int maxAnalysesPerDay;
  final List<String> allowedFileTypes;
  final int maxFileSize;
  final Map<String, bool> featureFlags;
  final String? termsVersion;
  final String? privacyVersion;
  final DateTime? lastUpdated;

  SystemSettings({
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.registrationEnabled = true,
    this.freeTrialEnabled = true,
    this.freeTrialDays = 7,
    this.analysisPrice = 0,
    this.maxAnalysesPerDay = 100,
    this.allowedFileTypes = const ['jpg', 'png', 'mp4', 'mov'],
    this.maxFileSize = 100000000,
    this.featureFlags = const {},
    this.termsVersion,
    this.privacyVersion,
    this.lastUpdated,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      registrationEnabled: json['registrationEnabled'] as bool? ?? true,
      freeTrialEnabled: json['freeTrialEnabled'] as bool? ?? true,
      freeTrialDays: json['freeTrialDays'] as int? ?? 7,
      analysisPrice: (json['analysisPrice'] as num?)?.toDouble() ?? 0,
      maxAnalysesPerDay: json['maxAnalysesPerDay'] as int? ?? 100,
      allowedFileTypes: (json['allowedFileTypes'] as List?)?.cast<String>() ?? [],
      maxFileSize: json['maxFileSize'] as int? ?? 100000000,
      featureFlags: (json['featureFlags'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
      termsVersion: json['termsVersion'] as String?,
      privacyVersion: json['privacyVersion'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'registrationEnabled': registrationEnabled,
      'freeTrialEnabled': freeTrialEnabled,
      'freeTrialDays': freeTrialDays,
      'analysisPrice': analysisPrice,
      'maxAnalysesPerDay': maxAnalysesPerDay,
      'allowedFileTypes': allowedFileTypes,
      'maxFileSize': maxFileSize,
      'featureFlags': featureFlags,
      'termsVersion': termsVersion,
      'privacyVersion': privacyVersion,
    };
  }
}

/// Audit log entry
class AuditLog {
  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String resourceType;
  final String resourceId;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.changes,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      action: json['action'] as String,
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String,
      changes: json['changes'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
