class Variant {
  final String? id;
  final String productId;
  final String sku;
  final double price;
  final int stock;
  final int reorderPoint;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Variant({
    this.id,
    required this.productId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.reorderPoint,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sku': sku,
      'price': price,
      'stock': stock,
      'reorderPoint': reorderPoint,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      id: map['id'],
      productId: map['productId'],
      sku: map['sku'],
      price: map['price'].toDouble(),
      stock: map['stock'],
      reorderPoint: map['reorderPoint'],
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Variant copyWith({
    String? id,
    String? productId,
    String? sku,
    double? price,
    int? stock,
    int? reorderPoint,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Variant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
