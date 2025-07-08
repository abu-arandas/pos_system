import 'package:get/get.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/products/products_view.dart';
import '../views/transactions/transactions_view.dart';
import '../views/stores/stores_view.dart';
import '../views/settings/settings_view.dart';
import '../views/admin/demo_data_view.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String transactions = '/transactions';
  static const String stores = '/stores';
  static const String settings = '/settings';
  static const String demoData = '/demo-data';

  // Route definitions
  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardView(),
    ),
    GetPage(
      name: products,
      page: () => const ProductsView(),
    ),
    GetPage(
      name: transactions,
      page: () => const TransactionsView(),
    ),
    GetPage(
      name: stores,
      page: () => const StoresView(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
    ),
    GetPage(
      name: demoData,
      page: () => const DemoDataView(),
    ),
  ];
}
