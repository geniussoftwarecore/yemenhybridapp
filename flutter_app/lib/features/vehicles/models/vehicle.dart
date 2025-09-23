// Temporarily commenting out import to fix circular dependencies
// import '../../customers/models/customer.dart';

class Vehicle {
  final int? id;
  final int customerId;
  final String plate;
  final String? vin;
  final String make;
  final String model;
  final int? year;
  final String? color;
  final int? odometer;
  final String? hybridType;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Temporarily comment out complex type
  // final Customer? customer;

  Vehicle({
    this.id,
    required this.customerId,
    required this.plate,
    this.vin,
    required this.make,
    required this.model,
    this.year,
    this.color,
    this.odometer,
    this.hybridType,
    this.notes,
    this.createdAt,
    this.updatedAt,
    // this.customer,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      customerId: json['customer_id'],
      plate: json['plate_no'] ?? json['plate'] ?? '',
      vin: json['vin'],
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'],
      color: json['color'],
      odometer: json['odometer'],
      hybridType: json['hybrid_type'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      // Temporarily comment out complex fromJson call
      // customer: json['customer'] != null 
      //     ? Customer.fromJson(json['customer'])
      //     : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'plate_no': plate,
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'odometer': odometer,
      'hybrid_type': hybridType,
      'notes': notes,
    };
  }

  Vehicle copyWith({
    int? id,
    int? customerId,
    String? plate,
    String? vin,
    String? make,
    String? model,
    int? year,
    String? color,
    int? odometer,
    String? hybridType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Customer? customer,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      plate: plate ?? this.plate,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      odometer: odometer ?? this.odometer,
      hybridType: hybridType ?? this.hybridType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // customer: customer ?? this.customer,
    );
  }

  String get displayName => '$make $model - $plate';
}

// VehicleListResponse moved to core/models/api_response.dart to avoid duplication

class VehicleSearchFilters {
  final String? query;
  final String? make;
  final String? model;
  final int? customerId;
  final int? page;
  final int? limit;

  VehicleSearchFilters({
    this.query,
    this.make,
    this.model,
    this.customerId,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) params['search'] = query;
    if (make != null && make!.isNotEmpty) params['make'] = make;
    if (model != null && model!.isNotEmpty) params['model'] = model;
    if (customerId != null) params['customer_id'] = customerId;
    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;
    return params;
  }
}