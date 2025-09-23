import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workorder_api_service.dart';
import '../models/workorder.dart';
import '../../../core/models/api_response.dart';

// Work order list provider with search and filters
final workOrderSearchFiltersProvider = StateProvider<WorkOrderSearchFilters>((ref) {
  return WorkOrderSearchFilters();
});

// Work order list provider
final workOrderListProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  final filters = ref.watch(workOrderSearchFiltersProvider);
  
  final response = await apiService.getWorkOrders(
    page: filters.page,
    size: filters.size,
    status: filters.status?.backendValue,
    customerId: filters.customerId,
    vehicleId: filters.vehicleId,
  );
  
  return response.items;
});

// Work order notifier for CRUD operations
final workOrderNotifierProvider = StateNotifierProvider<WorkOrderNotifier, AsyncValue<List<WorkOrder>>>((ref) {
  return WorkOrderNotifier(ref.read(workOrderApiServiceProvider));
});

class WorkOrderNotifier extends StateNotifier<AsyncValue<List<WorkOrder>>> {
  final WorkOrderApiService _apiService;

  WorkOrderNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getWorkOrders();
      state = AsyncValue.data(response.items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadWorkOrders();
  }

  Future<WorkOrder> createWorkOrder(WorkOrder workOrder) async {
    try {
      final newWorkOrder = await _apiService.createWorkOrder(workOrder);
      // Refresh the list
      await _loadWorkOrders();
      return newWorkOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> updateWorkOrder(int id, WorkOrder workOrder) async {
    try {
      final updatedWorkOrder = await _apiService.updateWorkOrder(id, workOrder);
      // Refresh the list
      await _loadWorkOrders();
      return updatedWorkOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteWorkOrder(int id) async {
    try {
      await _apiService.deleteWorkOrder(id);
      // Refresh the list
      await _loadWorkOrders();
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> requestApproval(int id) async {
    try {
      final workOrder = await _apiService.requestApproval(id);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> startWorkOrder(int id) async {
    try {
      final workOrder = await _apiService.startWorkOrder(id);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> finishWorkOrder(int id) async {
    try {
      final workOrder = await _apiService.finishWorkOrder(id);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> closeWorkOrder(int id) async {
    try {
      final workOrder = await _apiService.closeWorkOrder(id);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> updateEstimate(int id, {double? estParts, double? estLabor}) async {
    try {
      final workOrder = await _apiService.setEstimate(id, estParts: estParts, estLabor: estLabor);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  Future<WorkOrder> scheduleWorkOrder(int id, DateTime scheduledAt) async {
    try {
      final workOrder = await _apiService.scheduleWorkOrder(id, scheduledAt);
      // Refresh the list
      await _loadWorkOrders();
      return workOrder;
    } catch (error) {
      rethrow;
    }
  }

  // Method to invalidate all work order providers
  void invalidateProviders(WidgetRef ref) {
    ref.invalidate(workOrderListProvider);
  }

  Future<List<WorkOrder>> searchWorkOrders(String query) async {
    try {
      final response = await _apiService.searchWorkOrders(query);
      return response.items;
    } catch (error) {
      rethrow;
    }
  }
}

// Individual work order provider
final workOrderProvider = FutureProvider.family<WorkOrder, int>((ref, id) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getWorkOrder(id);
});

// Work order media providers
final workOrderMediaProvider = FutureProvider.family<List<MediaUploadResponse>, WorkOrderMediaParams>((ref, params) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getWorkOrderMedia(params.workOrderId, phase: params.phase);
});

final workOrderBeforeGalleryProvider = FutureProvider.family<List<MediaUploadResponse>, int>((ref, workOrderId) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getBeforeGallery(workOrderId);
});

final workOrderDuringGalleryProvider = FutureProvider.family<List<MediaUploadResponse>, int>((ref, workOrderId) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getDuringGallery(workOrderId);
});

final workOrderAfterGalleryProvider = FutureProvider.family<List<MediaUploadResponse>, int>((ref, workOrderId) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getAfterGallery(workOrderId);
});

// Pending approvals provider
final pendingApprovalsProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final apiService = ref.read(workOrderApiServiceProvider);
  return apiService.getPendingApprovals();
});

// Search filters class
class WorkOrderSearchFilters {
  final int page;
  final int size;
  final WorkOrderStatus? status;
  final int? customerId;
  final int? vehicleId;
  final String? searchQuery;

  WorkOrderSearchFilters({
    this.page = 1,
    this.size = 10,
    this.status,
    this.customerId,
    this.vehicleId,
    this.searchQuery,
  });

  WorkOrderSearchFilters copyWith({
    int? page,
    int? size,
    WorkOrderStatus? status,
    int? customerId,
    int? vehicleId,
    String? searchQuery,
  }) {
    return WorkOrderSearchFilters(
      page: page ?? this.page,
      size: size ?? this.size,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Parameters for media provider
class WorkOrderMediaParams {
  final int workOrderId;
  final String? phase;

  WorkOrderMediaParams({
    required this.workOrderId,
    this.phase,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkOrderMediaParams &&
        other.workOrderId == workOrderId &&
        other.phase == phase;
  }

  @override
  int get hashCode => workOrderId.hashCode ^ phase.hashCode;
}