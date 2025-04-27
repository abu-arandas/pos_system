class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? categoryId;
  final String? imageUrl;
  final String? barcode;
  final double? costPrice;
  final int? reorderPoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.imageUrl,
    this.barcode,
    this.costPrice,
    this.reorderPoint,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'costPrice': costPrice,
      'reorderPoint': reorderPoint,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      stock: map['stock'],
      categoryId: map['categoryId'],
      imageUrl: map['imageUrl'],
      barcode: map['barcode'],
      costPrice: map['costPrice']?.toDouble(),
      reorderPoint: map['reorderPoint'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    String? imageUrl,
    String? barcode,
    double? costPrice,
    int? reorderPoint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
