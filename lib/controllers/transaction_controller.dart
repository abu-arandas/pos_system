import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/security_service.dart';
import '../services/error_handler_service.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  final ProductVariant? variant;
  final RxInt quantity;
  final RxDouble unitPrice;
  final RxDouble discount;

  CartItem({
    required this.product,
    this.variant,
    int quantity = 1,
    double? unitPrice,
    double discount = 0.0,
  })  : quantity = quantity.obs,
        unitPrice = (unitPrice ?? variant?.price ?? product.price).obs,
        discount = discount.obs;

  double get total => (unitPrice.value * quantity.value) - discount.value;
  String get displayName => variant != null ? '${product.name} (${variant!.name})' : product.name;
  String get productId => product.id;
  String? get variantId => variant?.id;
}

class TransactionController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final SecurityService _securityService = Get.find<SecurityService>();
  final ErrorHandlerService _errorHandler = Get.find<ErrorHandlerService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxDouble taxRate = 0.0.obs; // Tax rate as percentage (e.g., 8.5 for 8.5%)
  final RxDouble discountAmount = 0.0.obs;
  final RxString customerInfo = ''.obs;

  // Pagination for transaction history
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  final RxBool hasMoreTransactions = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  // Cart Management
  void addToCart(ProductModel product, {ProductVariant? variant, int quantity = 1}) {
    if (!_securityService.hasPermission(Permission.processTransactions)) {
      _showPermissionDenied();
      return;
    }

    // Check if item already exists in cart
    final existingIndex = cartItems.indexWhere((item) => item.productId == product.id && item.variantId == variant?.id);

    if (existingIndex != -1) {
      // Update quantity of existing item
      cartItems[existingIndex].quantity.value += quantity;
    } else {
      // Add new item to cart
      cartItems.add(CartItem(
        product: product,
        variant: variant,
        quantity: quantity,
        unitPrice: variant?.price ?? product.price,
      ));
    }

    Get.snackbar(
      'Added to Cart',
      '${variant?.name ?? product.name} added to cart',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems.removeAt(index);
    }
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (index >= 0 && index < cartItems.length && quantity > 0) {
      cartItems[index].quantity.value = quantity;
    }
  }

  void updateCartItemDiscount(int index, double discount) {
    if (index >= 0 && index < cartItems.length && discount >= 0) {
      cartItems[index].discount.value = discount;
    }
  }

  void clearCart() {
    cartItems.clear();
    discountAmount.value = 0.0;
    customerInfo.value = '';
  }

  // Cart Calculations
  double get subtotal => cartItems.fold(0.0, (total, item) => total + item.total);
  double get taxAmount => (subtotal * taxRate.value) / 100;
  double get totalAmount => subtotal + taxAmount - discountAmount.value;
  int get totalItems => cartItems.fold(0, (total, item) => total + item.quantity.value);

  // Transaction Processing
  Future<bool> processTransaction({
    required List<PaymentInfo> payments,
    String? notes,
    String? customerId,
  }) async {
    if (!_securityService.hasPermission(Permission.processTransactions)) {
      _showPermissionDenied();
      return false;
    }

    if (cartItems.isEmpty) {
      _errorHandler.handleValidationError(
        'Cart is empty',
        'Process Transaction',
      );
      return false;
    }

    final totalPaid = payments.fold(0.0, (total, payment) => total + payment.amount);
    if (totalPaid < totalAmount) {
      _errorHandler.handleValidationError(
        'Insufficient payment amount',
        'Process Transaction',
        metadata: {'totalPaid': totalPaid, 'totalAmount': totalAmount},
      );
      return false;
    }

    try {
      isLoading.value = true;

      final currentUser = _securityService.currentUser;
      if (currentUser == null) return false;

      // Generate receipt number
      final receiptNumber = _generateReceiptNumber();

      // Create transaction items
      final transactionItems = cartItems
          .map((cartItem) => TransactionItem(
                productId: cartItem.productId,
                productName: cartItem.displayName,
                variantId: cartItem.variantId,
                variantName: cartItem.variant?.name,
                unitPrice: cartItem.unitPrice.value,
                quantity: cartItem.quantity.value,
                discount: cartItem.discount.value,
                total: cartItem.total,
              ))
          .toList();

      // Create transaction
      final transaction = TransactionModel(
        id: '', // Will be set by Firestore
        businessId: currentUser.businessId,
        storeId: currentUser.storeId ?? '',
        cashierId: currentUser.id,
        customerId: customerId,
        items: transactionItems,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount.value,
        total: totalAmount,
        payments: payments,
        status: TransactionStatus.completed,
        notes: notes,
        receiptNumber: receiptNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save transaction to Firestore
      await _firebaseService.addDocument('transactions', transaction.toMap());

      // Update product stock quantities
      await _updateProductStock();

      Get.snackbar(
        'Success',
        'Transaction completed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Clear cart after successful transaction
      clearCart();

      // Refresh transaction list
      await loadTransactions(refresh: true);

      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        operation: 'Process Transaction',
        metadata: {
          'cartItemsCount': cartItems.length,
          'totalAmount': totalAmount,
        },
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update product stock after transaction
  Future<void> _updateProductStock() async {
    final batch = _firebaseService.batch();

    for (final cartItem in cartItems) {
      if (cartItem.product.trackInventory) {
        final newStock = cartItem.product.stockQuantity - cartItem.quantity.value;

        final productRef = _firebaseService.firestore.collection('products').doc(cartItem.productId);

        batch.update(productRef, {
          'stockQuantity': newStock,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    await _firebaseService.commitBatch(batch);
  }

  // Transaction History
  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _lastDocument = null;
      transactions.clear();
      hasMoreTransactions.value = true;
    }

    if (!hasMoreTransactions.value) return;

    try {
      isLoading.value = refresh;

      final currentUser = _securityService.currentUser;
      if (currentUser?.businessId == null) return;

      Query query = _firebaseService.firestore
          .collection('transactions')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // Add store filter if user is assigned to specific store
      if (currentUser.storeId != null) {
        query = query.where('storeId', isEqualTo: currentUser.storeId);
      }

      // Add pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newTransactions = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

        if (refresh) {
          transactions.value = newTransactions;
        } else {
          transactions.addAll(newTransactions);
        }

        _lastDocument = snapshot.docs.last;
        hasMoreTransactions.value = snapshot.docs.length == _pageSize;
      } else {
        hasMoreTransactions.value = false;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        operation: 'Load Transactions',
        metadata: {'refresh': refresh, 'hasMore': hasMoreTransactions.value},
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refund transaction
  Future<bool> refundTransaction(String transactionId) async {
    if (!_securityService.hasPermission(Permission.refundTransactions)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      await _firebaseService.updateDocument(
        'transactions',
        transactionId,
        {
          'status': TransactionStatus.refunded.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      Get.snackbar(
        'Success',
        'Transaction refunded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh transaction list
      await loadTransactions(refresh: true);

      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        operation: 'Refund Transaction',
        metadata: {'transactionId': transactionId},
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  String _generateReceiptNumber() {
    final now = DateTime.now();
    return 'RCP${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  void _showPermissionDenied() {
    _errorHandler.handlePermissionError(
      'Transaction Processing',
      metadata: {'userId': _securityService.currentUserId},
    );
  }

  // Setters
  void setTaxRate(double rate) {
    taxRate.value = rate;
  }

  void setDiscountAmount(double amount) {
    discountAmount.value = amount;
  }

  void setCustomerInfo(String info) {
    customerInfo.value = info;
  }
}
