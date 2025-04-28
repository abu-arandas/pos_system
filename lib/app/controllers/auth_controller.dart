import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxList<String> _userRoles = <String>[].obs;
  RxString email = ''.obs;
  RxString password = ''.obs;

  User? get user => _user.value;
  List<String> get userRoles => _userRoles.toList();

  @override
  void onInit() {
    _user.bindStream(_auth.authStateChanges());
    ever(_user, _onUserChanged);
    super.onInit();
  }

  void _onUserChanged(User? user) async {
    if (user != null) {
      // Fetch custom claims (roles)
      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims;

      // Extract roles from claims
      if (claims != null && claims['roles'] != null) {
        if (claims['roles'] is List) {
          _userRoles.value = List<String>.from(claims['roles']);
        } else if (claims['roles'] is Map) {
          _userRoles.value = (claims['roles'] as Map)
              .entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList();
        }
      } else {
        // Default role if none specified
        _userRoles.value = ['user'];
      }
    } else {
      _userRoles.clear();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
