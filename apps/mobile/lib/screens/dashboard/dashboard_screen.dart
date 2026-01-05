import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/horses_provider.dart';
import '../../providers/analyses_provider.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/stat_card.dart';
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
        title: const Text('Horse Vision AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
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
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // New features section
              _buildNewFeaturesSection(context),
              const SizedBox(height: 24),

              // Stats section
              Text(
                'Statistiques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(
                context,
                horsesAsync,
                analysesAsync,
                reportsAsync,
              ),
              const SizedBox(height: 24),

              // Recent analyses
              _buildRecentSection(
                context,
                'Analyses récentes',
                Icons.analytics,
                analysesAsync,
                () => context.go('/analyses'),
              ),
              const SizedBox(height: 24),

              // Recent reports
              _buildRecentSection(
                context,
                'Rapports récents',
                Icons.description,
                reportsAsync,
                () => context.go('/reports'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/analyses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle analyse'),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AuthState authState) {
    final greeting = _getGreeting();
    final userName = authState.user?.firstName ?? 'Utilisateur';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
            'Gérez vos chevaux et suivez leurs performances',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.pets,
            label: 'Ajouter\nun cheval',
            color: AppColors.primary,
            onTap: () => context.push('/horses/add'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.videocam,
            label: 'Nouvelle\nanalyse',
            color: AppColors.secondary,
            onTap: () => context.push('/analyses/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.description,
            label: 'Créer\nun rapport',
            color: AppColors.success,
            onTap: () => context.push('/reports/new'),
          ),
        ),
      ],
    );
  }

  Widget _buildNewFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explorer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FeatureCard(
                icon: Icons.leaderboard,
                title: 'Classements',
                subtitle: 'Cavaliers & Chevaux',
                gradient: [Colors.orange, Colors.deepOrange],
                onTap: () => context.push('/leaderboard'),
              ),
              const SizedBox(width: 12),
              _FeatureCard(
                icon: Icons.favorite,
                title: 'Poulinage',
                subtitle: 'Conseils élevage',
                gradient: [Colors.pink, Colors.red],
                onTap: () => context.push('/breeding'),
              ),
              const SizedBox(width: 12),
              _FeatureCard(
                icon: Icons.people,
                title: 'Communauté',
                subtitle: 'Feed & Partage',
                gradient: [Colors.blue, Colors.indigo],
                onTap: () => context.push('/feed'),
              ),
              const SizedBox(width: 12),
              _FeatureCard(
                icon: Icons.emoji_events,
                title: 'Hobby Horse',
                subtitle: 'Discipline fun',
                gradient: [Colors.purple, Colors.deepPurple],
                onTap: () => context.push('/leaderboard'),
              ),
            ],
          ),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Chevaux',
          value: horsesAsync.when(
            data: (horses) => horses.length.toString(),
            loading: () => '-',
            error: (_, __) => '!',
          ),
          icon: Icons.pets,
          iconColor: AppColors.primary,
          onTap: () => context.go('/horses'),
        ),
        StatCard(
          title: 'Analyses',
          value: analysesAsync.when(
            data: (analyses) => analyses.length.toString(),
            loading: () => '-',
            error: (_, __) => '!',
          ),
          icon: Icons.analytics,
          iconColor: AppColors.secondary,
          onTap: () => context.go('/analyses'),
        ),
        StatCard(
          title: 'Rapports',
          value: reportsAsync.when(
            data: (reports) => reports.length.toString(),
            loading: () => '-',
            error: (_, __) => '!',
          ),
          icon: Icons.description,
          iconColor: AppColors.success,
          onTap: () => context.go('/reports'),
        ),
        StatCard(
          title: 'Ce mois',
          value: analysesAsync.when(
            data: (analyses) {
              final now = DateTime.now();
              final count = analyses.where((a) {
                return a.createdAt.month == now.month &&
                    a.createdAt.year == now.year;
              }).length;
              return count.toString();
            },
            loading: () => '-',
            error: (_, __) => '!',
          ),
          icon: Icons.calendar_today,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    String title,
    IconData icon,
    AsyncValue asyncValue,
    VoidCallback onViewAll,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncValue.when(
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun élément',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final recentItems = items.take(3).toList();
            return Column(
              children: recentItems.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(item.type ?? 'Sans titre'),
                    subtitle: Text(
                      _formatDate(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: _buildStatusChip(context, item.status),
                    onTap: () {
                      if (title.contains('Analyses')) {
                        context.push('/analyses/${item.id}');
                      } else {
                        context.push('/reports/${item.id}');
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
