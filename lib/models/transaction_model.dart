import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, completed, cancelled, refunded }

enum PaymentMethod { cash, card, digitalWallet, other }

class TransactionItem {
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final double discount;
  final double total;

  TransactionItem({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.discount = 0.0,
    required this.total,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> data) {
    return TransactionItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      variantId: data['variantId'],
      variantName: data['variantName'],
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'variantId': variantId,
      'variantName': variantName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'discount': discount,
      'total': total,
    };
  }
}

class PaymentInfo {
  final PaymentMethod method;
  final double amount;
  final String? reference;
  final Map<String, dynamic>? metadata;

  PaymentInfo({
    required this.method,
    required this.amount,
    this.reference,
    this.metadata,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> data) {
    return PaymentInfo(
      method: _parsePaymentMethod(data['method']),
      amount: (data['amount'] ?? 0.0).toDouble(),
      reference: data['reference'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method.name,
      'amount': amount,
      'reference': reference,
      'metadata': metadata,
    };
  }

  static PaymentMethod _parsePaymentMethod(dynamic methodData) {
    if (methodData is String) {
      switch (methodData.toLowerCase()) {
        case 'cash':
          return PaymentMethod.cash;
        case 'card':
          return PaymentMethod.card;
        case 'digitalwallet':
          return PaymentMethod.digitalWallet;
        default:
          return PaymentMethod.other;
      }
    }
    return PaymentMethod.cash;
  }
}

class TransactionModel {
  final String id;
  final String businessId;
  final String storeId;
  final String cashierId;
  final String? customerId;
  final List<TransactionItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final List<PaymentInfo> payments;
  final TransactionStatus status;
  final String? notes;
  final String? receiptNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.cashierId,
    this.customerId,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.payments,
    this.status = TransactionStatus.pending,
    this.notes,
    this.receiptNumber,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Factory constructor from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      storeId: data['storeId'] ?? '',
      cashierId: data['cashierId'] ?? '',
      customerId: data['customerId'],
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0.0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      payments: (data['payments'] as List<dynamic>?)
              ?.map((payment) => PaymentInfo.fromMap(payment as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseTransactionStatus(data['status']),
      notes: data['notes'],
      receiptNumber: data['receiptNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'storeId': storeId,
      'cashierId': cashierId,
      'customerId': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'total': total,
      'payments': payments.map((payment) => payment.toMap()).toList(),
      'status': status.name,
      'notes': notes,
      'receiptNumber': receiptNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Helper method to parse transaction status from string
  static TransactionStatus _parseTransactionStatus(dynamic statusData) {
    if (statusData is String) {
      switch (statusData.toLowerCase()) {
        case 'pending':
          return TransactionStatus.pending;
        case 'completed':
          return TransactionStatus.completed;
        case 'cancelled':
          return TransactionStatus.cancelled;
        case 'refunded':
          return TransactionStatus.refunded;
        default:
          return TransactionStatus.pending;
      }
    }
    return TransactionStatus.pending;
  }

  // Computed properties
  int get totalItems => items.fold(0, (total, item) => total + item.quantity);

  double get totalPaid => payments.fold(0.0, (total, payment) => total + payment.amount);

  double get changeAmount => totalPaid - total;

  bool get isFullyPaid => totalPaid >= total;

  bool get needsChange => totalPaid > total;

  // Validation methods
  bool get isValid {
    return businessId.isNotEmpty && storeId.isNotEmpty && cashierId.isNotEmpty && items.isNotEmpty && total >= 0;
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, total: $total, status: ${status.name}, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
