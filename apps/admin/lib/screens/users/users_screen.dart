import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final filters = ref.watch(userFiltersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Utilisateurs',
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
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un utilisateur...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          ref.read(userFiltersProvider.notifier).state =
                              filters.copyWith(search: value, page: 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<UserStatus?>(
                        value: filters.status,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tous')),
                          ...UserStatus.values.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.displayName),
                              )),
                        ],
                        onChanged: (value) {
                          ref.read(userFiltersProvider.notifier).state =
                              filters.copyWith(status: value, page: 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String?>(
                        value: filters.plan,
                        decoration: const InputDecoration(
                          labelText: 'Abonnement',
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tous')),
                          DropdownMenuItem(value: 'free', child: Text('Gratuit')),
                          DropdownMenuItem(value: 'basic', child: Text('Basic')),
                          DropdownMenuItem(value: 'premium', child: Text('Premium')),
                          DropdownMenuItem(value: 'pro', child: Text('Pro')),
                        ],
                        onChanged: (value) {
                          ref.read(userFiltersProvider.notifier).state =
                              filters.copyWith(plan: value, page: 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Users table
            Expanded(
              child: Card(
                child: usersAsync.when(
                  data: (response) => Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.darkCard,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            _buildHeaderCell('Utilisateur', flex: 2),
                            _buildHeaderCell('Email', flex: 2),
                            _buildHeaderCell('Abonnement'),
                            _buildHeaderCell('Statut'),
                            _buildHeaderCell('Inscrit le'),
                            _buildHeaderCell('Actions'),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AdminColors.darkBorder),

                      // Table body
                      Expanded(
                        child: ListView.separated(
                          itemCount: response.users.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AdminColors.darkBorder),
                          itemBuilder: (context, index) {
                            final user = response.users[index];
                            return _buildUserRow(user);
                          },
                        ),
                      ),

                      // Pagination
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AdminColors.darkBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Affichage ${(filters.page - 1) * filters.limit + 1}-'
                              '${(filters.page * filters.limit).clamp(0, response.total)} '
                              'sur ${response.total}',
                              style: TextStyle(color: AdminColors.textSecondary),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: filters.page > 1
                                      ? () => ref.read(userFiltersProvider.notifier).state =
                                            filters.copyWith(page: filters.page - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Page ${filters.page}/${response.totalPages}'),
                                IconButton(
                                  onPressed: filters.page < response.totalPages
                                      ? () => ref.read(userFiltersProvider.notifier).state =
                                            filters.copyWith(page: filters.page + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AdminColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildUserRow(AppUser user) {
    return InkWell(
      onTap: () => context.go('/users/${user.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // User info
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(user.name.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${user.horseCount} chevaux • ${user.analysisCount} analyses',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Email
            Expanded(
              flex: 2,
              child: Text(
                user.email,
                style: TextStyle(color: AdminColors.textSecondary),
              ),
            ),
            // Subscription
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlanColor(user.subscriptionPlan).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.subscriptionPlan ?? 'Gratuit',
                  style: TextStyle(
                    color: _getPlanColor(user.subscriptionPlan),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Status
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(user.status.colorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.status.displayName,
                  style: TextStyle(
                    color: Color(user.status.colorValue),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Created at
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(user.createdAt),
                style: TextStyle(color: AdminColors.textSecondary),
              ),
            ),
            // Actions
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => context.go('/users/${user.id}'),
                    tooltip: 'Voir',
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'impersonate',
                        child: Row(
                          children: [
                            Icon(Icons.login, size: 18),
                            SizedBox(width: 8),
                            Text('Se connecter en tant que'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'ban',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 18, color: AdminColors.error),
                            const SizedBox(width: 8),
                            Text('Bannir', style: TextStyle(color: AdminColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleAction(value, user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'premium':
        return AdminColors.warning;
      case 'pro':
        return AdminColors.primary;
      case 'basic':
        return AdminColors.accent;
      default:
        return AdminColors.textSecondary;
    }
  }

  void _handleAction(String action, AppUser user) {
    switch (action) {
      case 'edit':
        context.go('/users/${user.id}');
        break;
      case 'impersonate':
        _showImpersonateDialog(user);
        break;
      case 'ban':
        _showBanDialog(user);
        break;
    }
  }

  void _showImpersonateDialog(AppUser user) {
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
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(AppUser user) {
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
              decoration: const InputDecoration(
                labelText: 'Raison du bannissement',
              ),
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
              await ref
                  .read(adminActionsProvider.notifier)
                  .banUser(user.id, reasonController.text);
            },
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }
}
