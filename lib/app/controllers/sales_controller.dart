import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import 'inventory_controller.dart';

class SalesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Sale> sales = <Sale>[].obs;
  final RxList<CartItem> cart = <CartItem>[].obs;
  final RxDouble total = 0.0.obs;
  final RxBool isLoading = false.obs;
  final InventoryController _inventoryController = Get.find<InventoryController>();

  @override
  void onInit() {
    super.onInit();
    fetchSales();
  }

  Future<void> fetchSales() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore.collection('sales').orderBy('createdAt', descending: true).get();
      sales.value = snapshot.docs.map((doc) => Sale.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch sales: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void addToCart(Product product, int quantity) {
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

    calculateTotal();
  }

  void removeFromCart(Product product) {
    cart.removeWhere((item) => item.product.id == product.id);
    calculateTotal();
  }

  void updateQuantity(Product product, int quantity) {
    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      cart[index] = CartItem(product: product, quantity: quantity);
      calculateTotal();
    }
  }

  void calculateTotal() {
    total.value = cart.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  Future<void> processSale(String paymentMethod) async {
    try {
      isLoading.value = true;
      final batch = _firestore.batch();
      final saleRef = _firestore.collection('sales').doc();

      final sale = Sale(
        id: saleRef.id,
        items: cart,
        total: total.value,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      batch.set(saleRef, sale.toMap());

      // Update inventory
      for (final item in cart) {
        await _inventoryController.updateStock(
          item.product.id!,
          -item.quantity,
        );
      }

      await batch.commit();
      cart.clear();
      total.value = 0.0;
      await fetchSales();
      Get.snackbar(
        'Success',
        'Sale processed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process sale: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> processRefund(String saleId, List<CartItem> items) async {
    try {
      isLoading.value = true;
      final batch = _firestore.batch();
      final refundRef = _firestore.collection('refunds').doc();

      final refund = Refund(
        id: refundRef.id,
        saleId: saleId,
        items: items,
        total: items.fold(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        ),
        createdAt: DateTime.now(),
      );

      batch.set(refundRef, refund.toMap());

      // Update inventory
      for (final item in items) {
        await _inventoryController.updateStock(
          item.product.id!,
          item.quantity,
        );
      }

      await batch.commit();
      await fetchSales();
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
      isLoading.value = false;
    }
  }
}
