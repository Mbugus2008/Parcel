import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/ui/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Items',
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Items',
              subtitle: 'Add your first item',
            ),
          ),
        ),
      );

      expect(find.text('Add your first item'), findsOneWidget);
    });

    testWidgets('displays action widget when provided', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Items',
              action: ElevatedButton(
                onPressed: () => pressed = true,
                child: const Text('Add Item'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(pressed, isTrue);
    });
  });

  group('EmptyState factories', () {
    testWidgets('noParcels shows correct content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noParcels(),
          ),
        ),
      );

      expect(find.text('No Parcels Yet'), findsOneWidget);
      expect(find.text('Start by adding your first parcel'), findsOneWidget);
    });

    testWidgets('noParcels shows add button when callback provided',
        (tester) async {
      bool addPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noParcels(
              onAddParcel: () => addPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Parcel'), findsOneWidget);

      await tester.tap(find.text('Add Parcel'));
      await tester.pumpAndSettle();
      expect(addPressed, isTrue);
    });

    testWidgets('noSearchResults shows query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noSearchResults(query: 'test query'),
          ),
        ),
      );

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.textContaining('test query'), findsOneWidget);
    });

    testWidgets('noSearchResults shows clear button', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noSearchResults(
              query: 'test',
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();
      expect(cleared, isTrue);
    });

    testWidgets('noFilteredResults shows status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noFilteredResults(status: 'Pending'),
          ),
        ),
      );

      expect(find.text('No Pending Parcels'), findsOneWidget);
    });

    testWidgets('networkError shows retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.networkError(
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('No Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('error shows message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.error(message: 'Custom error message'),
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Custom error message'), findsOneWidget);
    });
  });
}
