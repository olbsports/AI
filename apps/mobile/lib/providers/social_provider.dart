import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:dio/dio.dart';
import '../models/social.dart';
import '../services/api_service.dart';

/// Helper to check if error is 404
bool _is404Error(Object error) {
  if (error is DioException) {
    return error.response?.statusCode == 404;
  }
  return false;
}

/// Feed type
enum FeedType {
  forYou,      // Algorithmic feed
  following,   // Only from followed users
  discover,    // Discover new content
  trending,    // Trending posts
}

/// Current feed type
final feedTypeProvider = StateProvider<FeedType>((ref) => FeedType.forYou);

/// Social feed (paginated)
final socialFeedProvider =
    FutureProvider.family<List<PublicNote>, ({FeedType type, int page})>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/feed', queryParams: {
    'type': params.type.name,
    'page': params.page.toString(),
  });
  return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
});

/// For You feed
final forYouFeedProvider = FutureProvider<List<PublicNote>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/feed/for-you');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Following feed
final followingFeedProvider = FutureProvider<List<PublicNote>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/feed/following');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Trending posts
final trendingPostsProvider = FutureProvider<List<PublicNote>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/feed/trending');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Note by ID
final noteProvider =
    FutureProvider.family<PublicNote, String>((ref, noteId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/notes/$noteId');
  return PublicNote.fromJson(response);
});

/// Comments for a note
final noteCommentsProvider =
    FutureProvider.family<List<NoteComment>, String>((ref, noteId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/notes/$noteId/comments');
    return ((response as List?) ?? []).map((e) => NoteComment.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// User's own notes
final myNotesProvider = FutureProvider<List<PublicNote>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/notes/my');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// User's saved notes
final savedNotesProvider = FutureProvider<List<PublicNote>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/notes/saved');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Notes by horse
final horseNotesProvider =
    FutureProvider.family<List<PublicNote>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/horses/$horseId/notes');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// User profile
final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/users/$userId/profile');
  return UserProfile.fromJson(response);
});

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int noteCount;
  final int horseCount;
  final bool isFollowing;
  final bool isFollowedBy;
  final List<Badge> badges;
  final DateTime joinedAt;

  UserProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    this.followerCount = 0,
    this.followingCount = 0,
    this.noteCount = 0,
    this.horseCount = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.badges = const [],
    required this.joinedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      followerCount: json['followerCount'] as int? ?? json['_count']?['followers'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? json['_count']?['following'] as int? ?? 0,
      noteCount: json['noteCount'] as int? ?? json['_count']?['notes'] as int? ?? 0,
      horseCount: json['horseCount'] as int? ?? json['_count']?['horses'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollowedBy: json['isFollowedBy'] as bool? ?? false,
      badges: (json['badges'] as List?)?.map((b) => Badge.fromJson(b)).toList() ?? [],
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

/// User notes
final userNotesProvider =
    FutureProvider.family<List<PublicNote>, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/$userId/notes');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// User followers
final userFollowersProvider =
    FutureProvider.family<List<FollowUser>, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/$userId/followers');
    return ((response as List?) ?? []).map((e) => FollowUser.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// User following
final userFollowingProvider =
    FutureProvider.family<List<FollowUser>, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/$userId/following');
    return ((response as List?) ?? []).map((e) => FollowUser.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Follow user model
class FollowUser {
  final String id;
  final String name;
  final String? photoUrl;
  final bool isFollowing;

  FollowUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.isFollowing = false,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}

/// Search users
final searchUsersProvider =
    FutureProvider.family<List<FollowUser>, String>((ref, query) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/search', queryParams: {'q': query});
    return ((response as List?) ?? []).map((e) => FollowUser.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Suggested users to follow
final suggestedUsersProvider = FutureProvider<List<FollowUser>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/users/suggested');
    return ((response as List?) ?? []).map((e) => FollowUser.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Notifications
final notificationsProvider = FutureProvider<List<SocialNotification>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/notifications');
    return ((response as List?) ?? []).map((e) => SocialNotification.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/notifications/unread-count');
    return response['count'] as int? ?? 0;
  } catch (e) {
    if (_is404Error(e)) return 0;
    rethrow;
  }
});

/// Social notification model
class SocialNotification {
  final String id;
  final NotificationType type;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String? targetId;
  final String? targetType;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  SocialNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    this.targetId,
    this.targetType,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    return SocialNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.other,
      ),
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      actorPhotoUrl: json['actorPhotoUrl'] as String?,
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Notification type
enum NotificationType {
  like,
  comment,
  follow,
  mention,
  share,
  badge,
  challenge,
  other;

  String get displayName {
    switch (this) {
      case NotificationType.like:
        return 'J\'aime';
      case NotificationType.comment:
        return 'Commentaire';
      case NotificationType.follow:
        return 'Abonnement';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.share:
        return 'Partage';
      case NotificationType.badge:
        return 'Badge';
      case NotificationType.challenge:
        return 'Défi';
      case NotificationType.other:
        return 'Autre';
    }
  }
}

/// Trending tags
final trendingTagsProvider = FutureProvider<List<TrendingTag>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/feed/trending-tags');
    return ((response as List?) ?? []).map((e) => TrendingTag.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Trending tag model
class TrendingTag {
  final String tag;
  final int postCount;
  final double trendScore;

  TrendingTag({
    required this.tag,
    required this.postCount,
    required this.trendScore,
  });

  factory TrendingTag.fromJson(Map<String, dynamic> json) {
    return TrendingTag(
      tag: json['tag'] as String,
      postCount: json['postCount'] as int,
      trendScore: (json['trendScore'] as num).toDouble(),
    );
  }
}

/// Posts by tag
final postsByTagProvider =
    FutureProvider.family<List<PublicNote>, String>((ref, tag) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/feed/tags/$tag');
    return ((response as List?) ?? []).map((e) => PublicNote.fromJson(e)).toList();
  } catch (e) {
    if (_is404Error(e)) return [];
    rethrow;
  }
});

/// Social notifier for CRUD operations
class SocialNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  SocialNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Upload media file and return URL
  Future<String?> uploadMedia(File file, {String type = 'image'}) async {
    try {
      final url = await _api.uploadMedia(file, type: type);
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Upload multiple media files and return URLs
  Future<List<String>> uploadMultipleMedia(List<File> files, {String type = 'image'}) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadMedia(file, type: type);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Create note/post with optional media
  Future<PublicNote?> createNoteWithMedia({
    required String content,
    List<File>? mediaFiles,
    String? mediaType,
    String? horseId,
    List<String>? tags,
    String visibility = 'public',
  }) async {
    state = const AsyncValue.loading();
    try {
      // Upload media files first if provided
      List<String> mediaUrls = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        mediaUrls = await uploadMultipleMedia(
          mediaFiles,
          type: mediaType ?? 'image',
        );
      }

      // Create the note with media URLs
      final data = {
        'content': content,
        if (mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
        if (mediaType != null) 'mediaType': mediaType,
        if (horseId != null) 'horseId': horseId,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        'visibility': visibility,
      };

      final response = await _api.post('/notes', data);
      _ref.invalidate(myNotesProvider);
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      state = const AsyncValue.data(null);
      return PublicNote.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Create note/post
  Future<PublicNote?> createNote(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/notes', data);
      _ref.invalidate(myNotesProvider);
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      state = const AsyncValue.data(null);
      return PublicNote.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update note
  Future<bool> updateNote(String noteId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/notes/$noteId', data);
      _ref.invalidate(noteProvider(noteId));
      _ref.invalidate(myNotesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/notes/$noteId');
      _ref.invalidate(noteProvider(noteId));
      _ref.invalidate(myNotesProvider);
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(trendingPostsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Like note
  Future<bool> likeNote(String noteId) async {
    try {
      await _api.post('/notes/$noteId/like', {});
      _ref.invalidate(noteProvider(noteId));
      // Invalidate feeds to update like counts
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(myNotesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unlike note
  Future<bool> unlikeNote(String noteId) async {
    try {
      await _api.delete('/notes/$noteId/like');
      _ref.invalidate(noteProvider(noteId));
      // Invalidate feeds to update like counts
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(myNotesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save note
  Future<bool> saveNote(String noteId) async {
    try {
      await _api.post('/notes/$noteId/save', {});
      _ref.invalidate(noteProvider(noteId));
      _ref.invalidate(savedNotesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unsave note
  Future<bool> unsaveNote(String noteId) async {
    try {
      await _api.delete('/notes/$noteId/save');
      _ref.invalidate(noteProvider(noteId));
      _ref.invalidate(savedNotesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share note
  Future<bool> shareNote(String noteId) async {
    try {
      await _api.post('/notes/$noteId/share', {});
      _ref.invalidate(noteProvider(noteId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add comment
  Future<NoteComment?> addComment(String noteId, String content, {String? parentId}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/notes/$noteId/comments', {
        'content': content,
        'parentId': parentId,
      });
      _ref.invalidate(noteCommentsProvider(noteId));
      _ref.invalidate(noteProvider(noteId));
      state = const AsyncValue.data(null);
      return NoteComment.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String noteId, String commentId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/notes/$noteId/comments/$commentId');
      _ref.invalidate(noteCommentsProvider(noteId));
      _ref.invalidate(noteProvider(noteId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Like comment
  Future<bool> likeComment(String noteId, String commentId) async {
    try {
      await _api.post('/notes/$noteId/comments/$commentId/like', {});
      _ref.invalidate(noteCommentsProvider(noteId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unlike comment
  Future<bool> unlikeComment(String noteId, String commentId) async {
    try {
      await _api.delete('/notes/$noteId/comments/$commentId/like');
      _ref.invalidate(noteCommentsProvider(noteId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Follow user
  Future<bool> followUser(String userId) async {
    try {
      await _api.post('/users/$userId/follow', {});
      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(userFollowersProvider(userId));
      _ref.invalidate(userFollowingProvider(userId));
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(suggestedUsersProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unfollow user
  Future<bool> unfollowUser(String userId) async {
    try {
      await _api.delete('/users/$userId/follow');
      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(userFollowersProvider(userId));
      _ref.invalidate(userFollowingProvider(userId));
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(suggestedUsersProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Block user
  Future<bool> blockUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/users/$userId/block', {});
      // Invalidate all feeds and user data to remove blocked user's content
      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(forYouFeedProvider);
      _ref.invalidate(followingFeedProvider);
      _ref.invalidate(trendingPostsProvider);
      _ref.invalidate(suggestedUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Report user
  Future<bool> reportUser(String userId, String reason, String? details) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/users/$userId/report', {
        'reason': reason,
        'details': details,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Report note
  Future<bool> reportNote(String noteId, String reason, String? details) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/notes/$noteId/report', {
        'reason': reason,
        'details': details,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mark notifications as read
  Future<bool> markNotificationsRead(List<String> notificationIds) async {
    try {
      await _api.post('/notifications/mark-read', {'ids': notificationIds});
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsRead() async {
    try {
      await _api.post('/notifications/mark-all-read', {});
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/users/profile', data);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final socialNotifierProvider =
    StateNotifierProvider<SocialNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SocialNotifier(api, ref);
});

/// Feed engagement stats
final feedStatsProvider = FutureProvider<FeedStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/feed/stats');
  return FeedStats.fromJson(response);
});

/// Feed stats model
class FeedStats {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int activeUsers;
  final List<String> topTags;

  FeedStats({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.activeUsers,
    required this.topTags,
  });

  factory FeedStats.fromJson(Map<String, dynamic> json) {
    return FeedStats(
      totalPosts: json['totalPosts'] as int? ?? 0,
      totalLikes: json['totalLikes'] as int? ?? 0,
      totalComments: json['totalComments'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      topTags: (json['topTags'] as List?)?.cast<String>() ?? [],
    );
  }
}
