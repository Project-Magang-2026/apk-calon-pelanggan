import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../utils/constants.dart';
import 'firebase_bootstrap.dart';
import 'firebase_customer_service.dart';
import 'geo_calculation_service.dart';

class CustomerRepository extends ChangeNotifier {
  // Singleton pattern agar state sinkron di seluruh halaman
  static final CustomerRepository _instance = CustomerRepository._internal();
  factory CustomerRepository() => _instance;

  CustomerRepository._internal() {
    _seedInitialData();
  }

  final List<CustomerModel> _customers = [];
  final FirebaseCustomerService _firebaseService = FirebaseCustomerService();
  StreamSubscription<List<CustomerModel>>? _firestoreSubscription;

  bool get isUsingFirebase => FirebaseBootstrap.isInitialized;

  /// Aktifkan sinkronisasi real-time dengan Cloud Firestore jika Firebase siap
  void enableFirebaseSync() {
    if (!isUsingFirebase) return;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firebaseService.watchCustomers().listen(
      (remoteCustomers) {
        if (remoteCustomers.isNotEmpty) {
          _customers
            ..clear()
            ..addAll(remoteCustomers);
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('[CustomerRepository] Firestore sync error: $e');
      },
    );
  }

  void _syncCustomerToFirebase(CustomerModel customer) {
    if (!isUsingFirebase) return;
    _firebaseService.upsertCustomer(customer).catchError((e) {
      debugPrint('[CustomerRepository] Gagal simpan ke Firestore: $e');
    });
  }

  // Stream controller untuk mendeteksi data baru (Simulasi Firebase Real-time dari Web)
  final StreamController<CustomerModel> _newCustomerStreamController =
      StreamController<CustomerModel>.broadcast();
  Stream<CustomerModel> get onNewCustomerAdded => _newCustomerStreamController.stream;

  List<CustomerModel> get allCustomers => List.unmodifiable(_customers);

  List<CustomerModel> getCustomersByStatus(CustomerStatus status) {
    return _customers.where((c) => c.status == status).toList();
  }

  List<CustomerModel> getJobsForTechnician(String technicianName) {
    return _customers
        .where((c) =>
            (c.status == CustomerStatus.dijadwalkan ||
             c.status == CustomerStatus.progresInstalasi ||
             c.status == CustomerStatus.menungguVerifikasi ||
             c.status == CustomerStatus.selesai) &&
            (c.assignedTechnician != null &&
             c.assignedTechnician!.toLowerCase().contains(technicianName.toLowerCase())))
        .toList();
  }

  CustomerModel? findByCodeOrPhone(String query) {
    final cleanQuery = query.trim().toLowerCase();
    try {
      return _customers.firstWhere(
        (c) =>
            c.registrationCode.toLowerCase() == cleanQuery ||
            c.phoneNumber.replaceAll('-', '').contains(cleanQuery),
      );
    } catch (_) {
      return null;
    }
  }

  /// Tambah Calon Pelanggan Baru (Dipanggil dari Web Pelanggan saat submit formulir)
  Future<CustomerModel> registerCustomerFromWeb({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String selectedPackage,
    required double latitude,
    required double longitude,
    int packagePrice = 320000,
  }) async {
    final odpResult = GeoCalculationService.findNearestOdp(latitude, longitude);
    final nearestOdp = odpResult['odp'];
    final double distance = odpResult['distanceMeters'] as double;

    final String generatedCode =
        'MMD-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${(_customers.length + 1).toString().padLeft(3, '0')}';

    final newCustomer = CustomerModel(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      registrationCode: generatedCode,
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      selectedPackage: selectedPackage,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      status: CustomerStatus.menungguJadwal,
      nearestOdpCode: nearestOdp != null ? nearestOdp.code : 'ODP-MANUAL-CHECK',
      distanceToOdpMeter: distance,
      isPackageVerified: false,
      paymentStatus: PaymentStatus.belumBayar,
      packagePrice: packagePrice,
    );

    _customers.insert(0, newCustomer);
    _newCustomerStreamController.add(newCustomer);
    _syncCustomerToFirebase(newCustomer);
    notifyListeners();

    return newCustomer;
  }

  /// Admin Menyortir Paket & Verifikasi Pembayaran
  void verifyPackageAndPayment({
    required String customerId,
    required bool isPackageVerified,
    required PaymentStatus paymentStatus,
    String? updatedPackage,
    int? updatedPrice,
    String? paymentMethod,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        isPackageVerified: isPackageVerified,
        paymentStatus: paymentStatus,
        selectedPackage: updatedPackage,
        packagePrice: updatedPrice,
        paymentMethod: paymentMethod,
        paymentDate: paymentStatus == PaymentStatus.sudahBayar ? DateTime.now() : null,
      );
      _syncCustomerToFirebase(_customers[index]);
      notifyListeners();
    }
  }

  /// Admin Memberi Tahu / Menugaskan Teknisi (Hanya setelah lunas & lolos verifikasi)
  bool scheduleAndAssignTechnician({
    required String customerId,
    required DateTime scheduledDate,
    required String scheduledTimeSlot,
    required String assignedTechnician,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? selectedPackage,
    int? packagePrice,
    bool isPackageVerified = true,
    String? adminNotes,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final customer = _customers[index];
      final effectivePaymentStatus = paymentStatus ?? customer.paymentStatus;

      // Pengecekan syarat: jika belum bayar, tolak
      if (effectivePaymentStatus != PaymentStatus.sudahBayar) {
        return false;
      }

      _customers[index] = customer.copyWith(
        status: CustomerStatus.dijadwalkan,
        isPackageVerified: isPackageVerified,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: paymentMethod ?? customer.paymentMethod ?? 'Transfer Bank',
        paymentDate: DateTime.now(),
        selectedPackage: selectedPackage ?? customer.selectedPackage,
        packagePrice: packagePrice ?? customer.packagePrice,
        scheduledDate: scheduledDate,
        scheduledTimeSlot: scheduledTimeSlot,
        assignedTechnician: assignedTechnician,
        adminNotes: adminNotes,
        needsRevision: false,
      );
      _syncCustomerToFirebase(_customers[index]);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Teknisi memulai pekerjaan di lapangan
  void startInstallation(String customerId) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        status: CustomerStatus.progresInstalasi,
      );
      _syncCustomerToFirebase(_customers[index]);
      notifyListeners();
    }
  }

  /// Teknisi menyelesaikan pekerjaan di lapangan & mengirim laporan ke Admin (Menunggu Verifikasi)
  bool submitTechnicianReport({
    required String customerId,
    required String modemSerialNumber,
    required String odpPortUsed,
    required double opticalAttenuationDbm,
    String? installationPhotoUrl,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      // Validasi redaman harus di bawah -25.5 dBm
      if (opticalAttenuationDbm < -25.5 || opticalAttenuationDbm > -14.0) {
        return false; // Redaman tidak memenuhi standar ISP
      }

      final updatedCustomer = _customers[index].copyWith(
        status: CustomerStatus.menungguVerifikasi,
        modemSerialNumber: modemSerialNumber,
        odpPortUsed: odpPortUsed,
        opticalAttenuationDbm: opticalAttenuationDbm,
        installationPhotoUrl: installationPhotoUrl ??
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?auto=format&fit=crop&w=400&q=80',
        reportSubmittedAt: DateTime.now(),
        needsRevision: false,
      );
      _customers[index] = updatedCustomer;
      _syncCustomerToFirebase(updatedCustomer);

      if (isUsingFirebase &&
          installationPhotoUrl != null &&
          !installationPhotoUrl.startsWith('http')) {
        _firebaseService
            .uploadInstallationPhoto(
          customerId: customerId,
          localPath: installationPhotoUrl,
        )
            .then((remoteUrl) {
          if (remoteUrl != null && remoteUrl != installationPhotoUrl) {
            final latestIdx = _customers.indexWhere((c) => c.id == customerId);
            if (latestIdx != -1) {
              _customers[latestIdx] = _customers[latestIdx].copyWith(
                installationPhotoUrl: remoteUrl,
              );
              _firebaseService.updateFields(customerId, {
                'installationPhotoUrl': remoteUrl,
              });
              notifyListeners();
            }
          }
        }).catchError((e) {
          debugPrint('[CustomerRepository] Gagal upload foto ke Storage: $e');
        });
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Admin MENYETUJUI laporan teknisi -> Status resmi menjadi 'Selesai' & Internet Aktif
  void approveInstallationReport(String customerId, {String? adminFeedback}) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        status: CustomerStatus.selesai,
        adminFeedback: adminFeedback ?? 'Laporan pemasangan telah dicek & disetujui Admin. Layanan aktif.',
        needsRevision: false,
        completedAt: DateTime.now(),
      );
      _syncCustomerToFirebase(_customers[index]);
      notifyListeners();
    }
  }

  /// Admin MEMINTA REVISI laporan teknisi -> Status kembali ke 'Progres Instalasi'
  void requestRevisionForReport(String customerId, {required String revisionReason}) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        status: CustomerStatus.progresInstalasi,
        adminFeedback: revisionReason,
        needsRevision: true,
      );
      _syncCustomerToFirebase(_customers[index]);
      notifyListeners();
    }
  }

  /// Backward-compatible wrapper
  bool completeInstallation({
    required String customerId,
    required String modemSerialNumber,
    required String odpPortUsed,
    required double opticalAttenuationDbm,
    String? installationPhotoUrl,
  }) {
    return submitTechnicianReport(
      customerId: customerId,
      modemSerialNumber: modemSerialNumber,
      odpPortUsed: odpPortUsed,
      opticalAttenuationDbm: opticalAttenuationDbm,
      installationPhotoUrl: installationPhotoUrl,
    );
  }

  /// Seed data awal untuk pengujian operasional
  void _seedInitialData() {
    _customers.addAll([
      // 1. Data Baru dari Web (Belum disortir paketnya & Belum Bayar)
      CustomerModel(
        id: 'cust_seed_1',
        registrationCode: 'MMD-202611-001',
        fullName: 'Bambang Sutrisno',
        phoneNumber: '081234567890',
        address: 'Jl. Merdeka No. 45, RT 02/RW 04, Kelurahan Senayan',
        selectedPackage: '50 Mbps Super Cepat',
        packagePrice: 320000,
        latitude: -6.200500,
        longitude: 106.817100,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: CustomerStatus.menungguJadwal,
        nearestOdpCode: 'ODP-MMD-PST-01',
        distanceToOdpMeter: 72.0,
        isPackageVerified: false,
        paymentStatus: PaymentStatus.belumBayar,
      ),

      // 2. Data dari Web yang SUDAH LUNAS (Siap Dijadwalkan oleh Admin ke Teknisi)
      CustomerModel(
        id: 'cust_seed_2',
        registrationCode: 'MMD-202611-002',
        fullName: 'Ibu Ratna Dewi',
        phoneNumber: '085712349988',
        address: 'Perumahan Griya Indah Blok C No. 12',
        selectedPackage: '30 Mbps Hemat Rumah',
        packagePrice: 225000,
        latitude: -6.209100,
        longitude: 106.819800,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: CustomerStatus.menungguJadwal,
        nearestOdpCode: 'ODP-MMD-BRT-02',
        distanceToOdpMeter: 110.0,
        isPackageVerified: true,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: 'Transfer Mandiri',
        paymentDate: DateTime.now().subtract(const Duration(hours: 2)),
      ),

      // 3. Sedang Dipasang oleh Teknisi di Lapangan
      CustomerModel(
        id: 'cust_seed_3',
        registrationCode: 'MMD-202611-003',
        fullName: 'Hendrik Pratama',
        phoneNumber: '081399887766',
        address: 'Kavling Harmoni No. 8A, Samping Masjid Al-Hidayah',
        selectedPackage: '100 Mbps Pro Gamer/Bisnis',
        packagePrice: 499000,
        latitude: -6.195600,
        longitude: 106.825800,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        status: CustomerStatus.progresInstalasi,
        nearestOdpCode: 'ODP-MMD-TMR-03',
        distanceToOdpMeter: 85.0,
        isPackageVerified: true,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: 'QRIS BCA',
        paymentDate: DateTime.now().subtract(const Duration(hours: 6)),
        scheduledDate: DateTime.now(),
        scheduledTimeSlot: 'Siang (13.00 - 16.00)',
        assignedTechnician: 'Tim Alpha (Budi & Doni)',
        adminNotes: 'Paket 100Mbps sudah lunas via QRIS. Pelanggan minta kabel rapi lewat plafon.',
      ),

      // 4. Laporan Telah Dikirim Teknisi (Menunggu Verifikasi & Pengecekan Admin)
      CustomerModel(
        id: 'cust_seed_4',
        registrationCode: 'MMD-202611-004',
        fullName: 'Klinik Medika Pratama',
        phoneNumber: '081299881122',
        address: 'Jl. Ahmad Yani No. 88, Ruko Melati Indah',
        selectedPackage: '100 Mbps Pro Gamer/Bisnis',
        packagePrice: 499000,
        latitude: -6.198000,
        longitude: 106.822000,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        status: CustomerStatus.menungguVerifikasi,
        nearestOdpCode: 'ODP-MMD-TMR-03',
        distanceToOdpMeter: 65.0,
        isPackageVerified: true,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: 'Transfer Mandiri',
        scheduledDate: DateTime.now(),
        scheduledTimeSlot: 'Pagi (09.00 - 12.00)',
        assignedTechnician: 'Tim Alpha (Budi & Doni)',
        modemSerialNumber: 'ZTEG-F670L-998812',
        odpPortUsed: 'Port 02',
        opticalAttenuationDbm: -20.4,
        installationPhotoUrl: 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?auto=format&fit=crop&w=400&q=80',
        reportSubmittedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),

      // 5. Selesai Terpasang & Disetujui Admin
      CustomerModel(
        id: 'cust_seed_5',
        registrationCode: 'MMD-202611-005',
        fullName: 'Toko Elektronik Makmur',
        phoneNumber: '082188771122',
        address: 'Ruko Sentra Bisnis Blok B-05',
        selectedPackage: '50 Mbps Super Cepat',
        packagePrice: 320000,
        latitude: -6.214400,
        longitude: 106.811100,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: CustomerStatus.selesai,
        nearestOdpCode: 'ODP-MMD-SLT-04',
        distanceToOdpMeter: 60.0,
        isPackageVerified: true,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: 'Transfer BNI',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        scheduledTimeSlot: 'Pagi (09.00 - 12.00)',
        assignedTechnician: 'Tim Beta (Agus & Rian)',
        modemSerialNumber: 'ZTEG-F670L-889123',
        odpPortUsed: 'Port 04',
        opticalAttenuationDbm: -20.8,
        adminFeedback: 'Pemasangan valid & redaman -20.8 dBm memenuhi standar.',
        completedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);
  }
}
