import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http.dart';
import '../models/vehicle.dart';

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  return VehicleApiService(ref.read(httpClientProvider));
});

class VehicleApiService {
  final HttpClient _httpClient;

  VehicleApiService(this._httpClient);

  Future<List<Vehicle>> getVehicles({VehicleSearchFilters? filters}) async {
    final queryParams = filters?.toQueryParameters() ?? {};
    
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }

  Future<Vehicle> getVehicle(int id) async {
    final response = await _httpClient.get('/api/v1/vehicles/$id');
    return Vehicle.fromJson(response.data);
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await _httpClient.post(
      '/api/v1/vehicles',
      data: vehicle.toJson(),
    );
    return Vehicle.fromJson(response.data);
  }

  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    final response = await _httpClient.put(
      '/api/v1/vehicles/$id',
      data: vehicle.toJson(),
    );
    return Vehicle.fromJson(response.data);
  }

  Future<void> deleteVehicle(int id) async {
    await _httpClient.delete('/api/v1/vehicles/$id');
  }

  Future<List<Vehicle>> searchVehicles(String query) async {
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: {'search': query},
    );

    return (response.data as List)
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }

  Future<List<Vehicle>> searchByPlate(String plate) async {
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: {'plate': plate},
    );

    return (response.data as List)
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }

  Future<List<Vehicle>> searchByVin(String vin) async {
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: {'vin': vin},
    );

    return (response.data as List)
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }

  Future<List<Vehicle>> getVehiclesByCustomer(int customerId) async {
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: {'customer_id': customerId},
    );

    return (response.data as List)
        .map((json) => Vehicle.fromJson(json))
        .toList();
  }
}