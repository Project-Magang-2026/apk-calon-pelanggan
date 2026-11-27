import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../admin/admin_dashboard_screen.dart';
import '../technician/technician_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRoleTab = UserRole.admin;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _authService.login(
      _usernameController.text,
      _passwordController.text,
      expectedRole: _selectedRoleTab,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selamat Datang, ${user.fullName} (${user.isAdmin ? "Admin Dispatcher" : user.teamName})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );

      if (user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianDashboardScreen(
              technicianName: user.teamName ?? 'Tim Alpha (Budi & Doni)',
            ),
          ),
        );
      }
    } else {
      final roleLabel = _selectedRoleTab == UserRole.admin ? 'Admin' : 'Teknisi';
      setState(() {
        _errorMessage =
            'ID Pengguna atau Kata Sandi salah / tidak sesuai dengan role $roleLabel!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EAF4), // Platinum Cool Silver
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4EAF4), Color(0xFFD5DFEE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand Header
                  _buildBrandHeader(),
                  const SizedBox(height: 24),

                  // Card Form Login
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tab Selector Role (Admin vs Teknisi)
                            _buildRoleTabs(),
                            const SizedBox(height: 20),

                            // Judul Form
                            Text(
                              _selectedRoleTab == UserRole.admin
                                  ? 'Masuk Portal Admin'
                                  : 'Masuk Portal Teknisi',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F1E36),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedRoleTab == UserRole.admin
                                  ? 'Monitoring status, validasi paket, & penugasan teknisi.'
                                  : 'Akses penugasan instalasi lapangan & input redaman OPM.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 18),

                            // Pesan Error jika Login Gagal
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Input ID Login / Username
                            const Text(
                              'ID Pengguna / Username',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: _selectedRoleTab == UserRole.admin
                                    ? 'Masukkan ID Admin (misal: admin)'
                                    : 'Masukkan ID Teknisi (misal: tek_alpha)',
                                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                prefixIcon: Icon(
                                  _selectedRoleTab == UserRole.admin ? Icons.badge_outlined : Icons.engineering_outlined,
                                  color: const Color(0xFF0077B6),
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'ID pengguna wajib diisi' : null,
                            ),
                            const SizedBox(height: 14),

                            // Input Kata Sandi
                            const Text(
                              'Kata Sandi / Password',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi...',
                                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0077B6), size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _isObscure = !_isObscure),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Kata sandi wajib diisi' : null,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 22),

                            // Tombol Masuk
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Masuk ke Sistem',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _selectedRoleTab == UserRole.admin
                                                ? Icons.arrow_forward_rounded
                                                : Icons.bolt_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Security Info Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.security_rounded, size: 16, color: Color(0xFF0077B6)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Akses terenkripsi khusus karyawan resmi PT Mitra Media Data.',
                                      style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800, height: 1.3),
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
                  const SizedBox(height: 18),

                  // Footer Copyright
                  Text(
                    '© 2026 PT Mitra Media Data • Sistem Operasional Lapangan FTTH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_mimedia.png',
          height: 82,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppConstants.secondaryColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'FTTH Monitoring & Installation System',
            style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _switchRoleTab(UserRole role) {
    if (_selectedRoleTab == role) return;
    FocusScope.of(context).unfocus();
    _usernameController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _selectedRoleTab = role;
      _errorMessage = null;
      _isObscure = true;
    });
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Admin',
              icon: Icons.shield_outlined,
              isSelected: _selectedRoleTab == UserRole.admin,
              onTap: () => _switchRoleTab(UserRole.admin),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Teknisi',
              icon: Icons.handyman_outlined,
              isSelected: _selectedRoleTab == UserRole.technician,
              onTap: () => _switchRoleTab(UserRole.technician),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppConstants.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppConstants.primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
