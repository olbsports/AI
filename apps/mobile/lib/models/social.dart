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
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      horsePhotoUrl: json['horsePhotoUrl'] as String?,
      analysisId: json['analysisId'] as String?,
      content: json['content'] as String,
      mediaUrls: (json['mediaUrls'] as List?)?.cast<String>() ?? [],
      visibility: ContentVisibility.fromString(json['visibility'] as String? ?? 'public'),
      allowComments: json['allowComments'] as bool? ?? true,
      allowSharing: json['allowSharing'] as bool? ?? true,
      likeCount: json['likeCount'] as int? ?? json['_count']?['likes'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? json['_count']?['comments'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
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
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      content: json['content'] as String,
      likeCount: json['likeCount'] as int? ?? json['_count']?['likes'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      category: BadgeCategory.fromString(json['category'] as String? ?? 'general'),
      rarity: BadgeRarity.fromString(json['rarity'] as String? ?? 'common'),
      earnedAt: json['earnedAt'] != null ? DateTime.parse(json['earnedAt'] as String) : null,
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
      id: json['id'] as String,
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
