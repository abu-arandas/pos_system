import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/customer_controller.dart';

class CheckoutScreen extends StatelessWidget {
  final CheckoutController checkoutController = Get.find<CheckoutController>();
  final CustomerController customerController = Get.find<CustomerController>();

  CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showClearCartDialog(context),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: Obx(() {
        if (checkoutController.cart.isEmpty) {
          return const Center(
            child: Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return Column(
          children: [
            // Customer selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Customer: ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Obx(() {
                      final selectedId = checkoutController.selectedCustomerId.value;
                      final selectedCustomer = selectedId.isEmpty
                          ? null
                          : customerController.customers.firstWhere((c) => c.id == selectedId);

                      return DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select Customer'),
                        value: selectedCustomer?.id,
                        onChanged: (value) {
                          if (value != null) {
                            checkoutController.setCustomer(value);
                          }
                        },
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('No Customer'),
                          ),
                          ...customerController.customers.map((customer) {
                            return DropdownMenuItem<String>(
                              value: customer.id,
                              child: Text(customer.name),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Cart items
            Expanded(
              child: ListView.builder(
                itemCount: checkoutController.cart.length,
                itemBuilder: (context, index) {
                  final item = checkoutController.cart[index];
                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('\$${item.product.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item.quantity > 1) {
                              checkoutController.updateItemQuantity(
                                index,
                                item.quantity - 1,
                              );
                            } else {
                              checkoutController.removeItem(index);
                            }
                          },
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            checkoutController.updateItemQuantity(
                              index,
                              item.quantity + 1,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Order summary
            Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${checkoutController.subtotal.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('-\$${checkoutController.discount.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text('\$${checkoutController.tax.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '\$${checkoutController.total.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Discount and payment buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.discount),
                      label: const Text('Apply Discount'),
                      onPressed: () => _showDiscountDialog(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Proceed to Payment'),
                      onPressed: checkoutController.cart.isEmpty ? null : () => Get.toNamed('/payment-selection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final TextEditingController discountController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Apply Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter discount percentage:'),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffix: Text('%'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text);
              if (discount != null && discount >= 0 && discount <= 100) {
                // TODO: Implement discount logic
                Get.back();
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a valid discount percentage (0-100)',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear the cart?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              checkoutController.clearCart();
              Get.back();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
