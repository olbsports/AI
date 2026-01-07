import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gestation.dart';
import '../../providers/gestation_provider.dart';
import '../../theme/app_theme.dart';

class GestationScreen extends ConsumerWidget {
  const GestationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gestationsAsync = ref.watch(activeGestationsProvider);
    final birthsAsync = ref.watch(birthRecordsProvider);
    final statsAsync = ref.watch(breedingStatsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestation & Naissances'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Naissances'),
              Tab(text: 'Statistiques'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddGestationDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildActiveGestationsTab(context, ref, gestationsAsync),
            _buildBirthsTab(context, ref, birthsAsync),
            _buildStatsTab(context, ref, statsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGestationsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GestationRecord>> gestationsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeGestationsProvider);
        ref.invalidate(gestationsDueSoonProvider);
      },
      child: gestationsAsync.when(
        data: (gestations) {
          if (gestations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.child_care, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucune gestation en cours'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGestationDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Enregistrer une gestation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gestations.length,
            itemBuilder: (context, index) {
              return _buildGestationCard(context, ref, gestations[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBirthsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BirthRecord>> birthsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(birthRecordsProvider),
      child: birthsAsync.when(
        data: (births) {
          if (births.isEmpty) {
            return const Center(child: Text('Aucune naissance enregistrée'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: births.length,
            itemBuilder: (context, index) {
              return _buildBirthCard(context, births[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildStatsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<BreedingStats> statsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(breedingStatsProvider),
      child: statsAsync.when(
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Gestations', stats.totalGestations.toString(), Icons.pregnant_woman, Colors.pink)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Naissances', stats.successfulBirths.toString(), Icons.child_care, Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Mâles', stats.maleFoals.toString(), Icons.male, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Femelles', stats.femaleFoals.toString(), Icons.female, Colors.pink)),
              ],
            ),
            const SizedBox(height: 24),

            // Success rate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taux de réussite',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: stats.successRate / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                stats.successRate >= 80 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${stats.successRate.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: stats.successRate >= 80 ? Colors.green : Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Average gestation
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer, color: Colors.purple),
                ),
                title: const Text('Durée moyenne de gestation'),
                subtitle: Text('${stats.averageGestationDays.toStringAsFixed(0)} jours'),
              ),
            ),
            const SizedBox(height: 16),

            // Active gestations
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hourglass_empty, color: Colors.orange),
                ),
                title: const Text('Gestations en cours'),
                subtitle: Text('${stats.activeGestations} jument(s)'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildGestationCard(BuildContext context, WidgetRef ref, GestationRecord gestation) {
    final progress = gestation.progressPercent;
    final statusColor = Color(gestation.status.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showGestationDetails(context, ref, gestation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.pregnant_woman, color: Colors.pink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gestation.mareName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (gestation.stallionName != null)
                          Text(
                            'x ${gestation.stallionName}',
                            style: TextStyle(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gestation.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jour ${gestation.daysOfGestation} / 340',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info row
              Row(
                children: [
                  _buildInfoChip(Icons.calendar_today, _formatDate(gestation.conceptionDate), 'Conception'),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.child_friendly,
                    _formatDate(gestation.expectedDueDate),
                    gestation.daysRemaining > 0
                        ? '${gestation.daysRemaining}j restants'
                        : gestation.isOverdue
                            ? 'En retard'
                            : 'Terme',
                  ),
                ],
              ),

              // Trimester badge
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gestation.trimester,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthCard(BuildContext context, BirthRecord birth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: birth.sex == FoalSex.male
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.pink.withValues(alpha: 0.1),
          child: Icon(
            birth.sex == FoalSex.male ? Icons.male : Icons.female,
            color: birth.sex == FoalSex.male ? Colors.blue : Colors.pink,
          ),
        ),
        title: Text(
          birth.foalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${birth.mareName} x ${birth.stallionName ?? "Inconnu"}\n'
          'Né le ${_formatDate(birth.birthDate)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(birth.initialHealth.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            birth.initialHealth.displayName,
            style: TextStyle(
              color: Color(birth.initialHealth.color),
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showBirthDetails(context, birth),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddGestationDialog(BuildContext context, WidgetRef ref) {
    // Show add gestation dialog
  }

  void _showGestationDetails(BuildContext context, WidgetRef ref, GestationRecord gestation) {
    // Navigate to gestation details
  }

  void _showBirthDetails(BuildContext context, BirthRecord birth) {
    // Show birth details
  }
}
