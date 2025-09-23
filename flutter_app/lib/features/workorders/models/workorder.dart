
// Temporarily commenting out imports to fix circular dependencies
// import '../../customers/models/customer.dart';
// import '../../vehicles/models/vehicle.dart';
// import '../../auth/models/user.dart';

enum WorkOrderStatus {
  newOrder,
  awaitingApproval,
  readyToStart,
  inProgress,
  done,
  closed;

  String get displayName {
    switch (this) {
      case WorkOrderStatus.newOrder:
        return 'New';
      case WorkOrderStatus.awaitingApproval:
        return 'Awaiting Approval';
      case WorkOrderStatus.readyToStart:
        return 'Ready to Start';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.done:
        return 'Done';
      case WorkOrderStatus.closed:
        return 'Closed';
    }
  }

  static WorkOrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return WorkOrderStatus.newOrder;
      case 'awaiting_approval':
        return WorkOrderStatus.awaitingApproval;
      case 'ready_to_start':
        return WorkOrderStatus.readyToStart;
      case 'in_progress':
        return WorkOrderStatus.inProgress;
      case 'done':
        return WorkOrderStatus.done;
      case 'closed':
        return WorkOrderStatus.closed;
      default:
        return WorkOrderStatus.newOrder;
    }
  }

  String get backendValue {
    switch (this) {
      case WorkOrderStatus.newOrder:
        return 'new';
      case WorkOrderStatus.awaitingApproval:
        return 'awaiting_approval';
      case WorkOrderStatus.readyToStart:
        return 'ready_to_start';
      case WorkOrderStatus.inProgress:
        return 'in_progress';
      case WorkOrderStatus.done:
        return 'done';
      case WorkOrderStatus.closed:
        return 'closed';
    }
  }
}

class WorkOrder {
  final int? id;
  final int customerId;
  final int vehicleId;
  final int? createdBy;
  final String? complaint;
  final WorkOrderStatus status;
  final double? estParts;
  final double? estLabor;
  final double? estTotal;
  final double? finalCost;
  final String? warrantyText;
  final String? notes;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final List<WorkOrderItem>? items;

  WorkOrder({
    this.id,
    required this.customerId,
    required this.vehicleId,
    this.createdBy,
    this.complaint,
    this.status = WorkOrderStatus.newOrder,
    this.estParts,
    this.estLabor,
    this.estTotal,
    this.finalCost,
    this.warrantyText,
    this.notes,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.items,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      customerId: json['customer_id'],
      vehicleId: json['vehicle_id'],
      createdBy: json['created_by'],
      complaint: json['complaint'],
      status: WorkOrderStatus.fromString(json['status'] ?? 'new'),
      estParts: json['est_parts']?.toDouble(),
      estLabor: json['est_labor']?.toDouble(),
      estTotal: json['est_total']?.toDouble(),
      finalCost: json['final_cost']?.toDouble(),
      warrantyText: json['warranty_text'],
      notes: json['notes'],
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at'])
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => WorkOrderItem.fromJson(item)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'complaint': complaint,
    };
    
    // Only include non-null optional fields
    if (id != null) json['id'] = id;
    if (createdBy != null) json['created_by'] = createdBy;
    if (notes != null) json['notes'] = notes;
    if (scheduledAt != null) json['scheduled_at'] = scheduledAt!.toIso8601String();
    if (estParts != null) json['est_parts'] = estParts;
    if (estLabor != null) json['est_labor'] = estLabor;
    
    return json;
  }
}

enum ItemType {
  part,
  labor;

  String get displayName {
    switch (this) {
      case ItemType.part:
        return 'Part';
      case ItemType.labor:
        return 'Labor';
    }
  }

  String get backendValue => name.toLowerCase();

  static ItemType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'part':
        return ItemType.part;
      case 'labor':
        return ItemType.labor;
      default:
        return ItemType.part;
    }
  }
}

class WorkOrderItem {
  final int? id;
  final int? workOrderId;
  final ItemType itemType;
  final String name;
  final double qty;
  final double unitPrice;

  WorkOrderItem({
    this.id,
    this.workOrderId,
    required this.itemType,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  double get total => qty * unitPrice;

  factory WorkOrderItem.fromJson(Map<String, dynamic> json) {
    return WorkOrderItem(
      id: json['id'],
      workOrderId: json['work_order_id'],
      itemType: ItemType.fromString(json['item_type'] ?? 'part'),
      name: json['name'] ?? '',
      qty: json['qty']?.toDouble() ?? 1.0,
      unitPrice: json['unit_price']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemType.backendValue,
      'name': name,
      'qty': qty,
      'unit_price': unitPrice,
    };
  }
}

// Search filters for work orders
class WorkOrderSearchFilters {
  final String? query;
  final WorkOrderStatus? status;
  final int? customerId;
  final int? vehicleId;
  final int? technicianId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? page;
  final int? limit;

  WorkOrderSearchFilters({
    this.query,
    this.status,
    this.customerId,
    this.vehicleId,
    this.technicianId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) params['search'] = query;
    if (status != null) params['status'] = status!.backendValue;
    if (customerId != null) params['customer_id'] = customerId;
    if (vehicleId != null) params['vehicle_id'] = vehicleId;
    if (technicianId != null) params['technician_id'] = technicianId;
    if (dateFrom != null) params['date_from'] = dateFrom!.toIso8601String();
    if (dateTo != null) params['date_to'] = dateTo!.toIso8601String();
    if (page != null) params['page'] = page;
    if (limit != null) params['size'] = limit;
    return params;
  }
}

