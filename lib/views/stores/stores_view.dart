import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/store_controller.dart';
import '../../services/security_service.dart';
import '../../models/store_model.dart';
import 'add_store_view.dart';
import 'store_detail_view.dart';

class StoresView extends GetView<StoreController> {
  const StoresView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(StoreController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores'),
        actions: [
          // Add store button
          if (Get.find<SecurityService>().hasPermission(Permission.manageStores))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Get.to(() => const AddStoreView()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and stats section
          _buildSearchAndStats(context),

          // Stores list
          Expanded(
            child: _buildStoresList(context),
          ),
        ],
      ),
      floatingActionButton: Get.find<SecurityService>().hasPermission(Permission.manageStores)
          ? FloatingActionButton(
              onPressed: () => Get.to(() => const AddStoreView()),
              tooltip: 'Add Store',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSearchAndStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: controller.searchStores,
          ),

          const SizedBox(height: 16),

          // Stats cards
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Stores',
                      '${controller.totalStores}',
                      Icons.store,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Stores',
                      '${controller.activeStores}',
                      Icons.store_mall_directory,
                      Colors.green,
                    ),
                  ),
                ],
              )),
        ],
      ),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
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

  Widget _buildStoresList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.stores.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredStores.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No stores found matching "${controller.searchQuery.value}"'
                    : 'No stores available',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (Get.find<SecurityService>().hasPermission(Permission.manageStores))
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const AddStoreView()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Store'),
                ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadStores(refresh: true),
        child: ListView.builder(
          itemCount: controller.filteredStores.length,
          itemBuilder: (context, index) {
            final store = controller.filteredStores[index];
            return _buildStoreCard(context, store);
          },
        ),
      );
    });
  }

  Widget _buildStoreCard(BuildContext context, StoreModel store) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              store.isActive ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.withOpacity(0.3),
          child: Icon(
            Icons.store,
            color: store.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ),
        title: Text(
          store.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: store.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.fullAddress.isNotEmpty)
              Text(
                store.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Manager: ${controller.getManagerName(store.managerId)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: store.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    store.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: store.isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleStoreAction(value, store),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (Get.find<SecurityService>().hasPermission(Permission.manageStores))
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            if (Get.find<SecurityService>().hasPermission(Permission.manageStores))
              const PopupMenuItem(
                value: 'assign_manager',
                child: Row(
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text('Assign Manager'),
                  ],
                ),
              ),
            if (Get.find<SecurityService>().hasPermission(Permission.manageStores) && store.isActive)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => Get.to(() => StoreDetailView(store: store)),
      ),
    );
  }

  void _handleStoreAction(String action, StoreModel store) {
    switch (action) {
      case 'view':
        Get.to(() => StoreDetailView(store: store));
        break;
      case 'edit':
        Get.to(() => AddStoreView(store: store));
        break;
      case 'assign_manager':
        _showAssignManagerDialog(store);
        break;
      case 'delete':
        _showDeleteConfirmation(store);
        break;
    }
  }

  void _showAssignManagerDialog(StoreModel store) {
    String? selectedManagerId = store.managerId.isNotEmpty ? store.managerId : null;

    Get.dialog(
      AlertDialog(
        title: Text('Assign Manager - ${store.name}'),
        content: Obx(() => DropdownButtonFormField<String>(
              value: selectedManagerId,
              decoration: const InputDecoration(
                labelText: 'Select Manager',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Manager'),
                ),
                ...controller.storeManagers.map((manager) => DropdownMenuItem<String>(
                      value: manager.id,
                      child: Text('${manager.fullName} (${manager.role.name})'),
                    )),
              ],
              onChanged: (value) => selectedManagerId = value,
            )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedManagerId != null) {
                controller.assignManagerToStore(store.id, selectedManagerId!);
              }
              Get.back();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(StoreModel store) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Store'),
        content: Text(
          'Are you sure you want to delete "${store.name}"?\n\n'
          'This action will deactivate the store and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteStore(store.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
