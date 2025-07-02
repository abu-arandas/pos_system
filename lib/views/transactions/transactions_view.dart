import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../services/security_service.dart';
import '../../models/transaction_model.dart';
import 'pos_view.dart';
import 'transaction_detail_view.dart';

class TransactionsView extends GetView<TransactionController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(TransactionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // New Sale button
          if (Get.find<SecurityService>().hasPermission(Permission.processTransactions))
            IconButton(
              icon: const Icon(Icons.point_of_sale),
              onPressed: () => Get.to(() => const POSView()),
              tooltip: 'New Sale',
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats section
          _buildStatsSection(context),

          // Transactions list
          Expanded(
            child: _buildTransactionsList(context),
          ),
        ],
      ),
      floatingActionButton: Get.find<SecurityService>().hasPermission(Permission.processTransactions)
          ? FloatingActionButton(
              onPressed: () => Get.to(() => const POSView()),
              tooltip: 'New Sale',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Obx(() {
      final todayTransactions = controller.transactions.where((t) {
        final today = DateTime.now();
        final transactionDate = t.createdAt;
        return transactionDate.year == today.year &&
            transactionDate.month == today.month &&
            transactionDate.day == today.day;
      }).toList();

      final todaySales =
          todayTransactions.where((t) => t.status == TransactionStatus.completed).fold(0.0, (sum, t) => sum + t.total);

      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Today\'s Sales',
                '\$${todaySales.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Today\'s Orders',
                '${todayTransactions.length}',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Total Orders',
                '${controller.transactions.length}',
                Icons.list_alt,
                Colors.orange,
              ),
            ),
          ],
        ),
      );
    });
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

  Widget _buildTransactionsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.transactions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (Get.find<SecurityService>().hasPermission(Permission.processTransactions))
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const POSView()),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Start Selling'),
                ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadTransactions(refresh: true),
        child: ListView.builder(
          itemCount: controller.transactions.length + (controller.hasMoreTransactions.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.transactions.length) {
              // Load more button
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => controller.loadTransactions(),
                  child: const Text('Load More'),
                ),
              );
            }

            final transaction = controller.transactions[index];
            return _buildTransactionCard(context, transaction);
          },
        ),
      );
    });
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(transaction.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(transaction.status),
            color: _getStatusColor(transaction.status),
          ),
        ),
        title: Text(
          'Receipt #${transaction.receiptNumber ?? transaction.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${transaction.total.toStringAsFixed(2)}'),
            Text(
              '${transaction.totalItems} items • ${_formatDate(transaction.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(transaction.status),
                    style: TextStyle(
                      color: _getStatusColor(transaction.status),
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
          onSelected: (value) => _handleTransactionAction(value, transaction),
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
        onTap: () => Get.to(() => TransactionDetailView(transaction: transaction)),
      ),
    );
  }

  void _handleTransactionAction(String action, TransactionModel transaction) {
    switch (action) {
      case 'view':
        Get.to(() => TransactionDetailView(transaction: transaction));
        break;
      case 'refund':
        _showRefundConfirmation(transaction);
        break;
    }
  }

  void _showRefundConfirmation(TransactionModel transaction) {
    Get.dialog(
      AlertDialog(
        title: const Text('Refund Transaction'),
        content: Text(
          'Are you sure you want to refund this transaction?\n\n'
          'Amount: \$${transaction.total.toStringAsFixed(2)}\n'
          'Receipt: ${transaction.receiptNumber ?? transaction.id.substring(0, 8)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.refundTransaction(transaction.id);
              Get.back();
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

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      case TransactionStatus.refunded:
        return Icons.undo;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
