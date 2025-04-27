import 'product_model.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;
}

class Sale {
  final String? id;
  final List<CartItem> items;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;

  Sale({
    this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => {
            'productId': item.product.id,
            'quantity': item.quantity,
            'price': item.product.price,
          }).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      items: (map['items'] as List)
          .map((item) => CartItem(
                product: Product(
                  id: item['productId'],
                  name: '',
                  description: '',
                  price: item['price'],
                  stock: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                quantity: item['quantity'],
              ))
          .toList(),
      total: map['total'].toDouble(),
      paymentMethod: map['paymentMethod'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class Refund {
  final String? id;
  final String saleId;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;

  Refund({
    this.id,
    required this.saleId,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'items': items.map((item) => {
            'productId': item.product.id,
            'quantity': item.quantity,
            'price': item.product.price,
          }).toList(),
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      id: map['id'],
      saleId: map['saleId'],
      items: (map['items'] as List)
          .map((item) => CartItem(
                product: Product(
                  id: item['productId'],
                  name: '',
                  description: '',
                  price: item['price'],
                  stock: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                quantity: item['quantity'],
              ))
          .toList(),
      total: map['total'].toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 