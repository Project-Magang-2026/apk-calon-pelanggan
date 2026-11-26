import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/customer_model.dart';
import '../../services/customer_repository.dart';

class SmartQualityCheckSheet extends StatefulWidget {
  final CustomerModel customer;

  const SmartQualityCheckSheet({super.key, required this.customer});

  @override
  State<SmartQualityCheckSheet> createState() => _SmartQualityCheckSheetState();
}

class _SmartQualityCheckSheetState extends State<SmartQualityCheckSheet> {
  final TextEditingController _attenuationController = TextEditingController(text: '-21.5');
  final TextEditingController _snModemController = TextEditingController(text: 'ZTEG-F670L-');
  final TextEditingController _portOdpController = TextEditingController(text: 'Port 03');

  XFile? _pickedPhoto;
  double _currentAttenuation = -21.5;

  @override
  void initState() {
    super.initState();
    if (widget.customer.opticalAttenuationDbm != null) {
      _currentAttenuation = widget.customer.opticalAttenuationDbm!;
      _attenuationController.text = _currentAttenuation.toString();
    }
    if (widget.customer.modemSerialNumber != null &&
        widget.customer.modemSerialNumber!.isNotEmpty) {
      _snModemController.text = widget.customer.modemSerialNumber!;
    }
    if (widget.customer.odpPortUsed != null &&
        widget.customer.odpPortUsed!.isNotEmpty) {
      _portOdpController.text = widget.customer.odpPortUsed!;
    }
    _attenuationController.addListener(() {
      final parsed = double.tryParse(_attenuationController.text);
      if (parsed != null) {
        setState(() => _currentAttenuation = parsed);
      }
    });
  }

  @override
  void dispose() {
    _attenuationController.dispose();
    _snModemController.dispose();
    _portOdpController.dispose();
    super.dispose();
  }

  // Kategori Kualitas Sinyal Berdasarkan Redaman Optik (dBm)
  Color get _attenuationColor {
    if (_currentAttenuation >= -22.5 && _currentAttenuation <= -15.0) {
      return Colors.green;
    } else if (_currentAttenuation >= -25.0 && _currentAttenuation < -22.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String get _attenuationStatusText {
    if (_currentAttenuation >= -22.5 && _currentAttenuation <= -15.0) {
      return 'Sinyal Sangat Baik (Memenuhi Standar)';
    } else if (_currentAttenuation >= -25.0 && _currentAttenuation < -22.5) {
      return 'Sinyal Cukup (Batas Toleransi)';
    } else {
      return 'Redaman Buruk! (Maksimal standar -25.0 dBm)';
    }
  }

  bool get _isAcceptable => _currentAttenuation >= -25.0 && _currentAttenuation <= -14.0;

  // Dialog Pemilihan Sumber Foto (Kamera HP vs Galeri)
  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unggah Foto Bukti Instalasi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF0077B6)),
                ),
                title: const Text('Buka Kamera HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Ambil foto langsung alat OPM / modem di rumah pelanggan', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Pilih foto dari penyimpanan ponsel', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedPhoto = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera/Galeri tidak dapat dibuka: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Header QC
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quality Control & Selesai Pasang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pelanggan: ${widget.customer.fullName}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (widget.customer.needsRevision &&
                widget.customer.adminFeedback != null &&
                widget.customer.adminFeedback!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 6),
                        Text(
                          'Catatan Revisi dari Admin:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customer.adminFeedback!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ],

            // Fitur Cerdas: Validasi Redaman Optik (OPM)
            const Text(
              'Pengukuran Redaman Optik (Optical Power)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Masukkan hasil ukur dari alat OPM di rumah pelanggan',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),

            // Input Angka & Gauge Warna
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _attenuationColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _attenuationColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _attenuationController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _attenuationColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '-20.5',
                            suffixText: 'dBm',
                            suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Icon(
                        _isAcceptable ? Icons.check_circle : Icons.warning_rounded,
                        color: _attenuationColor,
                        size: 28,
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: _attenuationColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _attenuationStatusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _attenuationColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Data Teknis: SN Modem & Port ODP
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Serial Number (SN) Modem', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _snModemController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Port ODP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _portOdpController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Lampiran Foto Bukti (Bisa Buka Kamera HP & Galeri)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Foto Bukti Pemasangan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.camera_alt_outlined, size: 14),
                  label: const Text('Buka Kamera', style: TextStyle(fontSize: 11)),
                  onPressed: _showPhotoSourceDialog,
                ),
              ],
            ),
            const SizedBox(height: 4),

            InkWell(
              onTap: _showPhotoSourceDialog,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(
                    color: _pickedPhoto != null ? Colors.green : Colors.grey.shade300,
                    width: _pickedPhoto != null ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _pickedPhoto != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(_pickedPhoto!.path, height: 140, width: double.infinity, fit: BoxFit.cover)
                                : Image.file(File(_pickedPhoto!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Foto Berhasil Diambil (${_pickedPhoto!.name})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF0077B6), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ambil Foto dari Kamera HP Teknisi',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ketuk untuk membuka Kamera atau Galeri ponsel',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Konfirmasi Kirim Laporan ke Admin
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAcceptable ? const Color(0xFF0077B6) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _isAcceptable ? 'Kirim Laporan ke Admin' : 'Terkunci (Perbaiki Redaman Dahulu)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isAcceptable
                    ? () {
                        final success = CustomerRepository().submitTechnicianReport(
                          customerId: widget.customer.id,
                          modemSerialNumber: _snModemController.text.trim(),
                          odpPortUsed: _portOdpController.text.trim(),
                          opticalAttenuationDbm: _currentAttenuation,
                          installationPhotoUrl: _pickedPhoto?.path,
                        );

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Laporan terkirim! Menunggu verifikasi Admin.'),
                              backgroundColor: Color(0xFF0077B6),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
