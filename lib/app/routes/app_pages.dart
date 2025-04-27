import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../views/auth/login_view.dart';
import '../views/dashboard_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(name: _Paths.LOGIN, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: _Paths.DASHBOARD, page: () => const DashboardView(), binding: DashboardBinding()),
  ];
}
