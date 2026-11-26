import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Helper inisialisasi Firebase yang aman.
/// Jika file konfigurasi Firebase (google-services.json / firebase_options.dart)
/// belum ditambahkan, aplikasi otomatis berjalan dalam mode simulasi lokal.
class FirebaseBootstrap {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized && Firebase.apps.isNotEmpty;

  static Future<bool> init() async {
    if (isInitialized) return true;

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('[FirebaseBootstrap] Firebase berhasil diinisialisasi.');
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint(
        '[FirebaseBootstrap] Konfigurasi Firebase belum aktif ($e). '
        'Berjalan menggunakan mode simulasi lokal.',
      );
      return false;
    }
  }
}
