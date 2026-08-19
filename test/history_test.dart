import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendtrail/features/history/views/history_screen.dart';

void main() {
  testWidgets('History screen filters render test', (WidgetTester tester) async {
    // Build the HistoryScreen in a ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    // Verify app bar title
    expect(find.text('SpendTrail'), findsOneWidget);

    // Verify filters header components
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    
    // Verify date picker calendar icon
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
  });
}
