// Common API response models for paginated data
import '../../features/customers/models/customer.dart';
import '../../features/vehicles/models/vehicle.dart';
import '../../features/workorders/models/workorder.dart';
import '../../features/invoices/models/invoice.dart';
import '../../features/bookings/models/booking.dart';

class CustomerListResponse {
  final List<Customer> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  CustomerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      items: (json['items'] as List)
          .map((item) => Customer.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }
}

class VehicleListResponse {
  final List<Vehicle> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  VehicleListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory VehicleListResponse.fromJson(Map<String, dynamic> json) {
    return VehicleListResponse(
      items: (json['items'] as List)
          .map((item) => Vehicle.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }
}

class WorkOrderListResponse {
  final List<WorkOrder> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  WorkOrderListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory WorkOrderListResponse.fromJson(Map<String, dynamic> json) {
    return WorkOrderListResponse(
      items: (json['items'] as List)
          .map((item) => WorkOrder.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }
}

class InvoiceListResponse {
  final List<Invoice> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  InvoiceListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceListResponse(
      items: (json['items'] as List)
          .map((item) => Invoice.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }
}

class BookingListResponse {
  final List<Booking> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  BookingListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    return BookingListResponse(
      items: (json['items'] as List)
          .map((item) => Booking.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }
}

class MediaUploadResponse {
  final int id;
  final String filename;
  final String path;
  final String phase;
  final String? note;
  final String url;

  MediaUploadResponse({
    required this.id,
    required this.filename,
    required this.path,
    required this.phase,
    this.note,
    required this.url,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      id: json['id'],
      filename: json['filename'],
      path: json['path'],
      phase: json['phase'],
      note: json['note'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'path': path,
      'phase': phase,
      'note': note,
      'url': url,
    };
  }
}

class WorkOrderItemResponse {
  final int id;
  final int workOrderId;
  final String itemType;
  final String name;
  final double price;
  final int quantity;
  final String? description;

  WorkOrderItemResponse({
    required this.id,
    required this.workOrderId,
    required this.itemType,
    required this.name,
    required this.price,
    required this.quantity,
    this.description,
  });

  factory WorkOrderItemResponse.fromJson(Map<String, dynamic> json) {
    return WorkOrderItemResponse(
      id: json['id'],
      workOrderId: json['work_order_id'],
      itemType: json['item_type'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_id': workOrderId,
      'item_type': itemType,
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
    };
  }
}

class ApprovalRequestResponse {
  final int id;
  final int workOrderId;
  final String token;
  final DateTime expiresAt;
  final String sentVia;
  final DateTime? respondedAt;
  final bool? approved;

  ApprovalRequestResponse({
    required this.id,
    required this.workOrderId,
    required this.token,
    required this.expiresAt,
    required this.sentVia,
    this.respondedAt,
    this.approved,
  });

  factory ApprovalRequestResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestResponse(
      id: json['id'],
      workOrderId: json['work_order_id'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expires_at']),
      sentVia: json['sent_via'],
      respondedAt: json['responded_at'] != null 
          ? DateTime.parse(json['responded_at']) 
          : null,
      approved: json['approved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_id': workOrderId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'sent_via': sentVia,
      'responded_at': respondedAt?.toIso8601String(),
      'approved': approved,
    };
  }
}