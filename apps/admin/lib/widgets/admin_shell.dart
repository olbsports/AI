import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile ? _buildMobileAppBar(context, authState) : null,
      drawer: isMobile ? _buildDrawer(context, authState) : null,
      body: isMobile
          ? widget.child
          : Row(
              children: [
                _buildDesktopSidebar(context, authState),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(context),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AdminAuthState authState) {
    return AppBar(
      backgroundColor: AdminColors.darkSurface,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AdminColors.textPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminColors.primary, AdminColors.secondary],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Horse Tempo Admin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AdminColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: AdminColors.textSecondary),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AdminAuthState authState) {
    return Drawer(
      backgroundColor: AdminColors.darkSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.darkBorder)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AdminColors.primary,
                    child: Text(
                      authState.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.name ?? 'Admin',
                          style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authState.user?.role.displayName ?? '',
                          style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMobileNavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
                  _buildMobileNavItem(Icons.people_outline, 'Utilisateurs', '/users'),
                  _buildMobileNavItem(Icons.credit_card_outlined, 'Abonnements', '/subscriptions'),
                  _buildMobileNavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
                  _buildMobileNavItem(Icons.flag_outlined, 'Modération', '/moderation'),
                  _buildMobileNavItem(Icons.pets_outlined, 'Chevaux', '/horses'),
                  _buildMobileNavItem(Icons.article_outlined, 'Contenu', '/content'),
                  _buildMobileNavItem(Icons.support_agent_outlined, 'Support', '/support'),
                  _buildMobileNavItem(Icons.assessment_outlined, 'Rapports', '/reports'),
                  const Divider(color: AdminColors.darkBorder),
                  _buildMobileNavItem(Icons.settings_outlined, 'Paramètres', '/settings'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(IconData icon, String label, String path) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = currentPath == path || currentPath.startsWith('$path/');

    return ListTile(
      leading: Icon(icon, color: isSelected ? AdminColors.primary : AdminColors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AdminColors.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, AdminAuthState authState) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AdminColors.darkSurface,
        border: Border(right: BorderSide(color: AdminColors.darkBorder)),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AdminColors.primary, AdminColors.secondary]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pets, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Horse Tempo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const Divider(color: AdminColors.darkBorder, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDesktopNavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
                _buildDesktopNavItem(Icons.people_outline, 'Utilisateurs', '/users'),
                _buildDesktopNavItem(Icons.credit_card_outlined, 'Abonnements', '/subscriptions'),
                _buildDesktopNavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
                _buildDesktopNavItem(Icons.flag_outlined, 'Modération', '/moderation'),
                _buildDesktopNavItem(Icons.pets_outlined, 'Chevaux', '/horses'),
                _buildDesktopNavItem(Icons.article_outlined, 'Contenu', '/content'),
                _buildDesktopNavItem(Icons.support_agent_outlined, 'Support', '/support'),
                _buildDesktopNavItem(Icons.assessment_outlined, 'Rapports', '/reports'),
                const SizedBox(height: 16),
                const Divider(color: AdminColors.darkBorder),
                _buildDesktopNavItem(Icons.settings_outlined, 'Paramètres', '/settings'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AdminColors.darkBorder))),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminColors.primary,
                  child: Text(authState.user?.name.substring(0, 1).toUpperCase() ?? 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authState.user?.name ?? 'Admin', style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      Text(authState.user?.role.displayName ?? '', style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.logout, size: 20), color: AdminColors.textSecondary, onPressed: () => _logout(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(IconData icon, String label, String path) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AdminColors.primary : AdminColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(color: isSelected ? AdminColors.primary : AdminColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AdminColors.darkSurface,
        border: Border(bottom: BorderSide(color: AdminColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: AdminColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AdminColors.textMuted),
                filled: true,
                fillColor: AdminColors.darkCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              ref.read(adminAuthProvider.notifier).logout();
              Navigator.pop(ctx);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
