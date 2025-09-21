import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${role.toUpperCase()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getRoleIcon(role),
              size: 80,
              color: _getRoleColor(role),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, $role!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'sales':
        return Icons.sell;
      case 'engineer':
        return Icons.engineering;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'sales':
        return Colors.green;
      case 'engineer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.people),
          label: const Text('Customers'),
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.car_rental),
          label: const Text('Vehicles'),
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.work),
          label: const Text('Work Orders'),
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.receipt),
          label: const Text('Invoices'),
          onPressed: () {},
        ),
      ],
    );
  }
}