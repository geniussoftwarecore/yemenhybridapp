import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/gate',
        name: 'gate',
        builder: (context, state) => const GateScreen(),
      ),
      GoRoute(
        path: '/dashboard/:role',
        name: 'dashboard',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'admin';
          return DashboardScreen(role: role);
        },
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
}

// Placeholder gate screen
class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome Gate'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard/admin'),
              child: const Text('Admin Dashboard'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/dashboard/sales'),
              child: const Text('Sales Dashboard'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/dashboard/engineer'),
              child: const Text('Engineer Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}