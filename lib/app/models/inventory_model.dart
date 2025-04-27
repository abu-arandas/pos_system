import 'product_model.dart';

class InventoryItem {
  final String? id;
  final Product product;
  final String locationId;
  final int stock;
  final DateTime lastUpdated;

  InventoryItem({
    this.id,
    required this.product,
    required this.locationId,
    required this.stock,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'locationId': locationId,
      'stock': stock,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      product: Product.fromMap(map['product'] as Map<String, dynamic>),
      locationId: map['locationId'],
      stock: map['stock'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  InventoryItem copyWith({String? id, Product? product, String? locationId, int? stock, DateTime? lastUpdated}) {
    return InventoryItem(
      id: id ?? this.id,
      product: product ?? this.product,
      locationId: locationId ?? this.locationId,
      stock: stock ?? this.stock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
