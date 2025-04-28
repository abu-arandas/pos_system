import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';

class LoyaltyController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerController _customerController = Get.find<CustomerController>();
  final RxInt points = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedCustomerId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to changes in selected customer
    ever(selectedCustomerId, (_) => _loadCustomerPoints());
  }

  void selectCustomer(String customerId) {
    selectedCustomerId.value = customerId;
  }

  void _loadCustomerPoints() {
    if (selectedCustomerId.isEmpty) {
      points.value = 0;
      return;
    }

    try {
      try {
        final customer = _customerController.customers.firstWhere(
          (c) => c.id == selectedCustomerId.value,
        );
        points.value = customer.loyaltyPoints;
      } catch (e) {
        // Customer not found
        points.value = 0;
      }
    } catch (e) {
      points.value = 0;
    }
  }

  Future<void> addPoints(String customerId, int pointsToAdd, {String? reason}) async {
    if (pointsToAdd <= 0) return;

    try {
      isLoading.value = true;

      // Update customer document
      await _firestore.collection('customers').doc(customerId).update({
        'loyaltyPoints': FieldValue.increment(pointsToAdd),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Record loyalty transaction
      await _firestore.collection('loyalty_transactions').add({
        'customerId': customerId,
        'points': pointsToAdd,
        'type': 'earn',
        'reason': reason ?? 'Purchase',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Update local state if this is the selected customer
      if (customerId == selectedCustomerId.value) {
        points.value += pointsToAdd;
      }

      // Refresh customers list
      await _customerController.fetchCustomers();

      Get.snackbar(
        'Success',
        '$pointsToAdd points added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add points: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> redeemPoints(String customerId, int pointsToRedeem, {String? reason}) async {
    if (pointsToRedeem <= 0) return false;

    try {
      isLoading.value = true;

      // Check if customer has enough points
      final customerDoc = await _firestore.collection('customers').doc(customerId).get();
      final customerData = customerDoc.data();
      if (customerData == null) return false;

      final currentPoints = customerData['loyaltyPoints'] ?? 0;
      if (currentPoints < pointsToRedeem) {
        Get.snackbar(
          'Error',
          'Not enough loyalty points',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Update customer document
      await _firestore.collection('customers').doc(customerId).update({
        'loyaltyPoints': FieldValue.increment(-pointsToRedeem),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Record loyalty transaction
      await _firestore.collection('loyalty_transactions').add({
        'customerId': customerId,
        'points': -pointsToRedeem,
        'type': 'redeem',
        'reason': reason ?? 'Discount',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Update local state if this is the selected customer
      if (customerId == selectedCustomerId.value) {
        points.value -= pointsToRedeem;
      }

      // Refresh customers list
      await _customerController.fetchCustomers();

      Get.snackbar(
        'Success',
        '$pointsToRedeem points redeemed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to redeem points: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getLoyaltyHistory(String customerId) async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore
          .collection('loyalty_transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch loyalty history: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate points based on purchase amount
  int calculatePointsForPurchase(double amount) {
    // Example: 1 point for every $10 spent
    return (amount / 10).floor();
  }
}
