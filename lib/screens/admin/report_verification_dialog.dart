import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_repository.dart';

class ReportVerificationDialog extends StatefulWidget {
  final CustomerModel customer;

  const ReportVerificationDialog({super.key, required this.customer});

  @override
  State<ReportVerificationDialog> createState() => _ReportVerificationDialogState();
}

class _ReportVerificationDialogState extends State<ReportVerificationDialog> {
  final TextEditingController _feedbackController = TextEditingController(
    text: 'Pemasangan valid & redaman memenuhi standar kualitas PT Mitra Media Data.',
  );
  final CustomerRepository _repository = CustomerRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Color _getAttenuationColor(double? dbm) {
    if (dbm == null) return Colors.grey;
    if (dbm >= -22.5 && dbm <= -15.0) return const Color(0xFF16A34A); // Green
    if (dbm >= -25.0 && dbm < -22.5) return const Color(0xFFD97706); // Orange
    return const Color(0xFFDC2626); // Red
  }

  String _getAttenuationNote(double? dbm) {
    if (dbm == null) return 'Belum ada data redaman';
    if (dbm >= -22.5 && dbm <= -15.0) {
      return 'Sangat Baik (Sesuai Standar FTTH PT Mitra Media Data)';
    }
    if (dbm >= -25.0 && dbm < -22.5) {
      return 'Batas Toleransi (Sinyal Cukup)';
    }
    return 'Redaman Terlalu Tinggi / Buruk (Maksimal -25.0 dBm)';
  }

  void _showImagePreview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPhotoWidget(path, height: 420, fit: BoxFit.contain),
            ),
            IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String path, {double height = 150, BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder('Gagal memuat gambar online'),
      );
    } else {
      if (kIsWeb) {
        return Image.network(
          path,
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder('Foto tidak tersedia di web'),
        );
      } else {
        return Image.file(
          File(path),
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPhotoPlaceholder('File foto lokal tidak ditemukan'),
        );
      }
    }
  }

  Widget _buildPhotoPlaceholder(String msg) {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 6),
            Text(msg, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  void _handleApprove() {
    setState(() => _isSubmitting = true);
    _repository.approveInstallationReport(
      widget.customer.id,
      adminFeedback: _feedbackController.text.trim().isEmpty
          ? 'Laporan disetujui oleh Admin Dispatcher.'
          : _feedbackController.text.trim(),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Laporan ${widget.customer.fullName} disetujui! Status menjadi Selesai & layanan aktif.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2EA043),
      ),
    );
  }

  void _handleRequestRevision() {
    showDialog(
      context: context,
      builder: (ctx) {
        final reasonController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Minta Revisi Teknisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tuliskan instruksi perbaikan untuk tim teknisi di lapangan:',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: Redaman -26 dBm terlalu tinggi, mohon splicing ulang atau cek bending kabel.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final reason = reasonController.text.trim().isEmpty
                    ? 'Mohon periksa kembali kerapian instalasi dan redaman optik.'
                    : reasonController.text.trim();
                Navigator.pop(ctx); // Tutup dialog input alasan
                Navigator.pop(context); // Tutup dialog verifikasi
                _repository.requestRevisionForReport(widget.customer.id, revisionReason: reason);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Laporan dikembalikan ke Teknisi (${widget.customer.assignedTechnician}) untuk perbaikan.'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              },
              child: const Text('Kirim Revisi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final double? attenuation = customer.opticalAttenuationDbm;
    final Color attColor = _getAttenuationColor(attenuation);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fact_check_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verifikasi Laporan Pemasangan',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${customer.fullName} • ${customer.registrationCode}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Info Teknisi & Waktu Submit Laporan
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.engineering_rounded, size: 16, color: Color(0xFF0077B6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pelaksana: ${customer.assignedTechnician ?? "Tim Teknisi"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                          ),
                          Text(
                            customer.reportSubmittedAt != null
                                ? 'Dikirim: ${customer.reportSubmittedAt!.hour.toString().padLeft(2, '0')}:${customer.reportSubmittedAt!.minute.toString().padLeft(2, '0')} WIB'
                                : 'Baru saja',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 1. Data Hasil Ukur Redaman (OPM)
              const Text(
                '1. Hasil Pengukuran Redaman (OPM)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: attColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: attColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: attColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${attenuation != null ? attenuation.toStringAsFixed(1) : "-"} dBm',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAttenuationNote(attenuation),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: attColor),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Standar PT Mitra Media Data: -15.0 s/d -22.5 dBm',
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Data Teknis (SN Modem & Port ODP)
              const Text(
                '2. Data Perangkat Terpasang',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Serial Number (SN) Modem', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            customer.modemSerialNumber ?? '-',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Port ODP Terhubung', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            customer.odpPortUsed ?? '-',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Foto Bukti Pemasangan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3. Foto Bukti Pemasangan & OPM',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (customer.installationPhotoUrl != null)
                    InkWell(
                      onTap: () => _showImagePreview(context, customer.installationPhotoUrl!),
                      child: const Row(
                        children: [
                          Icon(Icons.fullscreen_rounded, size: 14, color: Color(0xFF0077B6)),
                          SizedBox(width: 2),
                          Text('Perbesar', style: TextStyle(fontSize: 11, color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (customer.installationPhotoUrl != null)
                GestureDetector(
                  onTap: () => _showImagePreview(context, customer.installationPhotoUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPhotoWidget(customer.installationPhotoUrl!),
                  ),
                )
              else
                _buildPhotoPlaceholder('Teknisi belum mengunggah foto.'),
              const SizedBox(height: 14),

              // 4. Catatan Admin / Catatan Approval
              const Text(
                'Catatan Admin (Feedback Pelanggan & Arsip)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _feedbackController,
                maxLines: 2,
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'Tuliskan catatan verifikasi atau catatan approval...',
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Keputusan Admin (Tolak / Minta Revisi VS Setujui & Selesaikan)
              Row(
                children: [
                  // Tombol Minta Revisi
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 15),
                      label: const Text('Minta Revisi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _isSubmitting ? null : _handleRequestRevision,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Setujui & Selesaikan
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EA043),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Setujui & Selesaikan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _isSubmitting ? null : _handleApprove,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
