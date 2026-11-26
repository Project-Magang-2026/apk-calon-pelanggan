import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_repository.dart';
import '../../utils/constants.dart';

class ScheduleDialog extends StatefulWidget {
  final CustomerModel customer;

  const ScheduleDialog({super.key, required this.customer});

  @override
  State<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  late String _selectedPackage;
  late int _packagePrice;
  late bool _isPackageVerified;
  late PaymentStatus _paymentStatus;
  late String _paymentMethod;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _slotController = TextEditingController();
  String _selectedTechnician = 'Tim Alpha (Budi & Doni)';
  final TextEditingController _notesController = TextEditingController();

  final Map<String, int> _packagePrices = {
    '30 Mbps Hemat Rumah': 225000,
    '50 Mbps Super Cepat': 320000,
    '100 Mbps Pro Gamer/Bisnis': 499000,
  };

  final List<String> _paymentMethods = [
    'Transfer Bank (BCA/Mandiri)',
    'Transfer Mandiri',
    'Transfer BNI',
    'Transfer BCA',
    'QRIS (Gopay/OVO/Dana)',
    'QRIS BCA',
    'Tunai di Kantor',
  ];

  final List<String> _technicians = [
    'Tim Alpha (Budi & Doni)',
    'Tim Beta (Agus & Rian)',
    'Tim Gamma (Eko & Fajar)',
  ];

  @override
  void initState() {
    super.initState();
    // Validasi paket agar tidak error di dropdown
    if (_packagePrices.containsKey(widget.customer.selectedPackage)) {
      _selectedPackage = widget.customer.selectedPackage;
    } else {
      _selectedPackage = '50 Mbps Super Cepat';
    }
    _packagePrice = widget.customer.packagePrice;
    _isPackageVerified = widget.customer.isPackageVerified;
    _paymentStatus = widget.customer.paymentStatus;

    // Normalisasi metode pembayaran agar selalu ada di daftar dropdown
    final initialMethod = widget.customer.paymentMethod;
    if (initialMethod != null && _paymentMethods.contains(initialMethod)) {
      _paymentMethod = initialMethod;
    } else {
      _paymentMethod = 'Transfer Bank (BCA/Mandiri)';
    }

    if (widget.customer.scheduledTimeSlot != null &&
        widget.customer.scheduledTimeSlot!.isNotEmpty) {
      _slotController.text = widget.customer.scheduledTimeSlot!;
    }
    if (widget.customer.adminNotes != null) {
      _notesController.text = widget.customer.adminNotes!;
    }
  }

  @override
  void dispose() {
    _slotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canAssignTechnician = _paymentStatus == PaymentStatus.sudahBayar;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fact_check_outlined, color: AppConstants.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sortir & Verifikasi Pendaftaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.customer.fullName} • ${widget.customer.registrationCode}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // BAGIAN 1: SORTIR PAKET INTERNET
                _buildSectionTitle('1. Sortir & Cek Paket Internet', Icons.wifi_tethering),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedPackage,
                        decoration: const InputDecoration(
                          labelText: 'Paket Terpilih',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: _packagePrices.keys.map((pkg) {
                          return DropdownMenuItem(
                            value: pkg,
                            child: Text(
                              '$pkg - Rp ${_packagePrices[pkg]}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPackage = val;
                              _packagePrice = _packagePrices[val] ?? _packagePrice;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Paket sudah sesuai coverage dan kebutuhan pelanggan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        value: _isPackageVerified,
                        activeColor: AppConstants.primaryColor,
                        onChanged: (val) {
                          setState(() => _isPackageVerified = val ?? false);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // BAGIAN 2: VERIFIKASI STATUS PEMBAYARAN
                _buildSectionTitle('2. Verifikasi Status Pembayaran', Icons.payments_outlined),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _paymentStatus == PaymentStatus.sudahBayar
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _paymentStatus == PaymentStatus.sudahBayar
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _paymentStatus = PaymentStatus.belumBayar),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _paymentStatus == PaymentStatus.belumBayar
                                      ? Colors.orange.shade700
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange.shade700),
                                ),
                                child: Center(
                                  child: Text(
                                    'Belum Bayar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _paymentStatus == PaymentStatus.belumBayar
                                          ? Colors.white
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _paymentStatus = PaymentStatus.sudahBayar),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _paymentStatus == PaymentStatus.sudahBayar
                                      ? Colors.green.shade700
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade700),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sudah Bayar / Lunas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _paymentStatus == PaymentStatus.sudahBayar
                                          ? Colors.white
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_paymentStatus == PaymentStatus.sudahBayar) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tagihan Rp $_packagePrice terkonfirmasi LUNAS.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Metode Pembayaran',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            border: OutlineInputBorder(),
                          ),
                          items: _paymentMethods.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Perhatian: Teknisi TIDAK BOLEH ditugaskan sebelum pelanggan melakukan pembayaran awal.',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // BAGIAN 3: BERITAHU & TUGASKAN KE TEKNISI (Layout Vertikal Anti-Overflow)
                _buildSectionTitle('3. Jadwal & Beritahu Teknisi Lapangan', Icons.engineering),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: canAssignTechnician ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: canAssignTechnician ? Colors.blue.shade200 : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Tanggal Pemasangan
                      const Text('Tanggal Pemasangan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: canAssignTechnician
                            ? () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: canAssignTechnician ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              Icon(Icons.calendar_month, size: 16, color: canAssignTechnician ? Colors.blue : Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2. Slot Waktu (Input Manual)
                      const Text('Jam Pemasangan (Manual):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _slotController,
                        enabled: canAssignTechnician,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: canAssignTechnician ? Colors.white : Colors.grey.shade200,
                          hintText: 'Contoh: 09.00 - 12.00 atau 14.30 WIB',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: canAssignTechnician ? Colors.blue : Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Tim Teknisi
                      const Text('Tugaskan ke Tim Teknisi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedTechnician,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: _technicians.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: canAssignTechnician ? (val) => setState(() => _selectedTechnician = val!) : null,
                      ),
                      const SizedBox(height: 8),

                      // 4. Catatan Admin untuk Teknisi
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        enabled: canAssignTechnician,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Catatan untuk teknisi (misal: kabel lewat plafon)...',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.all(8),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Aksi Responsif
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Simpan Verifikasi Saja
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          onPressed: () {
                            CustomerRepository().verifyPackageAndPayment(
                              customerId: widget.customer.id,
                              isPackageVerified: _isPackageVerified,
                              paymentStatus: _paymentStatus,
                              updatedPackage: _selectedPackage,
                              updatedPrice: _packagePrice,
                              paymentMethod: _paymentStatus == PaymentStatus.sudahBayar ? _paymentMethod : null,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data sortir & verifikasi berhasil diperbarui.'),
                                backgroundColor: Colors.blueGrey,
                              ),
                            );
                          },
                          child: const Text('Simpan Status', style: TextStyle(fontSize: 12)),
                        ),

                        // Tombol Jadwalkan & Beritahu Teknisi
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAssignTechnician ? AppConstants.primaryColor : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Beritahu Teknisi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: canAssignTechnician
                              ? () {
                                  final manualSlot = _slotController.text.trim();
                                  if (manualSlot.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Mohon isi jam pemasangan terlebih dahulu.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  final success = CustomerRepository().scheduleAndAssignTechnician(
                                    customerId: widget.customer.id,
                                    scheduledDate: _selectedDate,
                                    scheduledTimeSlot: manualSlot,
                                    assignedTechnician: _selectedTechnician,
                                    paymentStatus: _paymentStatus,
                                    paymentMethod: _paymentMethod,
                                    selectedPackage: _selectedPackage,
                                    packagePrice: _packagePrice,
                                    isPackageVerified: _isPackageVerified,
                                    adminNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                  );

                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sukses! Jadwal telah diteruskan ke $_selectedTechnician.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gagal: Tandai status pembayaran "Sudah Bayar" terlebih dahulu sebelum menugaskan teknisi.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppConstants.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
