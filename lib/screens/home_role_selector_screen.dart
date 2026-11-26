import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'admin/admin_dashboard_screen.dart';
import 'technician/technician_dashboard_screen.dart';

class HomeRoleSelectorScreen extends StatefulWidget {
  const HomeRoleSelectorScreen({super.key});

  @override
  State<HomeRoleSelectorScreen> createState() => _HomeRoleSelectorScreenState();
}

class _HomeRoleSelectorScreenState extends State<HomeRoleSelectorScreen> {
  String _selectedTechnicianTeam = 'Tim Alpha (Budi & Doni)';

  final List<String> _technicianTeams = [
    'Tim Alpha (Budi & Doni)',
    'Tim Beta (Agus & Rian)',
    'Tim Gamma (Eko & Fajar)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand Header
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cell_tower_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3B59),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sistem Monitoring & Operasional Instalasi Pelanggan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // Container Login / Pilih Akses Internal
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.lock_person_outlined, color: AppConstants.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih Akses Pengguna',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Khusus Karyawan & Petugas Lapangan',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // Pilihan Role 1: Admin / Dispatcher
                          _buildRoleButton(
                            title: 'Admin / Dispatcher',
                            subtitle: 'Monitoring 4 status, validasi pendaftaran web, & atur jadwal.',
                            icon: Icons.dashboard_customize_rounded,
                            color: AppConstants.primaryColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Pilihan Role 2: Teknisi Lapangan
                          _buildRoleButton(
                            title: 'Teknisi Lapangan (Field Ops)',
                            subtitle: 'Monitoring tugas aktif, navigasi Maps, input redaman OPM & foto.',
                            icon: Icons.engineering_rounded,
                            color: const Color(0xFF1B3B59),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TechnicianDashboardScreen(
                                    technicianName: _selectedTechnicianTeam,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Dropdown Pemilihan Tim Teknisi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                const Text(
                                  'Pilih Akun Tim:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedTechnicianTeam,
                                      isDense: true,
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                                      items: _technicianTeams.map((team) {
                                        return DropdownMenuItem(value: team, child: Text(team, overflow: TextOverflow.ellipsis));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedTechnicianTeam = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Catatan Operasional
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Data calon pelanggan baru secara otomatis masuk ke aplikasi ini setiap kali pelanggan mengisi formulir di website pendaftaran resmi PT Mitra Media Data.',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
