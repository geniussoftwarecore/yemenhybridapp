import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading while checking auth status
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, redirect to login
    if (!authState.isAuthenticated || authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Redirect based on user role
    final userRole = authState.user!.role.toLowerCase();
    final dashboardPath = '/dashboard/$userRole';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(dashboardPath);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}