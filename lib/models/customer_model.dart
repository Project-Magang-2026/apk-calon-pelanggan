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
}
