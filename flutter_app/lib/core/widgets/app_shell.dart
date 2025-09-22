import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String userRole;

  const AppShell({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int selectedIndex = 0;

  List<NavigationItem> get navigationItems {
    final items = [
      NavigationItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard/${widget.userRole}',
      ),
    ];

    // Add customers for all authenticated users (engineer gets read-only access)
    items.add(
      NavigationItem(
        icon: Icons.people,
        label: 'Customers',
        route: '/customers',
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isWideScreen = MediaQuery.of(context).size.width >= 640;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              child: Text(
                user?.name.isNotEmpty == true 
                    ? user!.name[0].toUpperCase() 
                    : '?',
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile feature coming soon')),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings feature coming soon')),
                  );
                  break;
                case 'logout':
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  subtitle: Text(user?.email ?? ''),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: isWideScreen ? _buildWideLayout() : widget.child,
      bottomNavigationBar: isWideScreen ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
            context.go(navigationItems[index].route);
          },
          labelType: NavigationRailLabelType.all,
          destinations: navigationItems
              .map((item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ))
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
        context.go(navigationItems[index].route);
      },
      destinations: navigationItems
          .map((item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }

  String _getTitle() {
    switch (widget.userRole) {
      case 'admin':
        return 'Admin Dashboard';
      case 'sales':
        return 'Sales Dashboard';
      case 'engineer':
        return 'Engineer Dashboard';
      default:
        return 'Dashboard';
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}