import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/admin_theme.dart';

// Données de démonstration locales (pas besoin d'API)
class DemoStats {
  final int totalUsers;
  final int newUsersToday;
  final double mrr;
  final int activeSubscriptions;
  final int totalAnalyses;
  final int analysesToday;
  final int totalHorses;
  final int pendingReports;
  final int openTickets;
  final double churnRate;
  final int activeUsers;
  final Map<String, int> usersByPlan;

  DemoStats({
    this.totalUsers = 1245,
    this.newUsersToday = 12,
    this.mrr = 24580.0,
    this.activeSubscriptions = 487,
    this.totalAnalyses = 8932,
    this.analysesToday = 156,
    this.totalHorses = 3421,
    this.pendingReports = 3,
    this.openTickets = 7,
    this.churnRate = 2.4,
    this.activeUsers = 892,
    this.usersByPlan = const {
      'Gratuit': 758,
      'Starter': 312,
      'Pro': 145,
      'Enterprise': 30,
    },
  });
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final stats = DemoStats();

    return Scaffold(
      backgroundColor: AdminColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulation de rafraîchissement
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text('Aperçu de votre plateforme', style: TextStyle(color: AdminColors.textSecondary, fontSize: 14)),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                        Text('Bienvenue ! Voici un aperçu de votre plateforme.', style: TextStyle(color: AdminColors.textSecondary)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Exporter'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Main KPIs - Responsive grid
              _buildResponsiveGrid(
                context,
                isMobile: isMobile,
                children: [
                  _buildStatCard('Utilisateurs', stats.totalUsers.toString(), '+${stats.newUsersToday} aujourd\'hui', Icons.people, AdminColors.primary),
                  _buildStatCard('MRR', '${stats.mrr.toStringAsFixed(0)}€', '${stats.activeSubscriptions} abonnements', Icons.trending_up, AdminColors.success),
                  _buildStatCard('Analyses', stats.totalAnalyses.toString(), '+${stats.analysesToday} aujourd\'hui', Icons.analytics, AdminColors.accent),
                  _buildStatCard('Chevaux', stats.totalHorses.toString(), '${(stats.totalHorses / stats.totalUsers).toStringAsFixed(1)}/user', Icons.pets, AdminColors.secondary),
                ],
              ),
              const SizedBox(height: 16),

              // Secondary stats
              _buildResponsiveGrid(
                context,
                isMobile: isMobile,
                children: [
                  _buildAlertCard('Signalements', stats.pendingReports.toString(), 'en attente', Icons.flag, stats.pendingReports > 0 ? AdminColors.warning : AdminColors.success),
                  _buildAlertCard('Tickets', stats.openTickets.toString(), 'ouverts', Icons.support_agent, stats.openTickets > 5 ? AdminColors.warning : AdminColors.success),
                  _buildAlertCard('Churn', '${stats.churnRate}%', 'ce mois', Icons.person_remove, stats.churnRate > 5 ? AdminColors.error : AdminColors.success),
                  _buildAlertCard('Actifs', stats.activeUsers.toString(), '7 derniers jours', Icons.person, AdminColors.primary),
                ],
              ),
              const SizedBox(height: 24),

              // Distribution par plan
              Card(
                color: AdminColors.darkCard,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Par abonnement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                      const SizedBox(height: 16),
                      ...stats.usersByPlan.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: TextStyle(color: AdminColors.textSecondary)),
                            Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent activity
              Card(
                color: AdminColors.darkCard,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Activité récente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                          TextButton(onPressed: () => context.go('/analytics'), child: const Text('Voir tout')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem('Nouvel utilisateur', 'jean.dupont@email.com s\'est inscrit', '2 min', Icons.person_add, AdminColors.success),
                      _buildActivityItem('Nouvel abonnement', 'marie.martin@email.com → Premium', '15 min', Icons.star, AdminColors.warning),
                      _buildActivityItem('Signalement', 'Nouveau signalement de contenu', '32 min', Icons.flag, AdminColors.error),
                      _buildActivityItem('Analyse', '24 nouvelles analyses effectuées', '1h', Icons.analytics, AdminColors.accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, {required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(
        children: children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child)).toList(),
      );
    }
    return Row(
      children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child))).toList(),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      color: AdminColors.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: AdminColors.textSecondary, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      color: AdminColors.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                  Text(subtitle, style: TextStyle(color: AdminColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String description, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AdminColors.textPrimary, fontSize: 14)),
                Text(description, style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: AdminColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exporter les données'),
        content: const Text('Choisissez le format d\'exportation'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export CSV en cours...'))); }, child: const Text('CSV')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export JSON en cours...'))); }, child: const Text('JSON')),
        ],
      ),
    );
  }
}
