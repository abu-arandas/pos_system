import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/loyalty_controller.dart';

class CheckoutScreen extends StatelessWidget {
  final CheckoutController checkoutController = Get.find<CheckoutController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final LoyaltyController loyaltyController = Get.find<LoyaltyController>();

  CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearCartDialog(context),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: Obx(() {
        if (checkoutController.cart.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add products to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/products'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Browse Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Customer and Loyalty Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Customer Selection
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Customer: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Expanded(
                        child: Obx(() {
                          final selectedId = checkoutController.selectedCustomerId.value;
                          final selectedCustomer = selectedId.isEmpty
                              ? null
                              : customerController.customers.firstWhere(
                                  (c) => c.id == selectedId,
                                  orElse: () => customerController.customers.first,
                                );

                          return DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Select Customer'),
                            value: selectedCustomer?.id,
                            underline: Container(),
                            onChanged: (value) {
                              if (value != null) {
                                checkoutController.setCustomer(value);
                                loyaltyController.selectCustomer(value);
                              }
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Walk-in Customer'),
                              ),
                              ...customerController.customers.map((customer) {
                                return DropdownMenuItem<String>(
                                  value: customer.id,
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(customer.name)),
                                      if (customer.loyaltyPoints > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${customer.loyaltyPoints} pts',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                  // Loyalty Points Display
                  Obx(() {
                    if (loyaltyController.selectedCustomerId.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Available Points: ${loyaltyController.points.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[700],
                            ),
                          ),
                          const Spacer(),
                          if (loyaltyController.points.value >= 100)
                            TextButton(
                              onPressed: () => _showRedeemPointsDialog(context),
                              child: const Text('Redeem'),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Cart Items
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: checkoutController.cart.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = checkoutController.cart[index];
                  return _buildCartItem(item, index, context);
                },
              ),
            ),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', '\$${checkoutController.subtotal.value.toStringAsFixed(2)}'),
                  if (checkoutController.discount.value > 0)
                    _buildSummaryRow('Discount', '-\$${checkoutController.discount.value.toStringAsFixed(2)}', color: Colors.green),
                  _buildSummaryRow('Tax', '\$${checkoutController.tax.value.toStringAsFixed(2)}'),
                  const Divider(thickness: 2),
                  _buildSummaryRow(
                    'Total',
                    '\$${checkoutController.total.value.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.discount),
                          label: const Text('Discount'),
                          onPressed: () => _showDiscountDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Proceed to Payment'),
                          onPressed: checkoutController.cart.isEmpty ? null : () => Get.toNamed('/payment-selection'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCartItem(dynamic item, int index, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey[400],
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.product.price.toStringAsFixed(2)} each',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Get.theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (item.quantity > 1) {
                        checkoutController.updateItemQuantity(index, item.quantity - 1);
                      } else {
                        checkoutController.removeItem(index);
                      }
                    },
                    icon: Icon(
                      item.quantity > 1 ? Icons.remove : Icons.delete,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      checkoutController.updateItemQuantity(index, item.quantity + 1);
                    },
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Get.theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isTotal ? Get.theme.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final TextEditingController discountController = TextEditingController();
    bool isPercentage = true;

    Get.dialog(
      AlertDialog(
        title: const Text('Apply Discount'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Percentage'),
                      value: true,
                      groupValue: isPercentage,
                      onChanged: (value) => setState(() => isPercentage = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Amount'),
                      value: false,
                      groupValue: isPercentage,
                      onChanged: (value) => setState(() => isPercentage = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPercentage ? 'Discount Percentage' : 'Discount Amount',
                  suffix: Text(isPercentage ? '%' : '\$'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(discountController.text);
              if (value != null && value > 0) {
                if (isPercentage) {
                  if (value <= 100) {
                    checkoutController.applyPercentageDiscount(value);
                    Get.back();
                  } else {
                    Get.snackbar('Error', 'Percentage cannot exceed 100%');
                  }
                } else {
                  if (value <= checkoutController.subtotal.value) {
                    checkoutController.applyDiscount(value);
                    Get.back();
                  } else {
                    Get.snackbar('Error', 'Discount cannot exceed subtotal');
                  }
                }
              } else {
                Get.snackbar('Error', 'Please enter a valid discount value');
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRedeemPointsDialog(BuildContext context) {
    final TextEditingController pointsController = TextEditingController();
    final availablePoints = loyaltyController.points.value;
    final maxRedeemable = (availablePoints / 100).floor() * 100; // Redeem in multiples of 100

    Get.dialog(
      AlertDialog(
        title: const Text('Redeem Loyalty Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Points: $availablePoints'),
            Text('100 points = \$1.00 discount'),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points to Redeem',
                border: OutlineInputBorder(),
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
              final points = int.tryParse(pointsController.text);
              if (points != null && points > 0 && points <= maxRedeemable && points % 100 == 0) {
                final discount = points / 100;
                checkoutController.applyDiscount(discount);
                Get.back();
                Get.snackbar(
                  'Points Redeemed',
                  '$points points redeemed for \$${discount.toStringAsFixed(2)} discount',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a valid amount (multiples of 100, max $maxRedeemable)',
                );
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from the cart?'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}