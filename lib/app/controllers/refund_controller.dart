import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'inventory_controller.dart';
import 'payment_controller.dart';

class RefundController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentController _paymentController = Get.find<PaymentController>();
  final InventoryController _inventoryController = Get.find<InventoryController>();

  final RxBool isProcessing = false.obs;
  final RxString refundStatus = ''.obs;

  // Process a full refund for a sale
  Future<bool> processFullRefund(String saleId, String reason) async {
    try {
      isProcessing.value = true;
      refundStatus.value = 'Processing full refund...';

      // Get the sale details
      final saleDoc = await _firestore.collection('sales').doc(saleId).get();

      if (!saleDoc.exists) {
        throw Exception('Sale not found');
      }

      final saleData = saleDoc.data()!;
      final double totalAmount = saleData['total'] as double;
      final String paymentMethod = saleData['paymentMethod'] as String;

      // Get the payment record for this sale
      final paymentsSnapshot =
          await _firestore.collection('payments').where('saleId', isEqualTo: saleId).limit(1).get();

      if (paymentsSnapshot.docs.isEmpty) {
        throw Exception('Payment record not found for this sale');
      }

      final paymentDoc = paymentsSnapshot.docs.first;
      final String paymentId = paymentDoc.id;

      // Process the refund through payment controller
      final bool refundSuccess = await _paymentController.processRefund(
        paymentId,
        totalAmount,
        reason,
      );

      if (refundSuccess) {
        // Update inventory (return items to stock)
        await _updateInventoryForRefund(saleId);

        // Update sale status
        await _firestore.collection('sales').doc(saleId).update({
          'status': 'refunded',
          'refundReason': reason,
          'refundDate': FieldValue.serverTimestamp(),
        });

        refundStatus.value = 'Refund processed successfully';
        Get.snackbar('Success', 'Refund processed successfully', snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        refundStatus.value = 'Refund failed';
        return false;
      }
    } catch (e) {
      refundStatus.value = 'Refund failed: ${e.toString()}';
      Get.snackbar('Error', refundStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // Process a partial refund for specific items in a sale
  Future<bool> processPartialRefund(String saleId, List<Map<String, dynamic>> refundItems, String reason) async {
    try {
      isProcessing.value = true;
      refundStatus.value = 'Processing partial refund...';

      // Get the sale details
      final saleDoc = await _firestore.collection('sales').doc(saleId).get();

      if (!saleDoc.exists) {
        throw Exception('Sale not found');
      }

      final saleData = saleDoc.data()!;
      final String paymentMethod = saleData['paymentMethod'] as String;

      // Calculate refund amount
      double refundAmount = 0.0;
      for (final item in refundItems) {
        final double price = item['price'] as double;
        final int quantity = item['quantity'] as int;
        refundAmount += price * quantity;
      }

      // Get the payment record for this sale
      final paymentsSnapshot =
          await _firestore.collection('payments').where('saleId', isEqualTo: saleId).limit(1).get();

      if (paymentsSnapshot.docs.isEmpty) {
        throw Exception('Payment record not found for this sale');
      }

      final paymentDoc = paymentsSnapshot.docs.first;
      final String paymentId = paymentDoc.id;

      // Process the refund through payment controller
      final bool refundSuccess = await _paymentController.processRefund(
        paymentId,
        refundAmount,
        reason,
      );

      if (refundSuccess) {
        // Update inventory for refunded items
        await _updateInventoryForPartialRefund(refundItems);

        // Record the partial refund details
        await _firestore.collection('partial_refunds').add({
          'saleId': saleId,
          'paymentId': paymentId,
          'refundedItems': refundItems,
          'refundAmount': refundAmount,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update sale status
        await _firestore.collection('sales').doc(saleId).update({
          'partiallyRefunded': true,
          'lastRefundDate': FieldValue.serverTimestamp(),
        });

        refundStatus.value = 'Partial refund processed successfully';
        Get.snackbar('Success', 'Partial refund processed successfully', snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        refundStatus.value = 'Refund failed';
        return false;
      }
    } catch (e) {
      refundStatus.value = 'Refund failed: ${e.toString()}';
      Get.snackbar('Error', refundStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // Update inventory for a full refund
  Future<void> _updateInventoryForRefund(String saleId) async {
    try {
      // Get the sale items
      final saleDoc = await _firestore.collection('sales').doc(saleId).get();
      final saleData = saleDoc.data()!;
      final List<dynamic> items = saleData['items'] as List<dynamic>;

      // Return each item to inventory
      for (final item in items) {
        final String productId = item['productId'] as String;
        final int quantity = item['quantity'] as int;

        // Add the quantity back to inventory
        await _inventoryController.updateStock(productId, quantity);
      }
    } catch (e) {
      Get.snackbar('Inventory Error', 'Error updating inventory for refund: $e', snackPosition: SnackPosition.BOTTOM);
      rethrow;
    }
  }

  // Update inventory for a partial refund
  Future<void> _updateInventoryForPartialRefund(List<Map<String, dynamic>> refundItems) async {
    try {
      // Return each refunded item to inventory
      for (final item in refundItems) {
        final String productId = item['productId'] as String;
        final int quantity = item['quantity'] as int;

        // Add the quantity back to inventory
        await _inventoryController.updateStock(productId, quantity);
      }
    } catch (e) {
      Get.snackbar('Inventory Error', 'Error updating inventory for partial refund: $e', snackPosition: SnackPosition.BOTTOM);
      rethrow;
    }
  }

  // Get refund history for a sale
  Future<List<Map<String, dynamic>>> getRefundHistory(String saleId) async {
    try {
      final List<Map<String, dynamic>> refundHistory = [];

      // Get full refunds
      final fullRefundsSnapshot = await _firestore.collection('refunds').where('saleId', isEqualTo: saleId).get();

      for (final doc in fullRefundsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'full';
        refundHistory.add(data);
      }

      // Get partial refunds
      final partialRefundsSnapshot =
          await _firestore.collection('partial_refunds').where('saleId', isEqualTo: saleId).get();

      for (final doc in partialRefundsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'partial';
        refundHistory.add(data);
      }

      // Sort by timestamp
      refundHistory.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp;
        final bTimestamp = b['timestamp'] as Timestamp;
        return bTimestamp.compareTo(aTimestamp);
      });

      return refundHistory;
    } catch (e) {
      Get.snackbar('History Error', 'Error getting refund history: $e', snackPosition: SnackPosition.BOTTOM);
      return [];
    }
  }
}
