import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/payment_controller.dart';

class PaymentSelectionScreen extends StatelessWidget {
  final CheckoutController checkoutController = Get.find<CheckoutController>();
  final PaymentController paymentController = Get.find<PaymentController>();

  PaymentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Display total amount
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${checkoutController.subtotal.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('-\$${checkoutController.discount.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${checkoutController.total.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Payment method options
            ...paymentController.supportedPaymentMethods.map((method) {
              String title;
              String subtitle;
              IconData icon;

              switch (method) {
                case 'stripe':
                  title = 'Credit/Debit Card (Stripe)';
                  subtitle = 'Pay securely with Stripe';
                  icon = Icons.credit_card;
                  break;
                case 'cash':
                  title = 'Cash';
                  subtitle = 'Pay with cash at checkout';
                  icon = Icons.money;
                  break;
                case 'credit_card':
                  title = 'Credit Card (Manual)';
                  subtitle = 'Process credit card manually';
                  icon = Icons.credit_card;
                  break;
                case 'mobile_payment':
                  title = 'Mobile Payment';
                  subtitle = 'Apple Pay, Google Pay, etc.';
                  icon = Icons.smartphone;
                  break;
                default:
                  title = method.capitalizeFirst!;
                  subtitle = 'Pay with $method';
                  icon = Icons.payment;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: RadioListTile<String>(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  secondary: Icon(icon),
                  value: method,
                  groupValue: checkoutController.selectedPaymentMethod.value,
                  onChanged: (value) {
                    if (value != null) {
                      checkoutController.setPaymentMethod(value);
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 20),
            // Process payment button
            Obx(() => ElevatedButton(
                  onPressed: checkoutController.isProcessing.value ? null : () => _processPayment(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: checkoutController.isProcessing.value
                      ? const CircularProgressIndicator()
                      : Text(
                          'Pay \$${checkoutController.total.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                )),
          ],
        );
      }),
    );
  }

  void _processPayment(BuildContext context) async {
    // Show loading indicator
    checkoutController.isProcessing.value = true;

    try {
      // Process payment with selected method
      await checkoutController.processPayment(
        checkoutController.selectedPaymentMethod.value,
      );
    } catch (e) {
      // Error is already handled in the controller
      checkoutController.isProcessing.value = false;
    }
  }
}
