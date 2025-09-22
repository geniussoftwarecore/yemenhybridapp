import 'package:flutter/material.dart';
import 'screens/admin_dashboard.dart';
import 'screens/engineer_dashboard.dart';
import 'screens/sales_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminDashboard();
      case 'sales':
        return const SalesDashboard();
      case 'engineer':
        return const EngineerDashboard();
      default:
        return const EngineerDashboard(); // Default fallback
    }
  }
}