import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/security_service.dart';
import '../services/error_handler_service.dart';
import '../models/store_model.dart';
import '../models/user_model.dart';

class StoreController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final SecurityService _securityService = Get.find<SecurityService>();
  final ErrorHandlerService _errorHandler = Get.find<ErrorHandlerService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxList<StoreModel> stores = <StoreModel>[].obs;
  final RxList<StoreModel> filteredStores = <StoreModel>[].obs;
  final Rx<StoreModel?> selectedStore = Rx<StoreModel?>(null);
  final RxString searchQuery = ''.obs;
  final RxList<UserModel> storeManagers = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStores();
    loadStoreManagers();

    // Listen to search query changes
    debounce(searchQuery, (_) => _filterStores(), time: const Duration(milliseconds: 500));
  }

  // Load all stores for the current business
  Future<void> loadStores({bool refresh = false}) async {
    try {
      isLoading.value = true;

      final currentUser = _securityService.currentUser;
      if (currentUser?.businessId == null) return;

      Query query = _firebaseService.firestore
          .collection('stores')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .orderBy('name');

      final snapshot = await query.get();

      final storeList = snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();

      stores.value = storeList;
      _filterStores();

      // Set selected store if user has a specific store assigned
      if (currentUser.storeId != null && selectedStore.value == null) {
        selectedStore.value = stores.firstWhereOrNull(
          (store) => store.id == currentUser.storeId,
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        operation: 'Load Stores',
        metadata: {'currentUserId': _securityService.currentUserId},
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load store managers for assignment
  Future<void> loadStoreManagers() async {
    try {
      final currentUser = _securityService.currentUser;
      if (currentUser?.businessId == null) return;

      final query = _firebaseService.firestore
          .collection('users')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .where('role', whereIn: ['admin', 'manager']).where('isActive', isEqualTo: true);

      final snapshot = await query.get();

      storeManagers.value = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      _errorHandler.handleError(
        e,
        operation: 'Load Store Managers',
        metadata: {'businessId': _securityService.currentUser?.businessId},
      );
    }
  }

  // Add new store
  Future<bool> addStore(StoreModel store) async {
    if (!_securityService.hasPermission(Permission.manageStores)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      final storeData = store.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.addDocument('stores', storeData.toMap());

      Get.snackbar(
        'Success',
        'Store added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh stores list
      await loadStores(refresh: true);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update store
  Future<bool> updateStore(StoreModel store) async {
    if (!_securityService.hasPermission(Permission.manageStores)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      final updatedStore = store.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateDocument(
        'stores',
        store.id,
        updatedStore.toMap(),
      );

      Get.snackbar(
        'Success',
        'Store updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Update local list
      final index = stores.indexWhere((s) => s.id == store.id);
      if (index != -1) {
        stores[index] = updatedStore;
        _filterStores();
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete store (soft delete)
  Future<bool> deleteStore(String storeId) async {
    if (!_securityService.hasPermission(Permission.manageStores)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      // Check if store has active users or transactions
      final hasActiveUsers = await _checkStoreHasActiveUsers(storeId);
      if (hasActiveUsers) {
        Get.snackbar(
          'Cannot Delete',
          'Store has active users assigned. Please reassign users before deleting.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      await _firebaseService.updateDocument(
        'stores',
        storeId,
        {
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      Get.snackbar(
        'Success',
        'Store deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Remove from local list
      stores.removeWhere((s) => s.id == storeId);
      _filterStores();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete store: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if store has active users
  Future<bool> _checkStoreHasActiveUsers(String storeId) async {
    try {
      final query = _firebaseService.firestore
          .collection('users')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .limit(1);

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Assign manager to store
  Future<bool> assignManagerToStore(String storeId, String managerId) async {
    if (!_securityService.hasPermission(Permission.manageStores)) {
      _showPermissionDenied();
      return false;
    }

    try {
      isLoading.value = true;

      // Update store with new manager
      await _firebaseService.updateDocument(
        'stores',
        storeId,
        {
          'managerId': managerId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      // Update user's store assignment
      await _firebaseService.updateDocument(
        'users',
        managerId,
        {
          'storeId': storeId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      Get.snackbar(
        'Success',
        'Manager assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh data
      await loadStores(refresh: true);
      await loadStoreManagers();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to assign manager: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStatistics(String storeId) async {
    try {
      final currentUser = _securityService.currentUser;
      if (currentUser?.businessId == null) return {};

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // Get today's transactions for this store
      final todayQuery = _firebaseService.firestore
          .collection('transactions')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart));

      final todaySnapshot = await todayQuery.get();
      final todaySales = todaySnapshot.docs.fold(0.0, (total, doc) {
        final data = doc.data();
        return total + (data['total'] ?? 0.0);
      });

      // Get month's transactions for this store
      final monthQuery = _firebaseService.firestore
          .collection('transactions')
          .where('businessId', isEqualTo: currentUser.businessId)
          .where('storeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart));

      final monthSnapshot = await monthQuery.get();
      final monthSales = monthSnapshot.docs.fold(0.0, (total, doc) {
        final data = doc.data();
        return total + (data['total'] ?? 0.0);
      });

      // Get product count for this store
      final productsQuery = _firebaseService.firestore
          .collection('products')
          .where('businessId', isEqualTo: currentUser.businessId)
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true);

      final productsSnapshot = await productsQuery.get();

      return {
        'todaySales': todaySales,
        'todayTransactions': todaySnapshot.docs.length,
        'monthSales': monthSales,
        'monthTransactions': monthSnapshot.docs.length,
        'totalProducts': productsSnapshot.docs.length,
      };
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get store statistics: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {};
    }
  }

  // Search and filter methods
  void searchStores(String query) {
    searchQuery.value = query;
  }

  void _filterStores() {
    var filtered = stores.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((store) {
        return store.name.toLowerCase().contains(query) ||
            store.address.toLowerCase().contains(query) ||
            store.city.toLowerCase().contains(query);
      }).toList();
    }

    filteredStores.value = filtered;
  }

  // Store selection
  void selectStore(StoreModel store) {
    selectedStore.value = store;
  }

  void _showPermissionDenied() {
    Get.snackbar(
      'Access Denied',
      'You do not have permission to perform this action.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Getters
  int get totalStores => stores.length;
  int get activeStores => stores.where((store) => store.isActive).length;
  bool get hasMultipleStores => stores.length > 1;

  // Get manager name for a store
  String getManagerName(String managerId) {
    final manager = storeManagers.firstWhereOrNull((user) => user.id == managerId);
    return manager?.fullName ?? 'Unassigned';
  }
}
