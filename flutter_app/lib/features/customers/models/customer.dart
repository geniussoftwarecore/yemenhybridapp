class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'notes': notes,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CustomerSearchFilters {
  final String? query;
  final String? city;
  final int? page;
  final int? limit;

  CustomerSearchFilters({
    this.query,
    this.city,
    this.page = 1,
    this.limit = 10,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) params['search'] = query;
    if (city != null && city!.isNotEmpty) params['city'] = city;
    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;
    return params;
  }
}