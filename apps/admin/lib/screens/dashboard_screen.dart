import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Bienvenue ! Voici un aperçu de votre plateforme.',
                        style: TextStyle(color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportDashboardData(context, ref),
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    // Main KPIs
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Utilisateurs',
                            stats.totalUsers.toString(),
                            '+${stats.newUsersToday} aujourd\'hui',
                            Icons.people,
                            AdminColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'MRR',
                            '${NumberFormat.currency(locale: 'fr', symbol: '€').format(stats.mrr)}',
                            '${stats.activeSubscriptions} abonnements',
                            Icons.trending_up,
                            AdminColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Analyses',
                            stats.totalAnalyses.toString(),
                            '+${stats.analysesToday} aujourd\'hui',
                            Icons.analytics,
                            AdminColors.accent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Chevaux',
                            stats.totalHorses.toString(),
                            '${(stats.totalHorses / stats.totalUsers).toStringAsFixed(1)}/user',
                            Icons.pets,
                            AdminColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Secondary stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildAlertCard(
                            'Signalements',
                            stats.pendingReports.toString(),
                            'en attente',
                            Icons.flag,
                            stats.pendingReports > 0 ? AdminColors.warning : AdminColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAlertCard(
                            'Tickets',
                            stats.openTickets.toString(),
                            'ouverts',
                            Icons.support_agent,
                            stats.openTickets > 5 ? AdminColors.warning : AdminColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAlertCard(
                            'Churn',
                            '${stats.churnRate.toStringAsFixed(1)}%',
                            'ce mois',
                            Icons.person_remove,
                            stats.churnRate > 5 ? AdminColors.error : AdminColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAlertCard(
                            'Actifs',
                            stats.activeUsers.toString(),
                            '7 derniers jours',
                            Icons.person,
                            AdminColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Charts row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User growth chart placeholder
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
                                    height: 250,
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
                        // Distribution by plan
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Par abonnement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...stats.usersByPlan.entries.map((e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(e.key, style: TextStyle(color: AdminColors.textSecondary)),
                                            Text(
                                              e.value.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AdminColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Activité récente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/analytics'),
                                  child: const Text('Voir tout'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActivityItem(
                              'Nouvel utilisateur',
                              'jean.dupont@email.com s\'est inscrit',
                              '2 min',
                              Icons.person_add,
                              AdminColors.success,
                            ),
                            _buildActivityItem(
                              'Nouvel abonnement',
                              'marie.martin@email.com → Premium',
                              '15 min',
                              Icons.star,
                              AdminColors.warning,
                            ),
                            _buildActivityItem(
                              'Signalement',
                              'Nouveau signalement de contenu',
                              '32 min',
                              Icons.flag,
                              AdminColors.error,
                            ),
                            _buildActivityItem(
                              'Analyse',
                              '24 nouvelles analyses effectuées',
                              '1h',
                              Icons.analytics,
                              AdminColors.accent,
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
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AdminColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AdminColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: AdminColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDashboardData(BuildContext context, WidgetRef ref) async {
    final stats = ref.read(dashboardStatsProvider).valueOrNull;
    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune donnée à exporter')),
      );
      return;
    }

    // Show export dialog
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: const Text('Choisissez le format d\'exportation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const Text('CSV'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'json'),
            child: const Text('JSON'),
          ),
        ],
      ),
    );

    if (format != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export $format en cours... Vérifiez vos téléchargements.')),
      );
      // In production, this would trigger actual file download via API
      await ref.read(adminActionsProvider.notifier).exportDashboardStats(format);
    }
  }
}
