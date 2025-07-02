import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;


  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate loading time
      await Future.delayed(const Duration(seconds: 2));

      // Check if user is already authenticated
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is authenticated, navigate to dashboard
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        // User is not authenticated, navigate to login
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      // Handle initialization error
      Get.snackbar(
        'Error',
        'Failed to initialize app: $e',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to login on error
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }
}
