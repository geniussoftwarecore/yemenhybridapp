import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/http.dart';
import '../models/workorder.dart';

final workOrderApiServiceProvider = Provider<WorkOrderApiService>((ref) {
  return WorkOrderApiService(ref.read(httpClientProvider));
});

class WorkOrderApiService {
  final HttpClient _httpClient;

  WorkOrderApiService(this._httpClient);

  Future<List<WorkOrder>> getWorkOrders({
    int? page,
    int? limit,
    String? status,
    int? customerId,
    int? assignedTo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (status != null) queryParams['status'] = status;
    if (customerId != null) queryParams['customer_id'] = customerId;
    if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
    
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((json) => WorkOrder.fromJson(json))
        .toList();
  }

  Future<WorkOrder> getWorkOrder(int id) async {
    final response = await _httpClient.get('/api/v1/workorders/$id');
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> createWorkOrder(WorkOrder workOrder) async {
    final response = await _httpClient.post(
      '/api/v1/workorders',
      data: workOrder.toJson(),
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> updateWorkOrder(int id, WorkOrder workOrder) async {
    final response = await _httpClient.put(
      '/api/v1/workorders/$id',
      data: workOrder.toJson(),
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<void> deleteWorkOrder(int id) async {
    await _httpClient.delete('/api/v1/workorders/$id');
  }

  Future<WorkOrder> updateStatus(int id, WorkOrderStatus status) async {
    final response = await _httpClient.put(
      '/api/v1/workorders/$id/status',
      data: {'status': status.backendValue},
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> startWorkOrder(int id) async {
    final response = await _httpClient.post('/api/v1/workorders/$id/start');
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> completeWorkOrder(int id) async {
    final response = await _httpClient.post('/api/v1/workorders/$id/complete');
    return WorkOrder.fromJson(response.data);
  }

  Future<void> requestApproval(int id, {String? notes}) async {
    await _httpClient.post(
      '/api/v1/workorders/$id/request-approval',
      data: {'notes': notes},
    );
  }

  Future<String> sendToCustomer(int id, {
    String? channel = 'email',
    String? message,
  }) async {
    final response = await _httpClient.post(
      '/api/v1/workorders/$id/send-to-customer',
      data: {
        'channel': channel,
        'message': message,
      },
    );
    
    // Return the approval link for development console logging
    return response.data['approval_link'] ?? '';
  }

  Future<String> getPublicApprovalLink(int id) async {
    final response = await _httpClient.get('/api/v1/workorders/$id/approval-link');
    return response.data['link'] ?? '';
  }

  // Media upload functionality
  Future<WorkOrderMedia> uploadMedia(
    int workOrderId,
    String filePath,
    MediaType type, {
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'work_order_id': workOrderId,
      'type': type.backendValue,
      'description': description ?? '',
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _httpClient.post(
      '/api/v1/workorders/$workOrderId/media',
      data: formData,
    );

    return WorkOrderMedia.fromJson(response.data);
  }

  Future<List<WorkOrderMedia>> getWorkOrderMedia(int workOrderId) async {
    final response = await _httpClient.get('/api/v1/workorders/$workOrderId/media');
    
    return (response.data as List)
        .map((json) => WorkOrderMedia.fromJson(json))
        .toList();
  }

  Future<List<WorkOrderMedia>> getMediaByType(int workOrderId, MediaType type) async {
    final response = await _httpClient.get(
      '/api/v1/workorders/$workOrderId/media',
      queryParameters: {'type': type.backendValue},
    );
    
    return (response.data as List)
        .map((json) => WorkOrderMedia.fromJson(json))
        .toList();
  }

  Future<void> deleteMedia(int workOrderId, int mediaId) async {
    await _httpClient.delete('/api/v1/workorders/$workOrderId/media/$mediaId');
  }

  // Services management
  Future<WorkOrder> addService(int workOrderId, WorkOrderService service) async {
    final response = await _httpClient.post(
      '/api/v1/workorders/$workOrderId/services',
      data: service.toJson(),
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> updateService(
    int workOrderId,
    int serviceId,
    WorkOrderService service,
  ) async {
    final response = await _httpClient.put(
      '/api/v1/workorders/$workOrderId/services/$serviceId',
      data: service.toJson(),
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> removeService(int workOrderId, int serviceId) async {
    final response = await _httpClient.delete(
      '/api/v1/workorders/$workOrderId/services/$serviceId',
    );
    return WorkOrder.fromJson(response.data);
  }

  // Search and filtering
  Future<List<WorkOrder>> searchWorkOrders(String query) async {
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: {'search': query},
    );

    return (response.data as List)
        .map((json) => WorkOrder.fromJson(json))
        .toList();
  }

  Future<List<WorkOrder>> getMyWorkOrders(int userId) async {
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: {'assigned_to': userId},
    );

    return (response.data as List)
        .map((json) => WorkOrder.fromJson(json))
        .toList();
  }

  Future<List<WorkOrder>> getPendingApprovals() async {
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: {'status': 'waiting_approval'},
    );

    return (response.data as List)
        .map((json) => WorkOrder.fromJson(json))
        .toList();
  }
}