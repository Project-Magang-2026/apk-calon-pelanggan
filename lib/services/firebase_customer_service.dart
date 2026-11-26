import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';

/// Layanan sinkronisasi data pelanggan & foto instalasi ke Cloud Firestore + Firebase Storage.
class FirebaseCustomerService {
  static const String customersCollection = 'customers';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection(customersCollection);

  /// Stream real-time seluruh data pelanggan/penugasan dari Firestore
  Stream<List<CustomerModel>> watchCustomers() {
    return _customersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Simpan atau perbarui data pelanggan di Firestore
  Future<void> upsertCustomer(CustomerModel customer) async {
    await _customersRef.doc(customer.id).set(
          customer.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Perbarui sebagian field di dokumen pelanggan
  Future<void> updateFields(String customerId, Map<String, dynamic> fields) async {
    await _customersRef.doc(customerId).update(fields);
  }

  /// Upload foto bukti pemasangan ke Firebase Storage dan kembalikan URL publiknya
  Future<String?> uploadInstallationPhoto({
    required String customerId,
    required String localPath,
  }) async {
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }
    if (kIsWeb) return localPath;

    final file = File(localPath);
    if (!await file.exists()) return null;

    final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('installations/$customerId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
