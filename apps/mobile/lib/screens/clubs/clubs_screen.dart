import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/clubs.dart';
import '../../providers/clubs_provider.dart';
import '../../theme/app_theme.dart';

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Écuries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes clubs'),
            Tab(text: 'Classement'),
            Tab(text: 'Découvrir'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateClubDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyClubsTab(),
          _buildLeaderboardTab(),
          _buildDiscoverTab(),
        ],
      ),
    );
  }

  Widget _buildMyClubsTab() {
    final clubsAsync = ref.watch(myClubsProvider);
    final invitationsAsync = ref.watch(clubInvitationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myClubsProvider);
        ref.invalidate(clubInvitationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invitations
          invitationsAsync.when(
            data: (invitations) {
              if (invitations.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invitations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...invitations.map((i) => _buildInvitationCard(i)),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // My clubs
          clubsAsync.when(
            data: (clubs) {
              if (clubs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Vous n\'avez pas encore de club'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateClubDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un club'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(2),
                        icon: const Icon(Icons.search),
                        label: const Text('Rejoindre un club'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes clubs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...clubs.map((c) => _buildClubCard(c)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderboardAsync = ref.watch(clubLeaderboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(clubLeaderboardProvider),
      child: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Aucun classement'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildLeaderboardEntry(entry, index);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un club...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (query) => _searchClubs(query),
        ),
        const SizedBox(height: 24),

        // Featured clubs
        Text(
          'Clubs populaires',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final leaderboardAsync = ref.watch(clubLeaderboardProvider);
            return leaderboardAsync.when(
              data: (entries) => Column(
                children: entries.take(5).map((e) => _buildDiscoverClubCard(e)).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur'),
            );
          },
        ),
        const SizedBox(height: 24),

        // Upcoming events
        Text(
          'Événements à venir',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final eventsAsync = ref.watch(upcomingClubEventsProvider);
            return eventsAsync.when(
              data: (events) => events.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun événement'),
                      ),
                    )
                  : Column(
                      children: events.take(5).map((e) => _buildEventCard(e)).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClubCard(Club club) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openClubDetails(club),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
                child: club.logoUrl == null
                    ? Text(
                        club.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (club.isVerified)
                          const Icon(Icons.verified, color: Colors.blue, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.type.displayName,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${club.memberCount}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${club.totalXp} XP'),
                        if (club.rank > 0) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${club.rank}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(ClubInvitation invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: invitation.clubLogoUrl != null
                      ? NetworkImage(invitation.clubLogoUrl!)
                      : null,
                  child: invitation.clubLogoUrl == null
                      ? Text(invitation.clubName[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.clubName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Invité par ${invitation.inviterName}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invitation.message != null) ...[
              const SizedBox(height: 12),
              Text(
                invitation.message!,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _declineInvitation(invitation),
                  child: const Text('Refuser'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptInvitation(invitation),
                  child: const Text('Accepter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntry(ClubLeaderboardEntry entry, int index) {
    Color? backgroundColor;
    Color? textColor;
    Widget? rankWidget;

    if (index == 0) {
      backgroundColor = Colors.amber.withOpacity(0.1);
      textColor = Colors.amber;
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 24));
    } else if (index == 1) {
      backgroundColor = Colors.grey.shade300.withOpacity(0.3);
      textColor = Colors.grey.shade600;
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 24));
    } else if (index == 2) {
      backgroundColor = Colors.brown.withOpacity(0.1);
      textColor = Colors.brown;
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 24));
    } else {
      rankWidget = Text(
        '#${entry.rank}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: backgroundColor,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(child: rankWidget),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: entry.clubLogoUrl != null
                  ? NetworkImage(entry.clubLogoUrl!)
                  : null,
              child: entry.clubLogoUrl == null
                  ? Text(entry.clubName[0])
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.clubName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${entry.memberCount} membres',
          style: TextStyle(color: textColor?.withOpacity(0.7)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalXp} XP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor ?? AppColors.primary,
              ),
            ),
            if (entry.rankChange != 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.rankChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: entry.rankChange > 0 ? Colors.green : Colors.red,
                  ),
                  Text(
                    '${entry.rankChange.abs()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: entry.rankChange > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverClubCard(ClubLeaderboardEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: entry.clubLogoUrl != null
              ? NetworkImage(entry.clubLogoUrl!)
              : null,
          child: entry.clubLogoUrl == null
              ? Text(entry.clubName[0])
              : null,
        ),
        title: Text(entry.clubName),
        subtitle: Text('${entry.memberCount} membres - ${entry.totalXp} XP'),
        trailing: OutlinedButton(
          onPressed: () => _joinClub(entry.clubId),
          child: const Text('Rejoindre'),
        ),
      ),
    );
  }

  Widget _buildEventCard(ClubEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            event.type == ClubEventType.competition ? Icons.emoji_events : Icons.event,
            color: AppColors.primary,
          ),
        ),
        title: Text(event.title),
        subtitle: Text(
          '${event.clubName} - ${_formatDate(event.startDate)}',
        ),
        trailing: event.isFull
            ? const Chip(label: Text('Complet'))
            : TextButton(
                onPressed: () => _joinEvent(event),
                child: const Text('Participer'),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateClubDialog(BuildContext context) {
    // Show create club dialog
  }

  void _openClubDetails(Club club) {
    // Navigate to club details
  }

  void _searchClubs(String query) {
    // Search clubs
  }

  void _acceptInvitation(ClubInvitation invitation) {
    ref.read(clubsNotifierProvider.notifier).acceptInvitation(invitation.id);
  }

  void _declineInvitation(ClubInvitation invitation) {
    ref.read(clubsNotifierProvider.notifier).declineInvitation(invitation.id);
  }

  void _joinClub(String clubId) {
    ref.read(clubsNotifierProvider.notifier).joinClub(clubId);
  }

  void _joinEvent(ClubEvent event) {
    ref.read(clubsNotifierProvider.notifier).joinEvent(event.id);
  }
}
