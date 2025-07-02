import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/security_service.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(DashboardController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('controller.businessName')),
        actions: [
          // Store selector (if multiple stores)
          Obx(() {
            if (controller.hasMultipleStores) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.store),
                onSelected: (storeId) {
                  final store = controller.stores.firstWhere((s) => s.id == storeId);
                  controller.selectStore(store);
                },
                itemBuilder: (context) => controller.stores.map((store) {
                  return PopupMenuItem(
                    value: store.id,
                    child: Row(
                      children: [
                        Icon(
                          controller.selectedStore.value?.id == store.id ? Icons.check_circle : Icons.store_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(store.name),
                      ],
                    ),
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          }),

          // Profile menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  controller.navigateToSettings();
                  break;
                case 'logout':
                  authController.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  controller.welcomeMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Selected store info
                if (controller.selectedStore.value != null)
                  Text(
                    'Store: ${controller.selectedStore.value!.name}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),

                const SizedBox(height: 24),

                // Quick actions
                _buildQuickActions(context),

                const SizedBox(height: 24),

                // Statistics cards
                _buildStatsCards(context),

                const SizedBox(height: 24),

                // Navigation menu
                _buildNavigationMenu(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.startNewSale,
                icon: const Icon(Icons.point_of_sale),
                label: const Text('New Sale'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.addProduct,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Product'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final stats = controller.stats.value;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                'Today\'s Sales',
                '\$${stats.todaySales.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Transactions',
                '${stats.todayTransactions}',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Products',
                '${stats.totalProducts}',
                Icons.inventory,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Low Stock',
                '${stats.lowStockProducts}',
                Icons.warning,
                stats.lowStockProducts > 0 ? Colors.red : Colors.grey,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    final securityService = Get.find<SecurityService>();

    final menuItems = <Map<String, dynamic>>[
      if (securityService.hasPermission(Permission.viewProducts))
        {
          'title': 'Products',
          'subtitle': 'Manage your inventory',
          'icon': Icons.inventory_2_outlined,
          'onTap': controller.navigateToProducts,
        },
      if (securityService.hasPermission(Permission.viewTransactions))
        {
          'title': 'Transactions',
          'subtitle': 'View sales history',
          'icon': Icons.receipt_long_outlined,
          'onTap': controller.navigateToTransactions,
        },
      if (securityService.hasPermission(Permission.viewStores))
        {
          'title': 'Stores',
          'subtitle': 'Manage store locations',
          'icon': Icons.store_outlined,
          'onTap': controller.navigateToStores,
        },
      if (securityService.hasPermission(Permission.viewSettings))
        {
          'title': 'Settings',
          'subtitle': 'Configure your system',
          'icon': Icons.settings_outlined,
          'onTap': controller.navigateToSettings,
        },
    ];

    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...menuItems.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(item['icon'] as IconData),
                title: Text(item['title'] as String),
                subtitle: Text(item['subtitle'] as String),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: item['onTap'] as VoidCallback,
              ),
            )),
      ],
    );
  }
}
