import 'package:get/get.dart';
import '../models/user_model.dart';

enum UserRole { admin, manager, cashier }

enum Permission {
  // User management
  manageUsers,
  viewUsers,
  
  // Business management
  manageBusiness,
  viewBusiness,
  
  // Store management
  manageStores,
  viewStores,
  
  // Product management
  manageProducts,
  viewProducts,
  
  // Transaction management
  processTransactions,
  viewTransactions,
  refundTransactions,
  
  // Customer management
  manageCustomers,
  viewCustomers,
  
  // Analytics and reports
  viewAnalytics,
  viewReports,
  exportData,
  
  // Settings
  manageSettings,
  viewSettings,
  
  // Inventory
  manageInventory,
  viewInventory,
}

class SecurityService extends GetxService {
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxMap<UserRole, Set<Permission>> _rolePermissions = RxMap<UserRole, Set<Permission>>();

  // Getters
  UserModel? get currentUser => _currentUser.value;
  UserRole? get currentUserRole => _currentUser.value?.role;
  String? get currentUserId => _currentUser.value?.id;
  String? get currentBusinessId => _currentUser.value?.businessId;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
  }

  void _initializePermissions() {
    // Admin permissions - full access
    _rolePermissions[UserRole.admin] = {
      Permission.manageUsers,
      Permission.viewUsers,
      Permission.manageBusiness,
      Permission.viewBusiness,
      Permission.manageStores,
      Permission.viewStores,
      Permission.manageProducts,
      Permission.viewProducts,
      Permission.processTransactions,
      Permission.viewTransactions,
      Permission.refundTransactions,
      Permission.manageCustomers,
      Permission.viewCustomers,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.exportData,
      Permission.manageSettings,
      Permission.viewSettings,
      Permission.manageInventory,
      Permission.viewInventory,
    };

    // Manager permissions - store operations
    _rolePermissions[UserRole.manager] = {
      Permission.viewUsers,
      Permission.viewBusiness,
      Permission.viewStores,
      Permission.manageProducts,
      Permission.viewProducts,
      Permission.processTransactions,
      Permission.viewTransactions,
      Permission.refundTransactions,
      Permission.manageCustomers,
      Permission.viewCustomers,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.viewSettings,
      Permission.manageInventory,
      Permission.viewInventory,
    };

    // Cashier permissions - basic operations
    _rolePermissions[UserRole.cashier] = {
      Permission.viewProducts,
      Permission.processTransactions,
      Permission.viewTransactions,
      Permission.viewCustomers,
      Permission.viewInventory,
    };
  }

  // Set current user
  void setCurrentUser(UserModel? user) {
    _currentUser.value = user;
  }

  // Clear current user (logout)
  void clearCurrentUser() {
    _currentUser.value = null;
  }

  // Check if user has specific permission
  bool hasPermission(Permission permission) {
    if (_currentUser.value == null) return false;
    
    final userRole = _currentUser.value!.role;
    final permissions = _rolePermissions[userRole];
    
    return permissions?.contains(permission) ?? false;
  }

  // Check if user has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  // Check if user has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  // Check if user can access a specific route
  bool canAccessRoute(String route) {
    if (_currentUser.value == null) {
      // Allow access to auth routes when not logged in
      return route.startsWith('/login') || 
             route.startsWith('/register') || 
             route.startsWith('/splash');
    }

    // Route-based permission checking
    switch (route) {
      case '/dashboard':
        return true; // All authenticated users can access dashboard
      
      case '/products':
        return hasPermission(Permission.viewProducts);
      
      case '/transactions':
        return hasPermission(Permission.viewTransactions);
      
      case '/stores':
        return hasPermission(Permission.viewStores);
      
      case '/customers':
        return hasPermission(Permission.viewCustomers);
      
      case '/analytics':
        return hasPermission(Permission.viewAnalytics);
      
      case '/reports':
        return hasPermission(Permission.viewReports);
      
      case '/settings':
        return hasPermission(Permission.viewSettings);
      
      case '/users':
        return hasPermission(Permission.viewUsers);
      
      default:
        return true; // Allow access to unknown routes by default
    }
  }

  // Check if user belongs to the same business
  bool isSameBusiness(String businessId) {
    return _currentUser.value?.businessId == businessId;
  }

  // Check if user can manage another user
  bool canManageUser(UserModel targetUser) {
    if (!hasPermission(Permission.manageUsers)) return false;
    
    // Admin can manage anyone in the same business
    if (currentUserRole == UserRole.admin) {
      return isSameBusiness(targetUser.businessId);
    }
    
    // Manager can manage cashiers in the same business
    if (currentUserRole == UserRole.manager) {
      return isSameBusiness(targetUser.businessId) && 
             targetUser.role == UserRole.cashier;
    }
    
    return false;
  }

  // Get permissions for current user role
  Set<Permission> getCurrentUserPermissions() {
    if (_currentUser.value == null) return {};
    return _rolePermissions[_currentUser.value!.role] ?? {};
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUser.value != null;

  // Check if user is admin
  bool get isAdmin => currentUserRole == UserRole.admin;

  // Check if user is manager
  bool get isManager => currentUserRole == UserRole.manager;

  // Check if user is cashier
  bool get isCashier => currentUserRole == UserRole.cashier;
}
