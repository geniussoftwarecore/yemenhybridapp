import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/splash/splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/role_gate.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../core/widgets/app_shell.dart';

// Router provider that can access auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;
      
      // Don't redirect while loading
      if (isLoading) return null;
      
      // If accessing dashboard routes without auth, redirect to login
      if (currentPath.startsWith('/dashboard') && !isAuthenticated) {
        return '/login';
      }
      
      // If accessing login while authenticated, redirect to gate
      if (currentPath == '/login' && isAuthenticated) {
        return '/gate';
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/gate',
        name: 'gate',
        builder: (context, state) => const RoleGate(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final role = state.pathParameters['role'] ?? 'engineer';
          return AppShell(
            userRole: role,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard/:role',
            name: 'dashboard',
            builder: (context, state) {
              final role = state.pathParameters['role'] ?? 'engineer';
              return DashboardScreen(role: role);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Legacy class for backward compatibility
class AppRouter {
  // This is now deprecated - use routerProvider instead
  static GoRouter get router => throw UnsupportedError(
    'Use routerProvider instead of AppRouter.router'
  );
}

