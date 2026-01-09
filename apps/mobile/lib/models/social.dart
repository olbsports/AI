/// Visibility settings for notes and analyses
enum ContentVisibility {
  private,       // Only visible to owner
  organization,  // Visible to organization members
  followers,     // Visible to followers only
  public;        // Visible to everyone

  String get displayName {
    switch (this) {
      case ContentVisibility.private:
        return 'Privé';
      case ContentVisibility.organization:
        return 'Mon écurie';
      case ContentVisibility.followers:
        return 'Abonnés';
      case ContentVisibility.public:
        return 'Public';
    }
  }

  String get description {
    switch (this) {
      case ContentVisibility.private:
        return 'Visible uniquement par vous';
      case ContentVisibility.organization:
        return 'Visible par les membres de votre écurie';
      case ContentVisibility.followers:
        return 'Visible par vos abonnés';
      case ContentVisibility.public:
        return 'Visible par tout le monde';
    }
  }

  String get icon {
    switch (this) {
      case ContentVisibility.private:
        return '🔒';
      case ContentVisibility.organization:
        return '🏠';
      case ContentVisibility.followers:
        return '👥';
      case ContentVisibility.public:
        return '🌍';
    }
  }

  static ContentVisibility fromString(String value) {
    return ContentVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentVisibility.private,
    );
  }
}

/// Public note/post that can be shared on feed
class PublicNote {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String? horseId;
  final String? horseName;
  final String? horsePhotoUrl;
  final String? analysisId;
  final String content;
  final List<String> mediaUrls;
  final ContentVisibility visibility;
  final bool allowComments;
  final bool allowSharing;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked; // By current user
  final bool isSaved; // By current user
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PublicNote({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.horseId,
    this.horseName,
    this.horsePhotoUrl,
    this.analysisId,
    required this.content,
    this.mediaUrls = const [],
    this.visibility = ContentVisibility.public,
    this.allowComments = true,
    this.allowSharing = true,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory PublicNote.fromJson(Map<String, dynamic> json) {
    return PublicNote(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      horsePhotoUrl: json['horsePhotoUrl'] as String?,
      analysisId: json['analysisId'] as String?,
      content: json['content'] as String? ?? '',
      mediaUrls: (json['mediaUrls'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      visibility: ContentVisibility.fromString(json['visibility'] as String? ?? 'public'),
      allowComments: json['allowComments'] as bool? ?? true,
      allowSharing: json['allowSharing'] as bool? ?? true,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? (json['_count']?['likes'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? (json['_count']?['comments'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'horseId': horseId,
      'analysisId': analysisId,
      'mediaUrls': mediaUrls,
      'visibility': visibility.name,
      'allowComments': allowComments,
      'allowSharing': allowSharing,
      'tags': tags,
    };
  }
}

/// Comment on a public note
class NoteComment {
  final String id;
  final String noteId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final int likeCount;
  final bool isLiked;
  final String? parentId; // For nested comments
  final DateTime createdAt;

  NoteComment({
    required this.id,
    required this.noteId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.parentId,
    required this.createdAt,
  });

  factory NoteComment.fromJson(Map<String, dynamic> json) {
    return NoteComment(
      id: json['id'] as String? ?? '',
      noteId: json['noteId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      content: json['content'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? (json['_count']?['likes'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      parentId: json['parentId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// User badge/achievement
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    this.rarity = BadgeRarity.common,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      category: BadgeCategory.fromString(json['category'] as String? ?? 'general'),
      rarity: BadgeRarity.fromString(json['rarity'] as String? ?? 'common'),
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt'] as String) : null,
    );
  }
}

enum BadgeCategory {
  analysis,    // Analysis milestones
  training,    // Training achievements
  social,      // Community engagement
  competition, // Competition results
  streak,      // Consistency badges
  general;     // General achievements

  String get displayName {
    switch (this) {
      case BadgeCategory.analysis:
        return 'Analyses';
      case BadgeCategory.training:
        return 'Entraînement';
      case BadgeCategory.social:
        return 'Communauté';
      case BadgeCategory.competition:
        return 'Compétition';
      case BadgeCategory.streak:
        return 'Régularité';
      case BadgeCategory.general:
        return 'Général';
    }
  }

  static BadgeCategory fromString(String value) {
    return BadgeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeCategory.general,
    );
  }
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Commun';
      case BadgeRarity.uncommon:
        return 'Peu commun';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Épique';
      case BadgeRarity.legendary:
        return 'Légendaire';
    }
  }

  int get colorValue {
    switch (this) {
      case BadgeRarity.common:
        return 0xFF9E9E9E; // Grey
      case BadgeRarity.uncommon:
        return 0xFF4CAF50; // Green
      case BadgeRarity.rare:
        return 0xFF2196F3; // Blue
      case BadgeRarity.epic:
        return 0xFF9C27B0; // Purple
      case BadgeRarity.legendary:
        return 0xFFFF9800; // Orange/Gold
    }
  }

  static BadgeRarity fromString(String value) {
    return BadgeRarity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeRarity.common,
    );
  }
}

/// Follow relationship
class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String? ?? '',
      followerId: json['followerId'] as String? ?? '',
      followingId: json['followingId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Story type
enum StoryType {
  image,
  video;

  static StoryType fromString(String value) {
    return StoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StoryType.image,
    );
  }
}

/// Story model for 24-hour ephemeral content
class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String? thumbnailUrl;
  final StoryType mediaType;
  final int? duration; // in seconds for video
  final int viewsCount;
  final bool isViewed; // by current user
  final DateTime expiresAt;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    this.duration,
    this.viewsCount = 0,
    this.isViewed = false,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Check if story is expired (24h)
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Time remaining until expiry
  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      mediaUrl: json['mediaUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediaType: StoryType.fromString(json['mediaType'] as String? ?? 'image'),
      duration: json['duration'] as int?,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      isViewed: json['isViewed'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String) ?? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType.name,
      'duration': duration,
    };
  }
}

/// Group of stories by user
class StoryGroup {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final List<Story> stories;
  final bool hasUnviewed;

  StoryGroup({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.stories,
  }) : hasUnviewed = stories.any((s) => !s.isViewed);

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      stories: (json['stories'] as List?)
          ?.map((e) => Story.fromJson(e as Map<String, dynamic>))
          .where((s) => !s.isExpired)
          .toList() ?? [],
    );
  }
}

/// Hashtag with details
class Hashtag {
  final String tag;
  final int postCount;
  final int weeklyPostCount;
  final double trendScore;
  final bool isFollowing;
  final DateTime? lastUsedAt;

  Hashtag({
    required this.tag,
    required this.postCount,
    this.weeklyPostCount = 0,
    this.trendScore = 0.0,
    this.isFollowing = false,
    this.lastUsedAt,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      tag: json['tag'] as String? ?? '',
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      weeklyPostCount: (json['weeklyPostCount'] as num?)?.toInt() ?? 0,
      trendScore: (json['trendScore'] as num?)?.toDouble() ?? 0.0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
    );
  }
}

/// Follow status for profiles
enum FollowStatus {
  notFollowing,
  following,
  pending,   // Request sent, waiting for approval
  blocked;

  static FollowStatus fromString(String value) {
    return FollowStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FollowStatus.notFollowing,
    );
  }
}

/// Extended user profile for profile screen
class ExtendedUserProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int horseCount;
  final FollowStatus followStatus;
  final bool isFollowedBy;
  final bool isPrivate;
  final bool canMessage;
  final List<Badge> badges;
  final List<String> featuredHorseIds;
  final DateTime joinedAt;

  ExtendedUserProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    this.location,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.horseCount = 0,
    this.followStatus = FollowStatus.notFollowing,
    this.isFollowedBy = false,
    this.isPrivate = false,
    this.canMessage = true,
    this.badges = const [],
    this.featuredHorseIds = const [],
    required this.joinedAt,
  });

  bool get isFollowing => followStatus == FollowStatus.following;

  factory ExtendedUserProfile.fromJson(Map<String, dynamic> json) {
    return ExtendedUserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ??
          (json['_count']?['followers'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ??
          (json['_count']?['following'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt() ??
          (json['_count']?['notes'] as num?)?.toInt() ?? 0,
      horseCount: (json['horseCount'] as num?)?.toInt() ??
          (json['_count']?['horses'] as num?)?.toInt() ?? 0,
      followStatus: FollowStatus.fromString(json['followStatus'] as String? ?? 'notFollowing'),
      isFollowedBy: json['isFollowedBy'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      canMessage: json['canMessage'] as bool? ?? true,
      badges: (json['badges'] as List?)?.map((b) => Badge.fromJson(b as Map<String, dynamic>)).toList() ?? [],
      featuredHorseIds: (json['featuredHorseIds'] as List?)?.cast<String>() ?? [],
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
