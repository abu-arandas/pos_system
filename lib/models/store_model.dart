import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String businessId;
  final String managerId;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  StoreModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.businessId,
    required this.managerId,
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
    this.phone = '',
    this.email = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  // Factory constructor from Firestore document
  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      businessId: data['businessId'] ?? '',
      managerId: data['managerId'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      country: data['country'] ?? '',
      postalCode: data['postalCode'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  // Factory constructor from Map
  factory StoreModel.fromMap(Map<String, dynamic> data, String id) {
    return StoreModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      businessId: data['businessId'] ?? '',
      managerId: data['managerId'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      country: data['country'] ?? '',
      postalCode: data['postalCode'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'businessId': businessId,
      'managerId': managerId,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'settings': settings,
    };
  }

  // Create a copy with updated fields
  StoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? businessId,
    String? managerId,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessId: businessId ?? this.businessId,
      managerId: managerId ?? this.managerId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }

  // Computed properties
  String get fullAddress {
    final parts = [address, city, state, postalCode, country]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty &&
           businessId.isNotEmpty &&
           managerId.isNotEmpty;
  }

  @override
  String toString() {
    return 'StoreModel(id: $id, name: $name, businessId: $businessId, managerId: $managerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
