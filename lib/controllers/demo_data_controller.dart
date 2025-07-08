import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/demo_data_service.dart';
import '../services/security_service.dart';
import '../services/json_export_service.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

class DemoDataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = false.obs;
  final RxString uploadStatus = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxInt uploadedItems = 0.obs;
  final RxInt totalItems = 0.obs;

  /// Upload all demo data to Firebase
  Future<void> uploadAllDemoData() async {
    try {
      isLoading.value = true;
      uploadStatus.value = 'Preparing demo data...';
      uploadProgress.value = 0.0;
      uploadedItems.value = 0;

      // Get all demo data
      final users = DemoDataService.generateDemoUsers();
      final stores = DemoDataService.generateDemoStores();
      final products = DemoDataService.generateDemoProducts();
      final transactions = DemoDataService.generateDemoTransactions();

      totalItems.value = users.length + stores.length + products.length + transactions.length;

      // Upload in batches to avoid overwhelming Firestore
      await _uploadUsersData(users);
      await _uploadStoresData(stores);
      await _uploadProductsData(products);
      await _uploadTransactionsData(transactions);

      uploadStatus.value = 'Demo data uploaded successfully!';
      uploadProgress.value = 1.0;

      Get.snackbar(
        'Success',
        'Demo data has been uploaded to the backend successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      uploadStatus.value = 'Error: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to upload demo data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload users data
  Future<void> _uploadUsersData(List<UserModel> users) async {
    uploadStatus.value = 'Uploading users...';

    final batch = _firestore.batch();

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final userRef = _firestore.collection('users').doc(user.id);
      batch.set(userRef, user.toMap());

      uploadedItems.value++;
      uploadProgress.value = uploadedItems.value / totalItems.value;

      // Commit batch every 500 operations (Firestore limit)
      if ((i + 1) % 500 == 0) {
        await batch.commit();
      }
    }

    // Commit remaining operations
    await batch.commit();
  }

  /// Upload stores data
  Future<void> _uploadStoresData(List<StoreModel> stores) async {
    uploadStatus.value = 'Uploading stores...';

    final batch = _firestore.batch();

    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      final storeRef = _firestore.collection('stores').doc(store.id);
      batch.set(storeRef, store.toMap());

      uploadedItems.value++;
      uploadProgress.value = uploadedItems.value / totalItems.value;

      if ((i + 1) % 500 == 0) {
        await batch.commit();
      }
    }

    await batch.commit();
  }

  /// Upload products data
  Future<void> _uploadProductsData(List<ProductModel> products) async {
    uploadStatus.value = 'Uploading products...';

    final batch = _firestore.batch();

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final productRef = _firestore.collection('products').doc(product.id);
      batch.set(productRef, product.toMap());

      uploadedItems.value++;
      uploadProgress.value = uploadedItems.value / totalItems.value;

      if ((i + 1) % 500 == 0) {
        await batch.commit();
      }
    }

    await batch.commit();
  }

  /// Upload transactions data
  Future<void> _uploadTransactionsData(List<TransactionModel> transactions) async {
    uploadStatus.value = 'Uploading transactions...';

    final batch = _firestore.batch();

    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final transactionRef = _firestore.collection('transactions').doc(transaction.id);
      batch.set(transactionRef, transaction.toMap());

      uploadedItems.value++;
      uploadProgress.value = uploadedItems.value / totalItems.value;

      if ((i + 1) % 500 == 0) {
        await batch.commit();
      }
    }

    await batch.commit();
  }

  /// Clear all demo data from Firebase
  Future<void> clearAllDemoData() async {
    try {
      isLoading.value = true;
      uploadStatus.value = 'Clearing demo data...';

      // Get demo data to identify what to delete
      final users = DemoDataService.generateDemoUsers();
      final stores = DemoDataService.generateDemoStores();
      final products = DemoDataService.generateDemoProducts();
      final transactions = DemoDataService.generateDemoTransactions();

      totalItems.value = users.length + stores.length + products.length + transactions.length;
      uploadedItems.value = 0;

      await _clearCollection('users', users.map((u) => u.id).toList());
      await _clearCollection('stores', stores.map((s) => s.id).toList());
      await _clearCollection('products', products.map((p) => p.id).toList());
      await _clearCollection('transactions', transactions.map((t) => t.id).toList());

      uploadStatus.value = 'Demo data cleared successfully!';
      uploadProgress.value = 1.0;

      Get.snackbar(
        'Success',
        'Demo data has been cleared from the backend!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      uploadStatus.value = 'Error: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to clear demo data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear specific collection documents
  Future<void> _clearCollection(String collectionName, List<String> documentIds) async {
    uploadStatus.value = 'Clearing $collectionName...';

    final batch = _firestore.batch();

    for (int i = 0; i < documentIds.length; i++) {
      final docRef = _firestore.collection(collectionName).doc(documentIds[i]);
      batch.delete(docRef);

      uploadedItems.value++;
      uploadProgress.value = uploadedItems.value / totalItems.value;

      if ((i + 1) % 500 == 0) {
        await batch.commit();
      }
    }

    await batch.commit();
  }

  /// Generate and export demo data as JSON
  String exportDemoDataAsJson() {
    try {
      final demoData = DemoDataService.getAllDemoData();
      final sanitizedData = JsonExportService.sanitizeForJson(demoData);
      return JsonExportService.exportAsJson(sanitizedData);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export demo data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return '';
    }
  }

  /// Copy demo data JSON to clipboard
  Future<void> copyDemoDataToClipboard() async {
    try {
      final jsonData = exportDemoDataAsJson();
      if (jsonData.isNotEmpty) {
        await JsonExportService.copyToClipboard(jsonData);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to copy demo data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Validate demo data before upload
  bool validateDemoData() {
    try {
      final users = DemoDataService.generateDemoUsers();
      final stores = DemoDataService.generateDemoStores();
      final products = DemoDataService.generateDemoProducts();
      final transactions = DemoDataService.generateDemoTransactions();

      // Basic validation
      for (final user in users) {
        if (!user.isValid) {
          uploadStatus.value = 'Invalid user data found: ${user.email}';
          return false;
        }
      }

      for (final store in stores) {
        if (!store.isValid) {
          uploadStatus.value = 'Invalid store data found: ${store.name}';
          return false;
        }
      }

      for (final product in products) {
        if (!product.isValid) {
          uploadStatus.value = 'Invalid product data found: ${product.name}';
          return false;
        }
      }

      for (final transaction in transactions) {
        if (!transaction.isValid) {
          uploadStatus.value = 'Invalid transaction data found: ${transaction.id}';
          return false;
        }
      }

      uploadStatus.value = 'Demo data validation passed!';
      return true;
    } catch (e) {
      uploadStatus.value = 'Validation error: ${e.toString()}';
      return false;
    }
  }

  /// Get demo data statistics
  Map<String, dynamic> getDemoDataStatistics() {
    final users = DemoDataService.generateDemoUsers();
    final stores = DemoDataService.generateDemoStores();
    final products = DemoDataService.generateDemoProducts();
    final transactions = DemoDataService.generateDemoTransactions();

    final totalRevenue =
        transactions.where((t) => t.status == TransactionStatus.completed).fold(0.0, (sum, t) => sum + t.total);

    final totalProducts = products.fold(0, (sum, p) => sum + p.stockQuantity);

    return {
      'users': {
        'total': users.length,
        'admins': users.where((u) => u.role == UserRole.admin).length,
        'managers': users.where((u) => u.role == UserRole.manager).length,
        'cashiers': users.where((u) => u.role == UserRole.cashier).length,
      },
      'stores': {
        'total': stores.length,
        'active': stores.where((s) => s.isActive).length,
      },
      'products': {
        'total': products.length,
        'simple': products.where((p) => p.type == ProductType.simple).length,
        'variable': products.where((p) => p.type == ProductType.variable).length,
        'service': products.where((p) => p.type == ProductType.service).length,
        'totalStock': totalProducts,
        'lowStock': products.where((p) => p.isLowStock).length,
      },
      'transactions': {
        'total': transactions.length,
        'completed': transactions.where((t) => t.status == TransactionStatus.completed).length,
        'pending': transactions.where((t) => t.status == TransactionStatus.pending).length,
        'refunded': transactions.where((t) => t.status == TransactionStatus.refunded).length,
        'totalRevenue': totalRevenue,
      },
    };
  }

  @override
  void onInit() {
    super.onInit();
    uploadStatus.value = 'Ready to upload demo data';
  }
}
