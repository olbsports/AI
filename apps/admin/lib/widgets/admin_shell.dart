import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _isExpanded = true;
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final pendingReportsAsync = ref.watch(pendingReportsCountProvider);
    final openTicketsAsync = ref.watch(openTicketsCountProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 260 : 72,
            child: Container(
              decoration: const BoxDecoration(
                color: AdminColors.darkSurface,
                border: Border(
                  right: BorderSide(color: AdminColors.darkBorder),
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AdminColors.primary, AdminColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 24),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Horse Vision',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(color: AdminColors.darkBorder, height: 1),

                  // Navigation items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildNavItem(
                          icon: Icons.dashboard_outlined,
                          label: 'Dashboard',
                          path: '/dashboard',
                        ),
                        _buildNavItem(
                          icon: Icons.people_outline,
                          label: 'Utilisateurs',
                          path: '/users',
                        ),
                        _buildNavItem(
                          icon: Icons.credit_card_outlined,
                          label: 'Abonnements',
                          path: '/subscriptions',
                        ),
                        _buildNavItem(
                          icon: Icons.analytics_outlined,
                          label: 'Analytics',
                          path: '/analytics',
                        ),
                        _buildNavItem(
                          icon: Icons.flag_outlined,
                          label: 'Modération',
                          path: '/moderation',
                          badge: pendingReportsAsync.whenOrNull(data: (c) => c > 0 ? c : null),
                        ),
                        _buildNavItem(
                          icon: Icons.pets_outlined,
                          label: 'Chevaux',
                          path: '/horses',
                        ),
                        _buildNavItem(
                          icon: Icons.article_outlined,
                          label: 'Contenu',
                          path: '/content',
                        ),
                        _buildNavItem(
                          icon: Icons.support_agent_outlined,
                          label: 'Support',
                          path: '/support',
                          badge: openTicketsAsync.whenOrNull(data: (c) => c > 0 ? c : null),
                        ),
                        _buildNavItem(
                          icon: Icons.assessment_outlined,
                          label: 'Rapports',
                          path: '/reports',
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AdminColors.darkBorder),
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          label: 'Paramètres',
                          path: '/settings',
                        ),
                      ],
                    ),
                  ),

                  // User info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AdminColors.darkBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AdminColors.primary,
                          child: Text(
                            authState.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.user?.name ?? 'Admin',
                                  style: const TextStyle(
                                    color: AdminColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  authState.user?.role.displayName ?? '',
                                  style: const TextStyle(
                                    color: AdminColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, size: 20),
                            color: AdminColors.textSecondary,
                            onPressed: () => _logout(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: AdminColors.darkSurface,
                    border: Border(
                      bottom: BorderSide(color: AdminColors.darkBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu),
                        onPressed: () => setState(() => _isExpanded = !_isExpanded),
                        color: AdminColors.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher...',
                            hintStyle: const TextStyle(color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.search, color: AdminColors.textMuted),
                            filled: true,
                            fillColor: AdminColors.darkCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AdminColors.textSecondary,
                        onPressed: () => _showNotifications(context),
                      ),
                      IconButton(
                        icon: Icon(_isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                        color: AdminColors.textSecondary,
                        onPressed: () => _toggleDarkMode(),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String path,
    int? badge,
  }) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = currentPath == path || currentPath.startsWith('$path/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AdminColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
                  size: 22,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminAuthProvider.notifier).logout();
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications),
            const SizedBox(width: 8),
            const Text('Notifications'),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
                );
              },
              child: const Text('Tout marquer comme lu'),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView(
            children: [
              _buildNotificationItem(
                'Nouveau signalement',
                'Un utilisateur a signalé un contenu inapproprié',
                '5 min',
                Icons.flag,
                AdminColors.warning,
              ),
              _buildNotificationItem(
                'Nouvel abonnement',
                'jean.dupont@email.com a souscrit au plan Premium',
                '15 min',
                Icons.star,
                AdminColors.success,
              ),
              _buildNotificationItem(
                'Ticket support',
                'Nouveau ticket ouvert par marie.martin@email.com',
                '1h',
                Icons.support_agent,
                AdminColors.primary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/support');
            },
            child: const Text('Voir tout'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: TextStyle(color: AdminColors.textMuted, fontSize: 12)),
    );
  }

  void _toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDarkMode ? 'Mode sombre activé' : 'Mode clair activé'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
