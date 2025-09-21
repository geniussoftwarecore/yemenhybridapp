import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http.dart';
import '../../../core/models/api_response.dart';
import '../models/vehicle.dart';

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  return VehicleApiService(ref.read(httpClientProvider));
});

class VehicleApiService {
  final HttpClient _httpClient;

  VehicleApiService(this._httpClient);

  Future<VehicleListResponse> getVehicles({
    int page = 1,
    int size = 10,
    String? search,
    int? customerId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (customerId != null) {
      queryParams['customer_id'] = customerId;
    }
    
    final response = await _httpClient.get(
      '/api/v1/vehicles',
      queryParameters: queryParams,
    );

    return VehicleListResponse.fromJson(response.data);
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

  Future<VehicleListResponse> searchByPlate(String plate) async {
    return getVehicles(search: plate);
  }

  Future<VehicleListResponse> searchByVin(String vin) async {
    return getVehicles(search: vin);
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