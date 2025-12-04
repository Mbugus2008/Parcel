import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/ui/status_badge.dart';

void main() {
  group('StatusConfig', () {
    test('creates config with required properties', () {
      const config = StatusConfig(
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      expect(config.backgroundColor, equals(Colors.green));
      expect(config.textColor, equals(Colors.white));
      expect(config.icon, isNull);
      expect(config.shouldPulse, isFalse);
    });

    test('creates config with optional properties', () {
      const config = StatusConfig(
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        icon: Icons.schedule,
        shouldPulse: true,
      );

      expect(config.icon, equals(Icons.schedule));
      expect(config.shouldPulse, isTrue);
    });
  });

  group('StatusBadge', () {
    testWidgets('displays status text in title case', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'pending'),
          ),
        ),
      );

      // Just pump a few frames for pulse animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Status is formatted as title case: "Pending"
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows icon when showIcon is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'delivered',
              showIcon: true,
            ),
          ),
        ),
      );

      // delivered doesn't pulse, so pumpAndSettle is fine
      await tester.pumpAndSettle();

      // Check for delivered icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'delivered',
              showIcon: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('displays different status badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'pending'),
                StatusBadge(status: 'delivered'),
                StatusBadge(status: 'in_transit'),
                StatusBadge(status: 'failed'),
              ],
            ),
          ),
        ),
      );

      // Just pump a few frames for badges with pulse animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Status is formatted as title case
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(
          find.text('In Transit'), findsOneWidget); // underscores become spaces
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('applies custom fontSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'delivered', // Use non-pulsing status
              fontSize: 16,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Delivered'));
      expect(textWidget.style?.fontSize, equals(16));
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'delivered', // Use non-pulsing status
              padding: EdgeInsets.all(20),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delivered'), findsOneWidget);
    });
  });

  group('StatusIndicator', () {
    testWidgets('displays colored dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(status: 'pending'),
          ),
        ),
      );

      // StatusIndicator is a Container with decoration
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('uses custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              status: 'pending',
              size: 16,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(16));
    });
  });
}
