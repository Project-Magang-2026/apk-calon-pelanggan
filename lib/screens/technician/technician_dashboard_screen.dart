import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/customer_repository.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'smart_quality_check_sheet.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  final String technicianName;

  const TechnicianDashboardScreen({
    super.key,
    this.technicianName = 'Tim Alpha (Budi & Doni)',
  });

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen>
    with SingleTickerProviderStateMixin {
  final CustomerRepository _repository = CustomerRepository();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openMaps(CustomerModel job) async {
    final googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${job.latitude},${job.longitude}',
    );
    final geoUri = Uri.parse(
      'geo:${job.latitude},${job.longitude}?q=${job.latitude},${job.longitude}(${Uri.encodeComponent(job.fullName)})',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        final launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
      if (await launchUrl(
        googleMapsWebUrl,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Ditangani oleh pesan error di bawah
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka Maps. Koordinat: ${job.latitude}, ${job.longitude}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ${widget.technicianName}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final jobs = _repository.getJobsForTechnician(widget.technicianName);
        final newScheduledJobs = jobs.where((j) => !j.needsRevision).toList()
          ..sort((a, b) {
            int order(CustomerStatus s) {
              switch (s) {
                case CustomerStatus.dijadwalkan:
                  return 0;
                case CustomerStatus.progresInstalasi:
                  return 1;
                case CustomerStatus.menungguVerifikasi:
                  return 2;
                case CustomerStatus.selesai:
                  return 3;
                default:
                  return 4;
              }
            }

            return order(a.status).compareTo(order(b.status));
          });
        final revisionJobs = jobs
            .where(
              (j) =>
                  j.needsRevision &&
                  j.status == CustomerStatus.progresInstalasi,
            )
            .toList();
        final activeJobs = jobs
            .where((j) => j.status != CustomerStatus.selesai)
            .length;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            backgroundColor: const Color(0xFFE4EAF4), // Platinum Cool Silver
            foregroundColor: AppConstants.primaryColor,
            elevation: 0,
            titleSpacing: 14,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo_mimedia.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.technicianName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Field Ops Teknisi',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppConstants.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Keluar / Logout',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppConstants.secondaryColor,
                  size: 20,
                ),
                onPressed: _confirmLogout,
              ),
            ],
          ),
          body: Column(
            children: [
              // Banner Info Tugas Hari Ini
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daftar Penugasan Instalasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Selesaikan penarikan kabel & input redaman optik',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activeJobs > 0
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activeJobs > 0
                              ? const Color(0xFF7DD3FC)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 14,
                            color: activeJobs > 0
                                ? const Color(0xFF0284C7)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$activeJobs Tugas Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: activeJobs > 0
                                  ? const Color(0xFF0284C7)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Kategori Tugas Teknisi (2 Tab: Baru Dijadwalkan & Revisi dari Admin)
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppConstants.primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: AppConstants.secondaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Flexible(
                            child: Text(
                              'Baru Dijadwalkan',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${newScheduledJobs.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Flexible(
                            child: Text(
                              'Revisi Admin',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: revisionJobs.isNotEmpty
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${revisionJobs.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: revisionJobs.isNotEmpty
                                    ? const Color(0xFFDC2626)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // List Tugas Teknisi per Kategori
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobList(
                      jobList: newScheduledJobs,
                      emptyIcon: Icons.assignment_turned_in_rounded,
                      emptyTitle: 'Belum Ada Jadwal Instalasi Baru',
                      emptySubtitle:
                          'Jadwal akan muncul secara otomatis setelah Admin memverifikasi paket & pembayaran pelanggan.',
                    ),
                    _buildJobList(
                      jobList: revisionJobs,
                      emptyIcon: Icons.fact_check_outlined,
                      emptyTitle: 'Tidak Ada Tugas Revisi',
                      emptySubtitle:
                          'Laporan pemasangan yang dikembalikan Admin untuk perbaikan akan tampil di kategori ini.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobList({
    required List<CustomerModel> jobList,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (jobList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            Text(
              emptyTitle,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: jobList.length,
      itemBuilder: (context, index) => _buildJobCard(jobList[index]),
    );
  }

  Widget _buildJobCard(CustomerModel job) {
    final bool isRevision =
        job.needsRevision && job.status == CustomerStatus.progresInstalasi;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRevision ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
            width: isRevision ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status baris atas: Jadwal & Status Lunas & Lifecycle (Responsif)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.scheduledTimeSlot ?? 'Hari Ini',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      // Badge Pembayaran Terverifikasi Lunas
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 10,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'LUNAS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isRevision
                        ? const Color(0xFFFEE2E2)
                        : job.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRevision ? Icons.edit_note_rounded : job.status.icon,
                        size: 12,
                        color: isRevision
                            ? const Color(0xFFDC2626)
                            : job.status.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRevision ? 'Perlu Revisi' : job.status.label,
                        style: TextStyle(
                          color: isRevision
                              ? const Color(0xFFDC2626)
                              : job.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nama Pelanggan
            Text(
              job.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),

            // Paket Internet & Telepon (Anti-overflow)
            Row(
              children: [
                const Icon(
                  Icons.wifi_rounded,
                  size: 14,
                  color: Color(0xFF0077B6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.selectedPackage,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  job.phoneNumber,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Alamat Lengkap
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ODP & Catatan Admin
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.router_rounded,
                        size: 14,
                        color: Color(0xFF0077B6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Titik Sambung: ${job.nearestOdpCode} (~${job.distanceToOdpMeter.toStringAsFixed(0)} meter)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0077B6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (job.adminNotes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan Admin: ${job.adminNotes}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (isRevision) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.report_problem_rounded,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Catatan Revisi dari Admin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (job.adminFeedback != null &&
                              job.adminFeedback!.isNotEmpty)
                          ? job.adminFeedback!
                          : 'Mohon periksa ulang hasil instalasi & kirim laporan kembali.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7F1D1D),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tombol Navigasi Google Maps & Aksi Pekerjaan
            Row(
              children: [
                // Tombol Buka Maps
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0077B6),
                    side: const BorderSide(color: Color(0xFF90E0EF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 15),
                  label: const Text(
                    'Buka Maps',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openMaps(job),
                ),
                const Spacer(),

                // Tombol Aksi Status
                if (job.status == CustomerStatus.dijadwalkan)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D4EDD),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text(
                      'Mulai Instalasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _repository.startInstallation(job.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pekerjaan instalasi untuk ${job.fullName} dimulai!',
                          ),
                          backgroundColor: const Color(0xFF9D4EDD),
                        ),
                      );
                    },
                  )
                else if (job.status == CustomerStatus.progresInstalasi)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRevision
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2EA043),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      isRevision ? Icons.edit_note_rounded : Icons.send_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isRevision
                          ? 'Perbaiki & Kirim Ulang'
                          : 'Input Redaman & Kirim',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => SmartQualityCheckSheet(customer: job),
                      );
                    },
                  )
                else if (job.status == CustomerStatus.menungguVerifikasi)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 13,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Menunggu Verifikasi Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (job.status == CustomerStatus.selesai)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selesai (${job.opticalAttenuationDbm} dBm)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
