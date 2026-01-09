import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_api_service.dart';
import '../theme/admin_theme.dart';

// Provider pour les stats du dashboard
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  return api.get('/admin/dashboard/stats');
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AdminColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorView(context, ref, error.toString()),
          data: (stats) => _buildDashboard(context, ref, stats, isMobile),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AdminColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: AdminColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(dashboardStatsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, Map<String, dynamic> stats, bool isMobile) {
    final totalUsers = stats['totalUsers'] ?? 0;
    final newUsersToday = stats['newUsersToday'] ?? 0;
    final mrr = (stats['mrr'] ?? 0).toDouble();
    final activeSubscriptions = stats['activeSubscriptions'] ?? 0;
    final totalAnalyses = stats['totalAnalyses'] ?? 0;
    final analysesToday = stats['analysesToday'] ?? 0;
    final totalHorses = stats['totalHorses'] ?? 0;
    final pendingReports = stats['pendingReports'] ?? 0;
    final openTickets = stats['openTickets'] ?? 0;
    final churnRate = (stats['churnRate'] ?? 0).toDouble();
    final activeUsers = stats['activeUsers'] ?? 0;
    final usersByPlan = Map<String, dynamic>.from(stats['usersByPlan'] ?? {});

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Données en temps réel', style: TextStyle(color: AdminColors.textSecondary, fontSize: 14)),
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
                    Text('Données en temps réel de votre plateforme', style: TextStyle(color: AdminColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => ref.invalidate(dashboardStatsProvider),
                      icon: const Icon(Icons.refresh, color: AdminColors.textSecondary),
                      tooltip: 'Rafraîchir',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Exporter'),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Main KPIs
          _buildResponsiveGrid(
            isMobile: isMobile,
            children: [
              _buildStatCard('Utilisateurs', totalUsers.toString(), '+$newUsersToday aujourd\'hui', Icons.people, AdminColors.primary),
              _buildStatCard('MRR', '${mrr.toStringAsFixed(0)}€', '$activeSubscriptions abonnements', Icons.trending_up, AdminColors.success),
              _buildStatCard('Analyses', totalAnalyses.toString(), '+$analysesToday aujourd\'hui', Icons.analytics, AdminColors.accent),
              _buildStatCard('Chevaux', totalHorses.toString(), totalUsers > 0 ? '${(totalHorses / totalUsers).toStringAsFixed(1)}/user' : '0/user', Icons.pets, AdminColors.secondary),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary stats
          _buildResponsiveGrid(
            isMobile: isMobile,
            children: [
              _buildAlertCard('Signalements', pendingReports.toString(), 'en attente', Icons.flag, pendingReports > 0 ? AdminColors.warning : AdminColors.success),
              _buildAlertCard('Tickets', openTickets.toString(), 'ouverts', Icons.support_agent, openTickets > 5 ? AdminColors.warning : AdminColors.success),
              _buildAlertCard('Churn', '${churnRate.toStringAsFixed(1)}%', 'ce mois', Icons.person_remove, churnRate > 5 ? AdminColors.error : AdminColors.success),
              _buildAlertCard('Actifs', activeUsers.toString(), '7 derniers jours', Icons.person, AdminColors.primary),
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
                  const Text('Utilisateurs par abonnement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                  const SizedBox(height: 16),
                  if (usersByPlan.isEmpty)
                    Text('Aucune donnée disponible', style: TextStyle(color: AdminColors.textSecondary))
                  else
                    ...usersByPlan.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getPlanDisplayName(e.key), style: TextStyle(color: AdminColors.textSecondary)),
                          Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions
          Card(
            color: AdminColors.darkCard,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actions rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickAction(context, 'Utilisateurs', Icons.people, '/users'),
                      _buildQuickAction(context, 'Abonnements', Icons.credit_card, '/subscriptions'),
                      _buildQuickAction(context, 'Modération', Icons.flag, '/moderation'),
                      _buildQuickAction(context, 'Support', Icons.support_agent, '/support'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'free': return 'Gratuit';
      case 'starter': return 'Starter';
      case 'professional': return 'Professional';
      case 'enterprise': return 'Enterprise';
      default: return plan;
    }
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, String path) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AdminColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AdminColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(children: children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child)).toList());
    }
    return Row(children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child))).toList());
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
