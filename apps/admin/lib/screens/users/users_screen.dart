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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AdminColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(usersProvider),
        child: Padding(
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
                      'Utilisateurs',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportUsers(context, ref),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Exporter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddUserDialog(context, ref),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Ajouter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Utilisateurs',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _exportUsers(context, ref),
                          icon: const Icon(Icons.download),
                          label: const Text('Exporter'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(context, ref),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Filters
              Card(
                color: AdminColors.darkCard,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: isMobile
                      ? Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              style: const TextStyle(color: AdminColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Rechercher...',
                                hintStyle: TextStyle(color: AdminColors.textMuted),
                                prefixIcon: Icon(Icons.search, color: AdminColors.textMuted),
                                filled: true,
                                fillColor: AdminColors.darkSurface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              onSubmitted: (value) {
                                ref.read(userFiltersProvider.notifier).state = filters.copyWith(search: value, page: 1);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<UserStatus?>(
                                    value: filters.status,
                                    dropdownColor: AdminColors.darkCard,
                                    style: const TextStyle(color: AdminColors.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'Statut',
                                      labelStyle: TextStyle(color: AdminColors.textSecondary),
                                      filled: true,
                                      fillColor: AdminColors.darkSurface,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Tous')),
                                      ...UserStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                                    ],
                                    onChanged: (value) {
                                      ref.read(userFiltersProvider.notifier).state = filters.copyWith(status: value, page: 1);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    value: filters.plan,
                                    dropdownColor: AdminColors.darkCard,
                                    style: const TextStyle(color: AdminColors.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'Plan',
                                      labelStyle: TextStyle(color: AdminColors.textSecondary),
                                      filled: true,
                                      fillColor: AdminColors.darkSurface,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('Tous')),
                                      DropdownMenuItem(value: 'free', child: Text('Gratuit')),
                                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                                    ],
                                    onChanged: (value) {
                                      ref.read(userFiltersProvider.notifier).state = filters.copyWith(plan: value, page: 1);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: AdminColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un utilisateur...',
                                  hintStyle: TextStyle(color: AdminColors.textMuted),
                                  prefixIcon: Icon(Icons.search, color: AdminColors.textMuted),
                                  filled: true,
                                  fillColor: AdminColors.darkSurface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                onSubmitted: (value) {
                                  ref.read(userFiltersProvider.notifier).state = filters.copyWith(search: value, page: 1);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<UserStatus?>(
                                value: filters.status,
                                dropdownColor: AdminColors.darkCard,
                                style: const TextStyle(color: AdminColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Statut',
                                  labelStyle: TextStyle(color: AdminColors.textSecondary),
                                  filled: true,
                                  fillColor: AdminColors.darkSurface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Tous')),
                                  ...UserStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                                ],
                                onChanged: (value) {
                                  ref.read(userFiltersProvider.notifier).state = filters.copyWith(status: value, page: 1);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String?>(
                                value: filters.plan,
                                dropdownColor: AdminColors.darkCard,
                                style: const TextStyle(color: AdminColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Abonnement',
                                  labelStyle: TextStyle(color: AdminColors.textSecondary),
                                  filled: true,
                                  fillColor: AdminColors.darkSurface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('Tous')),
                                  DropdownMenuItem(value: 'free', child: Text('Gratuit')),
                                  DropdownMenuItem(value: 'pro', child: Text('Pro')),
                                ],
                                onChanged: (value) {
                                  ref.read(userFiltersProvider.notifier).state = filters.copyWith(plan: value, page: 1);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Users list
              Expanded(
                child: usersAsync.when(
                  data: (response) => _buildUsersList(response, filters, isMobile),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildErrorView(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
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
              onPressed: () => ref.invalidate(usersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(UserListResponse response, UserFilters filters, bool isMobile) {
    if (response.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AdminColors.textMuted),
            const SizedBox(height: 16),
            Text('Aucun utilisateur trouvé', style: TextStyle(color: AdminColors.textSecondary)),
          ],
        ),
      );
    }

    return Card(
      color: AdminColors.darkCard,
      child: Column(
        children: [
          // Table header (desktop only)
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AdminColors.darkSurface,
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
          if (!isMobile) const Divider(height: 1, color: AdminColors.darkBorder),

          // List
          Expanded(
            child: ListView.separated(
              itemCount: response.users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AdminColors.darkBorder),
              itemBuilder: (context, index) {
                final user = response.users[index];
                return isMobile ? _buildMobileUserCard(user) : _buildDesktopUserRow(user);
              },
            ),
          ),

          // Pagination
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.darkBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${response.total} utilisateur(s)',
                  style: TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: filters.page > 1
                          ? () => ref.read(userFiltersProvider.notifier).state = filters.copyWith(page: filters.page - 1)
                          : null,
                      icon: Icon(Icons.chevron_left, color: filters.page > 1 ? AdminColors.textPrimary : AdminColors.textMuted),
                      iconSize: 20,
                    ),
                    Text('${filters.page}/${response.totalPages}', style: TextStyle(color: AdminColors.textSecondary)),
                    IconButton(
                      onPressed: filters.page < response.totalPages
                          ? () => ref.read(userFiltersProvider.notifier).state = filters.copyWith(page: filters.page + 1)
                          : null,
                      icon: Icon(Icons.chevron_right, color: filters.page < response.totalPages ? AdminColors.textPrimary : AdminColors.textMuted),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(AppUser user) {
    return InkWell(
      onTap: () => context.go('/users/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AdminColors.primary,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                  Text(user.email, style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPlanColor(user.subscriptionPlan).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.subscriptionPlan ?? 'Gratuit',
                          style: TextStyle(color: _getPlanColor(user.subscriptionPlan), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(user.status.colorValue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.status.displayName,
                          style: TextStyle(color: Color(user.status.colorValue), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AdminColors.textSecondary),
              color: AdminColors.darkCard,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('Voir', style: TextStyle(color: AdminColors.textPrimary))),
                const PopupMenuItem(value: 'edit', child: Text('Modifier', style: TextStyle(color: AdminColors.textPrimary))),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'ban', child: Text('Bannir', style: TextStyle(color: AdminColors.error))),
              ],
              onSelected: (value) => _handleAction(value, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopUserRow(AppUser user) {
    return InkWell(
      onTap: () => context.go('/users/${user.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AdminColors.primary,
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null
                        ? Text(user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500, color: AdminColors.textPrimary), overflow: TextOverflow.ellipsis),
                        Text('${user.horseCount} chevaux • ${user.analysisCount} analyses', style: TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(user.email, style: TextStyle(color: AdminColors.textSecondary), overflow: TextOverflow.ellipsis)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _getPlanColor(user.subscriptionPlan).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(user.subscriptionPlan ?? 'Gratuit', style: TextStyle(color: _getPlanColor(user.subscriptionPlan), fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.center),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Color(user.status.colorValue).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(user.status.displayName, style: TextStyle(color: Color(user.status.colorValue), fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.center),
              ),
            ),
            Expanded(child: Text(DateFormat('dd/MM/yyyy').format(user.createdAt), style: TextStyle(color: AdminColors.textSecondary))),
            Expanded(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.visibility, size: 20), color: AdminColors.textSecondary, onPressed: () => context.go('/users/${user.id}'), tooltip: 'Voir'),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: AdminColors.textSecondary),
                    color: AdminColors.darkCard,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier', style: TextStyle(color: AdminColors.textPrimary))),
                      const PopupMenuItem(value: 'impersonate', child: Text('Se connecter en tant que', style: TextStyle(color: AdminColors.textPrimary))),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'ban', child: Text('Bannir', style: TextStyle(color: AdminColors.error))),
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

  Widget _buildHeaderCell(String label, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AdminColors.textSecondary, fontSize: 13)));
  }

  Color _getPlanColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'premium':
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
      case 'view':
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: const Text('Se connecter en tant que', style: TextStyle(color: AdminColors.textPrimary)),
        content: Text('Voulez-vous vous connecter en tant que ${user.name} ?', style: TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: const Text('Bannir l\'utilisateur', style: TextStyle(color: AdminColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir bannir ${user.name} ?', style: TextStyle(color: AdminColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AdminColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Raison du bannissement',
                labelStyle: TextStyle(color: AdminColors.textSecondary),
                filled: true,
                fillColor: AdminColors.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminActionsProvider.notifier).banUser(user.id, reasonController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur banni')));
              }
            },
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUsers(BuildContext context, WidgetRef ref) async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: const Text('Exporter les utilisateurs', style: TextStyle(color: AdminColors.textPrimary)),
        content: const Text('Choisissez le format d\'exportation', style: TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'csv'), child: const Text('CSV')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'xlsx'), child: const Text('Excel')),
        ],
      ),
    );

    if (format != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export $format en cours...')));
      await ref.read(adminActionsProvider.notifier).exportUsers(format);
    }
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: const Text('Ajouter un utilisateur', style: TextStyle(color: AdminColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AdminColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  labelStyle: TextStyle(color: AdminColors.textSecondary),
                  filled: true,
                  fillColor: AdminColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: AdminColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AdminColors.textSecondary),
                  filled: true,
                  fillColor: AdminColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Requis';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) return 'Email invalide';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext);
                final success = await ref.read(adminActionsProvider.notifier).createUser(name: nameController.text, email: emailController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Utilisateur créé avec succès' : 'Erreur lors de la création'),
                      backgroundColor: success ? AdminColors.success : AdminColors.error,
                    ),
                  );
                  if (success) ref.invalidate(usersProvider);
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
