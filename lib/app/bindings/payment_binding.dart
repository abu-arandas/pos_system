import 'package:get/get.dart';
import '../controllers/payment_controller.dart';
import '../controllers/refund_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/inventory_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure inventory controller is available for refund operations
    Get.lazyPut<InventoryController>(() => InventoryController());

    // Initialize payment controller
    Get.lazyPut<PaymentController>(() => PaymentController());

    // Initialize checkout controller if not already initialized
    if (!Get.isRegistered<CheckoutController>()) {
      Get.lazyPut<CheckoutController>(() => CheckoutController());
    }

    // Initialize refund controller
    Get.lazyPut<RefundController>(() => RefundController());
  }
}
