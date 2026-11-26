import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'PT Mitra Media Data';
  static const String appSubtitle = 'Sistem Manajemen & Monitoring Instalasi Pelanggan';

  // Warna Utama Brand (Mi-Media: Deep Indigo/Navy & Merah khas logo)
  static const Color primaryColor = Color(0xFF1E227A); // Deep Indigo ("Mi-")
  static const Color secondaryColor = Color(0xFFD9141C); // Brand Red ("Media")
  static const Color accentColor = Color(0xFF2D34A8); // Bright Indigo
  static const Color backgroundColor = Color(0xFFF5F7FC);
  static const Color cardColor = Colors.white;

  // Status Warna
  static const Color statusWaitingColor = Color(0xFFE67E22); // Orange
  static const Color statusScheduledColor = Color(0xFF0077B6); // Blue
  static const Color statusProgressColor = Color(0xFF9D4EDD); // Purple
  static const Color statusVerificationColor = Color(0xFFD97706); // Amber / Yellow
  static const Color statusCompletedColor = Color(0xFF2EA043); // Green
  static const Color statusDangerColor = Color(0xFFDC2626); // Red
}

enum CustomerStatus {
  menungguJadwal,
  dijadwalkan,
  progresInstalasi,
  menungguVerifikasi, // Laporan dikirim teknisi, menunggu pengecekan Admin
  selesai,
}

extension CustomerStatusExtension on CustomerStatus {
  String get label {
    switch (this) {
      case CustomerStatus.menungguJadwal:
        return 'Menunggu Jadwal';
      case CustomerStatus.dijadwalkan:
        return 'Dijadwalkan';
      case CustomerStatus.progresInstalasi:
        return 'Progres Instalasi';
      case CustomerStatus.menungguVerifikasi:
        return 'Verifikasi Laporan';
      case CustomerStatus.selesai:
        return 'Selesai';
    }
  }

  Color get color {
    switch (this) {
      case CustomerStatus.menungguJadwal:
        return AppConstants.statusWaitingColor;
      case CustomerStatus.dijadwalkan:
        return AppConstants.statusScheduledColor;
      case CustomerStatus.progresInstalasi:
        return AppConstants.statusProgressColor;
      case CustomerStatus.menungguVerifikasi:
        return AppConstants.statusVerificationColor;
      case CustomerStatus.selesai:
        return AppConstants.statusCompletedColor;
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerStatus.menungguJadwal:
        return Icons.hourglass_top_rounded;
      case CustomerStatus.dijadwalkan:
        return Icons.event_available_rounded;
      case CustomerStatus.progresInstalasi:
        return Icons.engineering_rounded;
      case CustomerStatus.menungguVerifikasi:
        return Icons.fact_check_rounded;
      case CustomerStatus.selesai:
        return Icons.check_circle_rounded;
    }
  }
}
