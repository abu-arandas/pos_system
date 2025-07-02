import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/security_service.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final SecurityService _securityService = Get.find<SecurityService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxList<String> categories = <String>['All'].obs;

  // Pagination
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  final RxBool hasMoreProducts = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    
    // Listen to search query changes
    debounce(searchQuery, (_) => _filterProducts(), time: const Duration(milliseconds: 500));
    
    // Listen to category changes
    ever(selectedCategory, (_) => _filterProducts());
  }

  // Load products with pagination
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _lastDocument = null;
      products.clear();
      hasMoreProducts.value = true;
    }

    if (!hasMoreProducts.value) return;

    try {
      isLoading.value = refresh;
      isLoadingMore.value = !refresh;

      final currentUser = _securityService.currentUser;
      if (currentUser?.businessId == null) return;

      Query query = _firebaseService.firestore
          .collection('products')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
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
        final newProducts = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
        
        if (refresh) {
          products.value = newProducts;
        } else {
          products.addAll(newProducts);
        }
        
        _lastDocument = snapshot.docs.last;
        hasMoreProducts.value = snapshot.docs.length == _pageSize;
      } else {
        hasMoreProducts.value = false;
      }

      // Update categories
      _updateCategories();
      
      // Apply current filters
      _filterProducts();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load products: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Add new product
  Future<bool> addProduct(ProductModel product) async {
    if (!_securityService.hasPermission(Permission.manageProducts)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      final productData = product.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.addDocument('products', productData.toMap());
      
      Get.snackbar(
        'Success',
        'Product added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh products list
      await loadProducts(refresh: true);
      return true;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    if (!_securityService.hasPermission(Permission.manageProducts)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateDocument(
        'products',
        product.id,
        updatedProduct.toMap(),
      );

      Get.snackbar(
        'Success',
        'Product updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Update local list
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = updatedProduct;
        _filterProducts();
      }

      return true;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete product (soft delete)
  Future<bool> deleteProduct(String productId) async {
    if (!_securityService.hasPermission(Permission.manageProducts)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      await _firebaseService.updateDocument(
        'products',
        productId,
        {
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Remove from local list
      products.removeWhere((p) => p.id == productId);
      _filterProducts();

      return true;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String productId, int newQuantity) async {
    if (!_securityService.hasPermission(Permission.manageInventory)) {
      _showPermissionDenied();
      return false;
    }

    try {
      await _firebaseService.updateDocument(
        'products',
        productId,
        {
          'stockQuantity': newQuantity,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      // Update local list
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(
          stockQuantity: newQuantity,
          updatedAt: DateTime.now(),
        );
        _filterProducts();
      }

      return true;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update stock: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Search and filter methods
  void searchProducts(String query) {
    searchQuery.value = query;
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  void _filterProducts() {
    var filtered = products.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query) ||
               (product.sku?.toLowerCase().contains(query) ?? false) ||
               (product.barcode?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply category filter
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((product) {
        return product.categoryId == selectedCategory.value;
      }).toList();
    }

    filteredProducts.value = filtered;
  }

  void _updateCategories() {
    final productCategories = products
        .where((product) => product.categoryId.isNotEmpty)
        .map((product) => product.categoryId)
        .toSet()
        .toList();
    
    categories.value = ['All', ...productCategories];
  }

  void _showPermissionDenied() {
    Get.snackbar(
      'Access Denied',
      'You do not have permission to perform this action.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Getters
  List<ProductModel> get lowStockProducts {
    return products.where((product) => product.isLowStock).toList();
  }

  List<ProductModel> get outOfStockProducts {
    return products.where((product) => product.isOutOfStock).toList();
  }

  int get totalProducts => products.length;
  int get lowStockCount => lowStockProducts.length;
  int get outOfStockCount => outOfStockProducts.length;
}
