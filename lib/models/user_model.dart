enum UserRole {
  admin,
  technician,
}

class UserModel {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final UserRole role;
  final String? teamName; // Khusus teknisi (misal: "Tim Alpha (Budi & Doni)")
  final String email;

  const UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.teamName,
    required this.email,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isTechnician => role == UserRole.technician;
}
