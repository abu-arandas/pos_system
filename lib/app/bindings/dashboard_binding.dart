import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/variant_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/loyalty_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers
    Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<VariantController>(() => VariantController());
    Get.lazyPut<InventoryController>(() => InventoryController());

    // Sales and customer related controllers
    Get.lazyPut<SalesController>(() => SalesController());
    Get.lazyPut<CheckoutController>(() => CheckoutController());
    Get.lazyPut<CustomerController>(() => CustomerController());
    Get.lazyPut<LoyaltyController>(() => LoyaltyController());
  }
}
