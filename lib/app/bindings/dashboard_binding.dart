import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/customer_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<InventoryController>(() => InventoryController());
    Get.lazyPut<SalesController>(() => SalesController());
    Get.lazyPut<CustomerController>(() => CustomerController());
  }
}
