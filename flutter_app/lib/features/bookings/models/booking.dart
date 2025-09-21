enum BookingChannel {
  whatsapp,
  email,
  direct,
  phone;

  String get displayName {
    switch (this) {
      case BookingChannel.whatsapp:
        return 'WhatsApp';
      case BookingChannel.email:
        return 'Email';
      case BookingChannel.direct:
        return 'Direct';
      case BookingChannel.phone:
        return 'Phone';
    }
  }

  static BookingChannel fromString(String channel) {
    switch (channel.toLowerCase()) {
      case 'whatsapp':
        return BookingChannel.whatsapp;
      case 'email':
        return BookingChannel.email;
      case 'direct':
        return BookingChannel.direct;
      case 'phone':
        return BookingChannel.phone;
      default:
        return BookingChannel.direct;
    }
  }

  String get backendValue => name.toLowerCase();
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }
}

class Booking {
  final int? id;
  final int customerId;
  final int? vehicleId;
  final int? workOrderId;
  final DateTime scheduledAt;
  final String? description;
  final BookingChannel channel;
  final BookingStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Customer? customer;
  final Vehicle? vehicle;
  final WorkOrder? workOrder;

  Booking({
    this.id,
    required this.customerId,
    this.vehicleId,
    this.workOrderId,
    required this.scheduledAt,
    this.description,
    this.channel = BookingChannel.direct,
    this.status = BookingStatus.pending,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.vehicle,
    this.workOrder,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerId: json['customer_id'],
      vehicleId: json['vehicle_id'],
      workOrderId: json['work_order_id'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      description: json['description'],
      channel: BookingChannel.fromString(json['channel'] ?? 'direct'),
      status: BookingStatus.fromString(json['status'] ?? 'pending'),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'])
          : null,
      vehicle: json['vehicle'] != null 
          ? Vehicle.fromJson(json['vehicle'])
          : null,
      workOrder: json['work_order'] != null 
          ? WorkOrder.fromJson(json['work_order'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'work_order_id': workOrderId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'description': description,
      'channel': channel.backendValue,
      'status': status.backendValue,
      'notes': notes,
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
           scheduledAt.month == now.month &&
           scheduledAt.day == now.day;
  }

  bool get isUpcoming {
    return scheduledAt.isAfter(DateTime.now());
  }
}

// Import related models
import '../customers/models/customer.dart';
import '../vehicles/models/vehicle.dart';
import '../workorders/models/workorder.dart';