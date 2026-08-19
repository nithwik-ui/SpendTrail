import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendtrail/app.dart';

void main() {
  testWidgets('SpendTrail onboarding smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SpendTrailApp(),
      ),
    );

    // Settle all initial load animations
    await tester.pumpAndSettle();

    // Verify that the Onboarding page loaded by looking for the Get Started button
    expect(find.text('Get Started'), findsOneWidget);
  });
}
