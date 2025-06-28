import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/customer_controller.dart';

class DashboardView extends GetView<AuthController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductController productController = Get.find<ProductController>();
    final SalesController salesController = Get.find<SalesController>();
    final CustomerController customerController = Get.find<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context, productController),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            productController.fetchProducts(),
            salesController.fetchSales(),
            customerController.fetchCustomers(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening with your store today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Products',
                      productController.products.length.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                      context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sales Today',
                      salesController.sales.length.toString(),
                      Icons.trending_up,
                      Colors.green,
                      context,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Customers',
                      customerController.customers.length.toString(),
                      Icons.people,
                      Colors.orange,
                      context,
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildMenuCard(
                    context,
                    'Products',
                    Icons.inventory_2,
                    Colors.blue,
                    () => Get.toNamed('/products'),
                  ),
                  _buildMenuCard(
                    context,
                    'New Sale',
                    Icons.point_of_sale,
                    Colors.green,
                    () => Get.toNamed('/checkout'),
                  ),
                  _buildMenuCard(
                    context,
                    'Inventory',
                    Icons.warehouse,
                    Colors.orange,
                    () => Get.toNamed('/inventory'),
                  ),
                  _buildMenuCard(
                    context,
                    'Customers',
                    Icons.people,
                    Colors.purple,
                    () => Get.toNamed('/customers'),
                  ),
                  _buildMenuCard(
                    context,
                    'Sales History',
                    Icons.history,
                    Colors.teal,
                    () => Get.toNamed('/sales'),
                  ),
                  _buildMenuCard(
                    context,
                    'Reports',
                    Icons.analytics,
                    Colors.indigo,
                    () => Get.toNamed('/reports'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Low Stock Alert
              Obx(() {
                final lowStockProducts = productController.getLowStockProducts();
                if (lowStockProducts.isEmpty) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Low Stock Alert',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${lowStockProducts.length} products are running low on stock',
                        style: TextStyle(color: Colors.orange[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Get.toNamed('/inventory'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View Inventory'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, ProductController productController) {
    final lowStockProducts = productController.getLowStockProducts();
    final outOfStockProducts = productController.getOutOfStockProducts();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (lowStockProducts.isEmpty && outOfStockProducts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else ...[
              if (outOfStockProducts.isNotEmpty) ...[
                ListTile(
                  leading: Icon(Icons.error, color: Colors.red[600]),
                  title: const Text('Out of Stock'),
                  subtitle: Text('${outOfStockProducts.length} products'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Get.toNamed('/inventory'),
                ),
              ],
              if (lowStockProducts.isNotEmpty) ...[
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange[600]),
                  title: const Text('Low Stock'),
                  subtitle: Text('${lowStockProducts.length} products'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Get.toNamed('/inventory'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}