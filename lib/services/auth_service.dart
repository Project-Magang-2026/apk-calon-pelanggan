import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Daftar akun resmi internal PT Mitra Media Data
  static const List<UserModel> registeredUsers = [
    UserModel(
      id: 'usr_admin_01',
      username: 'admin',
      password: 'admin123',
      fullName: 'Ahmad Fauzan',
      role: UserRole.admin,
      email: 'admin.dispatcher@mitramediadata.com',
    ),
    UserModel(
      id: 'usr_tek_01',
      username: 'tek_alpha',
      password: 'tek123',
      fullName: 'Budi Santoso & Doni',
      role: UserRole.technician,
      teamName: 'Tim Alpha (Budi & Doni)',
      email: 'alpha.field@mitramediadata.com',
    ),
    UserModel(
      id: 'usr_tek_02',
      username: 'tek_beta',
      password: 'tek123',
      fullName: 'Agus P. & Rian',
      role: UserRole.technician,
      teamName: 'Tim Beta (Agus & Rian)',
      email: 'beta.field@mitramediadata.com',
    ),
    UserModel(
      id: 'usr_tek_03',
      username: 'tek_gamma',
      password: 'tek123',
      fullName: 'Eko W. & Fajar',
      role: UserRole.technician,
      teamName: 'Tim Gamma (Eko & Fajar)',
      email: 'gamma.field@mitramediadata.com',
    ),
  ];

  /// Login dengan verifikasi username, password, dan opsional kecocokan role
  Future<UserModel?> login(
    String username,
    String password, {
    UserRole? expectedRole,
  }) async {
    // Simulasi delay autentikasi kecil untuk kesan responsif profesional
    await Future.delayed(const Duration(milliseconds: 300));

    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final user = registeredUsers.firstWhere(
        (u) =>
            u.username.toLowerCase() == cleanUsername &&
            u.password == cleanPassword &&
            (expectedRole == null || u.role == expectedRole),
      );
      _currentUser = user;
      notifyListeners();
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Logout akun saat ini
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
