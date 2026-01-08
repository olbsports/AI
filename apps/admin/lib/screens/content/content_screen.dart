import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  String _notificationTitle = '';
  String _notificationMessage = '';
  String _notificationTarget = 'all';

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => _showCreateContentDialog(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _refreshContent(type),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: AdminColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun contenu pour l\'instant',
                    style: TextStyle(color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showCreateContentDialog(context, type: type),
                    child: const Text('Créer un contenu'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshContent(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Actualisation de $type...')),
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
              onChanged: (v) => setState(() => _notificationTitle = v),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Corps de la notification',
              ),
              maxLines: 3,
              onChanged: (v) => setState(() => _notificationMessage = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cible'),
              value: _notificationTarget,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                DropdownMenuItem(value: 'premium', child: Text('Abonnés Premium')),
                DropdownMenuItem(value: 'free', child: Text('Utilisateurs gratuits')),
                DropdownMenuItem(value: 'inactive', child: Text('Utilisateurs inactifs')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _notificationTarget = v);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _notificationTitle.isNotEmpty && _notificationMessage.isNotEmpty
                  ? () => _sendNotification()
                  : null,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateContentDialog(BuildContext context, {String? type}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Créer ${type ?? 'un contenu'}'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer l\'envoi'),
        content: Text(
          'Envoyer la notification "$_notificationTitle" à ${_getTargetLabel()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(adminActionsProvider.notifier).sendPushNotification(
        title: _notificationTitle,
        message: _notificationMessage,
        target: _notificationTarget,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée avec succès'),
            backgroundColor: AdminColors.success,
          ),
        );
        setState(() {
          _notificationTitle = '';
          _notificationMessage = '';
        });
      }
    }
  }

  String _getTargetLabel() {
    switch (_notificationTarget) {
      case 'all':
        return 'tous les utilisateurs';
      case 'premium':
        return 'les abonnés Premium';
      case 'free':
        return 'les utilisateurs gratuits';
      case 'inactive':
        return 'les utilisateurs inactifs';
      default:
        return 'les utilisateurs sélectionnés';
    }
  }
}
