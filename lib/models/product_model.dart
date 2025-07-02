import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType { simple, variable, service }

class ProductVariant {
  final String id;
  final String name;
  final double price;
  final String? sku;
  final int stockQuantity;
  final Map<String, dynamic>? attributes;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.sku,
    this.stockQuantity = 0,
    this.attributes,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> data) {
    return ProductVariant(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      sku: data['sku'],
      stockQuantity: data['stockQuantity'] ?? 0,
      attributes: data['attributes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'sku': sku,
      'stockQuantity': stockQuantity,
      'attributes': attributes,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String businessId;
  final String storeId;
  final String categoryId;
  final ProductType type;
  final double price;
  final double? costPrice;
  final String? sku;
  final String? barcode;
  final List<String> imageUrls;
  final int stockQuantity;
  final int? lowStockThreshold;
  final bool trackInventory;
  final bool isActive;
  final List<ProductVariant> variants;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.businessId,
    required this.storeId,
    this.categoryId = '',
    this.type = ProductType.simple,
    required this.price,
    this.costPrice,
    this.sku,
    this.barcode,
    this.imageUrls = const [],
    this.stockQuantity = 0,
    this.lowStockThreshold,
    this.trackInventory = true,
    this.isActive = true,
    this.variants = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      businessId: data['businessId'] ?? '',
      storeId: data['storeId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      type: _parseProductType(data['type']),
      price: (data['price'] ?? 0.0).toDouble(),
      costPrice: data['costPrice']?.toDouble(),
      sku: data['sku'],
      barcode: data['barcode'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      lowStockThreshold: data['lowStockThreshold'],
      trackInventory: data['trackInventory'] ?? true,
      isActive: data['isActive'] ?? true,
      variants: (data['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor from Map
  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      businessId: data['businessId'] ?? '',
      storeId: data['storeId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      type: _parseProductType(data['type']),
      price: (data['price'] ?? 0.0).toDouble(),
      costPrice: data['costPrice']?.toDouble(),
      sku: data['sku'],
      barcode: data['barcode'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      lowStockThreshold: data['lowStockThreshold'],
      trackInventory: data['trackInventory'] ?? true,
      isActive: data['isActive'] ?? true,
      variants: (data['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'businessId': businessId,
      'storeId': storeId,
      'categoryId': categoryId,
      'type': type.name,
      'price': price,
      'costPrice': costPrice,
      'sku': sku,
      'barcode': barcode,
      'imageUrls': imageUrls,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'trackInventory': trackInventory,
      'isActive': isActive,
      'variants': variants.map((v) => v.toMap()).toList(),
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper method to parse product type from string
  static ProductType _parseProductType(dynamic typeData) {
    if (typeData is String) {
      switch (typeData.toLowerCase()) {
        case 'simple':
          return ProductType.simple;
        case 'variable':
          return ProductType.variable;
        case 'service':
          return ProductType.service;
        default:
          return ProductType.simple;
      }
    }
    return ProductType.simple;
  }

  // Computed properties
  bool get isLowStock {
    if (!trackInventory || lowStockThreshold == null) return false;
    return stockQuantity <= lowStockThreshold!;
  }

  bool get isOutOfStock {
    if (!trackInventory) return false;
    return stockQuantity <= 0;
  }

  double get profitMargin {
    if (costPrice == null || costPrice == 0) return 0;
    return ((price - costPrice!) / costPrice!) * 100;
  }

  String get primaryImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : '';
  }

  // Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? businessId,
    String? storeId,
    String? categoryId,
    ProductType? type,
    double? price,
    double? costPrice,
    String? sku,
    String? barcode,
    List<String>? imageUrls,
    int? stockQuantity,
    int? lowStockThreshold,
    bool? trackInventory,
    bool? isActive,
    List<ProductVariant>? variants,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessId: businessId ?? this.businessId,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrls: imageUrls ?? this.imageUrls,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      trackInventory: trackInventory ?? this.trackInventory,
      isActive: isActive ?? this.isActive,
      variants: variants ?? this.variants,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty && businessId.isNotEmpty && storeId.isNotEmpty && price >= 0;
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, stockQuantity: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
