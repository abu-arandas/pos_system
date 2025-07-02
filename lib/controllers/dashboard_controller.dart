import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/security_service.dart';
import '../models/store_model.dart';
import '../models/transaction_model.dart';
import '../routes/app_routes.dart';

class DashboardStats {
  final double todaySales;
  final int todayTransactions;
  final int totalProducts;
  final int lowStockProducts;
  final double monthSales;
  final int monthTransactions;

  DashboardStats({
    this.todaySales = 0.0,
    this.todayTransactions = 0,
    this.totalProducts = 0,
    this.lowStockProducts = 0,
    this.monthSales = 0.0,
    this.monthTransactions = 0,
  });
}

class DashboardController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final SecurityService _securityService = Get.find<SecurityService>();

  // Observable states
  final RxBool isLoading = true.obs;
  final Rx<DashboardStats> stats = DashboardStats().obs;
  final RxList<StoreModel> stores = <StoreModel>[].obs;
  final Rx<StoreModel?> selectedStore = Rx<StoreModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      isLoading.value = true;

      // Load stores
      await _loadStores();

      // Load dashboard statistics
      await _loadDashboardStats();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStores() async {
    final currentUser = _securityService.currentUser;
    if (currentUser?.businessId != null) {
      final query = _firebaseService.firestore
          .collection('stores')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .where('isActive', isEqualTo: true);

      final storesSnapshot = await query.get();
      stores.value = storesSnapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();

      // Set default store if user has a specific store assigned
      if (currentUser.storeId != null) {
        selectedStore.value = stores.firstWhereOrNull(
          (store) => store.id == currentUser.storeId,
        );
      } else if (stores.isNotEmpty) {
        selectedStore.value = stores.first;
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    final currentUser = _securityService.currentUser;
    if (currentUser?.businessId == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    try {
      // Get today's transactions
      final todayQuery = _firebaseService.firestore
          .collection('transactions')
          .where('businessId', isEqualTo: currentUser!.businessId)
          .where('status', isEqualTo: TransactionStatus.completed.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart));

      if (selectedStore.value != null) {
        todayQuery.where('storeId', isEqualTo: selectedStore.value!.id);
      }

      final todaySnapshot = await todayQuery.get();
      final todayTransactions = todaySnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

      // Get month's transactions
      final monthQuery = _firebaseService.firestore
          .collection('transactions')
          .where('businessId', isEqualTo: currentUser.businessId)
          .where('status', isEqualTo: TransactionStatus.completed.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart));

      if (selectedStore.value != null) {
        monthQuery.where('storeId', isEqualTo: selectedStore.value!.id);
      }

      final monthSnapshot = await monthQuery.get();
      final monthTransactions = monthSnapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

      // Get products count
      final productsQuery = _firebaseService.firestore
          .collection('products')
          .where('businessId', isEqualTo: currentUser.businessId)
          .where('isActive', isEqualTo: true);

      if (selectedStore.value != null) {
        productsQuery.where('storeId', isEqualTo: selectedStore.value!.id);
      }

      final productsSnapshot = await productsQuery.get();
      final products = productsSnapshot.docs;

      // Calculate low stock products
      final lowStockProducts = products.where((doc) {
        final data = doc.data();
        final trackInventory = data['trackInventory'] ?? true;
        final stockQuantity = data['stockQuantity'] ?? 0;
        final lowStockThreshold = data['lowStockThreshold'] ?? 5;

        return trackInventory && stockQuantity <= lowStockThreshold;
      }).length;

      // Update stats
      stats.value = DashboardStats(
        todaySales: todayTransactions.fold(0.0, (total, t) => total + t.total),
        todayTransactions: todayTransactions.length,
        totalProducts: products.length,
        lowStockProducts: lowStockProducts,
        monthSales: monthTransactions.fold(0.0, (total, t) => total + t.total),
        monthTransactions: monthTransactions.length,
      );
    } catch (e) {
      // Use Get.snackbar instead of print for better UX
      Get.snackbar('Error', 'Failed to load dashboard statistics');
    }
  }

  // Navigation methods
  void navigateToProducts() {
    if (_securityService.hasPermission(Permission.viewProducts)) {
      Get.toNamed(AppRoutes.products);
    } else {
      _showPermissionDenied();
    }
  }

  void navigateToTransactions() {
    if (_securityService.hasPermission(Permission.viewTransactions)) {
      Get.toNamed(AppRoutes.transactions);
    } else {
      _showPermissionDenied();
    }
  }

  void navigateToStores() {
    if (_securityService.hasPermission(Permission.viewStores)) {
      Get.toNamed(AppRoutes.stores);
    } else {
      _showPermissionDenied();
    }
  }

  void navigateToSettings() {
    if (_securityService.hasPermission(Permission.viewSettings)) {
      Get.toNamed(AppRoutes.settings);
    } else {
      _showPermissionDenied();
    }
  }

  void _showPermissionDenied() {
    Get.snackbar(
      'Access Denied',
      'You do not have permission to access this feature.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Store selection
  void selectStore(StoreModel store) {
    selectedStore.value = store;
    _loadDashboardStats(); // Reload stats for selected store
  }

  // Refresh data
  Future<void> refreshData() async {
    await _initializeDashboard();
  }

  // Quick actions
  void startNewSale() {
    if (_securityService.hasPermission(Permission.processTransactions)) {
      // Navigate to POS interface (to be implemented)
      Get.snackbar(
        'Coming Soon',
        'POS interface will be implemented in the next phase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      _showPermissionDenied();
    }
  }

  void addProduct() {
    if (_securityService.hasPermission(Permission.manageProducts)) {
      // Navigate to add product (to be implemented)
      Get.snackbar(
        'Coming Soon',
        'Add product feature will be implemented in the next phase.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      _showPermissionDenied();
    }
  }

  // Getters for UI
  String get welcomeMessage {
    final user = _securityService.currentUser;
    final timeOfDay = DateTime.now().hour;
    String greeting;

    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return '$greeting, ${user?.firstName ?? 'User'}!';
  }

  bool get hasMultipleStores => stores.length > 1;

  UserRole? get currentUserRole => _securityService.currentUserRole;
}
