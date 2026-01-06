import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final retentionAsync = ref.watch(retentionCohortProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('30 derniers jours'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main metrics
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  // User metrics
                  const Text(
                    'Utilisateurs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricCard('Total', stats.totalUsers, Icons.people),
                      const SizedBox(width: 16),
                      _buildMetricCard('Actifs (7j)', stats.activeUsers, Icons.person),
                      const SizedBox(width: 16),
                      _buildMetricCard('Nouveaux (semaine)', stats.newUsersThisWeek, Icons.person_add),
                      const SizedBox(width: 16),
                      _buildMetricCard('Nouveaux (mois)', stats.newUsersThisMonth, Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Usage metrics
                  const Text(
                    'Utilisation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricCard('Chevaux', stats.totalHorses, Icons.pets),
                      const SizedBox(width: 16),
                      _buildMetricCard('Analyses', stats.totalAnalyses, Icons.analytics),
                      const SizedBox(width: 16),
                      _buildMetricCard("Analyses (aujourd'hui)", stats.analysesToday, Icons.today),
                      const SizedBox(width: 16),
                      _buildMetricCard('Abonnements actifs', stats.activeSubscriptions, Icons.star),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Charts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Croissance utilisateurs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Text(
                                      'Graphique de croissance',
                                      style: TextStyle(color: AdminColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Par pays',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...stats.usersByCountry.entries
                                    .take(5)
                                    .map((e) => _buildCountryRow(e.key, e.value, stats.totalUsers)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Retention cohort
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rétention par cohorte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          retentionAsync.when(
                            data: (cohorts) => cohorts.isEmpty
                                ? Text('Pas de données', style: TextStyle(color: AdminColors.textSecondary))
                                : _buildRetentionTable(cohorts),
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Erreur: $e'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, IconData icon) {
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
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryRow(String country, int count, int total) {
    final percentage = (count / total * 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(country, style: TextStyle(color: AdminColors.textSecondary)),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AdminColors.darkCard,
            valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionTable(List<RetentionCohort> cohorts) {
    return Table(
      border: TableBorder.all(color: AdminColors.darkBorder),
      children: [
        TableRow(
          decoration: BoxDecoration(color: AdminColors.darkCard),
          children: [
            _buildTableHeader('Cohorte'),
            _buildTableHeader('Users'),
            _buildTableHeader('M1'),
            _buildTableHeader('M2'),
            _buildTableHeader('M3'),
            _buildTableHeader('M6'),
          ],
        ),
        ...cohorts.take(5).map((cohort) => TableRow(
              children: [
                _buildTableCell(cohort.cohortMonth),
                _buildTableCell(cohort.totalUsers.toString()),
                ...List.generate(4, (i) {
                  final rate = i < cohort.retentionRates.length
                      ? cohort.retentionRates[i]
                      : 0.0;
                  return _buildRetentionCell(rate);
                }),
              ],
            )),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(color: AdminColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRetentionCell(double rate) {
    final color = rate >= 50
        ? AdminColors.success
        : rate >= 25
            ? AdminColors.warning
            : AdminColors.error;
    return Container(
      padding: const EdgeInsets.all(8),
      color: color.withOpacity(0.1),
      child: Text(
        '${rate.toStringAsFixed(0)}%',
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}
