import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http.dart';
import '../models/customer.dart';

final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  return CustomerApiService(ref.read(httpClientProvider));
});

class CustomerApiService {
  final HttpClient _httpClient;

  CustomerApiService(this._httpClient);

  Future<List<Customer>> getCustomers({CustomerSearchFilters? filters}) async {
    final queryParams = filters?.toQueryParameters() ?? {};
    
    final response = await _httpClient.get(
      '/api/v1/customers',
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<Customer> getCustomer(int id) async {
    final response = await _httpClient.get('/api/v1/customers/$id');
    return Customer.fromJson(response.data);
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _httpClient.post(
      '/api/v1/customers',
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data);
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response = await _httpClient.put(
      '/api/v1/customers/$id',
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data);
  }

  Future<void> deleteCustomer(int id) async {
    await _httpClient.delete('/api/v1/customers/$id');
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _httpClient.get(
      '/api/v1/customers',
      queryParameters: {'search': query},
    );

    return (response.data as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<List<Customer>> getCustomersByCity(String city) async {
    final response = await _httpClient.get(
      '/api/v1/customers',
      queryParameters: {'city': city},
    );

    return (response.data as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }
}