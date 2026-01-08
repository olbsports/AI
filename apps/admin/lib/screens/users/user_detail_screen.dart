import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final activityAsync = ref.watch(userActivityProvider(userId));

    return Scaffold(
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (user.isVerified)
                              const Icon(Icons.verified, color: AdminColors.primary, size: 20),
                          ],
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: AdminColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _contactUser(context, user.email),
                    icon: const Icon(Icons.email),
                    label: const Text('Contacter'),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminColors.darkBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('Actions'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'impersonate', child: Text('Se connecter en tant que')),
                      const PopupMenuItem(value: 'suspend', child: Text('Suspendre')),
                      const PopupMenuItem(value: 'ban', child: Text('Bannir')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                    onSelected: (value) => _handleUserAction(context, ref, value, user),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  _buildStatCard('Chevaux', user.horseCount.toString(), Icons.pets),
                  const SizedBox(width: 16),
                  _buildStatCard('Analyses', user.analysisCount.toString(), Icons.analytics),
                  const SizedBox(width: 16),
                  _buildStatCard('Connexions', user.loginCount.toString(), Icons.login),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Dernière activité',
                    user.lastActiveAt != null
                        ? DateFormat('dd/MM').format(user.lastActiveAt!)
                        : 'Jamais',
                    Icons.access_time,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Email', user.email),
                            _buildInfoRow('Téléphone', user.phone ?? 'Non renseigné'),
                            _buildInfoRow('Statut', user.status.displayName),
                            _buildInfoRow('Abonnement', user.subscriptionPlan ?? 'Gratuit'),
                            _buildInfoRow(
                              'Inscrit le',
                              DateFormat('dd MMMM yyyy', 'fr').format(user.createdAt),
                            ),
                            if (user.subscriptionExpiresAt != null)
                              _buildInfoRow(
                                'Expiration abonnement',
                                DateFormat('dd/MM/yyyy').format(user.subscriptionExpiresAt!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Activity log
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activité récente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            activityAsync.when(
                              data: (logs) => Column(
                                children: logs
                                    .take(10)
                                    .map((log) => _buildActivityItem(log))
                                    .toList(),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Erreur: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
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
                      fontSize: 20,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AdminColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AdminColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AdminColors.darkCard,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.history, size: 16, color: AdminColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(color: AdminColors.textPrimary),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt),
                  style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactUser(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email?subject=Horse Tempo - Support Admin');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le client email pour $email')),
      );
    }
  }

  void _handleUserAction(BuildContext context, WidgetRef ref, String action, dynamic user) {
    switch (action) {
      case 'impersonate':
        _showImpersonateDialog(context, ref, user);
        break;
      case 'suspend':
        _showSuspendDialog(context, ref, user);
        break;
      case 'ban':
        _showBanDialog(context, ref, user);
        break;
      case 'delete':
        _showDeleteDialog(context, ref, user);
        break;
    }
  }

  void _showImpersonateDialog(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se connecter en tant que'),
        content: Text('Voulez-vous vous connecter en tant que ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionsProvider.notifier).impersonateUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connecté en tant que ${user.name}')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre l\'utilisateur'),
        content: Text('Voulez-vous suspendre le compte de ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.warning),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionsProvider.notifier).suspendUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} a été suspendu')),
                );
              }
            },
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bannir l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir bannir ${user.name} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Raison du bannissement'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionsProvider.notifier).banUser(user.id, reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} a été banni')),
                );
              }
            },
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Cette action est irréversible. Voulez-vous vraiment supprimer ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionsProvider.notifier).deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} a été supprimé')),
                );
                context.go('/users');
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
