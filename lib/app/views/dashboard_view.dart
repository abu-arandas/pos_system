import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class DashboardView extends GetView<AuthController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => controller.signOut())],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(context, 'Products', Icons.inventory_2, () => Get.toNamed('/products')),
          _buildMenuCard(context, 'Sales', Icons.point_of_sale, () => Get.toNamed('/sales')),
          _buildMenuCard(context, 'Inventory', Icons.warehouse, () => Get.toNamed('/inventory')),
          _buildMenuCard(context, 'Customers', Icons.people, () => Get.toNamed('/customers')),
          _buildMenuCard(context, 'Reports', Icons.analytics, () => Get.toNamed('/reports')),
          _buildMenuCard(context, 'Settings', Icons.settings, () => Get.toNamed('/settings')),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
