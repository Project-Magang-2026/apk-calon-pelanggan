import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/customer_repository.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'report_verification_dialog.dart';
import 'schedule_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CustomerRepository _repository = CustomerRepository();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Dengar stream untuk notifikasi calon pelanggan baru dari Web
    _repository.onNewCustomerAdded.listen((newCustomer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pendaftaran Baru Masuk dari Website!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${newCustomer.fullName} - ${newCustomer.selectedPackage}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
            Text('Konfirmasi Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Admin Dispatcher?',
          style: TextStyle(fontSize: 13),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _simulateIncomingWebRegistration() {
    final sampleNames = ['Rizky Ramadhan', 'Siti Rahmawati', 'Dedi Kurniawan', 'Putri Ayu'];
    final samplePackages = ['30 Mbps Hemat Rumah', '50 Mbps Super Cepat', '100 Mbps Pro Gamer/Bisnis'];
    final sampleAddresses = [
      'Jl. Anggrek No. 15, RT 03/RW 02',
      'Komplek Permata Blok D-08',
      'Jl. Sudirman Gg. Melati No. 4',
      'Perumahan Griya Indah Blok E-11'
    ];

    final int count = _repository.allCustomers.length + 1;
    final name = sampleNames[count % sampleNames.length];
    final pkg = samplePackages[count % samplePackages.length];
    final addr = sampleAddresses[count % sampleAddresses.length];

    _repository.registerCustomerFromWeb(
      fullName: '$name (Web)',
      phoneNumber: '0812${(10000000 + count * 883).toString().substring(0, 8)}',
      address: addr,
      selectedPackage: pkg,
      latitude: -6.200200 + (count * 0.001),
      longitude: 106.816800 + (count * 0.001),
      packagePrice: pkg.contains('30') ? 225000 : (pkg.contains('50') ? 320000 : 499000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final all = _repository.allCustomers;
        final listMenunggu = _filterList(_repository.getCustomersByStatus(CustomerStatus.menungguJadwal));
        final listDijadwalkan = _filterList(_repository.getCustomersByStatus(CustomerStatus.dijadwalkan));
        final listProgres = _filterList(_repository.getCustomersByStatus(CustomerStatus.progresInstalasi));
        final listSelesai = _filterList(_repository.getCustomersByStatus(CustomerStatus.selesai));
    final listVerifikasi = _filterList(_repository.getCustomersByStatus(CustomerStatus.menungguVerifikasi));

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F1E36), // Deep Modern Navy
            elevation: 0,
            titleSpacing: 14,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'Admin Dispatcher',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Portal Admin • PT Mitra Media Data',
                            style: TextStyle(fontSize: 10, color: Color(0xFF90E0EF)),
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
                tooltip: 'Simulasikan Data Masuk dari Web',
                icon: const Icon(Icons.add_to_photos_rounded, color: Color(0xFF90E0EF), size: 22),
                onPressed: _simulateIncomingWebRegistration,
              ),
              IconButton(
                tooltip: 'Keluar / Logout',
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                onPressed: _confirmLogout,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(102),
              child: Container(
                color: const Color(0xFF0F1E36),
                child: Column(
                  children: [
                    // Search Bar Modern
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Cari nama, no HP, alamat, atau tiket...',
                            hintStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white70),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.white70),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),

                    // Modern Pill TabBar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: const Color(0xFF00B4D8),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                      tabs: [
                        _buildTab('Menunggu', listMenunggu.length, Icons.hourglass_top_rounded, Colors.orange),
                        _buildTab('Dijadwalkan', listDijadwalkan.length, Icons.event_available_rounded, const Color(0xFF00B4D8)),
                        _buildTab('Progres', listProgres.length, Icons.engineering_rounded, const Color(0xFF9D4EDD)),
                        _buildTab('Verifikasi', listVerifikasi.length, Icons.fact_check_rounded, const Color(0xFFD97706)),
                        _buildTab('Selesai', listSelesai.length, Icons.verified_rounded, Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Modern Statistics Metric Cards
              _buildModernMetricCards(all),

              // Daftar Pelanggan per Status
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCustomerList(listMenunggu, CustomerStatus.menungguJadwal),
                    _buildCustomerList(listDijadwalkan, CustomerStatus.dijadwalkan),
                    _buildCustomerList(listProgres, CustomerStatus.progresInstalasi),
                    _buildCustomerList(listVerifikasi, CustomerStatus.menungguVerifikasi),
                    _buildCustomerList(listSelesai, CustomerStatus.selesai),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernMetricCards(List<CustomerModel> all) {
    final waiting = _repository.getCustomersByStatus(CustomerStatus.menungguJadwal).length;
    final scheduled = _repository.getCustomersByStatus(CustomerStatus.dijadwalkan).length;
    final completed = _repository.getCustomersByStatus(CustomerStatus.selesai).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildMetricTile('Total', all.length.toString(), const Color(0xFF0F1E36), Icons.group_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('Menunggu', waiting.toString(), const Color(0xFFE67E22), Icons.hourglass_empty_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('Jadwal', scheduled.toString(), const Color(0xFF0077B6), Icons.event_note_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('Selesai', completed.toString(), const Color(0xFF2EA043), Icons.check_circle_outline_rounded)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<CustomerModel> _filterList(List<CustomerModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.phoneNumber.contains(q) ||
          c.registrationCode.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildTab(String title, int count, IconData icon, Color badgeColor) {
    return Tab(
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(title),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerModel> list, CustomerStatus status) {
    if (list.isEmpty) {
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
              child: Icon(status.icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ditemukan hasil untuk "$_searchQuery"'
                  : 'Belum ada data pada status "${status.label}"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final customer = list[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    final bool isPaid = customer.paymentStatus == PaymentStatus.sudahBayar;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Header Responsif (Kode Registrasi + Badge Bayar + Badge Status)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Kode Tiket
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          customer.registrationCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
                        ),
                      ),

                      // Badge Status Pembayaran (Belum Bayar vs Lunas)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFDBA74)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                              size: 11,
                              color: isPaid ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isPaid ? 'LUNAS' : 'BELUM BAYAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Badge Status Lifecycle (Kanan Atas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: customer.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(customer.status.icon, size: 12, color: customer.status.color),
                      const SizedBox(width: 4),
                      Text(
                        customer.status.label,
                        style: TextStyle(
                          color: customer.status.color,
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

            // Baris 2: Nama Pelanggan
            Text(
              customer.fullName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),

            // Baris 3: Paket & Harga (Dengan Ellipsis agar anti-overflow)
            Row(
              children: [
                const Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF0077B6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${customer.selectedPackage} • Rp ${customer.packagePrice}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0077B6), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Baris 4: Nomor Telepon
            Row(
              children: [
                const Icon(Icons.phone_iphone_rounded, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(customer.phoneNumber, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 4),

            // Baris 5: Alamat Pemasangan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Baris 6: Footer Card (Info ODP & Tombol Aksi)
            Row(
              children: [
                // Info Tiang ODP
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.distanceToOdpMeter <= 150
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: customer.distanceToOdpMeter <= 150
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_input_antenna_rounded,
                          size: 13,
                          color: customer.distanceToOdpMeter <= 150 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${customer.nearestOdpCode} • ${customer.distanceToOdpMeter.toStringAsFixed(0)}m',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: customer.distanceToOdpMeter <= 150 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Aksi Berdasarkan Status
                if (customer.status == CustomerStatus.menungguJadwal)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaid ? const Color(0xFF0077B6) : const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(isPaid ? Icons.send_rounded : Icons.checklist_rtl_rounded, size: 13),
                    label: Text(
                      isPaid ? 'Jadwalkan' : 'Sortir & Cek Bayar',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ScheduleDialog(customer: customer),
                      );
                    },
                  )
                else if (customer.status == CustomerStatus.dijadwalkan)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        customer.assignedTechnician ?? "-",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                      ),
                      Text(
                        customer.scheduledTimeSlot ?? '',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  )
                else if (customer.status == CustomerStatus.progresInstalasi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D4EDD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Dipasang: ${customer.assignedTechnician ?? "Teknisi"}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF9D4EDD), fontWeight: FontWeight.w600),
                    ),
                  )
                else if (customer.status == CustomerStatus.menungguVerifikasi)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.fact_check_rounded, size: 13),
                    label: const Text(
                      'Cek Laporan',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReportVerificationDialog(customer: customer),
                      );
                    },
                  )
                else if (customer.status == CustomerStatus.selesai)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        'Redaman: ${customer.opticalAttenuationDbm ?? 0} dBm',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
