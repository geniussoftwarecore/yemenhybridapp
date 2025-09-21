import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/customer_api_service.dart';
import '../models/customer.dart';

// Search filters state
final customerSearchFiltersProvider = StateProvider<CustomerSearchFilters>((ref) {
  return CustomerSearchFilters();
});

// Customer list provider with search filters
final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.read(customerApiServiceProvider);
  final filters = ref.watch(customerSearchFiltersProvider);
  return apiService.getCustomers(filters: filters);
});

// Unfiltered customer list provider for forms and dropdowns
final customerAllProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.read(customerApiServiceProvider);
  return apiService.getCustomers();
});

// Customer notifier for CRUD operations
final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(ref.read(customerApiServiceProvider));
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerApiService _apiService;

  CustomerNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      state = const AsyncValue.loading();
      final customers = await _apiService.getCustomers();
      state = AsyncValue.data(customers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadCustomers();
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final newCustomer = await _apiService.createCustomer(customer);
      // Refresh the list
      await _loadCustomers();
      return newCustomer;
    } catch (error) {
      rethrow;
    }
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    try {
      final updatedCustomer = await _apiService.updateCustomer(id, customer);
      // Refresh the list
      await _loadCustomers();
      return updatedCustomer;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.deleteCustomer(id);
      // Refresh the list
      await _loadCustomers();
    } catch (error) {
      rethrow;
    }
  }

  // Method to invalidate all customer providers
  void invalidateProviders(WidgetRef ref) {
    ref.invalidate(customerListProvider);
    ref.invalidate(customerAllProvider);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    try {
      return await _apiService.searchCustomers(query);
    } catch (error) {
      rethrow;
    }
  }
}

// Individual customer provider
final customerProvider = FutureProvider.family<Customer, int>((ref, id) async {
  final apiService = ref.read(customerApiServiceProvider);
  return apiService.getCustomer(id);
});