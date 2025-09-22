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
  final response = await apiService.getCustomers(
    page: filters.page ?? 1,
    size: filters.limit ?? 10,
    search: filters.query,
  );
  return response.items;
});

// Unfiltered customer list provider for forms and dropdowns
final customerAllProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.read(customerApiServiceProvider);
  final response = await apiService.getCustomers(page: 1, size: 100);
  return response.items;
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
      final response = await _apiService.getCustomers(page: 1, size: 50);
      state = AsyncValue.data(response.items);
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

  Future<Customer> updateCustomer(Customer customer) async {
    final id = customer.id;
    if (id == null) throw Exception('Customer ID is required for update');
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
      final response = await _apiService.searchCustomers(query);
      return response.items;
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

// Alias for backwards compatibility
final customerByIdProvider = customerProvider;