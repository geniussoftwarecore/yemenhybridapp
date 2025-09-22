
// Temporarily commenting out imports to fix circular dependencies
// import '../../customers/models/customer.dart';
// import '../../vehicles/models/vehicle.dart';
// import '../../auth/models/user.dart';

enum WorkOrderStatus {
  pending,
  inProgress,
  waitingParts,
  waitingApproval,
  waitingCustomer,
  completed,
  cancelled,
  invoiced;

  String get displayName {
    switch (this) {
      case WorkOrderStatus.pending:
        return 'Pending';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.waitingParts:
        return 'Waiting Parts';
      case WorkOrderStatus.waitingApproval:
        return 'Waiting Approval';
      case WorkOrderStatus.waitingCustomer:
        return 'Waiting Customer';
      case WorkOrderStatus.completed:
        return 'Completed';
      case WorkOrderStatus.cancelled:
        return 'Cancelled';
      case WorkOrderStatus.invoiced:
        return 'Invoiced';
    }
  }

  static WorkOrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return WorkOrderStatus.pending;
      case 'in_progress':
        return WorkOrderStatus.inProgress;
      case 'waiting_parts':
        return WorkOrderStatus.waitingParts;
      case 'waiting_approval':
        return WorkOrderStatus.waitingApproval;
      case 'waiting_customer':
        return WorkOrderStatus.waitingCustomer;
      case 'completed':
        return WorkOrderStatus.completed;
      case 'cancelled':
        return WorkOrderStatus.cancelled;
      case 'invoiced':
        return WorkOrderStatus.invoiced;
      default:
        return WorkOrderStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case WorkOrderStatus.pending:
        return 'pending';
      case WorkOrderStatus.inProgress:
        return 'in_progress';
      case WorkOrderStatus.waitingParts:
        return 'waiting_parts';
      case WorkOrderStatus.waitingApproval:
        return 'waiting_approval';
      case WorkOrderStatus.waitingCustomer:
        return 'waiting_customer';
      case WorkOrderStatus.completed:
        return 'completed';
      case WorkOrderStatus.cancelled:
        return 'cancelled';
      case WorkOrderStatus.invoiced:
        return 'invoiced';
    }
  }
}

class WorkOrder {
  final int? id;
  final int customerId;
  final int vehicleId;
  final int? assignedTo;
  final String complaint;
  final String? diagnosis;
  final WorkOrderStatus status;
  final double? estimate;
  final double? finalAmount;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Temporarily comment out complex types
  // final Customer? customer;
  // final Vehicle? vehicle;
  // final User? assignedUser;
  final List<WorkOrderService>? services;
  final List<WorkOrderMedia>? media;

  WorkOrder({
    this.id,
    required this.customerId,
    required this.vehicleId,
    this.assignedTo,
    required this.complaint,
    this.diagnosis,
    this.status = WorkOrderStatus.pending,
    this.estimate,
    this.finalAmount,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    // this.customer,
    // this.vehicle,
    // this.assignedUser,
    this.services,
    this.media,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      customerId: json['customer_id'],
      vehicleId: json['vehicle_id'],
      assignedTo: json['assigned_to'],
      complaint: json['complaint'] ?? '',
      diagnosis: json['diagnosis'],
      status: WorkOrderStatus.fromString(json['status'] ?? 'pending'),
      estimate: json['estimate']?.toDouble(),
      finalAmount: json['final_amount']?.toDouble(),
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at'])
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      // Temporarily comment out complex fromJson calls
      // customer: json['customer'] != null 
      //     ? Customer.fromJson(json['customer'])
      //     : null,
      // vehicle: json['vehicle'] != null 
      //     ? Vehicle.fromJson(json['vehicle'])
      //     : null,
      // assignedUser: json['assigned_user'] != null 
      //     ? User.fromJson(json['assigned_user'])
      //     : null,
      services: json['services'] != null 
          ? (json['services'] as List).map((s) => WorkOrderService.fromJson(s)).toList()
          : null,
      media: json['media'] != null 
          ? (json['media'] as List).map((m) => WorkOrderMedia.fromJson(m)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'assigned_to': assignedTo,
      'complaint': complaint,
      'diagnosis': diagnosis,
      'status': status.backendValue,
      'estimate': estimate,
      'final_amount': finalAmount,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

class WorkOrderService {
  final int? id;
  final int workOrderId;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final double total;

  WorkOrderService({
    this.id,
    required this.workOrderId,
    required this.name,
    this.description,
    required this.price,
    this.quantity = 1,
    required this.total,
  });

  factory WorkOrderService.fromJson(Map<String, dynamic> json) {
    return WorkOrderService(
      id: json['id'],
      workOrderId: json['work_order_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      total: json['total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'work_order_id': workOrderId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

enum MediaType {
  before,
  during,
  after;

  String get displayName {
    switch (this) {
      case MediaType.before:
        return 'BEFORE';
      case MediaType.during:
        return 'DURING';
      case MediaType.after:
        return 'AFTER';
    }
  }

  static MediaType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'before':
        return MediaType.before;
      case 'during':
        return MediaType.during;
      case 'after':
        return MediaType.after;
      default:
        return MediaType.before;
    }
  }

  String get backendValue => name.toLowerCase();
}

class WorkOrderMedia {
  final int? id;
  final int workOrderId;
  final String filename;
  final String? description;
  final MediaType type;
  final String url;
  final DateTime? createdAt;

  WorkOrderMedia({
    this.id,
    required this.workOrderId,
    required this.filename,
    this.description,
    required this.type,
    required this.url,
    this.createdAt,
  });

  factory WorkOrderMedia.fromJson(Map<String, dynamic> json) {
    return WorkOrderMedia(
      id: json['id'],
      workOrderId: json['work_order_id'],
      filename: json['filename'] ?? '',
      description: json['description'],
      type: MediaType.fromString(json['type'] ?? 'before'),
      url: json['url'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'work_order_id': workOrderId,
      'filename': filename,
      'description': description,
      'type': type.backendValue,
      'url': url,
    };
  }
}

