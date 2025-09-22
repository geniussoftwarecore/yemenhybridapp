import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import 'providers/vehicle_provider.dart';
import 'models/vehicle.dart';
import 'screens/vehicle_form_screen.dart';
import 'screens/vehicle_details_page.dart';

class VehiclesListPage extends ConsumerStatefulWidget {
  const VehiclesListPage({super.key});

  @override
  ConsumerState<VehiclesListPage> createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends ConsumerState<VehiclesListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCustomerId;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehicles),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToVehicleForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.refresh(vehicleListProvider.future);
              },
              child: vehiclesAsync.when(
                data: (vehicles) => _buildVehiclesList(vehicles),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(error.toString()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToVehicleForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by plate number or VIN...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _performSearch();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCustomerFilter(),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFilter() {
    // For now, we'll use a simple customer ID input
    // In a real app, this would be a dropdown of customers
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Customer ID (optional)',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
        hintText: 'Filter by customer ID',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          _selectedCustomerId = value.isNotEmpty ? int.tryParse(value) : null;
        });
        _performSearch();
      },
    );
  }

  Widget _buildVehiclesList(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add a new vehicle',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            vehicle.make.isNotEmpty ? vehicle.make[0].toUpperCase() : 'V',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          vehicle.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🚗 ${vehicle.plate}'),
            if (vehicle.year != null)
              Text('📅 ${vehicle.year}'),
            if (vehicle.color != null)
              Text('🎨 ${vehicle.color}'),
            if (vehicle.vin != null)
              Text('🔢 VIN: ${vehicle.vin}'),
            if (vehicle.hybridType != null)
              Text('🔋 ${vehicle.hybridType}'),
            if (vehicle.odometer != null)
              Text('📊 ${vehicle.odometer} km'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleVehicleAction(value, vehicle),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
        onTap: () => _navigateToVehicleDetails(vehicle),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading vehicles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(vehicleListProvider.future),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final filters = VehicleSearchFilters(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      customerId: _selectedCustomerId,
    );
    ref.read(vehicleSearchFiltersProvider.notifier).state = filters;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCustomerId = null;
      _searchController.clear();
    });
    ref.read(vehicleSearchFiltersProvider.notifier).state = VehicleSearchFilters();
  }

  void _navigateToVehicleForm(BuildContext context, {Vehicle? vehicle}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleFormScreen(vehicle: vehicle),
      ),
    ).then((_) {
      // Invalidate all vehicle providers when returning from form
      ref.read(vehicleNotifierProvider.notifier).invalidateProviders(ref);
    });
  }

  void _navigateToVehicleDetails(Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleDetailsPage(vehicleId: vehicle.id!),
      ),
    );
  }

  void _handleVehicleAction(String action, Vehicle vehicle) {
    switch (action) {
      case 'view':
        _navigateToVehicleDetails(vehicle);
        break;
      case 'edit':
        _navigateToVehicleForm(context, vehicle: vehicle);
        break;
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
                // Invalidate all vehicle providers to ensure UI updates
                ref.read(vehicleNotifierProvider.notifier).invalidateProviders(ref);
                if (mounted) {
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