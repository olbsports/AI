import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
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
import 'screens/settings/organization_screen.dart';
import 'screens/settings/notifications_screen.dart';
import 'screens/marketplace/create_listing_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/breeding/breeding_screen.dart';
import 'screens/social/feed_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/gamification/gamification_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/planning/planning_screen.dart';
import 'screens/clubs/clubs_screen.dart';
import 'screens/gestation/gestation_screen.dart';
import 'screens/services/services_screen.dart';
import 'screens/categories/ecurie_home_screen.dart';
import 'screens/categories/ia_home_screen.dart';
import 'screens/categories/social_home_screen.dart';
import 'screens/categories/plus_home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/main_scaffold.dart';

class HorseTempoApp extends ConsumerWidget {
  const HorseTempoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Horse Tempo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
          // Main dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          // Category home screens
          GoRoute(
            path: '/ecurie',
            builder: (context, state) => const EcurieHomeScreen(),
          ),
          GoRoute(
            path: '/ia',
            builder: (context, state) => const IAHomeScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialHomeScreen(),
          ),
          GoRoute(
            path: '/plus',
            builder: (context, state) => const PlusHomeScreen(),
          ),
          // Horse management
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
              GoRoute(
                path: 'organization',
                builder: (context, state) => const OrganizationScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
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
          // Marketplace route
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
            routes: [
              GoRoute(
                path: 'create/sale',
                builder: (context, state) => const CreateListingScreen(type: CreateListingType.sale),
              ),
              GoRoute(
                path: 'create/mare',
                builder: (context, state) => const CreateListingScreen(type: CreateListingType.mare),
              ),
              GoRoute(
                path: 'create/stallion',
                builder: (context, state) => const CreateListingScreen(type: CreateListingType.stallion),
              ),
            ],
          ),
          // Gamification route
          GoRoute(
            path: '/gamification',
            builder: (context, state) => const GamificationScreen(),
          ),
          // Health tracking route
          GoRoute(
            path: '/health',
            builder: (context, state) => const HealthScreen(),
          ),
          // Planning route
          GoRoute(
            path: '/planning',
            builder: (context, state) => const PlanningScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PlanningScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => const PlanningScreen(),
              ),
            ],
          ),
          // Clubs route
          GoRoute(
            path: '/clubs',
            builder: (context, state) => const ClubsScreen(),
          ),
          // Gestation tracking route
          GoRoute(
            path: '/gestation',
            builder: (context, state) => const GestationScreen(),
          ),
          // Services directory route
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
        ],
      ),
    ],
  );
});
