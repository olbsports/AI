import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clubs.dart';
import '../services/api_service.dart';

/// User's clubs
final myClubsProvider = FutureProvider<List<Club>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/my');
  return (response as List).map((e) => Club.fromJson(e)).toList();
});

/// Club by ID
final clubProvider = FutureProvider.family<Club, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId');
  return Club.fromJson(response);
});

/// Club members
final clubMembersProvider =
    FutureProvider.family<List<ClubMember>, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId/members');
  return (response as List).map((e) => ClubMember.fromJson(e)).toList();
});

/// Club leaderboard
final clubLeaderboardProvider = FutureProvider<List<ClubLeaderboardEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/leaderboard');
  return (response as List).map((e) => ClubLeaderboardEntry.fromJson(e)).toList();
});

/// Club leaderboard by type
final clubLeaderboardByTypeProvider =
    FutureProvider.family<List<ClubLeaderboardEntry>, ClubType>((ref, type) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/leaderboard', queryParams: {'type': type.name});
  return (response as List).map((e) => ClubLeaderboardEntry.fromJson(e)).toList();
});

/// Club challenges
final clubChallengesProvider =
    FutureProvider.family<List<ClubChallenge>, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId/challenges');
  return (response as List).map((e) => ClubChallenge.fromJson(e)).toList();
});

/// Active club challenges
final activeClubChallengesProvider = FutureProvider<List<ClubChallenge>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/challenges/active');
  return (response as List).map((e) => ClubChallenge.fromJson(e)).toList();
});

/// Club events
final clubEventsProvider =
    FutureProvider.family<List<ClubEvent>, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId/events');
  return (response as List).map((e) => ClubEvent.fromJson(e)).toList();
});

/// Upcoming club events
final upcomingClubEventsProvider = FutureProvider<List<ClubEvent>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/events/upcoming');
  return (response as List).map((e) => ClubEvent.fromJson(e)).toList();
});

/// Club posts/feed
final clubPostsProvider =
    FutureProvider.family<List<ClubPost>, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId/posts');
  return (response as List).map((e) => ClubPost.fromJson(e)).toList();
});

/// Club invitations
final clubInvitationsProvider = FutureProvider<List<ClubInvitation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/invitations');
  return (response as List).map((e) => ClubInvitation.fromJson(e)).toList();
});

/// Club statistics
final clubStatsProvider =
    FutureProvider.family<ClubStats, String>((ref, clubId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/$clubId/stats');
  return ClubStats.fromJson(response);
});

/// Search clubs
final searchClubsProvider =
    FutureProvider.family<List<Club>, String>((ref, query) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/search', queryParams: {'q': query});
  return (response as List).map((e) => Club.fromJson(e)).toList();
});

/// Nearby clubs
final nearbyClubsProvider =
    FutureProvider.family<List<Club>, ({double lat, double lng, double radius})>(
        (ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/clubs/nearby', queryParams: {
    'lat': params.lat.toString(),
    'lng': params.lng.toString(),
    'radius': params.radius.toString(),
  });
  return (response as List).map((e) => Club.fromJson(e)).toList();
});

/// Clubs notifier for CRUD operations
class ClubsNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _api;
  final Ref _ref;

  ClubsNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Create a club
  Future<Club?> createClub(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/clubs', data);
      _ref.invalidate(myClubsProvider);
      state = const AsyncValue.data(null);
      return Club.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update club
  Future<bool> updateClub(String clubId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/clubs/$clubId', data);
      _ref.invalidate(clubProvider(clubId));
      _ref.invalidate(myClubsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete club
  Future<bool> deleteClub(String clubId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/clubs/$clubId');
      _ref.invalidate(myClubsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Join club
  Future<bool> joinClub(String clubId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/$clubId/join', {});
      _ref.invalidate(myClubsProvider);
      _ref.invalidate(clubMembersProvider(clubId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Leave club
  Future<bool> leaveClub(String clubId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/$clubId/leave', {});
      _ref.invalidate(myClubsProvider);
      _ref.invalidate(clubMembersProvider(clubId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Invite to club
  Future<bool> inviteToClub(String clubId, String email, String? message) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/$clubId/invite', {
        'email': email,
        'message': message,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Accept invitation
  Future<bool> acceptInvitation(String invitationId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/invitations/$invitationId/accept', {});
      _ref.invalidate(clubInvitationsProvider);
      _ref.invalidate(myClubsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Decline invitation
  Future<bool> declineInvitation(String invitationId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/invitations/$invitationId/decline', {});
      _ref.invalidate(clubInvitationsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update member role
  Future<bool> updateMemberRole(String clubId, String memberId, ClubRole role) async {
    state = const AsyncValue.loading();
    try {
      await _api.put('/clubs/$clubId/members/$memberId', {'role': role.name});
      _ref.invalidate(clubMembersProvider(clubId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Remove member
  Future<bool> removeMember(String clubId, String memberId) async {
    state = const AsyncValue.loading();
    try {
      await _api.delete('/clubs/$clubId/members/$memberId');
      _ref.invalidate(clubMembersProvider(clubId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create club challenge
  Future<ClubChallenge?> createChallenge(String clubId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/clubs/$clubId/challenges', data);
      _ref.invalidate(clubChallengesProvider(clubId));
      _ref.invalidate(activeClubChallengesProvider);
      state = const AsyncValue.data(null);
      return ClubChallenge.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Accept challenge
  Future<bool> acceptChallenge(String challengeId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/challenges/$challengeId/accept', {});
      _ref.invalidate(activeClubChallengesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create club event
  Future<ClubEvent?> createEvent(String clubId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/clubs/$clubId/events', data);
      _ref.invalidate(clubEventsProvider(clubId));
      _ref.invalidate(upcomingClubEventsProvider);
      state = const AsyncValue.data(null);
      return ClubEvent.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Join event
  Future<bool> joinEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/events/$eventId/join', {});
      _ref.invalidate(upcomingClubEventsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create club post
  Future<ClubPost?> createPost(String clubId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.post('/clubs/$clubId/posts', data);
      _ref.invalidate(clubPostsProvider(clubId));
      state = const AsyncValue.data(null);
      return ClubPost.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Like post
  Future<bool> likePost(String clubId, String postId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/clubs/$clubId/posts/$postId/like', {});
      _ref.invalidate(clubPostsProvider(clubId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final clubsNotifierProvider =
    StateNotifierProvider<ClubsNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ClubsNotifier(api, ref);
});
