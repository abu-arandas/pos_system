import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

class PaymentView extends GetView<TransactionController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentAmounts = <PaymentMethod, TextEditingController>{
      PaymentMethod.cash: TextEditingController(),
      PaymentMethod.card: TextEditingController(),
      PaymentMethod.digitalWallet: TextEditingController(),
    };

    final notesController = TextEditingController();
    final customerController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            _buildOrderSummary(context),
            
            const SizedBox(height: 24),
            
            // Customer information
            _buildCustomerSection(context, customerController),
            
            const SizedBox(height: 24),
            
            // Payment methods
            _buildPaymentSection(context, paymentAmounts),
            
            const SizedBox(height: 24),
            
            // Notes
            _buildNotesSection(context, notesController),
            
            const SizedBox(height: 24),
            
            // Payment summary
            _buildPaymentSummary(context, paymentAmounts),
            
            const SizedBox(height: 24),
            
            // Complete payment button
            _buildCompletePaymentButton(context, paymentAmounts, notesController, customerController),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Obx(() => Column(
              children: controller.cartItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.quantity.value}x ${item.displayName}'),
                    ),
                    Text('\$${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              )).toList(),
            )),
            
            const Divider(),
            
            Obx(() => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('\$${controller.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                if (controller.taxAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (${controller.taxRate.value}%):'),
                      Text('\$${controller.taxAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                if (controller.discountAmount.value > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:'),
                      Text('-\$${controller.discountAmount.value.toStringAsFixed(2)}'),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${controller.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, TextEditingController customerController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: customerController,
              decoration: const InputDecoration(
                labelText: 'Customer Name or Phone',
                border: OutlineInputBorder(),
                hintText: 'Enter customer details',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, Map<PaymentMethod, TextEditingController> paymentAmounts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...PaymentMethod.values.map((method) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(_getPaymentMethodLabel(method)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: paymentAmounts[method]!,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: const OutlineInputBorder(),
                        prefixText: '\$',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calculate),
                          onPressed: () => _setFullAmount(paymentAmounts[method]!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, TextEditingController notesController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Transaction Notes',
                border: OutlineInputBorder(),
                hintText: 'Add any notes about this transaction',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, Map<PaymentMethod, TextEditingController> paymentAmounts) {
    return ValueListenableBuilder(
      valueListenable: _createPaymentSummaryNotifier(paymentAmounts),
      builder: (context, _, __) {
        final totalPaid = _calculateTotalPaid(paymentAmounts);
        final remaining = controller.totalAmount - totalPaid;
        final change = totalPaid > controller.totalAmount ? totalPaid - controller.totalAmount : 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:'),
                    Text('\$${controller.totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:'),
                    Text('\$${totalPaid.toStringAsFixed(2)}'),
                  ],
                ),
                
                if (remaining > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining:'),
                      Text(
                        '\$${remaining.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                
                if (change > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change:'),
                      Text(
                        '\$${change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletePaymentButton(
    BuildContext context,
    Map<PaymentMethod, TextEditingController> paymentAmounts,
    TextEditingController notesController,
    TextEditingController customerController,
  ) {
    return ValueListenableBuilder(
      valueListenable: _createPaymentSummaryNotifier(paymentAmounts),
      builder: (context, _, __) {
        final totalPaid = _calculateTotalPaid(paymentAmounts);
        final canComplete = totalPaid >= controller.totalAmount;

        return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !canComplete || controller.isLoading.value
                ? null
                : () => _completePayment(paymentAmounts, notesController, customerController),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(canComplete ? 'Complete Payment' : 'Insufficient Payment'),
          ),
        ));
      },
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  void _setFullAmount(TextEditingController controller) {
    controller.text = this.controller.totalAmount.toStringAsFixed(2);
  }

  double _calculateTotalPaid(Map<PaymentMethod, TextEditingController> paymentAmounts) {
    return paymentAmounts.values.fold(0.0, (sum, controller) {
      final amount = double.tryParse(controller.text) ?? 0.0;
      return sum + amount;
    });
  }

  ValueNotifier<int> _createPaymentSummaryNotifier(Map<PaymentMethod, TextEditingController> paymentAmounts) {
    final notifier = ValueNotifier<int>(0);
    for (final controller in paymentAmounts.values) {
      controller.addListener(() => notifier.value++);
    }
    return notifier;
  }

  Future<void> _completePayment(
    Map<PaymentMethod, TextEditingController> paymentAmounts,
    TextEditingController notesController,
    TextEditingController customerController,
  ) async {
    // Create payment info list
    final payments = <PaymentInfo>[];
    
    for (final entry in paymentAmounts.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (amount > 0) {
        payments.add(PaymentInfo(
          method: entry.key,
          amount: amount,
        ));
      }
    }

    if (payments.isEmpty) {
      Get.snackbar('Error', 'Please enter payment amount');
      return;
    }

    final success = await controller.processTransaction(
      payments: payments,
      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      customerId: customerController.text.trim().isNotEmpty ? customerController.text.trim() : null,
    );

    if (success) {
      // Navigate back to POS or transactions
      Get.back(); // Back to POS
      Get.back(); // Back to transactions or dashboard
      
      Get.snackbar(
        'Success',
        'Payment completed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
