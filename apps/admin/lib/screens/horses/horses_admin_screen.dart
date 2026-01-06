import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/admin_theme.dart';

class HorsesAdminScreen extends ConsumerWidget {
  const HorsesAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des chevaux',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('Total chevaux', '12,458', Icons.pets),
                const SizedBox(width: 16),
                _buildStatCard('Analyses ce mois', '3,247', Icons.analytics),
                const SizedBox(width: 16),
                _buildStatCard('Moyenne/user', '2.4', Icons.calculate),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Center(
                  child: Text(
                    'Liste des chevaux avec filtres et recherche',
                    style: TextStyle(color: AdminColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(label, style: TextStyle(color: AdminColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
