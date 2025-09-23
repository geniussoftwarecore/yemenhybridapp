import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/http.dart';
import '../../../core/models/api_response.dart';
import '../models/workorder.dart';

final workOrderApiServiceProvider = Provider<WorkOrderApiService>((ref) {
  return WorkOrderApiService(ref.read(httpClientProvider));
});

class WorkOrderApiService {
  final HttpClient _httpClient;

  WorkOrderApiService(this._httpClient);

  Future<WorkOrderListResponse> getWorkOrders({
    int page = 1,
    int size = 10,
    String? status,
    int? customerId,
    int? vehicleId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null) queryParams['status'] = status;
    if (customerId != null) queryParams['customer_id'] = customerId;
    if (vehicleId != null) queryParams['vehicle_id'] = vehicleId;
    
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: queryParams,
    );

    return WorkOrderListResponse.fromJson(response.data);
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

  Future<WorkOrder> setEstimate(int id, {
    double? estParts,
    double? estLabor,
  }) async {
    final response = await _httpClient.patch(
      '/api/v1/workorders/$id/estimate',
      data: {
        if (estParts != null) 'est_parts': estParts,
        if (estLabor != null) 'est_labor': estLabor,
      },
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> startWorkOrder(int id) async {
    final response = await _httpClient.patch('/api/v1/workorders/$id/start');
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> finishWorkOrder(int id) async {
    final response = await _httpClient.patch('/api/v1/workorders/$id/finish');
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> closeWorkOrder(int id) async {
    final response = await _httpClient.patch('/api/v1/workorders/$id/close');
    return WorkOrder.fromJson(response.data);
  }

  Future<WorkOrder> requestApproval(int id) async {
    final response = await _httpClient.post('/api/v1/workorders/$id/request-approval');
    return WorkOrder.fromJson(response.data);
  }

  Future<ApprovalRequestResponse> sendToCustomer(int id, {
    String channel = 'email',
  }) async {
    final response = await _httpClient.post(
      '/api/v1/workorders/$id/send-to-customer',
      data: {
        'sent_via': channel,
      },
    );
    
    return ApprovalRequestResponse.fromJson(response.data);
  }

  Future<String> getPublicApprovalLink(int id) async {
    // Note: This endpoint may not exist - get from send-to-customer response instead
    final response = await _httpClient.get('/api/v1/workorders/$id/approval-link');
    return response.data['link'] ?? '';
  }

  // Media upload functionality
  Future<MediaUploadResponse> uploadMedia(
    int workOrderId,
    String filePath,
    String phase, {
    String? note,
  }) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'phase': phase, // before, during, after
      'note': note ?? '',
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _httpClient.post(
      '/api/v1/workorders/$workOrderId/media',
      data: formData,
    );

    return MediaUploadResponse.fromJson(response.data);
  }

  Future<List<MediaUploadResponse>> getWorkOrderMedia(int workOrderId, {String? phase}) async {
    final queryParams = <String, dynamic>{};
    if (phase != null) queryParams['phase'] = phase;
    
    final response = await _httpClient.get(
      '/api/v1/workorders/$workOrderId/media',
      queryParameters: queryParams,
    );
    
    return (response.data as List)
        .map((json) => MediaUploadResponse.fromJson(json))
        .toList();
  }

  Future<List<MediaUploadResponse>> getBeforeGallery(int workOrderId) async {
    return getWorkOrderMedia(workOrderId, phase: 'before');
  }

  Future<List<MediaUploadResponse>> getDuringGallery(int workOrderId) async {
    return getWorkOrderMedia(workOrderId, phase: 'during');
  }

  Future<List<MediaUploadResponse>> getAfterGallery(int workOrderId) async {
    return getWorkOrderMedia(workOrderId, phase: 'after');
  }

  Future<void> deleteMedia(int mediaId) async {
    await _httpClient.delete('/api/v1/media/$mediaId');
  }

  // Work Order Items (Services/Parts) management
  Future<WorkOrderItem> addWorkOrderItem(int workOrderId, WorkOrderItem item) async {
    final response = await _httpClient.post(
      '/api/v1/workorders/$workOrderId/items',
      data: item.toJson(),
    );
    return WorkOrderItem.fromJson(response.data);
  }

  Future<void> deleteWorkOrderItem(int itemId) async {
    await _httpClient.delete('/api/v1/workorders/items/$itemId');
  }

  Future<WorkOrder> scheduleWorkOrder(int id, DateTime scheduledAt) async {
    final response = await _httpClient.patch(
      '/api/v1/workorders/$id/schedule',
      data: {'scheduled_at': scheduledAt.toIso8601String()},
    );
    return WorkOrder.fromJson(response.data);
  }

  Future<String> getPublicApprovalUrl(String token) async {
    // Generate the public approval URL
    final response = await _httpClient.get('/api/v1/public/approval/$token');
    return response.data['url'] ?? '';
  }

  // Search and filtering
  Future<List<WorkOrder>> searchWorkOrders(String query) async {
    final response = await _httpClient.get(
      '/api/v1/workorders',
      queryParameters: {'q': query}, // Use 'q' to match backend standard
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