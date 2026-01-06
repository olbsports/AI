import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    'Rapport utilisateurs',
                    'Export complet des utilisateurs',
                    Icons.people,
                    AdminColors.primary,
                  ),
                  _buildReportCard(
                    'Rapport revenus',
                    'Historique des transactions',
                    Icons.attach_money,
                    AdminColors.success,
                  ),
                  _buildReportCard(
                    'Rapport analyses',
                    'Statistiques d\'utilisation',
                    Icons.analytics,
                    AdminColors.accent,
                  ),
                  _buildReportCard(
                    'Rapport chevaux',
                    'Données des chevaux',
                    Icons.pets,
                    AdminColors.secondary,
                  ),
                  _buildReportCard(
                    'Rapport modération',
                    'Historique des signalements',
                    Icons.flag,
                    AdminColors.warning,
                  ),
                  _buildReportCard(
                    'Rapport support',
                    'Statistiques des tickets',
                    Icons.support_agent,
                    AdminColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {},
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
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('CSV'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
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
}
