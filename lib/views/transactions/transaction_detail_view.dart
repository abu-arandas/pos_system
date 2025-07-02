import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/transaction_model.dart';
import '../../services/security_service.dart';

class TransactionDetailView extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailView({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${transaction.receiptNumber ?? transaction.id.substring(0, 8)}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Receipt'),
                  ],
                ),
              ),
              if (Get.find<SecurityService>().hasPermission(Permission.refundTransactions) &&
                  transaction.status == TransactionStatus.completed)
                const PopupMenuItem(
                  value: 'refund',
                  child: Row(
                    children: [
                      Icon(Icons.undo, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Refund', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction header
            _buildTransactionHeader(context),
            
            const SizedBox(height: 24),
            
            // Items section
            _buildItemsSection(context),
            
            const SizedBox(height: 24),
            
            // Payment section
            _buildPaymentSection(context),
            
            const SizedBox(height: 24),
            
            // Summary section
            _buildSummarySection(context),
            
            if (transaction.notes != null) ...[
              const SizedBox(height: 24),
              _buildNotesSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusLabel(transaction.status),
                    style: TextStyle(
                      color: _getStatusColor(transaction.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Receipt Number', transaction.receiptNumber ?? 'N/A'),
            _buildInfoRow('Date', _formatDateTime(transaction.createdAt)),
            _buildInfoRow('Cashier ID', transaction.cashierId),
            if (transaction.customerId != null)
              _buildInfoRow('Customer', transaction.customerId!),
            _buildInfoRow('Store ID', transaction.storeId),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${transaction.totalItems})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...transaction.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (item.variantName != null)
                          Text(
                            'Variant: ${item.variantName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity}x',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '\$${item.unitPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildPaymentSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...transaction.payments.map((payment) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getPaymentMethodLabel(payment.method)),
                  Text('\$${payment.amount.toStringAsFixed(2)}'),
                ],
              ),
            )),
            
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Paid:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${transaction.totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (transaction.needsChange)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Given:'),
                  Text(
                    '\$${transaction.changeAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildSummaryRow('Subtotal', '\$${transaction.subtotal.toStringAsFixed(2)}'),
            
            if (transaction.taxAmount > 0)
              _buildSummaryRow('Tax', '\$${transaction.taxAmount.toStringAsFixed(2)}'),
            
            if (transaction.discountAmount > 0)
              _buildSummaryRow('Discount', '-\$${transaction.discountAmount.toStringAsFixed(2)}'),
            
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${transaction.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(transaction.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.cancelled:
        return Colors.grey;
      case TransactionStatus.refunded:
        return Colors.red;
    }
  }

  String _getStatusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleAction(String action) {
    switch (action) {
      case 'print':
        Get.snackbar(
          'Print Receipt',
          'Receipt printing feature will be implemented in a future update.',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      case 'refund':
        _showRefundDialog();
        break;
    }
  }

  void _showRefundDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Refund Transaction'),
        content: Text(
          'Are you sure you want to refund this transaction?\n\n'
          'Amount: \$${transaction.total.toStringAsFixed(2)}\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle refund logic here
              Get.back();
              Get.snackbar(
                'Refund Processed',
                'Transaction has been refunded successfully.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }
}
