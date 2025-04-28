import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/refund_controller.dart';
import '../models/sale_model.dart';

class RefundScreen extends StatelessWidget {
  final RefundController refundController = Get.find<RefundController>();
  final String saleId;
  final Sale sale;

  RefundScreen({
    super.key,
    required this.saleId,
    required this.sale,
  });

  final TextEditingController _reasonController = TextEditingController();
  final RxBool _isFullRefund = true.obs;
  final RxList<Map<String, dynamic>> _selectedItems = <Map<String, dynamic>>[].obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Refund'),
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sale information
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale ID: $saleId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Date: ${sale.createdAt.toString().substring(0, 16)}'),
                      const SizedBox(height: 8),
                      Text('Payment Method: ${sale.paymentMethod}'),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: \$${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Refund type selection
              const Text(
                'Refund Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isFullRefund.value,
                    onChanged: (value) {
                      if (value != null) {
                        _isFullRefund.value = value;
                        _selectedItems.clear();
                      }
                    },
                  ),
                  const Text('Full Refund'),
                  const SizedBox(width: 20),
                  Radio<bool>(
                    value: false,
                    groupValue: _isFullRefund.value,
                    onChanged: (value) {
                      if (value != null) {
                        _isFullRefund.value = value;
                      }
                    },
                  ),
                  const Text('Partial Refund'),
                ],
              ),

              // Item selection for partial refund
              if (!_isFullRefund.value) ...[
                const SizedBox(height: 16),
                const Text(
                  'Select Items to Refund',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sale.items.length,
                    itemBuilder: (context, index) {
                      final item = sale.items[index];
                      final isSelected = _selectedItems.any(
                        (element) => element['productId'] == item.product.id,
                      );

                      return CheckboxListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                          '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}',
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          if (value == true) {
                            _selectedItems.add({
                              'productId': item.product.id,
                              'quantity': item.quantity,
                              'price': item.product.price,
                            });
                          } else {
                            _selectedItems.removeWhere(
                              (element) => element['productId'] == item.product.id,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ] else ...{
                const SizedBox(height: 16),
                const Text(
                  'All items will be refunded',
                  style: TextStyle(fontSize: 16),
                ),
              },

              // Reason for refund
              const SizedBox(height: 20),
              const Text(
                'Reason for Refund',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for refund',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              // Process refund button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: refundController.isProcessing.value ? null : () => _processRefund(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: refundController.isProcessing.value
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Process Refund',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _processRefund(BuildContext context) async {
    if (_reasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a reason for the refund',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_isFullRefund.value && _selectedItems.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one item to refund',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final String reason = _reasonController.text.trim();
    bool success;

    if (_isFullRefund.value) {
      // Process full refund
      success = await refundController.processFullRefund(saleId, reason);
    } else {
      // Process partial refund
      success = await refundController.processPartialRefund(
        saleId,
        _selectedItems,
        reason,
      );
    }

    if (success) {
      // Navigate back to previous screen
      Get.back(result: true);
    }
  }
}
