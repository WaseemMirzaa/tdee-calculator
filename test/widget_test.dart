// Widget smoke test for a Vita design-system component. Renders the calorie
// ring under the real theme and verifies the value settles after the count-up.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/theme/vita_theme.dart';
import 'package:vita_tdee/widgets/calorie_ring.dart';

void main() {
  testWidgets('CalorieRing renders and counts up to its value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VitaTheme.light(),
        home: const Scaffold(
          body: Center(child: CalorieRing(value: 1968, fraction: 0.72)),
        ),
      ),
    );
    // Count-up animates from 0 → 1968; settle it.
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('1968'), findsOneWidget);
    expect(find.text('KCAL / DAY'), findsOneWidget);
  });
}
