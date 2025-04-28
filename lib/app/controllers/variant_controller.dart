import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/variant_model.dart';

class VariantController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();
  final RxMap<String, List<Variant>> productVariants = <String, List<Variant>>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with cached data if available
    _loadCachedVariants();
  }

  void _loadCachedVariants() {
    final cachedData = _storage.read('product_variants');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(cachedData);
        data.forEach((productId, variants) {
          productVariants[productId] =
              (variants as List).map((v) => Variant.fromMap(Map<String, dynamic>.from(v))).toList();
        });
      } catch (e) {
        Get.snackbar('Error', 'Failed to load cached variants: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _cacheVariants() {
    try {
      final Map<String, dynamic> dataToCache = {};
      productVariants.forEach((productId, variants) {
        dataToCache[productId] = variants.map((v) => v.toMap()).toList();
      });
      _storage.write('product_variants', dataToCache);
    } catch (e) {
      Get.snackbar('Error', 'Failed to cache variants: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> fetchVariantsForProduct(String productId) async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot =
          await _firestore.collection('products').doc(productId).collection('variants').get();

      final variants = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Variant.fromMap({'id': doc.id, ...data});
      }).toList();

      productVariants[productId] = variants;
      _cacheVariants();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch variants: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addVariant(Variant variant) async {
    try {
      isLoading.value = true;
      final docRef =
          await _firestore.collection('products').doc(variant.productId).collection('variants').add(variant.toMap());

      final newVariant = variant.copyWith(id: docRef.id);
      if (productVariants.containsKey(variant.productId)) {
        productVariants[variant.productId]!.add(newVariant);
      } else {
        productVariants[variant.productId] = [newVariant];
      }

      _cacheVariants();
      Get.snackbar('Success', 'Variant added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add variant: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateVariant(Variant variant) async {
    try {
      isLoading.value = true;
      await _firestore
          .collection('products')
          .doc(variant.productId)
          .collection('variants')
          .doc(variant.id)
          .update(variant.toMap());

      if (productVariants.containsKey(variant.productId)) {
        final index = productVariants[variant.productId]!.indexWhere((v) => v.id == variant.id);
        if (index != -1) {
          productVariants[variant.productId]![index] = variant;
          productVariants.refresh();
        }
      }

      _cacheVariants();
      Get.snackbar('Success', 'Variant updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update variant: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    try {
      isLoading.value = true;
      await _firestore.collection('products').doc(productId).collection('variants').doc(variantId).delete();

      if (productVariants.containsKey(productId)) {
        productVariants[productId]!.removeWhere((v) => v.id == variantId);
        productVariants.refresh();
      }

      _cacheVariants();
      Get.snackbar('Success', 'Variant deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete variant: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStock(String productId, String variantId, int newStock) async {
    try {
      isLoading.value = true;
      await _firestore.collection('products').doc(productId).collection('variants').doc(variantId).update({
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (productVariants.containsKey(productId)) {
        final index = productVariants[productId]!.indexWhere((v) => v.id == variantId);
        if (index != -1) {
          final variant = productVariants[productId]![index];
          productVariants[productId]![index] = variant.copyWith(
            stock: newStock,
            updatedAt: DateTime.now(),
          );
          productVariants.refresh();
        }
      }

      _cacheVariants();
      Get.snackbar('Success', 'Stock updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update stock: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Variant?> lookupBySKU(String sku) async {
    try {
      isLoading.value = true;
      // First check in local cache
      for (final variants in productVariants.values) {
        try {
          final variant = variants.firstWhere((v) => v.sku == sku);
          return variant;
        } catch (e) {
          // Variant not found in this product, continue to next product
          continue;
        }
      }

      // If not found in cache, query Firestore
      final QuerySnapshot snapshot =
          await _firestore.collectionGroup('variants').where('sku', isEqualTo: sku).limit(1).get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final productId = doc.reference.parent.parent!.id;

      return Variant.fromMap({'id': doc.id, 'productId': productId, ...data});
    } catch (e) {
      Get.snackbar('Error', 'Failed to lookup SKU: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
