import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/customer_model.dart';

class CustomerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore.collection('customers').get();
      customers.value = snapshot.docs.map((doc) => Customer.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch customers: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').add(customer.toMap());
      await fetchCustomers();
      Get.snackbar('Success', 'Customer added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add customer: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').doc(id).update(customer.toMap());
      await fetchCustomers();
      Get.snackbar('Success', 'Customer updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update customer: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').doc(id).delete();
      await fetchCustomers();
      Get.snackbar('Success', 'Customer deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete customer: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLoyaltyPoints(String customerId, int points) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').doc(customerId).update({
        'loyaltyPoints': FieldValue.increment(points),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchCustomers();
      Get.snackbar('Success', 'Loyalty points added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add loyalty points: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> redeemLoyaltyPoints(String customerId, int points) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').doc(customerId).update({
        'loyaltyPoints': FieldValue.increment(-points),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchCustomers();
      Get.snackbar('Success', 'Loyalty points redeemed successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to redeem loyalty points: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
