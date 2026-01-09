import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Main categories for navigation
enum NavCategory {
  accueil,
  ecurie,
  ia,
  social,
  plus,
}

/// Main scaffold with category-based bottom navigation
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  NavCategory _getCurrentCategory(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Accueil
    if (location.startsWith('/dashboard')) return NavCategory.accueil;

    // Écurie - Chevaux, Cavaliers, Santé, Gestation
    if (location.startsWith('/horses') ||
        location.startsWith('/riders') ||
        location.startsWith('/health') ||
        location.startsWith('/gestation') ||
        location.startsWith('/ecurie')) {
      return NavCategory.ecurie;
    }

    // IA - Analyses, Rapports, Planning
    if (location.startsWith('/analyses') ||
        location.startsWith('/reports') ||
        location.startsWith('/planning') ||
        location.startsWith('/ia')) {
      return NavCategory.ia;
    }

    // Social - Feed, Marketplace, Clubs, Leaderboard
    if (location.startsWith('/feed') ||
        location.startsWith('/marketplace') ||
        location.startsWith('/clubs') ||
        location.startsWith('/leaderboard') ||
        location.startsWith('/social')) {
      return NavCategory.social;
    }

    // Plus - Settings, Breeding, Services, Gamification
    if (location.startsWith('/settings') ||
        location.startsWith('/breeding') ||
        location.startsWith('/services') ||
        location.startsWith('/gamification') ||
        location.startsWith('/plus')) {
      return NavCategory.plus;
    }

    return NavCategory.accueil;
  }

  int _categoryToIndex(NavCategory category) {
    switch (category) {
      case NavCategory.accueil:
        return 0;
      case NavCategory.ecurie:
        return 1;
      case NavCategory.ia:
        return 2;
      case NavCategory.social:
        return 3;
      case NavCategory.plus:
        return 4;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/ecurie');
        break;
      case 2:
        context.go('/ia');
        break;
      case 3:
        context.go('/social');
        break;
      case 4:
        context.go('/plus');
        break;
    }
  }

  bool _isMainCategoryRoute(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return location == '/dashboard' ||
        location == '/ecurie' ||
        location == '/ia' ||
        location == '/social' ||
        location == '/plus';
  }

  /// Get the parent route for nested navigation
  String? _getParentRoute(String location) {
    // Map sub-routes to their parent routes
    final parentRoutes = {
      // Horses
      '/horses/': '/ecurie',
      '/horse/': '/horses',
      // Riders
      '/riders/': '/ecurie',
      '/rider/': '/riders',
      // Health
      '/health/': '/ecurie',
      // Gestation
      '/gestation/': '/ecurie',
      // Analyses
      '/analyses/': '/ia',
      '/analysis/': '/analyses',
      // Reports
      '/reports/': '/ia',
      '/report/': '/reports',
      // Planning
      '/planning/': '/ia',
      // Feed
      '/feed/': '/social',
      '/post/': '/feed',
      // Marketplace
      '/marketplace/': '/social',
      '/listing/': '/marketplace',
      // Clubs
      '/clubs/': '/social',
      '/club/': '/clubs',
      // Leaderboard
      '/leaderboard/': '/social',
      // Settings
      '/settings/': '/plus',
      // Breeding
      '/breeding/': '/plus',
      // Services
      '/services/': '/plus',
      // Gamification
      '/gamification/': '/plus',
    };

    // Check for exact matches or prefix matches
    for (final entry in parentRoutes.entries) {
      if (location.startsWith(entry.key) && location != entry.value) {
        return entry.value;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _getCurrentCategory(context);
    final selectedIndex = _categoryToIndex(currentCategory);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Si on est sur le dashboard, ne pas quitter l'app
        if (location == '/dashboard') {
          return;
        }

        // Si on est sur une route de catégorie principale, aller au dashboard
        if (_isMainCategoryRoute(context)) {
          context.go('/dashboard');
          return;
        }

        // Essayer d'abord de pop via go_router
        if (context.canPop()) {
          context.pop();
          return;
        }

        // Chercher la route parente
        final parentRoute = _getParentRoute(location);
        if (parentRoute != null) {
          context.go(parentRoute);
          return;
        }

        // Retour à la catégorie home selon la route actuelle
        final category = _getCurrentCategory(context);
        switch (category) {
          case NavCategory.accueil:
            context.go('/dashboard');
            break;
          case NavCategory.ecurie:
            context.go('/ecurie');
            break;
          case NavCategory.ia:
            context.go('/ia');
            break;
          case NavCategory.social:
            context.go('/social');
            break;
          case NavCategory.plus:
            context.go('/plus');
            break;
        }
      },
      child: Scaffold(
        body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Accueil',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onDestinationSelected(context, 0),
                ),
                _NavItem(
                  icon: Icons.pets_outlined,
                  selectedIcon: Icons.pets,
                  label: 'Écurie',
                  isSelected: selectedIndex == 1,
                  color: AppColors.categoryEcurie,
                  onTap: () => _onDestinationSelected(context, 1),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: 'IA',
                  isSelected: selectedIndex == 2,
                  color: AppColors.categoryIA,
                  onTap: () => _onDestinationSelected(context, 2),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Social',
                  isSelected: selectedIndex == 3,
                  color: AppColors.categorySocial,
                  onTap: () => _onDestinationSelected(context, 3),
                ),
                _NavItem(
                  icon: Icons.more_horiz,
                  selectedIcon: Icons.more_horiz,
                  label: 'Plus',
                  isSelected: selectedIndex == 4,
                  color: AppColors.categoryPlus,
                  onTap: () => _onDestinationSelected(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Individual navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? selectedIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? primaryColor : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
