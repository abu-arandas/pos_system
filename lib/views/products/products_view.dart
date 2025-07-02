import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../services/security_service.dart';
import '../../models/product_model.dart';
import 'add_product_view.dart';
import 'product_detail_view.dart';

class ProductsView extends GetView<ProductController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(ProductController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Add product button
          if (Get.find<SecurityService>().hasPermission(Permission.manageProducts))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Get.to(() => const AddProductView()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchAndFilter(context),

          // Stats section
          _buildStatsSection(context),

          // Products list
          Expanded(
            child: _buildProductsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: controller.searchProducts,
          ),

          const SizedBox(height: 16),

          // Category filter
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.categories.map((category) {
                    final isSelected = controller.selectedCategory.value == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => controller.selectCategory(category),
                      ),
                    );
                  }).toList(),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total',
                  '${controller.totalProducts}',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Low Stock',
                  '${controller.lowStockCount}',
                  Icons.warning,
                  controller.lowStockCount > 0 ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Out of Stock',
                  '${controller.outOfStockCount}',
                  Icons.error,
                  controller.outOfStockCount > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ));
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.products.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No products found matching "${controller.searchQuery.value}"'
                    : 'No products available',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (Get.find<SecurityService>().hasPermission(Permission.manageProducts))
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const AddProductView()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadProducts(refresh: true),
        child: ListView.builder(
          itemCount: controller.filteredProducts.length + (controller.hasMoreProducts.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.filteredProducts.length) {
              // Load more indicator
              if (controller.isLoadingMore.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                // Load more button
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => controller.loadProducts(),
                    child: const Text('Load More'),
                  ),
                );
              }
            }

            final product = controller.filteredProducts[index];
            return _buildProductCard(context, product);
          },
        ),
      );
    });
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: product.primaryImageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    product.primaryImageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
                  ),
                )
              : Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${product.price.toStringAsFixed(2)}'),
            if (product.trackInventory)
              Row(
                children: [
                  Icon(
                    product.isOutOfStock
                        ? Icons.error
                        : product.isLowStock
                            ? Icons.warning
                            : Icons.check_circle,
                    size: 16,
                    color: product.isOutOfStock
                        ? Colors.red
                        : product.isLowStock
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${product.stockQuantity}',
                    style: TextStyle(
                      color: product.isOutOfStock
                          ? Colors.red
                          : product.isLowStock
                              ? Colors.orange
                              : null,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
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
            if (Get.find<SecurityService>().hasPermission(Permission.manageProducts))
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
            if (Get.find<SecurityService>().hasPermission(Permission.manageInventory))
              const PopupMenuItem(
                value: 'stock',
                child: Row(
                  children: [
                    Icon(Icons.inventory),
                    SizedBox(width: 8),
                    Text('Update Stock'),
                  ],
                ),
              ),
            if (Get.find<SecurityService>().hasPermission(Permission.manageProducts))
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
        onTap: () => Get.to(() => ProductDetailView(product: product)),
      ),
    );
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'view':
        Get.to(() => ProductDetailView(product: product));
        break;
      case 'edit':
        Get.to(() => AddProductView(product: product));
        break;
      case 'stock':
        _showUpdateStockDialog(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  void _showUpdateStockDialog(ProductModel product) {
    final stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockController.text);
              if (newStock != null && newStock >= 0) {
                controller.updateStock(product.id, newStock);
                Get.back();
              } else {
                Get.snackbar('Error', 'Please enter a valid stock quantity');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteProduct(product.id);
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
