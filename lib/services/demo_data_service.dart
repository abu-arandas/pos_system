import '../models/user_model.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../services/security_service.dart';

class DemoDataService {
  // Generate demo business ID
  static const String demoBusiness1 = 'demo_business_001';
  static const String demoBusiness2 = 'demo_business_002';

  // Generate demo store IDs
  static const String demoStore1 = 'demo_store_001';
  static const String demoStore2 = 'demo_store_002';
  static const String demoStore3 = 'demo_store_003';

  // Generate demo user IDs
  static const String adminUser1 = 'admin_user_001';
  static const String managerUser1 = 'manager_user_001';
  static const String cashierUser1 = 'cashier_user_001';
  static const String cashierUser2 = 'cashier_user_002';

  /// Generate demo users
  static List<UserModel> generateDemoUsers() {
    final now = DateTime.now();

    return [
      UserModel(
        id: adminUser1,
        email: 'admin@demo.com',
        firstName: 'John',
        lastName: 'Administrator',
        role: UserRole.admin,
        businessId: demoBusiness1,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
        metadata: {
          'loginCount': 150,
          'lastLoginIp': '192.168.1.100',
          'preferredLanguage': 'en',
        },
      ),
      UserModel(
        id: managerUser1,
        email: 'manager@demo.com',
        firstName: 'Sarah',
        lastName: 'Manager',
        role: UserRole.manager,
        businessId: demoBusiness1,
        storeId: demoStore1,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        metadata: {
          'loginCount': 89,
          'lastLoginIp': '192.168.1.101',
          'preferredLanguage': 'en',
        },
      ),
      UserModel(
        id: cashierUser1,
        email: 'cashier1@demo.com',
        firstName: 'Mike',
        lastName: 'Johnson',
        role: UserRole.cashier,
        businessId: demoBusiness1,
        storeId: demoStore1,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        metadata: {
          'loginCount': 45,
          'lastLoginIp': '192.168.1.102',
          'preferredLanguage': 'en',
        },
      ),
      UserModel(
        id: cashierUser2,
        email: 'cashier2@demo.com',
        firstName: 'Emily',
        lastName: 'Davis',
        role: UserRole.cashier,
        businessId: demoBusiness1,
        storeId: demoStore2,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        metadata: {
          'loginCount': 32,
          'lastLoginIp': '192.168.1.103',
          'preferredLanguage': 'en',
        },
      ),
    ];
  }

  /// Generate demo stores
  static List<StoreModel> generateDemoStores() {
    final now = DateTime.now();

    return [
      StoreModel(
        id: demoStore1,
        name: 'Downtown Main Store',
        description: 'Our flagship store in the heart of downtown',
        businessId: demoBusiness1,
        managerId: managerUser1,
        address: '123 Main Street',
        city: 'Anytown',
        state: 'CA',
        country: 'USA',
        postalCode: '12345',
        phone: '+1-555-0123',
        email: 'downtown@demo.com',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 2)),
        settings: {
          'taxRate': 0.0875,
          'currency': 'USD',
          'timezone': 'America/Los_Angeles',
          'receiptFooter': 'Thank you for shopping with us!',
          'allowReturns': true,
          'returnPeriodDays': 30,
        },
      ),
      StoreModel(
        id: demoStore2,
        name: 'Mall Location',
        description: 'Convenient shopping mall location',
        businessId: demoBusiness1,
        managerId: managerUser1,
        address: '456 Shopping Center Blvd',
        city: 'Anytown',
        state: 'CA',
        country: 'USA',
        postalCode: '12346',
        phone: '+1-555-0124',
        email: 'mall@demo.com',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 1)),
        settings: {
          'taxRate': 0.0875,
          'currency': 'USD',
          'timezone': 'America/Los_Angeles',
          'receiptFooter': 'Visit us again soon!',
          'allowReturns': true,
          'returnPeriodDays': 30,
        },
      ),
      StoreModel(
        id: demoStore3,
        name: 'Outlet Store',
        description: 'Discounted items and clearance sales',
        businessId: demoBusiness1,
        managerId: managerUser1,
        address: '789 Outlet Drive',
        city: 'Anytown',
        state: 'CA',
        country: 'USA',
        postalCode: '12347',
        phone: '+1-555-0125',
        email: 'outlet@demo.com',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        settings: {
          'taxRate': 0.0875,
          'currency': 'USD',
          'timezone': 'America/Los_Angeles',
          'receiptFooter': 'Great deals every day!',
          'allowReturns': false,
          'returnPeriodDays': 0,
        },
      ),
    ];
  }

  /// Generate demo products
  static List<ProductModel> generateDemoProducts() {
    final now = DateTime.now();

    return [
      // Electronics
      ProductModel(
        id: 'product_001',
        name: 'Wireless Bluetooth Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        businessId: demoBusiness1,
        storeId: demoStore1,
        categoryId: 'electronics',
        type: ProductType.simple,
        price: 199.99,
        costPrice: 120.00,
        sku: 'WBH-001',
        barcode: '1234567890123',
        imageUrls: [
          'https://example.com/images/headphones1.jpg',
          'https://example.com/images/headphones2.jpg',
        ],
        stockQuantity: 45,
        lowStockThreshold: 10,
        trackInventory: true,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 3)),
        metadata: {
          'brand': 'TechSound',
          'warranty': '2 years',
          'weight': '250g',
        },
      ),

      ProductModel(
        id: 'product_002',
        name: 'Smartphone Case',
        description: 'Protective case for smartphones',
        businessId: demoBusiness1,
        storeId: demoStore1,
        categoryId: 'accessories',
        type: ProductType.variable,
        price: 24.99,
        costPrice: 8.00,
        sku: 'SC-VAR',
        barcode: '1234567890124',
        imageUrls: [
          'https://example.com/images/case1.jpg',
        ],
        stockQuantity: 0, // Stock is tracked in variants
        lowStockThreshold: 5,
        trackInventory: true,
        isActive: true,
        variants: [
          ProductVariant(
            id: 'variant_001',
            name: 'iPhone 15 Case - Clear',
            price: 24.99,
            sku: 'SC-IP15-CLR',
            stockQuantity: 25,
            attributes: {
              'phone_model': 'iPhone 15',
              'color': 'Clear',
              'material': 'TPU',
            },
          ),
          ProductVariant(
            id: 'variant_002',
            name: 'iPhone 15 Case - Black',
            price: 24.99,
            sku: 'SC-IP15-BLK',
            stockQuantity: 18,
            attributes: {
              'phone_model': 'iPhone 15',
              'color': 'Black',
              'material': 'TPU',
            },
          ),
          ProductVariant(
            id: 'variant_003',
            name: 'Samsung Galaxy S24 Case - Clear',
            price: 22.99,
            sku: 'SC-S24-CLR',
            stockQuantity: 12,
            attributes: {
              'phone_model': 'Samsung Galaxy S24',
              'color': 'Clear',
              'material': 'TPU',
            },
          ),
        ],
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now.subtract(const Duration(days: 1)),
        metadata: {
          'brand': 'ProtectPro',
          'dropProtection': '6 feet',
        },
      ),

      // Clothing
      ProductModel(
        id: 'product_003',
        name: 'Cotton T-Shirt',
        description: 'Comfortable 100% cotton t-shirt',
        businessId: demoBusiness1,
        storeId: demoStore1,
        categoryId: 'clothing',
        type: ProductType.variable,
        price: 19.99,
        costPrice: 7.50,
        sku: 'CT-VAR',
        barcode: '1234567890125',
        imageUrls: [
          'https://example.com/images/tshirt1.jpg',
          'https://example.com/images/tshirt2.jpg',
        ],
        stockQuantity: 0,
        lowStockThreshold: 10,
        trackInventory: true,
        isActive: true,
        variants: [
          ProductVariant(
            id: 'variant_004',
            name: 'Cotton T-Shirt - Small - White',
            price: 19.99,
            sku: 'CT-S-WHT',
            stockQuantity: 30,
            attributes: {
              'size': 'Small',
              'color': 'White',
              'material': '100% Cotton',
            },
          ),
          ProductVariant(
            id: 'variant_005',
            name: 'Cotton T-Shirt - Medium - White',
            price: 19.99,
            sku: 'CT-M-WHT',
            stockQuantity: 25,
            attributes: {
              'size': 'Medium',
              'color': 'White',
              'material': '100% Cotton',
            },
          ),
          ProductVariant(
            id: 'variant_006',
            name: 'Cotton T-Shirt - Large - Black',
            price: 19.99,
            sku: 'CT-L-BLK',
            stockQuantity: 22,
            attributes: {
              'size': 'Large',
              'color': 'Black',
              'material': '100% Cotton',
            },
          ),
        ],
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 5)),
        metadata: {
          'brand': 'ComfortWear',
          'careInstructions': 'Machine wash cold',
        },
      ),

      // Food & Beverage
      ProductModel(
        id: 'product_004',
        name: 'Premium Coffee Beans',
        description: 'Freshly roasted arabica coffee beans',
        businessId: demoBusiness1,
        storeId: demoStore2,
        categoryId: 'food_beverage',
        type: ProductType.simple,
        price: 14.99,
        costPrice: 6.00,
        sku: 'PCB-001',
        barcode: '1234567890126',
        imageUrls: [
          'https://example.com/images/coffee1.jpg',
        ],
        stockQuantity: 60,
        lowStockThreshold: 15,
        trackInventory: true,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 2)),
        metadata: {
          'origin': 'Colombia',
          'roastLevel': 'Medium',
          'weight': '12oz',
          'expiryDays': 365,
        },
      ),

      // Services
      ProductModel(
        id: 'product_005',
        name: 'Tech Support Service',
        description: '1-hour technical support consultation',
        businessId: demoBusiness1,
        storeId: demoStore1,
        categoryId: 'services',
        type: ProductType.service,
        price: 75.00,
        costPrice: 30.00,
        sku: 'TSS-001',
        stockQuantity: 0, // Services don't have stock
        trackInventory: false,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 1)),
        metadata: {
          'duration': '60 minutes',
          'expertise': 'General IT Support',
          'remote': true,
        },
      ),

      // More products for variety
      ProductModel(
        id: 'product_006',
        name: 'Wireless Mouse',
        description: 'Ergonomic wireless mouse with USB receiver',
        businessId: demoBusiness1,
        storeId: demoStore1,
        categoryId: 'electronics',
        type: ProductType.simple,
        price: 29.99,
        costPrice: 12.00,
        sku: 'WM-001',
        barcode: '1234567890127',
        imageUrls: [
          'https://example.com/images/mouse1.jpg',
        ],
        stockQuantity: 35,
        lowStockThreshold: 8,
        trackInventory: true,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 4)),
        metadata: {
          'brand': 'TechMouse',
          'batteryLife': '12 months',
          'dpi': '1600',
        },
      ),

      ProductModel(
        id: 'product_007',
        name: 'Energy Drink',
        description: 'Refreshing energy drink with natural caffeine',
        businessId: demoBusiness1,
        storeId: demoStore2,
        categoryId: 'food_beverage',
        type: ProductType.simple,
        price: 2.99,
        costPrice: 1.20,
        sku: 'ED-001',
        barcode: '1234567890128',
        imageUrls: [
          'https://example.com/images/energy1.jpg',
        ],
        stockQuantity: 120,
        lowStockThreshold: 30,
        trackInventory: true,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        metadata: {
          'brand': 'PowerBoost',
          'flavor': 'Tropical',
          'volume': '16 fl oz',
          'caffeine': '80mg',
        },
      ),

      ProductModel(
        id: 'product_008',
        name: 'Notebook Set',
        description: 'Set of 3 premium notebooks with lined pages',
        businessId: demoBusiness1,
        storeId: demoStore3,
        categoryId: 'stationery',
        type: ProductType.simple,
        price: 12.99,
        costPrice: 4.50,
        sku: 'NB-SET-001',
        barcode: '1234567890129',
        imageUrls: [
          'https://example.com/images/notebook1.jpg',
        ],
        stockQuantity: 8, // Low stock
        lowStockThreshold: 10,
        trackInventory: true,
        isActive: true,
        variants: [],
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 6)),
        metadata: {
          'brand': 'WriteWell',
          'pageCount': 200,
          'paperType': 'Ruled',
          'set': true,
        },
      ),
    ];
  }

  /// Generate demo transactions
  static List<TransactionModel> generateDemoTransactions() {
    final now = DateTime.now();

    return [
      // Recent completed transaction
      TransactionModel(
        id: 'transaction_001',
        businessId: demoBusiness1,
        storeId: demoStore1,
        cashierId: cashierUser1,
        items: [
          TransactionItem(
            productId: 'product_001',
            productName: 'Wireless Bluetooth Headphones',
            unitPrice: 199.99,
            quantity: 1,
            discount: 0.0,
            total: 199.99,
          ),
          TransactionItem(
            productId: 'product_006',
            productName: 'Wireless Mouse',
            unitPrice: 29.99,
            quantity: 2,
            discount: 5.00, // $5 discount on mouse
            total: 54.98,
          ),
        ],
        subtotal: 254.97,
        taxAmount: 22.31,
        discountAmount: 5.00,
        total: 272.28,
        payments: [
          PaymentInfo(
            method: PaymentMethod.card,
            amount: 272.28,
            reference: 'CARD_****1234',
            metadata: {
              'cardType': 'Visa',
              'approvalCode': 'ABC123',
            },
          ),
        ],
        status: TransactionStatus.completed,
        receiptNumber: 'RCP-001-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        metadata: {
          'customerSatisfaction': 5,
          'returnEligible': true,
        },
      ),

      // Cash transaction
      TransactionModel(
        id: 'transaction_002',
        businessId: demoBusiness1,
        storeId: demoStore2,
        cashierId: cashierUser2,
        items: [
          TransactionItem(
            productId: 'product_004',
            productName: 'Premium Coffee Beans',
            unitPrice: 14.99,
            quantity: 2,
            discount: 0.0,
            total: 29.98,
          ),
          TransactionItem(
            productId: 'product_007',
            productName: 'Energy Drink',
            unitPrice: 2.99,
            quantity: 3,
            discount: 0.0,
            total: 8.97,
          ),
        ],
        subtotal: 38.95,
        taxAmount: 3.41,
        discountAmount: 0.0,
        total: 42.36,
        payments: [
          PaymentInfo(
            method: PaymentMethod.cash,
            amount: 50.00,
            reference: 'CASH',
            metadata: {
              'changeGiven': 7.64,
            },
          ),
        ],
        status: TransactionStatus.completed,
        receiptNumber: 'RCP-002-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        metadata: {
          'customerSatisfaction': 4,
          'returnEligible': true,
        },
      ),

      // Transaction with variants
      TransactionModel(
        id: 'transaction_003',
        businessId: demoBusiness1,
        storeId: demoStore1,
        cashierId: cashierUser1,
        items: [
          TransactionItem(
            productId: 'product_002',
            productName: 'Smartphone Case',
            variantId: 'variant_001',
            variantName: 'iPhone 15 Case - Clear',
            unitPrice: 24.99,
            quantity: 1,
            discount: 0.0,
            total: 24.99,
          ),
          TransactionItem(
            productId: 'product_003',
            productName: 'Cotton T-Shirt',
            variantId: 'variant_005',
            variantName: 'Cotton T-Shirt - Medium - White',
            unitPrice: 19.99,
            quantity: 2,
            discount: 4.00, // Buy 2 get $4 off
            total: 35.98,
          ),
        ],
        subtotal: 60.97,
        taxAmount: 5.33,
        discountAmount: 4.00,
        total: 62.30,
        payments: [
          PaymentInfo(
            method: PaymentMethod.digitalWallet,
            amount: 62.30,
            reference: 'APPLE_PAY_****5678',
            metadata: {
              'walletType': 'Apple Pay',
              'deviceId': 'iPhone_ABC123',
            },
          ),
        ],
        status: TransactionStatus.completed,
        receiptNumber: 'RCP-003-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        metadata: {
          'customerSatisfaction': 5,
          'returnEligible': true,
        },
      ),

      // Service transaction
      TransactionModel(
        id: 'transaction_004',
        businessId: demoBusiness1,
        storeId: demoStore1,
        cashierId: managerUser1,
        items: [
          TransactionItem(
            productId: 'product_005',
            productName: 'Tech Support Service',
            unitPrice: 75.00,
            quantity: 1,
            discount: 0.0,
            total: 75.00,
          ),
        ],
        subtotal: 75.00,
        taxAmount: 6.56,
        discountAmount: 0.0,
        total: 81.56,
        payments: [
          PaymentInfo(
            method: PaymentMethod.card,
            amount: 81.56,
            reference: 'CARD_****9012',
            metadata: {
              'cardType': 'MasterCard',
              'approvalCode': 'DEF456',
            },
          ),
        ],
        status: TransactionStatus.completed,
        notes: 'Customer needed help setting up new laptop',
        receiptNumber: 'RCP-004-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        metadata: {
          'serviceCompleted': true,
          'technician': 'John Tech',
          'duration': 45,
        },
      ),

      // Pending transaction
      TransactionModel(
        id: 'transaction_005',
        businessId: demoBusiness1,
        storeId: demoStore3,
        cashierId: cashierUser1,
        items: [
          TransactionItem(
            productId: 'product_008',
            productName: 'Notebook Set',
            unitPrice: 12.99,
            quantity: 1,
            discount: 0.0,
            total: 12.99,
          ),
        ],
        subtotal: 12.99,
        taxAmount: 1.14,
        discountAmount: 0.0,
        total: 14.13,
        payments: [], // No payment yet
        status: TransactionStatus.pending,
        receiptNumber: 'RCP-005-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        metadata: {
          'holdReason': 'Customer went to get cash',
        },
      ),

      // Refunded transaction
      TransactionModel(
        id: 'transaction_006',
        businessId: demoBusiness1,
        storeId: demoStore1,
        cashierId: cashierUser1,
        items: [
          TransactionItem(
            productId: 'product_006',
            productName: 'Wireless Mouse',
            unitPrice: 29.99,
            quantity: 1,
            discount: 0.0,
            total: 29.99,
          ),
        ],
        subtotal: 29.99,
        taxAmount: 2.62,
        discountAmount: 0.0,
        total: 32.61,
        payments: [
          PaymentInfo(
            method: PaymentMethod.card,
            amount: 32.61,
            reference: 'CARD_****3456',
            metadata: {
              'cardType': 'Visa',
              'approvalCode': 'GHI789',
              'refundId': 'REF_123456',
            },
          ),
        ],
        status: TransactionStatus.refunded,
        notes: 'Customer returned defective mouse',
        receiptNumber: 'RCP-006-${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        metadata: {
          'refundReason': 'Defective product',
          'refundDate': now.subtract(const Duration(days: 2)).toIso8601String(),
          'refundedBy': managerUser1,
        },
      ),
    ];
  }

  /// Get all demo data as a comprehensive map
  static Map<String, dynamic> getAllDemoData() {
    return {
      'users': generateDemoUsers().map((user) => user.toMap()).toList(),
      'stores': generateDemoStores().map((store) => store.toMap()).toList(),
      'products': generateDemoProducts().map((product) => product.toMap()).toList(),
      'transactions': generateDemoTransactions().map((transaction) => transaction.toMap()).toList(),
      'metadata': {
        'generatedAt': DateTime.now().toIso8601String(),
        'totalUsers': generateDemoUsers().length,
        'totalStores': generateDemoStores().length,
        'totalProducts': generateDemoProducts().length,
        'totalTransactions': generateDemoTransactions().length,
        'businessIds': [demoBusiness1, demoBusiness2],
        'description': 'Comprehensive demo data for POS system testing and demonstration',
      },
    };
  }
}
