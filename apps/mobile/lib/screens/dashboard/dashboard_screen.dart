import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/horses_provider.dart';
import '../../providers/analyses_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/planning_provider.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final horsesAsync = ref.watch(horsesNotifierProvider);
    final analysesAsync = ref.watch(analysesNotifierProvider);
    final reportsAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horse Tempo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Global search
              showSearch(context: context, delegate: _AppSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(horsesNotifierProvider);
          ref.invalidate(analysesNotifierProvider);
          ref.invalidate(reportsNotifierProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(context, authState),
              const SizedBox(height: 20),

              // Quick actions row
              _buildQuickActionsRow(context),
              const SizedBox(height: 24),

              // All features grid
              Text(
                'Fonctionnalités',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildAllFeaturesGrid(context),
              const SizedBox(height: 24),

              // Stats section
              Text(
                'Mes Statistiques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(context, horsesAsync, analysesAsync, reportsAsync),
              const SizedBox(height: 24),

              // Upcoming events
              _buildUpcomingSection(context, ref),
              const SizedBox(height: 24),

              // My horses quick access
              _buildMyHorsesSection(context, ref, horsesAsync),
              const SizedBox(height: 24),

              // Recent activity
              _buildRecentActivitySection(context, analysesAsync, reportsAsync),
              const SizedBox(height: 24),

              // Community highlights
              _buildCommunitySection(context),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewActionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AuthState authState) {
    final greeting = _getGreeting();
    final userName = authState.user?.firstName ?? 'Cavalier';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre assistant équestre intelligent',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.videocam,
            label: 'Analyse',
            color: AppColors.categoryIA,
            onTap: () => context.push('/analyses/new'),
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.pets,
            label: 'Cheval',
            color: AppColors.categoryEcurie,
            onTap: () => context.push('/horses/add'),
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.calendar_today,
            label: 'Planning',
            color: AppColors.tertiary,
            onTap: () => context.go('/planning'),
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.description,
            label: 'Rapport',
            color: AppColors.success,
            onTap: () => context.push('/reports/new'),
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.medical_services,
            label: 'Santé',
            color: AppColors.error,
            onTap: () => context.go('/health'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: [
        // Écurie
        _FeatureIcon(
          icon: Icons.pets,
          label: 'Chevaux',
          color: AppColors.categoryEcurie,
          onTap: () => context.go('/horses'),
        ),
        _FeatureIcon(
          icon: Icons.person,
          label: 'Cavaliers',
          color: AppColors.categoryEcurie,
          onTap: () => context.go('/riders'),
        ),
        _FeatureIcon(
          icon: Icons.medical_services,
          label: 'Santé',
          color: AppColors.error,
          onTap: () => context.go('/health'),
        ),
        _FeatureIcon(
          icon: Icons.pregnant_woman,
          label: 'Gestation',
          color: Colors.pink,
          onTap: () => context.go('/gestation'),
        ),

        // IA
        _FeatureIcon(
          icon: Icons.analytics,
          label: 'Analyses',
          color: AppColors.categoryIA,
          onTap: () => context.go('/analyses'),
        ),
        _FeatureIcon(
          icon: Icons.description,
          label: 'Rapports',
          color: AppColors.categoryIA,
          onTap: () => context.go('/reports'),
        ),
        _FeatureIcon(
          icon: Icons.calendar_month,
          label: 'Planning',
          color: AppColors.tertiary,
          onTap: () => context.go('/planning'),
        ),
        _FeatureIcon(
          icon: Icons.child_care,
          label: 'Élevage',
          color: Colors.pink,
          onTap: () => context.go('/breeding'),
        ),

        // Social
        _FeatureIcon(
          icon: Icons.feed,
          label: 'Feed',
          color: AppColors.categorySocial,
          onTap: () => context.go('/feed'),
        ),
        _FeatureIcon(
          icon: Icons.store,
          label: 'Marketplace',
          color: AppColors.secondary,
          onTap: () => context.go('/marketplace'),
        ),
        _FeatureIcon(
          icon: Icons.groups,
          label: 'Clubs',
          color: AppColors.tertiary,
          onTap: () => context.go('/clubs'),
        ),
        _FeatureIcon(
          icon: Icons.leaderboard,
          label: 'Classements',
          color: Colors.orange,
          onTap: () => context.go('/leaderboard'),
        ),

        // Plus
        _FeatureIcon(
          icon: Icons.business,
          label: 'Services',
          color: AppColors.categoryPlus,
          onTap: () => context.go('/services'),
        ),
        _FeatureIcon(
          icon: Icons.emoji_events,
          label: 'Défis',
          color: Colors.amber,
          onTap: () => context.go('/gamification'),
        ),
        _FeatureIcon(
          icon: Icons.settings,
          label: 'Réglages',
          color: Colors.grey,
          onTap: () => context.go('/settings'),
        ),
        _FeatureIcon(
          icon: Icons.person_outline,
          label: 'Profil',
          color: AppColors.primary,
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue horsesAsync,
    AsyncValue analysesAsync,
    AsyncValue reportsAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            value: horsesAsync.when(
              data: (horses) => horses.length.toString(),
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Chevaux',
            icon: Icons.pets,
            color: AppColors.categoryEcurie,
            onTap: () => context.go('/horses'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            value: analysesAsync.when(
              data: (analyses) => analyses.length.toString(),
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Analyses',
            icon: Icons.analytics,
            color: AppColors.categoryIA,
            onTap: () => context.go('/analyses'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            value: reportsAsync.when(
              data: (reports) => reports.length.toString(),
              loading: () => '-',
              error: (_, __) => '!',
            ),
            label: 'Rapports',
            icon: Icons.description,
            color: AppColors.success,
            onTap: () => context.go('/reports'),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prochains événements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => context.go('/planning'),
              child: const Text('Planning'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: Consumer(
            builder: (context, ref, _) {
              final eventsAsync = ref.watch(upcomingEventsProvider);
              return eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucun événement prévu',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _EventCard(
                        title: event.title,
                        date: event.startDate,
                        type: event.type.name,
                        onTap: () => context.push('/planning/${event.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Card(
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => ref.invalidate(upcomingEventsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyHorsesSection(BuildContext context, WidgetRef ref, AsyncValue horsesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes Chevaux',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => context.go('/horses'),
              child: const Text('Voir tous'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: horsesAsync.when(
            data: (horses) {
              if (horses.isEmpty) {
                return Card(
                  child: InkWell(
                    onTap: () => context.push('/horses/add'),
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                          const SizedBox(height: 8),
                          const Text('Ajouter votre premier cheval'),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: horses.take(10).length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == horses.take(10).length) {
                    return SizedBox(
                      width: 90,
                      child: Card(
                        child: InkWell(
                          onTap: () => context.go('/horses'),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.more_horiz, color: AppColors.primary),
                                const SizedBox(height: 4),
                                Text(
                                  'Voir tous',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final horse = horses[index];
                  return _HorseCard(
                    name: horse.name,
                    photoUrl: horse.photoUrl,
                    onTap: () => context.push('/horses/${horse.id}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Card(
              child: Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(horsesNotifierProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    AsyncValue analysesAsync,
    AsyncValue reportsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        analysesAsync.when(
          data: (analyses) {
            final recent = analyses.take(3).toList();
            if (recent.isEmpty) {
              return Card(
                child: ListTile(
                  leading: Icon(Icons.analytics, color: Colors.grey.shade400),
                  title: const Text('Aucune analyse récente'),
                  subtitle: const Text('Commencez votre première analyse vidéo'),
                  trailing: FilledButton(
                    onPressed: () => context.push('/analyses/new'),
                    child: const Text('Créer'),
                  ),
                ),
              );
            }
            return Column(
              children: recent.map((analysis) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.categoryIA.withOpacity(0.1),
                      child: Icon(Icons.analytics, color: AppColors.categoryIA),
                    ),
                    title: Text(analysis.type ?? 'Analyse'),
                    subtitle: Text(_formatDate(analysis.createdAt)),
                    trailing: _buildStatusChip(context, analysis.status),
                    onTap: () => context.push('/analyses/${analysis.id}'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Erreur de chargement'),
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Communauté',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => context.go('/social'),
              child: const Text('Explorer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CommunityCard(
                icon: Icons.leaderboard,
                title: 'Classements',
                subtitle: 'Voir les top',
                color: Colors.orange,
                onTap: () => context.go('/leaderboard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CommunityCard(
                icon: Icons.store,
                title: 'Marketplace',
                subtitle: 'Acheter/Vendre',
                color: AppColors.secondary,
                onTap: () => context.go('/marketplace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CommunityCard(
                icon: Icons.groups,
                title: 'Clubs',
                subtitle: 'Rejoindre',
                color: AppColors.tertiary,
                onTap: () => context.go('/clubs'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CommunityCard(
                icon: Icons.feed,
                title: 'Feed Social',
                subtitle: 'Actualités',
                color: AppColors.categorySocial,
                onTap: () => context.go('/feed'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNewActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Créer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.categoryIA.withOpacity(0.1),
                  child: Icon(Icons.videocam, color: AppColors.categoryIA),
                ),
                title: const Text('Nouvelle analyse'),
                subtitle: const Text('Analyser une vidéo avec l\'IA'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/analyses/new');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.categoryEcurie.withOpacity(0.1),
                  child: Icon(Icons.pets, color: AppColors.categoryEcurie),
                ),
                title: const Text('Ajouter un cheval'),
                subtitle: const Text('Créer une fiche cheval'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/horses/add');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  child: Icon(Icons.description, color: AppColors.success),
                ),
                title: const Text('Nouveau rapport'),
                subtitle: const Text('Créer un rapport personnalisé'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/reports/new');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.tertiary.withOpacity(0.1),
                  child: Icon(Icons.event, color: AppColors.tertiary),
                ),
                title: const Text('Événement'),
                subtitle: const Text('Planifier un événement'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/planning/new');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, dynamic status) {
    Color color;
    String label;

    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('completed') || statusStr.contains('ready')) {
      color = AppColors.success;
      label = 'Terminé';
    } else if (statusStr.contains('processing') || statusStr.contains('pending')) {
      color = AppColors.warning;
      label = 'En cours';
    } else if (statusStr.contains('failed') || statusStr.contains('error')) {
      color = AppColors.error;
      label = 'Erreur';
    } else {
      color = AppColors.textSecondary;
      label = 'Brouillon';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatMiniCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String type;
  final VoidCallback onTap;

  const _EventCard({
    required this.title,
    required this.date,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  type,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorseCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  const _HorseCard({
    required this.name,
    this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.categoryEcurie.withOpacity(0.1),
                          child: Icon(Icons.pets, color: AppColors.categoryEcurie),
                        ),
                      )
                    : Container(
                        color: AppColors.categoryEcurie.withOpacity(0.1),
                        child: Icon(Icons.pets, color: AppColors.categoryEcurie),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchContent(context);
  }

  Widget _buildSearchContent(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Rechercher chevaux, analyses, événements...'),
      );
    }

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.pets),
          title: Text('Chercher "$query" dans Chevaux'),
          onTap: () {
            close(context, query);
            context.go('/horses?search=$query');
          },
        ),
        ListTile(
          leading: const Icon(Icons.analytics),
          title: Text('Chercher "$query" dans Analyses'),
          onTap: () {
            close(context, query);
            context.go('/analyses?search=$query');
          },
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('Chercher "$query" dans Planning'),
          onTap: () {
            close(context, query);
            context.go('/planning?search=$query');
          },
        ),
      ],
    );
  }
}
