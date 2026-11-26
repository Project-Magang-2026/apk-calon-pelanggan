import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

enum PaymentStatus {
  belumBayar,
  sudahBayar,
}

extension PaymentStatusExtension on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.belumBayar:
        return 'Belum Bayar';
      case PaymentStatus.sudahBayar:
        return 'Lunas';
    }
  }
}

class CustomerModel {
  final String id;
  final String registrationCode; // Format: MMD-YYYYMM-XXX
  final String fullName;
  final String phoneNumber;
  final String address;
  String selectedPackage; // e.g. "30 Mbps Home", "50 Mbps Pro"
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  // Status Lifecycle (5 Status: Menunggu Jadwal -> Dijadwalkan -> Progres -> Menunggu Verifikasi -> Selesai)
  CustomerStatus status;

  // Smart Coverage Info
  final String nearestOdpCode;
  final double distanceToOdpMeter; // dalam meter

  // Verifikasi & Sortir Admin
  bool isPackageVerified;
  PaymentStatus? _paymentStatus;
  PaymentStatus get paymentStatus => _paymentStatus ?? PaymentStatus.belumBayar;
  set paymentStatus(PaymentStatus value) => _paymentStatus = value;

  String? paymentMethod; // e.g. "Transfer Mandiri", "QRIS", "Tunai"
  int packagePrice; // Biaya langganan/deposit awal (Rp)
  DateTime? paymentDate;

  // Penjadwalan & Petugas (Diisi Admin setelah lolos verifikasi bayar)
  DateTime? scheduledDate;
  String? scheduledTimeSlot; // e.g. "Pagi (09.00 - 12.00)"
  String? assignedTechnician; // e.g. "Tim Alpha (Budi & Doni)"
  String? adminNotes;

  // Eksekusi Teknis (Diisi Teknisi saat kirim laporan)
  String? modemSerialNumber;
  String? odpPortUsed;
  double? opticalAttenuationDbm; // Redaman dalam -dBm (e.g. -20.5)
  String? installationPhotoUrl;
  DateTime? reportSubmittedAt;

  // Verifikasi Laporan Akhir oleh Admin
  String? adminFeedback; // Catatan persetujuan atau catatan revisi dari admin
  bool needsRevision; // Penanda apakah tugas dikembalikan admin untuk revisi
  DateTime? completedAt;

  CustomerModel({
    required this.id,
    required this.registrationCode,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.selectedPackage,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.status = CustomerStatus.menungguJadwal,
    required this.nearestOdpCode,
    required this.distanceToOdpMeter,
    this.isPackageVerified = false,
    PaymentStatus? paymentStatus = PaymentStatus.belumBayar,
    this.paymentMethod,
    this.packagePrice = 320000,
    this.paymentDate,
    this.scheduledDate,
    this.scheduledTimeSlot,
    this.assignedTechnician,
    this.adminNotes,
    this.modemSerialNumber,
    this.odpPortUsed,
    this.opticalAttenuationDbm,
    this.installationPhotoUrl,
    this.reportSubmittedAt,
    this.adminFeedback,
    this.needsRevision = false,
    this.completedAt,
  }) : _paymentStatus = paymentStatus ?? PaymentStatus.belumBayar;

  bool get isReadyForTechnician =>
      isPackageVerified && paymentStatus == PaymentStatus.sudahBayar;

  // Salin dengan update status/data
  CustomerModel copyWith({
    CustomerStatus? status,
    String? selectedPackage,
    bool? isPackageVerified,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    int? packagePrice,
    DateTime? paymentDate,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? assignedTechnician,
    String? adminNotes,
    String? modemSerialNumber,
    String? odpPortUsed,
    double? opticalAttenuationDbm,
    String? installationPhotoUrl,
    DateTime? reportSubmittedAt,
    String? adminFeedback,
    bool? needsRevision,
    DateTime? completedAt,
  }) {
    return CustomerModel(
      id: id,
      registrationCode: registrationCode,
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      status: status ?? this.status,
      nearestOdpCode: nearestOdpCode,
      distanceToOdpMeter: distanceToOdpMeter,
      isPackageVerified: isPackageVerified ?? this.isPackageVerified,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      packagePrice: packagePrice ?? this.packagePrice,
      paymentDate: paymentDate ?? this.paymentDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      assignedTechnician: assignedTechnician ?? this.assignedTechnician,
      adminNotes: adminNotes ?? this.adminNotes,
      modemSerialNumber: modemSerialNumber ?? this.modemSerialNumber,
      odpPortUsed: odpPortUsed ?? this.odpPortUsed,
      opticalAttenuationDbm: opticalAttenuationDbm ?? this.opticalAttenuationDbm,
      installationPhotoUrl: installationPhotoUrl ?? this.installationPhotoUrl,
      reportSubmittedAt: reportSubmittedAt ?? this.reportSubmittedAt,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      needsRevision: needsRevision ?? this.needsRevision,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper untuk mengecek apakah sinyal redaman lolos standar ISP
  bool get isAttenuationAcceptable {
    if (opticalAttenuationDbm == null) return false;
    return opticalAttenuationDbm! >= -25.0 && opticalAttenuationDbm! <= -15.0;
  }

  /// Konversi model ke Map untuk Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registrationCode': registrationCode,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'selectedPackage': selectedPackage,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'nearestOdpCode': nearestOdpCode,
      'distanceToOdpMeter': distanceToOdpMeter,
      'isPackageVerified': isPackageVerified,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'packagePrice': packagePrice,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTimeSlot': scheduledTimeSlot,
      'assignedTechnician': assignedTechnician,
      'adminNotes': adminNotes,
      'modemSerialNumber': modemSerialNumber,
      'odpPortUsed': odpPortUsed,
      'opticalAttenuationDbm': opticalAttenuationDbm,
      'installationPhotoUrl': installationPhotoUrl,
      'reportSubmittedAt': reportSubmittedAt != null ? Timestamp.fromDate(reportSubmittedAt!) : null,
      'adminFeedback': adminFeedback,
      'needsRevision': needsRevision,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Buat model dari dokumen Cloud Firestore
  factory CustomerModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CustomerModel(
      id: id ?? (map['id'] as String? ?? ''),
      registrationCode: map['registrationCode'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      selectedPackage: map['selectedPackage'] as String? ?? '30 Mbps Hemat Rumah',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      status: CustomerStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CustomerStatus.menungguJadwal,
      ),
      nearestOdpCode: map['nearestOdpCode'] as String? ?? 'ODP-MANUAL-CHECK',
      distanceToOdpMeter: (map['distanceToOdpMeter'] as num?)?.toDouble() ?? 0.0,
      isPackageVerified: map['isPackageVerified'] as bool? ?? false,
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == map['paymentStatus'],
        orElse: () => PaymentStatus.belumBayar,
      ),
      paymentMethod: map['paymentMethod'] as String?,
      packagePrice: (map['packagePrice'] as num?)?.toInt() ?? 320000,
      paymentDate: _parseDateTime(map['paymentDate']),
      scheduledDate: _parseDateTime(map['scheduledDate']),
      scheduledTimeSlot: map['scheduledTimeSlot'] as String?,
      assignedTechnician: map['assignedTechnician'] as String?,
      adminNotes: map['adminNotes'] as String?,
      modemSerialNumber: map['modemSerialNumber'] as String?,
      odpPortUsed: map['odpPortUsed'] as String?,
      opticalAttenuationDbm: (map['opticalAttenuationDbm'] as num?)?.toDouble(),
      installationPhotoUrl: map['installationPhotoUrl'] as String?,
      reportSubmittedAt: _parseDateTime(map['reportSubmittedAt']),
      adminFeedback: map['adminFeedback'] as String?,
      needsRevision: map['needsRevision'] as bool? ?? false,
      completedAt: _parseDateTime(map['completedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
