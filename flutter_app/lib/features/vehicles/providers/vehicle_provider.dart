import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vehicle_api_service.dart';
import '../models/vehicle.dart';

// Search filters state
final vehicleSearchFiltersProvider = StateProvider<VehicleSearchFilters>((ref) {
  return VehicleSearchFilters();
});

// Vehicle list provider with search filters
final vehicleListProvider = FutureProvider<List<Vehicle>>((ref) async {
  final apiService = ref.read(vehicleApiServiceProvider);
  final filters = ref.watch(vehicleSearchFiltersProvider);
  final response = await apiService.getVehicles(
    page: filters.page ?? 1,
    size: filters.limit ?? 10,
    search: filters.query,
    customerId: filters.customerId,
  );
  return response.items;
});

// Unfiltered vehicle list provider for forms and dropdowns
final vehicleAllProvider = FutureProvider<List<Vehicle>>((ref) async {
  final apiService = ref.read(vehicleApiServiceProvider);
  final response = await apiService.getVehicles(size: 1000); // Large size for dropdown
  return response.items;
});

// Vehicle notifier for CRUD operations
final vehicleNotifierProvider = StateNotifierProvider<VehicleNotifier, AsyncValue<List<Vehicle>>>((ref) {
  return VehicleNotifier(ref.read(vehicleApiServiceProvider));
});

class VehicleNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  final VehicleApiService _apiService;

  VehicleNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getVehicles(size: 1000);
      state = AsyncValue.data(response.items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadVehicles();
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      final newVehicle = await _apiService.createVehicle(vehicle);
      // Refresh the list
      await _loadVehicles();
      return newVehicle;
    } catch (error) {
      rethrow;
    }
  }

  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    try {
      final updatedVehicle = await _apiService.updateVehicle(id, vehicle);
      // Refresh the list
      await _loadVehicles();
      return updatedVehicle;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _apiService.deleteVehicle(id);
      // Refresh the list
      await _loadVehicles();
    } catch (error) {
      rethrow;
    }
  }

  // Method to invalidate all vehicle providers
  void invalidateProviders(WidgetRef ref) {
    ref.invalidate(vehicleListProvider);
    ref.invalidate(vehicleAllProvider);
  }

  Future<List<Vehicle>> searchVehicles(String query) async {
    try {
      final response = await _apiService.searchVehicles(query);
      return response.items;
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Vehicle>> getVehiclesByCustomer(int customerId) async {
    try {
      final response = await _apiService.getVehiclesByCustomer(customerId);
      return response.items;
    } catch (error) {
      rethrow;
    }
  }
}

// Individual vehicle provider
final vehicleProvider = FutureProvider.family<Vehicle, int>((ref, id) async {
  final apiService = ref.read(vehicleApiServiceProvider);
  return apiService.getVehicle(id);
});

// Available makes provider for form dropdowns
final vehicleMakesProvider = Provider<List<String>>((ref) {
  return [
    'Toyota',
    'Honda',
    'Nissan',
    'Hyundai',
    'Kia',
    'Mitsubishi',
    'Suzuki',
    'Mazda',
    'Isuzu',
    'Ford',
    'Chevrolet',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Peugeot',
    'Renault',
    'Fiat',
    'Skoda',
    'Daewoo',
    'Geely',
    'Changan',
    'BYD',
    'Great Wall',
    'JAC',
    'Chery',
    'Other',
  ];
});