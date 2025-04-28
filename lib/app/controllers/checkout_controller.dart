import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/variant_model.dart';
import 'inventory_controller.dart';
import 'payment_controller.dart';
import 'loyalty_controller.dart';

class CheckoutController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<CartItem> cart = <CartItem>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble discount = 0.0.obs;
  final RxDouble tax = 0.0.obs;
  final RxDouble total = 0.0.obs;
  final RxString selectedCustomerId = ''.obs;
  final RxBool isProcessing = false.obs;
  final RxString selectedPaymentMethod = 'cash'.obs;
  final InventoryController _inventoryController = Get.find<InventoryController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final LoyaltyController _loyaltyController = Get.find<LoyaltyController>();

  @override
  void onInit() {
    super.onInit();
    // Listen to changes in cart and recalculate totals
    ever(cart, (_) => _calculateTotals());
  }

  void _calculateTotals() {
    subtotal.value = cart.fold(0, (sum, item) => sum + item.subtotal);
    // Calculate tax (assuming a fixed rate of 10%)
    tax.value = (subtotal.value - discount.value) * 0.1;
    // Calculate final total
    total.value = subtotal.value - discount.value + tax.value;
  }

  void addItem(Product product, int quantity) {
    final existingItem = cart.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    if (existingItem.quantity > 0) {
      final index = cart.indexOf(existingItem);
      cart[index] = CartItem(
        product: product,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      cart.add(CartItem(product: product, quantity: quantity));
    }
  }

  void addVariantItem(Product product, Variant variant, int quantity) {
    // Create a modified product with the variant's price
    final variantProduct = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      price: variant.price,
      stock: variant.stock,
      barcode: variant.sku,
      imageUrl: variant.imageUrl ?? product.imageUrl,
      categoryId: product.categoryId,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );

    addItem(variantProduct, quantity);
  }

  void removeItem(int index) {
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < cart.length) {
      final item = cart[index];
      cart[index] = CartItem(
        product: item.product,
        quantity: quantity,
      );
    }
  }

  void clearCart() {
    cart.clear();
  }

  void applyDiscount(double amount) {
    discount.value = amount;
    _calculateTotals();
  }

  void applyPercentageDiscount(double percentage) {
    if (percentage < 0 || percentage > 100) return;
    discount.value = subtotal.value * (percentage / 100);
    _calculateTotals();
  }

  void setCustomer(String customerId) {
    selectedCustomerId.value = customerId;
  }

  void setPaymentMethod(String method) {
    if (_paymentController.supportedPaymentMethods.contains(method)) {
      selectedPaymentMethod.value = method;
    } else {
      Get.snackbar('Error', 'Unsupported payment method', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> processPayment(String paymentMethod) async {
    if (cart.isEmpty) {
      Get.snackbar('Error', 'Cart is empty', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isProcessing.value = true;

      // Process payment through payment controller
      final bool paymentSuccess = await _paymentController.processPayment(
        paymentMethod,
        total.value,
        'USD', // Default currency
      );

      if (!paymentSuccess) {
        throw Exception('Payment processing failed');
      }

      // Create sale document
      final sale = Sale(
        items: cart.toList(),
        total: total.value,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        status: 'completed',
      );

      // Add customer ID if selected
      final saleData = sale.toMap();
      if (selectedCustomerId.isNotEmpty) {
        saleData['customerId'] = selectedCustomerId.value;
      }

      // Save to Firestore
      final docRef = await _firestore.collection('sales').add(saleData);
      final String saleId = docRef.id;

      // Record payment transaction
      final String paymentId = await _paymentController.recordPaymentTransaction(
        saleId,
        paymentMethod,
        total.value,
      );

      // Update inventory
      for (final item in cart) {
        await _inventoryController.updateStock(item.product.id!, -item.quantity);
      }

      // Add loyalty points if customer is selected
      if (selectedCustomerId.isNotEmpty) {
        // Add 1 point for each dollar spent (rounded down)
        final int pointsToAdd = total.value.floor();
        if (pointsToAdd > 0) {
          await _loyaltyController.addPoints(
            selectedCustomerId.value,
            pointsToAdd,
            reason: 'Purchase: $saleId',
          );
        }
      }

      // Clear cart after successful payment
      clearCart();
      discount.value = 0;

      // Return to previous screen or show receipt
      Get.toNamed('/receipt', arguments: {'saleId': saleId, 'paymentId': paymentId});
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process payment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> processRefund(String saleId, List<CartItem> items, String reason) async {
    try {
      isProcessing.value = true;

      // Create refund document
      final refundData = {
        'saleId': saleId,
        'items': items
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                  'price': item.product.price,
                })
            .toList(),
        'total': items.fold(0.0, (sum, item) => sum + item.subtotal),
        'reason': reason,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore
      await _firestore.collection('sales').doc(saleId).collection('refunds').add(refundData);

      // Update inventory (add back refunded items)
      for (final item in items) {
        await _inventoryController.updateStock(item.product.id!, item.quantity);
      }

      Get.snackbar(
        'Success',
        'Refund processed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process refund: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }
}
