import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class HorsesAdminScreen extends ConsumerWidget {
  const HorsesAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsesStatsAsync = ref.watch(horsesStatsProvider);
    final horsesListAsync = ref.watch(horsesListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(horsesStatsProvider);
          ref.invalidate(horsesListProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des chevaux',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              horsesStatsAsync.when(
                data: (stats) => Row(
                  children: [
                    _buildStatCard(context, 'Total chevaux', stats['totalHorses']?.toString() ?? '0', Icons.pets),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Analyses ce mois', stats['analysesThisMonth']?.toString() ?? '0', Icons.analytics),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Moyenne/user', stats['averagePerUser']?.toStringAsFixed(1) ?? '0.0', Icons.calculate),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Erreur de chargement des statistiques: $e',
                    style: TextStyle(color: AdminColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  child: horsesListAsync.when(
                    data: (horses) => horses.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun cheval trouvé',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: horses.length,
                            itemBuilder: (context, index) {
                              final horse = horses[index];
                              return ListTile(
                                leading: const Icon(Icons.pets),
                                title: Text(horse['name'] ?? 'Cheval sans nom'),
                                subtitle: Text(horse['breed'] ?? ''),
                                trailing: Text(horse['ownerName'] ?? ''),
                              );
                            },
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Erreur de chargement: $e',
                        style: TextStyle(color: AdminColors.error),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AdminColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
