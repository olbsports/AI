import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Social category home screen
/// Contains: Feed, Marketplace, Clubs, Leaderboard
class SocialHomeScreen extends ConsumerWidget {
  const SocialHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community banner
            _CommunityBanner(),

            const SizedBox(height: 24),

            // Main sections
            Text(
              'Explorer',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _SectionGrid(
              items: [
                _SectionItem(
                  icon: Icons.feed,
                  label: 'Fil d\'actualité',
                  subtitle: 'Publications récentes',
                  color: AppColors.categorySocial,
                  onTap: () => context.go('/feed'),
                ),
                _SectionItem(
                  icon: Icons.store,
                  label: 'Marketplace',
                  subtitle: 'Acheter & vendre',
                  color: AppColors.secondary,
                  onTap: () => context.go('/marketplace'),
                ),
                _SectionItem(
                  icon: Icons.groups,
                  label: 'Clubs',
                  subtitle: 'Rejoindre un club',
                  color: AppColors.tertiary,
                  onTap: () => context.go('/clubs'),
                ),
                _SectionItem(
                  icon: Icons.leaderboard,
                  label: 'Classements',
                  subtitle: 'Top cavaliers',
                  color: AppColors.primary,
                  onTap: () => context.go('/leaderboard'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Actions rapides',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_photo_alternate,
                    label: 'Publier',
                    color: AppColors.categorySocial,
                    onTap: () => context.push('/feed?action=create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.sell,
                    label: 'Vendre',
                    color: AppColors.secondary,
                    onTap: () => context.push('/marketplace/create/sale'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event,
                    label: 'Événement',
                    color: AppColors.tertiary,
                    onTap: () => context.push('/planning?action=create'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Featured section
            _FeaturedSection(),

            const SizedBox(height: 24),

            // Trending
            _TrendingSection(),
          ],
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.categorySocial,
            AppColors.categorySocial.withRed(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communauté',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partagez, échangez, progressez ensemble',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  final List<_SectionItem> items;

  const _SectionGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items,
    );
  }
}

class _SectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'À la une',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Voir plus'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FeaturedCard(
                title: 'Concours régional',
                subtitle: 'CSO Amateur - 15 Jan',
                icon: Icons.emoji_events,
                color: AppColors.tertiary,
              ),
              _FeaturedCard(
                title: 'Stage dressage',
                subtitle: 'Avec Jean Dupont',
                icon: Icons.school,
                color: AppColors.categoryEcurie,
              ),
              _FeaturedCard(
                title: 'Vente aux enchères',
                subtitle: '20 chevaux disponibles',
                icon: Icons.gavel,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap ?? () => context.go('/feed'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendances',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _TrendingItem(
          rank: 1,
          title: '#ConcoursDressage',
          subtitle: '1.2k publications',
        ),
        _TrendingItem(
          rank: 2,
          title: '#SoinNaturel',
          subtitle: '890 publications',
        ),
        _TrendingItem(
          rank: 3,
          title: '#JeuneCheval',
          subtitle: '654 publications',
        ),
      ],
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;

  const _TrendingItem({
    required this.rank,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          // Navigate to feed with tag filter
          context.push('/feed?tag=${title.replaceAll('#', '')}');
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.categorySocial.withOpacity(0.1),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: AppColors.categorySocial,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.trending_up, color: AppColors.secondary),
      ),
    );
  }
}
