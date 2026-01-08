import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapports',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildReportCard(
                    context, ref,
                    'Rapport utilisateurs',
                    'Export complet des utilisateurs',
                    Icons.people,
                    AdminColors.primary,
                    'users',
                  ),
                  _buildReportCard(
                    context, ref,
                    'Rapport revenus',
                    'Historique des transactions',
                    Icons.attach_money,
                    AdminColors.success,
                    'revenue',
                  ),
                  _buildReportCard(
                    context, ref,
                    'Rapport analyses',
                    'Statistiques d\'utilisation',
                    Icons.analytics,
                    AdminColors.accent,
                    'analyses',
                  ),
                  _buildReportCard(
                    context, ref,
                    'Rapport chevaux',
                    'Données des chevaux',
                    Icons.pets,
                    AdminColors.secondary,
                    'horses',
                  ),
                  _buildReportCard(
                    context, ref,
                    'Rapport modération',
                    'Historique des signalements',
                    Icons.flag,
                    AdminColors.warning,
                    'moderation',
                  ),
                  _buildReportCard(
                    context, ref,
                    'Rapport support',
                    'Statistiques des tickets',
                    Icons.support_agent,
                    AdminColors.error,
                    'support',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    IconData icon,
    Color color,
    String reportType,
  ) {
    return Card(
      child: InkWell(
        onTap: () => _showReportOptions(context, ref, title, reportType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _generateReport(context, ref, reportType, 'csv'),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('CSV'),
                  ),
                  TextButton.icon(
                    onPressed: () => _generateReport(context, ref, reportType, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportOptions(BuildContext context, WidgetRef ref, String title, String reportType) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Période du rapport:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('7 derniers jours'),
              onTap: () {
                Navigator.pop(dialogContext);
                _generateReport(context, ref, reportType, 'pdf', days: 7);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('30 derniers jours'),
              onTap: () {
                Navigator.pop(dialogContext);
                _generateReport(context, ref, reportType, 'pdf', days: 30);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Cette année'),
              onTap: () {
                Navigator.pop(dialogContext);
                _generateReport(context, ref, reportType, 'pdf', days: 365);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    WidgetRef ref,
    String reportType,
    String format, {
    int days = 30,
  }) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(adminActionsProvider.notifier).generateReport(
        type: reportType,
        format: format,
        days: days,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport $format généré avec succès'),
          backgroundColor: AdminColors.success,
          action: SnackBarAction(
            label: 'Télécharger',
            textColor: Colors.white,
            onPressed: () {
              // Trigger download
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AdminColors.error,
        ),
      );
    }
  }
}
