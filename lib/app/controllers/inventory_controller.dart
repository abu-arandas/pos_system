import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<InventoryItem> inventory = <InventoryItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentLocationId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot =
          await _firestore.collection('inventory').where('locationId', isEqualTo: currentLocationId.value).get();
      inventory.value = snapshot.docs.map((doc) => InventoryItem.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch inventory: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStock(String productId, int quantity) async {
    try {
      isLoading.value = true;
      await _firestore.collection('inventory').doc(productId).update({
        'stock': FieldValue.increment(quantity),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchInventory();
      Get.snackbar('Success', 'Stock updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> transferStock(String productId, String fromLocationId, String toLocationId, int quantity) async {
    try {
      isLoading.value = true;
      final batch = _firestore.batch();

      // Decrease stock at source location
      batch.update(_firestore.collection('inventory').doc('${productId}_$fromLocationId'), {
        'stock': FieldValue.increment(-quantity),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Increase stock at destination location
      batch.update(_firestore.collection('inventory').doc('${productId}_$toLocationId'), {
        'stock': FieldValue.increment(quantity),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await batch.commit();
      await fetchInventory();
      Get.snackbar('Success', 'Stock transferred successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to transfer stock: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> scanBarcode(String barcode) async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore.collection('products').where('barcode', isEqualTo: barcode).get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar('Error', 'Product not found', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final product = Product.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      Get.toNamed('/product-details', arguments: product);
    } catch (e) {
      Get.snackbar('Error', 'Failed to scan barcode: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  List<InventoryItem> getLowStockItems() {
    return inventory.where((item) => item.stock <= (item.product.reorderPoint ?? 0) && item.stock > 0).toList();
  }

  List<InventoryItem> getOutOfStockItems() {
    return inventory.where((item) => item.stock <= 0).toList();
  }
}
