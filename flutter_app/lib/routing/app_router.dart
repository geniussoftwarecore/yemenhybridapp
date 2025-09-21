import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/screens/engineer_dashboard.dart';
import '../features/dashboard/screens/sales_dashboard.dart';
import '../features/dashboard/screens/admin_dashboard.dart';

// Routes
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const engineerDashboard = '/engineer-dashboard';
  static const salesDashboard = '/sales-dashboard';
  static const adminDashboard = '/admin-dashboard';
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // If not logged in and not on login/splash, redirect to splash
      if (!isLoggedIn && !isLoggingIn && !isSplash) {
        return AppRoutes.splash;
      }

      // If logged in and on login/splash, redirect to appropriate dashboard
      if (isLoggedIn && (isLoggingIn || isSplash)) {
        final userRole = authState.user?.role ?? 'engineer';
        switch (userRole) {
          case 'admin':
            return AppRoutes.adminDashboard;
          case 'sales':
            return AppRoutes.salesDashboard;
          case 'engineer':
          default:
            return AppRoutes.engineerDashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.engineerDashboard,
        builder: (context, state) => const EngineerDashboard(),
      ),
      GoRoute(
        path: AppRoutes.salesDashboard,
        builder: (context, state) => const SalesDashboard(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});