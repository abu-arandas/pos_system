import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/payment_binding.dart';
import '../views/auth/login_view.dart';
import '../views/dashboard_view.dart';
import '../views/checkout_screen.dart';
import '../views/payment_selection_screen.dart';
import '../views/refund_screen.dart';
import '../views/refund_history_screen.dart';
import '../middleware/role_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(name: _Paths.LOGIN, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.PRODUCTS,
      page: () => const SizedBox(), // Placeholder - implement ProductsView
      binding: DashboardBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.INVENTORY,
      page: () => const SizedBox(), // Placeholder - implement InventoryView
      binding: DashboardBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.SALES,
      page: () => const SizedBox(), // Placeholder - implement SalesView
      binding: DashboardBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.CUSTOMERS,
      page: () => const SizedBox(), // Placeholder - implement CustomersView
      binding: DashboardBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.REPORTS,
      page: () => const SizedBox(), // Placeholder - implement ReportsView
      binding: DashboardBinding(),
      middlewares: [ManagerRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SizedBox(), // Placeholder - implement SettingsView
      binding: DashboardBinding(),
      middlewares: [AdminRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.NO_ACCESS,
      page: () => const SizedBox(), // Placeholder - implement NoAccessView
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CHECKOUT,
      page: () => CheckoutScreen(),
      binding: PaymentBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.PAYMENT_SELECTION,
      page: () => PaymentSelectionScreen(),
      binding: PaymentBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.REFUND,
      page: () => RefundScreen(saleId: Get.arguments['saleId'], sale: Get.arguments['sale']),
      binding: PaymentBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
    GetPage(
      name: _Paths.REFUND_HISTORY,
      page: () => RefundHistoryScreen(saleId: Get.arguments['saleId']),
      binding: PaymentBinding(),
      middlewares: [CashierRoleMiddleware()],
    ),
  ];
}
