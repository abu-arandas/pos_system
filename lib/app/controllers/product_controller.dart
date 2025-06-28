import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Product> _allProducts = <Product>[].obs;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    
    // Listen to search query changes
    debounce(searchQuery, (_) => _filterProducts(), time: const Duration(milliseconds: 300));
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      
      _allProducts.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap({'id': doc.id, ...data});
      }).toList();
      
      _filterProducts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _filterProducts() {
    List<Product> filtered = _allProducts.toList();
    
    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (product.barcode?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Filter by category
    if (selectedCategoryId.value.isNotEmpty) {
      filtered = filtered.where((product) => product.categoryId == selectedCategoryId.value).toList();
    }
    
    products.value = filtered;
  }

  void searchProducts(String query) {
    searchQuery.value = query;
  }

  void filterByCategory(String? categoryId) {
    selectedCategoryId.value = categoryId ?? '';
    _filterProducts();
  }

  Future<void> addProduct(Product product) async {
    try {
      isLoading.value = true;
      final docRef = await _firestore.collection('products').add(product.toMap());
      
      // Add to local list
      final newProduct = product.copyWith(id: docRef.id);
      _allProducts.insert(0, newProduct);
      _filterProducts();
      
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
      
      // Update local list
      final index = _allProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _allProducts[index] = product.copyWith(id: id);
        _filterProducts();
      }
      
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
      
      // Remove from local list
      _allProducts.removeWhere((p) => p.id == id);
      _filterProducts();
      
      Get.snackbar('Success', 'Product deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> searchProductsByQuery(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to search products: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return [];
    }
  }

  List<Product> getLowStockProducts() {
    return _allProducts.where((product) {
      final reorderPoint = product.reorderPoint ?? 10;
      return product.stock <= reorderPoint && product.stock > 0;
    }).toList();
  }

  List<Product> getOutOfStockProducts() {
    return _allProducts.where((product) => product.stock <= 0).toList();
  }

  double getTotalInventoryValue() {
    return _allProducts.fold(0.0, (sum, product) {
      final costPrice = product.costPrice ?? product.price;
      return sum + (costPrice * product.stock);
    });
  }
}