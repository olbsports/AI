import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/admin_models.dart';
import 'providers/admin_auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/users/user_detail_screen.dart';
import 'screens/subscriptions/subscriptions_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/moderation/moderation_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/horses/horses_admin_screen.dart';
import 'screens/content/content_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/reports/admin_reports_screen.dart';
import 'theme/admin_theme.dart';
import 'widgets/admin_shell.dart';

class HorseTempoAdminApp extends ConsumerWidget {
  const HorseTempoAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'Horse Tempo Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      darkTheme: AdminTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAdmin = authState.user?.role == AdminRole.admin ||
                      authState.user?.role == AdminRole.superAdmin;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && !isAdmin) {
        return '/login?error=unauthorized';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Admin shell routes
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => UserDetailScreen(
                  userId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/moderation',
            builder: (context, state) => const ModerationScreen(),
          ),
          GoRoute(
            path: '/horses',
            builder: (context, state) => const HorsesAdminScreen(),
          ),
          GoRoute(
            path: '/content',
            builder: (context, state) => const ContentScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
