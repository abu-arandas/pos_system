import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'payment_view.dart';

class POSView extends GetView<TransactionController> {
  const POSView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(TransactionController());
    Get.put(ProductController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          // Clear cart button
          Obx(() => controller.cartItems.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showClearCartDialog(),
                  tooltip: 'Clear Cart',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Row(
        children: [
          // Products section (left side)
          Expanded(
            flex: 2,
            child: _buildProductsSection(context),
          ),

          // Cart section (right side)
          Expanded(
            flex: 1,
            child: _buildCartSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    final productController = Get.find<ProductController>();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: productController.searchProducts,
            ),
          ),

          // Products grid
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value && productController.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productController.filteredProducts.isEmpty) {
                return const Center(
                  child: Text('No products available'),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: productController.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = productController.filteredProducts[index];
                  return _buildProductCard(context, product);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      child: InkWell(
        onTap: () => controller.addToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.primaryImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.primaryImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.inventory, size: 32),
                          ),
                        )
                      : const Icon(Icons.inventory, size: 32),
                ),
              ),

              const SizedBox(height: 8),

              // Product name
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Product price
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              // Stock status
              if (product.trackInventory)
                Text(
                  'Stock: ${product.stockQuantity}',
                  style: TextStyle(
                    color: product.isOutOfStock
                        ? Colors.red
                        : product.isLowStock
                            ? Colors.orange
                            : Colors.green,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Obx(() => Text(
                      '${controller.totalItems} items',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: Obx(() {
              if (controller.cartItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Cart is empty'),
                      Text('Add products to start selling'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = controller.cartItems[index];
                  return _buildCartItem(context, cartItem, index);
                },
              );
            }),
          ),

          // Cart summary and checkout
          _buildCartSummary(context),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem cartItem, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cartItem.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.removeFromCart(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (cartItem.quantity.value > 1) {
                            controller.updateCartItemQuantity(index, cartItem.quantity.value - 1);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Obx(() => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('${cartItem.quantity.value}'),
                          )),
                      InkWell(
                        onTap: () => controller.updateCartItemQuantity(index, cartItem.quantity.value + 1),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Price
                Obx(() => Text(
                      '\$${cartItem.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text('\$${controller.subtotal.toStringAsFixed(2)}'),
                ],
              )),

          const SizedBox(height: 8),

          // Tax
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax (${controller.taxRate.value}%):'),
                  Text('\$${controller.taxAmount.toStringAsFixed(2)}'),
                ],
              )),

          const SizedBox(height: 8),

          // Discount
          Obx(() => controller.discountAmount.value > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:'),
                    Text('-\$${controller.discountAmount.value.toStringAsFixed(2)}'),
                  ],
                )
              : const SizedBox.shrink()),

          const Divider(),

          // Total
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '\$${controller.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              )),

          const SizedBox(height: 16),

          // Checkout button
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.cartItems.isEmpty ? null : () => Get.to(() => const PaymentView()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Proceed to Payment'),
                ),
              )),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearCart();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
