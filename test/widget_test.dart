import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appzap_pos/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AppZapPOSApp()));

    // Verify app launches (splash screen shows)
    expect(find.text('AppZap POS'), findsOneWidget);
  });
}
