import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nova/main.dart';

void main() {
  testWidgets('Drawer navigation and basic functionality flow', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const NovaApp());

    // Verify Home Screen content
    expect(find.text('Nova Assistant'), findsOneWidget);
    expect(find.text('Hello, I\'m Nova.'), findsOneWidget);
    expect(find.text('What can I do for you?'), findsOneWidget);

    // Step 1: Navigate to Nova UI Screen
    await tester.tap(find.text('What can I do for you?'));
    await tester.pumpAndSettle();

    // Verify Nova UI Screen is displayed
    expect(find.text('Nova UI'), findsOneWidget);
    expect(find.text('Welcome to Nova!'), findsOneWidget);

    // Step 2: Open the Drawer in Nova UI
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify Drawer contains Home and Calendar options (or relevant items)
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Step 3: Navigate to Calendar Screen (if relevant)
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // Verify Calendar Screen content (update if specifics have changed)
    expect(find.text('Calendar UI'), findsOneWidget);
    // Add any additional checks based on your current calendar screen

    // Step 4: Open the Drawer from Calendar Screen
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify Drawer options still present
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Step 5: Navigate Back to Home Screen
    await tester.tap(find.text('Home Screen'));
    await tester.pumpAndSettle();

    // Verify Home Screen is displayed again
    expect(find.text('Nova Assistant'), findsOneWidget);
    expect(find.text('Hello, I\'m Nova.'), findsOneWidget);
  });
}
