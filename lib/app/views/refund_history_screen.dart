import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/refund_controller.dart';

class RefundHistoryScreen extends StatelessWidget {
  final RefundController refundController = Get.find<RefundController>();
  final String saleId;

  RefundHistoryScreen({
    super.key,
    required this.saleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: refundController.getRefundHistory(saleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading refund history: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final refunds = snapshot.data ?? [];

          if (refunds.isEmpty) {
            return const Center(
              child: Text(
                'No refunds found for this sale',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: refunds.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final refund = refunds[index];
              final timestamp = refund['timestamp'] as Timestamp;
              final date = timestamp.toDate();
              final amount = refund['amount'] as double;
              final reason = refund['reason'] as String;
              final type = refund['type'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type == 'full' ? 'Full Refund' : 'Partial Refund',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${date.toString().substring(0, 16)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text('Reason: $reason'),

                      // Show refunded items for partial refunds
                      if (type == 'partial' && refund.containsKey('refundedItems')) ...{
                        const SizedBox(height: 16),
                        const Text(
                          'Refunded Items:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(refund['refundedItems'] as List).map((item) {
                          final quantity = item['quantity'] as int;
                          final price = item['price'] as double;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${quantity}x Item'),
                                Text('\$${price.toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }),
                      },
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
