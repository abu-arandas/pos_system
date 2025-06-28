import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .orderBy('name')
          .get();
      
      categories.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Category.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch categories: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      isLoading.value = true;
      final docRef = await _firestore.collection('categories').add(category.toMap());
      
      // Add to local list
      final newCategory = category.copyWith(id: docRef.id);
      categories.add(newCategory);
      categories.sort((a, b) => a.name.compareTo(b.name));
      
      Get.snackbar('Success', 'Category added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add category: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCategory(String id, Category category) async {
    try {
      isLoading.value = true;
      await _firestore.collection('categories').doc(id).update(category.toMap());
      
      // Update local list
      final index = categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        categories[index] = category.copyWith(id: id);
        categories.sort((a, b) => a.name.compareTo(b.name));
      }
      
      Get.snackbar('Success', 'Category updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update category: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      isLoading.value = true;
      
      // Check if category is being used by any products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: id)
          .limit(1)
          .get();
      
      if (productsSnapshot.docs.isNotEmpty) {
        Get.snackbar(
          'Cannot Delete',
          'This category is being used by products. Please remove products first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      await _firestore.collection('categories').doc(id).delete();
      
      // Remove from local list
      categories.removeWhere((c) => c.id == id);
      
      Get.snackbar('Success', 'Category deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}