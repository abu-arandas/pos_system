import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class Location {
  final String id;
  final String name;
  final String address;
  final bool isActive;

  Location({
    required this.id,
    required this.name,
    required this.address,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'isActive': isActive,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class LocationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();
  final RxList<Location> locations = <Location>[].obs;
  final RxString currentLocationId = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocation();
    fetchLocations();
  }

  void _loadSavedLocation() {
    final savedLocationId = _storage.read('current_location_id');
    if (savedLocationId != null) {
      currentLocationId.value = savedLocationId;
    }
  }

  Future<void> fetchLocations() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore.collection('locations').get();
      locations.value =
          snapshot.docs.map((doc) => Location.fromMap({'id': doc.id, ...doc.data() as Map<String, dynamic>})).toList();

      // If no current location is set and locations exist, set the first one as current
      if (currentLocationId.isEmpty && locations.isNotEmpty) {
        setCurrentLocation(locations.first.id);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch locations: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void setCurrentLocation(String locationId) {
    currentLocationId.value = locationId;
    _storage.write('current_location_id', locationId);
    Get.snackbar('Location Changed', 'Current location has been updated', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> addLocation(Location location) async {
    try {
      isLoading.value = true;
      final docRef = await _firestore.collection('locations').add(location.toMap());
      locations.add(Location.fromMap({'id': docRef.id, ...location.toMap()}));

      // If this is the first location, set it as current
      if (locations.length == 1) {
        setCurrentLocation(docRef.id);
      }

      Get.snackbar('Success', 'Location added successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add location: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLocation(Location location) async {
    try {
      isLoading.value = true;
      await _firestore.collection('locations').doc(location.id).update(location.toMap());

      final index = locations.indexWhere((loc) => loc.id == location.id);
      if (index != -1) {
        locations[index] = location;
        locations.refresh();
      }

      Get.snackbar('Success', 'Location updated successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update location: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      // Don't allow deleting the current location
      if (locationId == currentLocationId.value) {
        Get.snackbar('Error', 'Cannot delete the current location', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      isLoading.value = true;
      await _firestore.collection('locations').doc(locationId).delete();
      locations.removeWhere((loc) => loc.id == locationId);

      Get.snackbar('Success', 'Location deleted successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete location: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Location? getCurrentLocation() {
    if (currentLocationId.isEmpty) return null;
    try {
      return locations.firstWhere((loc) => loc.id == currentLocationId.value);
    } catch (e) {
      return null;
    }
  }
}
