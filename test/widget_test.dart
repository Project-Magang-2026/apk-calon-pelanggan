import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aplikasi/main.dart';
import 'package:flutter_aplikasi/utils/constants.dart';

void main() {
  testWidgets('Renders LoginScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MitraMediaDataApp());

    // Verify brand title and login UI elements
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('ID Pengguna / Username'), findsOneWidget);
    expect(find.text('Kata Sandi / Password'), findsOneWidget);
    expect(find.text('Masuk ke Sistem'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Teknisi'), findsOneWidget);
  });
}
