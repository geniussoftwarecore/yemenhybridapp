import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/dashboard_card.dart';

class EngineerDashboard extends ConsumerWidget {
  const EngineerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.engineerDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.welcome}, ${authState.user?.name ?? ''}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                DashboardCard(
                  title: l10n.workOrders,
                  icon: Icons.build,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to work orders
                  },
                ),
                DashboardCard(
                  title: l10n.vehicles,
                  icon: Icons.directions_car,
                  color: Colors.green,
                  onTap: () {
                    // Navigate to vehicles
                  },
                ),
                DashboardCard(
                  title: l10n.customers,
                  icon: Icons.people,
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to customers
                  },
                ),
                DashboardCard(
                  title: l10n.media,
                  icon: Icons.photo_library,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to media
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Work Orders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noDataAvailable,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}