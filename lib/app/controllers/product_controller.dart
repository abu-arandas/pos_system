import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore.collection('products').get();
      products.value = snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      isLoading.value = true;
      await _firestore.collection('products').add(product.toMap());
      await fetchProducts();
      Get.snackbar('Success', 'Product added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      isLoading.value = true;
      await _firestore.collection('products').doc(id).update(product.toMap());
      await fetchProducts();
      Get.snackbar('Success', 'Product updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      isLoading.value = true;
      await _firestore.collection('products').doc(id).delete();
      await fetchProducts();
      Get.snackbar('Success', 'Product deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('products')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to search products: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return [];
    }
  }
}
