import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../services/security_service.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final SecurityService _securityService = Get.find<SecurityService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await _firebaseService.getDocument('users', userId);

      if (userDoc.exists) {
        final userData = UserModel.fromFirestore(userDoc);
        currentUser.value = userData;
        _securityService.setCurrentUser(userData);
        isLoggedIn.value = true;
      } else {
        // User document doesn't exist, sign out
        await signOut();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      await signOut();
    }
  }

  void _clearUserData() {
    currentUser.value = null;
    _securityService.clearCurrentUser();
    isLoggedIn.value = false;
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      isLoading.value = true;

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // User data will be loaded automatically by the auth state listener
        Get.offAllNamed(AppRoutes.dashboard);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Register new user and business
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String businessName,
  }) async {
    try {
      isLoading.value = true;

      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      final userId = credential.user!.uid;

      // Create user document
      final userData = UserModel(
        id: userId,
        email: email.trim(),
        firstName: firstName,
        lastName: lastName,
        role: UserRole.admin, // First user is always admin
        businessId: businessName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.setDocument('users', userId, userData.toMap());

      // Update Firebase Auth display name
      await credential.user!.updateDisplayName('$firstName $lastName');

      Get.offAllNamed(AppRoutes.dashboard);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registration failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      Get.snackbar(
        'Success',
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message}';
    }

    Get.snackbar(
      'Authentication Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Check if user is authenticated
  bool get isAuthenticated => isLoggedIn.value && currentUser.value != null;

  // Get current user role
  UserRole? get currentUserRole => currentUser.value?.role;

  // Check if current user has permission
  bool hasPermission(Permission permission) {
    return _securityService.hasPermission(permission);
  }
}
