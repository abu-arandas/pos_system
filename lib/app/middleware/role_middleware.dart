import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class RoleMiddleware extends GetMiddleware {
  final String requiredRole;
  final String redirectRoute;

  RoleMiddleware({
    required this.requiredRole,
    this.redirectRoute = '/no_access',
  });

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Check if user is logged in
    if (authController.user == null) {
      return const RouteSettings(name: '/login');
    }

    // Check if user has the required role
    final userRoles = authController.userRoles;
    if (!userRoles.contains(requiredRole)) {
      return RouteSettings(name: redirectRoute);
    }

    return null;
  }
}

// Predefined middleware instances for common roles
class AdminRoleMiddleware extends RoleMiddleware {
  AdminRoleMiddleware() : super(requiredRole: 'admin');
}

class CashierRoleMiddleware extends RoleMiddleware {
  CashierRoleMiddleware() : super(requiredRole: 'cashier');
}

class ManagerRoleMiddleware extends RoleMiddleware {
  ManagerRoleMiddleware() : super(requiredRole: 'manager');
}
