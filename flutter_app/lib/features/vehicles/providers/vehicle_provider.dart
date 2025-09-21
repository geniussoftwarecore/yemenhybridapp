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
  return apiService.getVehicles(filters: filters);
});

// Unfiltered vehicle list provider for forms and dropdowns
final vehicleAllProvider = FutureProvider<List<Vehicle>>((ref) async {
  final apiService = ref.read(vehicleApiServiceProvider);
  return apiService.getVehicles();
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
      final vehicles = await _apiService.getVehicles();
      state = AsyncValue.data(vehicles);
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
      return await _apiService.searchVehicles(query);
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Vehicle>> getVehiclesByCustomer(int customerId) async {
    try {
      return await _apiService.getVehiclesByCustomer(customerId);
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