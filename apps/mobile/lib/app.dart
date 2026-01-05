import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/horses/horses_screen.dart';
import 'screens/horses/horse_detail_screen.dart';
import 'screens/horses/horse_form_screen.dart';
import 'screens/riders/riders_screen.dart';
import 'screens/riders/rider_detail_screen.dart';
import 'screens/riders/rider_form_screen.dart';
import 'screens/reports/new_report_screen.dart';
import 'screens/analyses/analyses_screen.dart';
import 'screens/analyses/analysis_detail_screen.dart';
import 'screens/analyses/new_analysis_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/report_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/settings/billing_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/breeding/breeding_screen.dart';
import 'screens/social/feed_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/main_scaffold.dart';

class HorseVisionApp extends ConsumerWidget {
  const HorseVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Horse Vision AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/horses',
            builder: (context, state) => const HorsesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const HorseFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => HorseDetailScreen(
                  horseId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => HorseFormScreen(
                      horseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/riders',
            builder: (context, state) => const RidersScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const RiderFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => RiderDetailScreen(
                  riderId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => RiderFormScreen(
                      riderId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/analyses',
            builder: (context, state) => const AnalysesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => NewAnalysisScreen(
                  horseId: state.uri.queryParameters['horseId'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => AnalysisDetailScreen(
                  analysisId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => NewReportScreen(
                  horseId: state.uri.queryParameters['horseId'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ReportDetailScreen(
                  reportId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'billing',
                builder: (context, state) => const BillingScreen(),
              ),
            ],
          ),
          // Leaderboard route
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          // Breeding recommendation route
          GoRoute(
            path: '/breeding',
            builder: (context, state) => const BreedingScreen(),
          ),
          // Community feed route
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
        ],
      ),
    ],
  );
});
