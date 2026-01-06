import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/admin_theme.dart';

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestion du contenu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau contenu'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const TabBar(
                tabs: [
                  Tab(text: 'Publications'),
                  Tab(text: 'Annonces'),
                  Tab(text: 'Articles'),
                  Tab(text: 'Notifications'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildContentList('Publications'),
                    _buildContentList('Annonces marketplace'),
                    _buildContentList('Articles de blog'),
                    _buildNotificationsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentList(String type) {
    return Card(
      child: Center(
        child: Text(
          'Liste des $type',
          style: TextStyle(color: AdminColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildNotificationsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envoyer une notification push',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Titre de la notification',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Corps de la notification',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cible'),
              value: 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                DropdownMenuItem(value: 'premium', child: Text('Abonnés Premium')),
                DropdownMenuItem(value: 'free', child: Text('Utilisateurs gratuits')),
                DropdownMenuItem(value: 'inactive', child: Text('Utilisateurs inactifs')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
