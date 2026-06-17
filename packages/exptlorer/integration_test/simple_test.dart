import 'package:exptlorer/src/app.dart';
import 'package:exptlorer/src/rust/frb_generated.dart';
import 'package:exptlorer/src/utils/platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await RustLib.init();
    await loadAccentColor();
    await windowInit();
  });
  testWidgets('Can call rust function', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() async {
      while (find.textContaining('C:').evaluate().isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(find.textContaining('C:'), findsOneWidget);
  });
}
