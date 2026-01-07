import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/horses_provider.dart';
import '../../providers/riders_provider.dart';

/// Écurie category home screen
/// Contains: Horses, Riders, Health, Gestation
class EcurieHomeScreen extends ConsumerWidget {
  const EcurieHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsesAsync = ref.watch(horsesProvider);
    final ridersAsync = ref.watch(ridersProvider);
    final theme = Theme.of(context);

    // Extract data from AsyncValue with fallback to empty list
    final horsesList = horsesAsync.valueOrNull ?? [];
    final ridersList = ridersAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Écurie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            _QuickStats(
              horsesCount: horsesList.length,
              ridersCount: ridersList.length,
            ),

            const SizedBox(height: 24),

            // Main sections
            Text(
              'Gestion',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _SectionGrid(
              items: [
                _SectionItem(
                  icon: Icons.pets,
                  label: 'Chevaux',
                  subtitle: '${horsesList.length} enregistrés',
                  color: AppColors.categoryEcurie,
                  onTap: () => context.go('/horses'),
                ),
                _SectionItem(
                  icon: Icons.person,
                  label: 'Cavaliers',
                  subtitle: '${ridersList.length} enregistrés',
                  color: AppColors.secondary,
                  onTap: () => context.go('/riders'),
                ),
                _SectionItem(
                  icon: Icons.favorite,
                  label: 'Santé',
                  subtitle: 'Suivi médical',
                  color: AppColors.error,
                  onTap: () => context.go('/health'),
                ),
                _SectionItem(
                  icon: Icons.child_care,
                  label: 'Gestation',
                  subtitle: 'Suivi poulinières',
                  color: AppColors.tertiary,
                  onTap: () => context.go('/gestation'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activity
            _RecentActivitySection(horses: horsesList.take(3).toList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppColors.categoryEcurie,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.categoryEcurie.withValues(alpha: 0.1),
                child: const Icon(Icons.pets, color: AppColors.categoryEcurie),
              ),
              title: const Text('Nouveau cheval'),
              subtitle: const Text('Ajouter un cheval à votre écurie'),
              onTap: () {
                Navigator.pop(context);
                context.go('/horses/add');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                child: const Icon(Icons.person_add, color: AppColors.secondary),
              ),
              title: const Text('Nouveau cavalier'),
              subtitle: const Text('Ajouter un cavalier'),
              onTap: () {
                Navigator.pop(context);
                context.go('/riders/add');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final int horsesCount;
  final int ridersCount;

  const _QuickStats({
    required this.horsesCount,
    required this.ridersCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.categoryEcurie,
            AppColors.categoryEcurie.withValues(alpha: 0.8),
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
                  'Mon Écurie',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez vos chevaux et cavaliers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$horsesCount',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Chevaux',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$ridersCount',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cavaliers',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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

class _RecentActivitySection extends StatelessWidget {
  final List<dynamic> horses;

  const _RecentActivitySection({required this.horses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (horses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chevaux récents',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/horses'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...horses.map((horse) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.categoryEcurie.withValues(alpha: 0.1),
                  child: const Icon(Icons.pets, color: AppColors.categoryEcurie),
                ),
                title: Text(horse.name ?? 'Sans nom'),
                subtitle: Text(horse.breed ?? 'Race non spécifiée'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/horses/${horse.id}'),
              ),
            )),
      ],
    );
  }
}
