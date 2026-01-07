/// Complete Clubs & Stables System for Horse Vision AI

import 'package:flutter/material.dart';

// ============================================
// CLUBS / VIRTUAL STABLES
// ============================================

/// Club or stable organization
class Club {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final ClubType type;
  final String ownerId;
  final String ownerName;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final ClubVisibility visibility;
  final int memberCount;
  final int horseCount;
  final int totalXp;
  final int rank;
  final List<ClubBadge> badges;
  final ClubSettings settings;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Club({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    this.visibility = ClubVisibility.public,
    this.memberCount = 0,
    this.horseCount = 0,
    this.totalXp = 0,
    this.rank = 0,
    this.badges = const [],
    required this.settings,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      type: ClubType.fromString(json['type'] as String? ?? 'stable'),
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      location: json['location'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      visibility: ClubVisibility.fromString(json['visibility'] as String? ?? 'public'),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      horseCount: (json['horseCount'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List?)
          ?.map((b) => ClubBadge.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      settings: json['settings'] != null
          ? ClubSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : ClubSettings(),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'type': type.name,
      'ownerId': ownerId,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'visibility': visibility.name,
      'settings': settings.toJson(),
    };
  }
}

/// Club types
enum ClubType {
  stable,         // Écurie
  ridingSchool,   // Centre équestre
  breedingFarm,   // Haras
  association,    // Association
  team,           // Équipe
  informal;       // Groupe informel

  String get displayName {
    switch (this) {
      case ClubType.stable: return 'Écurie';
      case ClubType.ridingSchool: return 'Centre équestre';
      case ClubType.breedingFarm: return 'Haras';
      case ClubType.association: return 'Association';
      case ClubType.team: return 'Équipe';
      case ClubType.informal: return 'Groupe';
    }
  }

  IconData get icon {
    switch (this) {
      case ClubType.stable: return Icons.home;
      case ClubType.ridingSchool: return Icons.school;
      case ClubType.breedingFarm: return Icons.pets;
      case ClubType.association: return Icons.groups;
      case ClubType.team: return Icons.emoji_events;
      case ClubType.informal: return Icons.people;
    }
  }

  static ClubType fromString(String value) {
    return ClubType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubType.stable,
    );
  }
}

/// Club visibility
enum ClubVisibility {
  public,     // Visible par tous
  private,    // Sur invitation
  hidden;     // Caché des recherches

  String get displayName {
    switch (this) {
      case ClubVisibility.public: return 'Public';
      case ClubVisibility.private: return 'Privé';
      case ClubVisibility.hidden: return 'Caché';
    }
  }

  static ClubVisibility fromString(String value) {
    return ClubVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubVisibility.public,
    );
  }
}

/// Club settings
class ClubSettings {
  final bool allowMemberPosts;
  final bool requireApproval;
  final bool showInLeaderboard;
  final bool allowChallenges;
  final bool notifyNewMembers;
  final int maxMembers;
  final List<String> requiredFields;

  ClubSettings({
    this.allowMemberPosts = true,
    this.requireApproval = false,
    this.showInLeaderboard = true,
    this.allowChallenges = true,
    this.notifyNewMembers = true,
    this.maxMembers = 100,
    this.requiredFields = const [],
  });

  factory ClubSettings.fromJson(Map<String, dynamic> json) {
    return ClubSettings(
      allowMemberPosts: json['allowMemberPosts'] as bool? ?? true,
      requireApproval: json['requireApproval'] as bool? ?? false,
      showInLeaderboard: json['showInLeaderboard'] as bool? ?? true,
      allowChallenges: json['allowChallenges'] as bool? ?? true,
      notifyNewMembers: json['notifyNewMembers'] as bool? ?? true,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 100,
      requiredFields: (json['requiredFields'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowMemberPosts': allowMemberPosts,
      'requireApproval': requireApproval,
      'showInLeaderboard': showInLeaderboard,
      'allowChallenges': allowChallenges,
      'notifyNewMembers': notifyNewMembers,
      'maxMembers': maxMembers,
      'requiredFields': requiredFields,
    };
  }
}

// ============================================
// CLUB MEMBERSHIP
// ============================================

/// Member of a club
class ClubMember {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String clubId;
  final ClubRole role;
  final MemberStatus status;
  final int xpContribution;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final List<String> permissions;

  ClubMember({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.clubId,
    this.role = ClubRole.member,
    this.status = MemberStatus.active,
    this.xpContribution = 0,
    required this.joinedAt,
    this.lastActiveAt,
    this.permissions = const [],
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      clubId: json['clubId'] as String? ?? '',
      role: ClubRole.fromString(json['role'] as String? ?? 'member'),
      status: MemberStatus.fromString(json['status'] as String? ?? 'active'),
      xpContribution: (json['xpContribution'] as num?)?.toInt() ?? 0,
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now() : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
      permissions: (json['permissions'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
    );
  }
}

/// Club roles
enum ClubRole {
  owner,      // Propriétaire
  admin,      // Administrateur
  moderator,  // Modérateur
  coach,      // Coach/Enseignant
  member;     // Membre

  String get displayName {
    switch (this) {
      case ClubRole.owner: return 'Propriétaire';
      case ClubRole.admin: return 'Administrateur';
      case ClubRole.moderator: return 'Modérateur';
      case ClubRole.coach: return 'Coach';
      case ClubRole.member: return 'Membre';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case ClubRole.owner:
        return ['manage_club', 'manage_members', 'manage_events', 'post', 'challenge'];
      case ClubRole.admin:
        return ['manage_members', 'manage_events', 'post', 'challenge'];
      case ClubRole.moderator:
        return ['manage_events', 'post', 'challenge'];
      case ClubRole.coach:
        return ['manage_events', 'post'];
      case ClubRole.member:
        return ['post'];
    }
  }

  static ClubRole fromString(String value) {
    return ClubRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubRole.member,
    );
  }
}

/// Member status
enum MemberStatus {
  pending,    // En attente d'approbation
  active,     // Actif
  inactive,   // Inactif
  banned;     // Banni

  static MemberStatus fromString(String value) {
    return MemberStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemberStatus.active,
    );
  }
}

// ============================================
// CLUB BADGES
// ============================================

/// Club-specific badge
class ClubBadge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final ClubBadgeType type;
  final DateTime earnedAt;

  ClubBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.earnedAt,
  });

  factory ClubBadge.fromJson(Map<String, dynamic> json) {
    return ClubBadge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      type: ClubBadgeType.fromString(json['type'] as String? ?? 'achievement'),
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

enum ClubBadgeType {
  achievement,  // Performance
  activity,     // Activité
  milestone,    // Milestone
  special;      // Spécial

  static ClubBadgeType fromString(String value) {
    return ClubBadgeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubBadgeType.achievement,
    );
  }
}

// ============================================
// CLUB RANKINGS
// ============================================

/// Club leaderboard entry
class ClubLeaderboardEntry {
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final ClubType clubType;
  final int rank;
  final int previousRank;
  final int totalXp;
  final int memberCount;
  final int analysisCount;
  final int challengesWon;
  final String? region;

  ClubLeaderboardEntry({
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.clubType,
    required this.rank,
    this.previousRank = 0,
    required this.totalXp,
    required this.memberCount,
    this.analysisCount = 0,
    this.challengesWon = 0,
    this.region,
  });

  int get rankChange => previousRank > 0 ? previousRank - rank : 0;

  factory ClubLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ClubLeaderboardEntry(
      clubId: json['clubId'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      clubLogoUrl: json['clubLogoUrl'] as String?,
      clubType: ClubType.fromString(json['clubType'] as String? ?? 'stable'),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      previousRank: (json['previousRank'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      analysisCount: (json['analysisCount'] as num?)?.toInt() ?? 0,
      challengesWon: (json['challengesWon'] as num?)?.toInt() ?? 0,
      region: json['region'] as String?,
    );
  }
}

// ============================================
// CLUB CHALLENGES
// ============================================

/// Challenge between clubs
class ClubChallenge {
  final String id;
  final String title;
  final String? description;
  final String challengerClubId;
  final String challengerClubName;
  final String challengedClubId;
  final String challengedClubName;
  final ChallengeCategory category;
  final int targetValue;
  final int challengerProgress;
  final int challengedProgress;
  final DateTime startDate;
  final DateTime endDate;
  final ClubChallengeStatus status;
  final String? winnerId;
  final int xpReward;
  final DateTime createdAt;

  ClubChallenge({
    required this.id,
    required this.title,
    this.description,
    required this.challengerClubId,
    required this.challengerClubName,
    required this.challengedClubId,
    required this.challengedClubName,
    required this.category,
    required this.targetValue,
    this.challengerProgress = 0,
    this.challengedProgress = 0,
    required this.startDate,
    required this.endDate,
    this.status = ClubChallengeStatus.pending,
    this.winnerId,
    this.xpReward = 500,
    required this.createdAt,
  });

  bool get isActive => status == ClubChallengeStatus.active;
  bool get isCompleted => status == ClubChallengeStatus.completed;
  Duration get timeRemaining => endDate.difference(DateTime.now());

  factory ClubChallenge.fromJson(Map<String, dynamic> json) {
    return ClubChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      challengerClubId: json['challengerClubId'] as String? ?? '',
      challengerClubName: json['challengerClubName'] as String? ?? '',
      challengedClubId: json['challengedClubId'] as String? ?? '',
      challengedClubName: json['challengedClubName'] as String? ?? '',
      category: ChallengeCategory.fromString(json['category'] as String? ?? 'analysisCount'),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
      challengerProgress: (json['challengerProgress'] as num?)?.toInt() ?? 0,
      challengedProgress: (json['challengedProgress'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now() : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now().add(Duration(days: 7)) : DateTime.now().add(Duration(days: 7)),
      status: ClubChallengeStatus.fromString(json['status'] as String? ?? 'pending'),
      winnerId: json['winnerId'] as String?,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 500,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Challenge categories
enum ChallengeCategory {
  analysisCount,      // Nombre d'analyses
  totalXp,            // XP total
  trainingHours,      // Heures d'entraînement
  competitionResults, // Résultats compétition
  streakDays;         // Jours de série

  String get displayName {
    switch (this) {
      case ChallengeCategory.analysisCount: return 'Analyses';
      case ChallengeCategory.totalXp: return 'XP Total';
      case ChallengeCategory.trainingHours: return 'Heures d\'entraînement';
      case ChallengeCategory.competitionResults: return 'Compétitions';
      case ChallengeCategory.streakDays: return 'Jours consécutifs';
    }
  }

  static ChallengeCategory fromString(String value) {
    return ChallengeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeCategory.analysisCount,
    );
  }
}

/// Club challenge status
enum ClubChallengeStatus {
  pending,    // En attente d'acceptation
  active,     // En cours
  completed,  // Terminé
  declined,   // Refusé
  cancelled;  // Annulé

  String get displayName {
    switch (this) {
      case ClubChallengeStatus.pending: return 'En attente';
      case ClubChallengeStatus.active: return 'En cours';
      case ClubChallengeStatus.completed: return 'Terminé';
      case ClubChallengeStatus.declined: return 'Refusé';
      case ClubChallengeStatus.cancelled: return 'Annulé';
    }
  }

  static ClubChallengeStatus fromString(String value) {
    return ClubChallengeStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubChallengeStatus.pending,
    );
  }
}

// ============================================
// CLUB EVENTS
// ============================================

/// Club-organized event
class ClubEvent {
  final String id;
  final String clubId;
  final String clubName;
  final String title;
  final String? description;
  final ClubEventType type;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? address;
  final int maxParticipants;
  final int currentParticipants;
  final double? price;
  final String? imageUrl;
  final List<String> participantIds;
  final ClubEventStatus status;
  final String? createdBy;
  final DateTime createdAt;

  ClubEvent({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    this.location,
    this.address,
    this.maxParticipants = 0,
    this.currentParticipants = 0,
    this.price,
    this.imageUrl,
    this.participantIds = const [],
    this.status = ClubEventStatus.upcoming,
    this.createdBy,
    required this.createdAt,
  });

  bool get isFull => maxParticipants > 0 && currentParticipants >= maxParticipants;
  bool get isFree => price == null || price == 0;

  factory ClubEvent.fromJson(Map<String, dynamic> json) {
    return ClubEvent(
      id: json['id'] as String? ?? '',
      clubId: json['clubId'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: ClubEventType.fromString(json['type'] as String? ?? 'other'),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now() : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      location: json['location'] as String?,
      address: json['address'] as String?,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
      currentParticipants: (json['currentParticipants'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      participantIds: (json['participantIds'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      status: ClubEventStatus.fromString(json['status'] as String? ?? 'upcoming'),
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Club event types
enum ClubEventType {
  training,       // Entraînement collectif
  competition,    // Concours interne
  clinic,         // Stage
  social,         // Événement social
  meeting,        // Réunion
  openDay,        // Journée portes ouvertes
  fundraiser,     // Collecte de fonds
  other;

  String get displayName {
    switch (this) {
      case ClubEventType.training: return 'Entraînement';
      case ClubEventType.competition: return 'Concours';
      case ClubEventType.clinic: return 'Stage';
      case ClubEventType.social: return 'Événement social';
      case ClubEventType.meeting: return 'Réunion';
      case ClubEventType.openDay: return 'Portes ouvertes';
      case ClubEventType.fundraiser: return 'Collecte de fonds';
      case ClubEventType.other: return 'Autre';
    }
  }

  static ClubEventType fromString(String value) {
    return ClubEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubEventType.other,
    );
  }
}

/// Club event status
enum ClubEventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled;

  static ClubEventStatus fromString(String value) {
    return ClubEventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClubEventStatus.upcoming,
    );
  }
}

// ============================================
// CLUB FEED/POSTS
// ============================================

/// Post in club feed
class ClubPost {
  final String id;
  final String clubId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final PostType type;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClubPost({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.type = PostType.general,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'] as String? ?? '',
      clubId: json['clubId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      videoUrl: json['videoUrl'] as String?,
      type: PostType.fromString(json['type'] as String? ?? 'general'),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

enum PostType {
  general,
  announcement,
  achievement,
  question,
  event;

  static PostType fromString(String value) {
    return PostType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostType.general,
    );
  }
}

// ============================================
// CLUB INVITATION
// ============================================

/// Invitation to join a club
class ClubInvitation {
  final String id;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String inviterId;
  final String inviterName;
  final String inviteeId;
  final String? inviteeEmail;
  final String? message;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;

  ClubInvitation({
    required this.id,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    this.inviteeEmail,
    this.message,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    this.expiresAt,
    this.respondedAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory ClubInvitation.fromJson(Map<String, dynamic> json) {
    return ClubInvitation(
      id: json['id'] as String? ?? '',
      clubId: json['clubId'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      clubLogoUrl: json['clubLogoUrl'] as String?,
      inviterId: json['inviterId'] as String? ?? '',
      inviterName: json['inviterName'] as String? ?? '',
      inviteeId: json['inviteeId'] as String? ?? '',
      inviteeEmail: json['inviteeEmail'] as String?,
      message: json['message'] as String?,
      status: InvitationStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'] as String)
          : null,
    );
  }
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

// ============================================
// CLUB STATISTICS
// ============================================

/// Club statistics and analytics
class ClubStats {
  final String clubId;
  final int totalMembers;
  final int activeMembers;
  final int totalHorses;
  final int totalAnalyses;
  final int totalXp;
  final int rank;
  final int challengesWon;
  final int challengesLost;
  final double averageMemberXp;
  final List<MonthlyActivity> monthlyActivity;
  final DateTime calculatedAt;

  ClubStats({
    required this.clubId,
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.totalHorses = 0,
    this.totalAnalyses = 0,
    this.totalXp = 0,
    this.rank = 0,
    this.challengesWon = 0,
    this.challengesLost = 0,
    this.averageMemberXp = 0,
    this.monthlyActivity = const [],
    required this.calculatedAt,
  });

  factory ClubStats.fromJson(Map<String, dynamic> json) {
    return ClubStats(
      clubId: json['clubId'] as String? ?? '',
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      totalHorses: (json['totalHorses'] as num?)?.toInt() ?? 0,
      totalAnalyses: (json['totalAnalyses'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      challengesWon: (json['challengesWon'] as num?)?.toInt() ?? 0,
      challengesLost: (json['challengesLost'] as num?)?.toInt() ?? 0,
      averageMemberXp: (json['averageMemberXp'] as num?)?.toDouble() ?? 0,
      monthlyActivity: (json['monthlyActivity'] as List?)
          ?.map((m) => MonthlyActivity.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      calculatedAt: json['calculatedAt'] != null ? DateTime.tryParse(json['calculatedAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Monthly activity data
class MonthlyActivity {
  final int year;
  final int month;
  final int analyses;
  final int xpEarned;
  final int newMembers;

  MonthlyActivity({
    required this.year,
    required this.month,
    this.analyses = 0,
    this.xpEarned = 0,
    this.newMembers = 0,
  });

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    return MonthlyActivity(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      analyses: (json['analyses'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      newMembers: (json['newMembers'] as num?)?.toInt() ?? 0,
    );
  }
}
