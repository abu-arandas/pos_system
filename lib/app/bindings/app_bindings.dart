import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/loyalty_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers that should be available throughout the app
    Get.put(AuthController(), permanent: true);

    // Initialize customer controller for loyalty features
    Get.lazyPut<CustomerController>(() => CustomerController());

    // Initialize loyalty controller after customer controller
    Get.lazyPut<LoyaltyController>(() => LoyaltyController());
  }
}
