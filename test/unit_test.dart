import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aplikasi/models/customer_model.dart';
import 'package:flutter_aplikasi/models/user_model.dart';
import 'package:flutter_aplikasi/services/auth_service.dart';
import 'package:flutter_aplikasi/services/geo_calculation_service.dart';
import 'package:flutter_aplikasi/services/customer_repository.dart';
import 'package:flutter_aplikasi/utils/constants.dart';

void main() {
  group('Authentication & Role Access Tests', () {
    test('AuthService correctly authenticates Admin and Technician accounts', () async {
      final auth = AuthService();

      // 1. Login Admin sukses
      final adminUser = await auth.login('admin', 'admin123');
      expect(adminUser, isNotNull);
      expect(adminUser?.role, UserRole.admin);
      expect(adminUser?.isAdmin, isTrue);

      // 2. Logout
      auth.logout();
      expect(auth.currentUser, isNull);

      // 3. Login Teknisi sukses
      final techUser = await auth.login('tek_alpha', 'tek123');
      expect(techUser, isNotNull);
      expect(techUser?.role, UserRole.technician);
      expect(techUser?.isTechnician, isTrue);
      expect(techUser?.teamName, 'Tim Alpha (Budi & Doni)');

      // 4. Login dengan password salah harus gagal
      final failedUser = await auth.login('admin', 'salah_password');
      expect(failedUser, isNull);
    });
  });

  group('Smart Quality & Workflow Logic Tests', () {
    test('GeoCalculationService accurately finds nearest ODP and flags optimal coverage', () {
      final result = GeoCalculationService.findNearestOdp(-6.200100, 106.816700);

      expect(result['odp'], isNotNull);
      expect(result['distanceMeters'], lessThan(100.0));
      expect(result['isOptimal'], isTrue);
      expect(result['isCovered'], isTrue);
    });

    test('CustomerRepository enforces payment verification before assigning to technician', () async {
      final repo = CustomerRepository();

      // 1. Pelanggan daftar dari web (belum bayar & belum diverifikasi)
      final newCustomer = await repo.registerCustomerFromWeb(
        fullName: 'Calon Pelanggan Baru',
        phoneNumber: '081234567890',
        address: 'Jl. Uji Coba No. 1',
        selectedPackage: '50 Mbps Super Cepat',
        latitude: -6.200000,
        longitude: 106.816666,
      );

      expect(newCustomer.status, CustomerStatus.menungguJadwal);
      expect(newCustomer.paymentStatus, PaymentStatus.belumBayar);

      // 2. Admin mencoba menugaskan teknisi padahal BELUM BAYAR -> Harus DITOLAK
      final assignWithoutPayment = repo.scheduleAndAssignTechnician(
        customerId: newCustomer.id,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        scheduledTimeSlot: 'Pagi (09.00 - 12.00)',
        assignedTechnician: 'Tim Alpha (Budi & Doni)',
      );
      expect(assignWithoutPayment, isFalse);

      // Status pelanggan harus tetap menungguJadwal
      final checkCustomer = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(checkCustomer?.status, CustomerStatus.menungguJadwal);

      // 3. Admin melakukan sortir paket & konfirmasi pembayaran (LUNAS)
      repo.verifyPackageAndPayment(
        customerId: newCustomer.id,
        isPackageVerified: true,
        paymentStatus: PaymentStatus.sudahBayar,
        paymentMethod: 'Transfer BCA',
      );

      final paidCustomer = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(paidCustomer?.paymentStatus, PaymentStatus.sudahBayar);

      // 4. Admin menugaskan teknisi setelah LUNAS -> Harus BERHASIL
      final assignWithPayment = repo.scheduleAndAssignTechnician(
        customerId: newCustomer.id,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        scheduledTimeSlot: 'Pagi (09.00 - 12.00)',
        assignedTechnician: 'Tim Alpha (Budi & Doni)',
      );
      expect(assignWithPayment, isTrue);

      final scheduled = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(scheduled?.status, CustomerStatus.dijadwalkan);
      expect(scheduled?.assignedTechnician, 'Tim Alpha (Budi & Doni)');

      // 5. Teknisi melihat tugas di dashboardnya
      final technicianJobs = repo.getJobsForTechnician('Tim Alpha');
      expect(technicianJobs.any((job) => job.id == newCustomer.id), isTrue);

      // 6. Teknisi mulai instalasi
      repo.startInstallation(newCustomer.id);
      final inProgress = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(inProgress?.status, CustomerStatus.progresInstalasi);

      // 7. Teknisi input redaman standar (-20.5 dBm) dan kirim laporan -> Status menjadi Menunggu Verifikasi Admin
      final successQc = repo.submitTechnicianReport(
        customerId: newCustomer.id,
        modemSerialNumber: 'ZTEG-1234',
        odpPortUsed: 'Port 01',
        opticalAttenuationDbm: -20.5,
      );
      expect(successQc, isTrue);

      final waitingVerification = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(waitingVerification?.status, CustomerStatus.menungguVerifikasi);

      // 8. Admin mengecek dan menyetujui laporan -> Status resmi menjadi Selesai
      repo.approveInstallationReport(
        newCustomer.id,
        adminFeedback: 'Laporan valid dan redaman sesuai standar.',
      );

      final completed = repo.findByCodeOrPhone(newCustomer.registrationCode);
      expect(completed?.status, CustomerStatus.selesai);
    });
  });
}
