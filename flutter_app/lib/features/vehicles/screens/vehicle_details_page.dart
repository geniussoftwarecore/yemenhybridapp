import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../screens/vehicle_form_screen.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';

class VehicleDetailsPage extends ConsumerStatefulWidget {
  final int vehicleId;

  const VehicleDetailsPage({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends ConsumerState<VehicleDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));

    return Scaffold(
      body: vehicleAsync.when(
        data: (vehicle) => _buildVehicleDetails(vehicle),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Vehicle Details')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading vehicle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(vehicleProvider(widget.vehicleId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(Vehicle vehicle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(vehicle),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value, vehicle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'workorders',
                child: ListTile(
                  leading: Icon(Icons.build),
                  title: Text('Work Orders'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(vehicleProvider(widget.vehicleId).future);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleInfoCard(vehicle),
              const SizedBox(height: 16),
              _buildOwnerCard(vehicle),
              const SizedBox(height: 16),
              _buildTechnicalDetailsCard(vehicle),
              if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNotesCard(vehicle),
              ],
              const SizedBox(height: 16),
              _buildQuickActionsCard(vehicle),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(vehicle),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildVehicleInfoCard(Vehicle vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 30,
                  child: Text(
                    vehicle.make.isNotEmpty ? vehicle.make[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.plate,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Make',
                    vehicle.make,
                    Icons.directions_car,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Model',
                    vehicle.model,
                    Icons.model_training,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Year',
                    vehicle.year?.toString() ?? 'Not specified',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Color',
                    vehicle.color ?? 'Not specified',
                    Icons.palette,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(Vehicle vehicle) {
    final customerAsync = ref.watch(customerDetailProvider(vehicle.customerId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Vehicle Owner',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            customerAsync.when(
              data: (customer) => Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.phone != null)
                          Text('📞 ${customer.phone}'),
                        if (customer.email != null)
                          Text('📧 ${customer.email}'),
                        if (customer.address != null)
                          Text('📍 ${customer.address}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navigateToCustomer(customer),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading customer: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsCard(Vehicle vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Technical Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vehicle.vin != null)
              _buildDetailRow('VIN Number', vehicle.vin!, Icons.qr_code),
            if (vehicle.odometer != null)
              _buildDetailRow('Odometer', '${vehicle.odometer} km', Icons.speed),
            if (vehicle.hybridType != null)
              _buildDetailRow('Hybrid Type', vehicle.hybridType!, Icons.eco),
            if (vehicle.createdAt != null)
              _buildDetailRow('Registered', _formatDate(vehicle.createdAt!), Icons.calendar_month),
            if (vehicle.updatedAt != null)
              _buildDetailRow('Last Updated', _formatDate(vehicle.updatedAt!), Icons.update),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(Vehicle vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vehicle.notes!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(Vehicle vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction('workorders', vehicle),
                    icon: const Icon(Icons.build),
                    label: const Text('Work Orders'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEdit(vehicle),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Vehicle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToEdit(Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleFormScreen(vehicle: vehicle),
      ),
    ).then((_) {
      // Refresh vehicle details when returning from edit
      ref.refresh(vehicleProvider(widget.vehicleId));
    });
  }

  void _navigateToCustomer(Customer customer) {
    // TODO: Navigate to customer details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to ${customer.name} details')),
    );
  }

  void _handleAction(String action, Vehicle vehicle) {
    switch (action) {
      case 'workorders':
        // TODO: Navigate to work orders screen filtered by vehicle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work Orders view coming soon')),
        );
        break;
      case 'delete':
        _confirmDelete(vehicle);
        break;
    }
  }

  void _confirmDelete(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(vehicleNotifierProvider.notifier).deleteVehicle(vehicle.id!);
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to vehicle list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${vehicle.displayName} deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting vehicle: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}