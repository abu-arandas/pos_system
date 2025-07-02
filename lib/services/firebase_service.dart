import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirebaseService extends GetxService {
  // Firebase instances
  late final FirebaseFirestore _firestore;

  // Getters for Firebase instances
  FirebaseFirestore get firestore => _firestore;

  @override
  Future<void> onInit() async {
    super.onInit();
    _initializeFirebase();
  }

  void _initializeFirebase() {
    _firestore = FirebaseFirestore.instance;

    // Configure Firestore settings
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collection references
  CollectionReference get businessesCollection => _firestore.collection('businesses');
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get storesCollection => _firestore.collection('stores');
  CollectionReference get productsCollection => _firestore.collection('products');
  CollectionReference get transactionsCollection => _firestore.collection('transactions');
  CollectionReference get customersCollection => _firestore.collection('customers');

  // Generic CRUD operations
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Stream<DocumentSnapshot> getDocumentStream(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Future<QuerySnapshot> getCollection(String collection, {Query? query}) async {
    try {
      if (query != null) {
        return await query.get();
      }
      return await _firestore.collection(collection).get();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  Stream<QuerySnapshot> getCollectionStream(String collection, {Query? query}) {
    if (query != null) {
      return query.snapshots();
    }
    return _firestore.collection(collection).snapshots();
  }

  // Batch operations
  WriteBatch batch() => _firestore.batch();

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to commit batch: $e');
    }
  }

  // Transaction operations
  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }
}
