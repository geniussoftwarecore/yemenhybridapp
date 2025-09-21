import '../workorders/models/workorder.dart';
import '../customers/models/customer.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static InvoiceStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }

  String get backendValue => name.toLowerCase();
}

class Invoice {
  final int? id;
  final int workOrderId;
  final int customerId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double total;
  final InvoiceStatus status;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final String? notes;
  final String? pdfUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final WorkOrder? workOrder;
  final Customer? customer;
  final List<InvoiceItem>? items;

  Invoice({
    this.id,
    required this.workOrderId,
    required this.customerId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.status = InvoiceStatus.draft,
    this.issuedAt,
    this.dueAt,
    this.paidAt,
    this.notes,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
    this.workOrder,
    this.customer,
    this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      workOrderId: json['work_order_id'],
      customerId: json['customer_id'],
      invoiceNumber: json['invoice_number'] ?? '',
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
      status: InvoiceStatus.fromString(json['status'] ?? 'draft'),
      issuedAt: json['issued_at'] != null 
          ? DateTime.parse(json['issued_at'])
          : null,
      dueAt: json['due_at'] != null 
          ? DateTime.parse(json['due_at'])
          : null,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'])
          : null,
      notes: json['notes'],
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      workOrder: json['work_order'] != null 
          ? WorkOrder.fromJson(json['work_order'])
          : null,
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'])
          : null,
      items: json['items'] != null 
          ? (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'work_order_id': workOrderId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      'status': status.backendValue,
      'issued_at': issuedAt?.toIso8601String(),
      'due_at': dueAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final String description;
  final double price;
  final int quantity;
  final double total;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.description,
    required this.price,
    this.quantity = 1,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      invoiceId: json['invoice_id'],
      description: json['description'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      total: json['total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

