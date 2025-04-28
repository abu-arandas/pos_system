import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

class PaymentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final RxBool isLoading = false.obs;
  final RxString paymentStatus = ''.obs;
  final RxList<String> supportedPaymentMethods = <String>['stripe', 'cash', 'credit_card', 'mobile_payment'].obs;

  // Cloud Function URL for creating payment intents
  final String _paymentIntentUrl = 'https://us-central1-pos-system-12345.cloudfunctions.net/createPaymentIntent';

  Future<bool> processStripePayment(double amount, String currency) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'Processing payment...';

      // Create payment intent via Cloud Function
      final response = await http.post(
        Uri.parse(_paymentIntentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      final paymentIntentData = json.decode(response.body);
      final clientSecret = paymentIntentData['clientSecret'];

      // Show payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'POS System',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      paymentStatus.value = 'Payment successful';
      Get.snackbar('Success', 'Payment processed successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      if (e is StripeException) {
        paymentStatus.value = 'Payment failed: ${e.error.localizedMessage}';
      } else {
        paymentStatus.value = 'Payment failed: ${e.toString()}';
      }
      Get.snackbar('Error', paymentStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> processCashPayment(double amount) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'Processing cash payment...';

      // Show cash payment confirmation dialog
      final bool confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Cash Payment'),
              content: Text('Confirm cash payment of ${amount.toStringAsFixed(2)}?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) {
        paymentStatus.value = 'Payment cancelled';
        return false;
      }

      // Payment successful
      paymentStatus.value = 'Payment successful';
      Get.snackbar('Success', 'Cash payment processed successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      paymentStatus.value = 'Payment failed: ${e.toString()}';
      Get.snackbar('Error', paymentStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Record payment transaction in Firestore
  Future<String> recordPaymentTransaction(String saleId, String paymentMethod, double amount) async {
    try {
      final docRef = await _firestore.collection('payments').add({
        'saleId': saleId,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send payment notification
      await sendPaymentNotification(saleId, paymentMethod, amount);

      return docRef.id;
    } catch (e) {
      Get.snackbar('Error', 'Failed to record payment: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return '';
    }
  }

  // Process refund for a payment
  Future<bool> processRefund(String paymentId, double amount, String reason) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'Processing refund...';

      // Get the payment details
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();

      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final paymentData = paymentDoc.data()!;
      final paymentMethod = paymentData['paymentMethod'] as String;
      final originalAmount = paymentData['amount'] as double;

      // Validate refund amount
      if (amount > originalAmount) {
        throw Exception('Refund amount cannot exceed original payment amount');
      }

      // Process refund based on payment method
      bool refundSuccess = false;

      if (paymentMethod == 'stripe') {
        refundSuccess = await processStripeRefund(paymentId, amount);
      } else {
        // For cash and other payment methods, just record the refund
        refundSuccess = true;
      }

      if (refundSuccess) {
        // Record the refund in Firestore
        await _firestore.collection('refunds').add({
          'paymentId': paymentId,
          'amount': amount,
          'reason': reason,
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the original payment status
        await _firestore.collection('payments').doc(paymentId).update({
          'refundedAmount': FieldValue.increment(amount),
          'lastRefundDate': FieldValue.serverTimestamp(),
        });

        paymentStatus.value = 'Refund processed successfully';
        Get.snackbar('Success', 'Refund processed successfully', snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        paymentStatus.value = 'Refund failed';
        Get.snackbar('Error', 'Failed to process refund', snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      paymentStatus.value = 'Refund failed: ${e.toString()}';
      Get.snackbar('Error', paymentStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Process Stripe refund
  Future<bool> processStripeRefund(String paymentId, double amount) async {
    try {
      // Call Cloud Function to process Stripe refund
      final response = await http.post(
        Uri.parse('https://us-central1-pos-system-12345.cloudfunctions.net/processRefund'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentId': paymentId,
          'amount': (amount * 100).toInt(), // Convert to cents
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process Stripe refund: ${response.body}');
      }

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Stripe refund failed: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // Process payment with any supported payment method
  Future<bool> processPayment(String paymentMethod, double amount, String currency) async {
    switch (paymentMethod) {
      case 'stripe':
        return await processStripePayment(amount, currency);
      case 'cash':
        return await processCashPayment(amount);
      case 'credit_card':
        return await processCreditCardPayment(amount);
      case 'mobile_payment':
        return await processMobilePayment(amount);
      default:
        Get.snackbar('Error', 'Unsupported payment method', snackPosition: SnackPosition.BOTTOM);
        return false;
    }
  }

  // Process credit card payment (non-Stripe)
  Future<bool> processCreditCardPayment(double amount) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'Processing credit card payment...';

      // Show credit card payment dialog
      final bool confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Credit Card Payment'),
              content: Text('Confirm credit card payment of ${amount.toStringAsFixed(2)}?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) {
        paymentStatus.value = 'Payment cancelled';
        return false;
      }

      // Payment successful
      paymentStatus.value = 'Payment successful';
      Get.snackbar('Success', 'Credit card payment processed successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      paymentStatus.value = 'Payment failed: ${e.toString()}';
      Get.snackbar('Error', paymentStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Process mobile payment (Apple Pay, Google Pay, etc.)
  Future<bool> processMobilePayment(double amount) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'Processing mobile payment...';

      // Show mobile payment dialog
      final bool confirmed = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Mobile Payment'),
              content: Text('Confirm mobile payment of ${amount.toStringAsFixed(2)}?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) {
        paymentStatus.value = 'Payment cancelled';
        return false;
      }

      // Payment successful
      paymentStatus.value = 'Payment successful';
      Get.snackbar('Success', 'Mobile payment processed successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      paymentStatus.value = 'Payment failed: ${e.toString()}';
      Get.snackbar('Error', paymentStatus.value, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Send FCM notification for payment
  Future<void> sendPaymentNotification(String saleId, String paymentMethod, double amount) async {
    try {
      // Get admin FCM tokens
      final adminTokensSnapshot = await _firestore.collection('admin_tokens').get();
      final List<String> adminTokens = adminTokensSnapshot.docs.map((doc) => doc.data()['token'] as String).toList();

      if (adminTokens.isEmpty) return;

      // Prepare notification data
      final notificationData = {
        'title': 'New Payment',
        'body': 'New $paymentMethod payment of ${amount.toStringAsFixed(2)} received',
        'data': {
          'type': 'payment',
          'saleId': saleId,
          'amount': amount.toString(),
          'paymentMethod': paymentMethod,
        }
      };

      // Send to FCM via Cloud Function
      await http.post(
        Uri.parse('https://us-central1-your-project-id.cloudfunctions.net/sendNotification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tokens': adminTokens,
          'notification': notificationData,
        }),
      );
    } catch (e) {
      Get.snackbar('Notification Error', 'Failed to send payment notification: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
