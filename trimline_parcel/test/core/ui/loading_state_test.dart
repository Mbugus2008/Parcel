import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trimline_parcel/core/ui/loading_state.dart';

void main() {
  group('LoadingStatus', () {
    test('has all expected values', () {
      expect(LoadingStatus.values, contains(LoadingStatus.initial));
      expect(LoadingStatus.values, contains(LoadingStatus.loading));
      expect(LoadingStatus.values, contains(LoadingStatus.success));
      expect(LoadingStatus.values, contains(LoadingStatus.error));
      expect(LoadingStatus.values, contains(LoadingStatus.empty));
    });
  });

  group('LoadingState', () {
    test('initial state has correct properties', () {
      final state = LoadingState<String>.initial();

      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.isEmpty, isFalse);
      expect(state.hasData, isFalse);
      expect(state.data, isNull);
    });

    test('loading state preserves previous data', () {
      final state = LoadingState<String>.loading(previousData: 'old data');

      expect(state.isLoading, isTrue);
      expect(state.data, equals('old data'));
    });

    test('success state has data', () {
      final state = LoadingState<String>.success('test data');

      expect(state.isSuccess, isTrue);
      expect(state.data, equals('test data'));
      expect(state.hasData, isTrue);
      expect(state.lastUpdated, isNotNull);
    });

    test('error state has message and preserves data', () {
      final state =
          LoadingState<String>.error('error msg', previousData: 'old');

      expect(state.isError, isTrue);
      expect(state.errorMessage, equals('error msg'));
      expect(state.data, equals('old'));
    });

    test('empty state has correct properties', () {
      final state = LoadingState<String>.empty();

      expect(state.isEmpty, isTrue);
      expect(state.hasData, isFalse);
    });

    test('map transforms data', () {
      final state = LoadingState<int>.success(42);
      final mapped = state.map((data) => data.toString());

      expect(mapped.data, equals('42'));
      expect(mapped.isSuccess, isTrue);
    });

    test('when executes correct callback', () {
      final successState = LoadingState<String>.success('data');
      final errorState = LoadingState<String>.error('error');
      final loadingState = LoadingState<String>.loading();

      final successResult = successState.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (data) => 'success: $data',
        error: (msg) => 'error: $msg',
        empty: () => 'empty',
      );
      expect(successResult, equals('success: data'));

      final errorResult = errorState.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (data) => 'success: $data',
        error: (msg) => 'error: $msg',
        empty: () => 'empty',
      );
      expect(errorResult, equals('error: error'));

      final loadingResult = loadingState.when(
        initial: () => 'initial',
        loading: () => 'loading',
        success: (data) => 'success: $data',
        error: (msg) => 'error: $msg',
        empty: () => 'empty',
      );
      expect(loadingResult, equals('loading'));
    });

    test('maybeWhen uses orElse for unhandled states', () {
      final state = LoadingState<String>.success('data');

      final result = state.maybeWhen(
        success: (data) => 'handled: $data',
        orElse: () => 'fallback',
      );
      expect(result, equals('handled: data'));

      final fallbackResult = state.maybeWhen(
        error: (msg) => 'error',
        orElse: () => 'fallback',
      );
      expect(fallbackResult, equals('fallback'));
    });
  });

  group('RxLoadingState', () {
    test('initial state is correct', () {
      final rxState = RxLoadingState<String>();

      expect(rxState.isInitial, isTrue);
      expect(rxState.hasData, isFalse);
    });

    test('withData constructor creates success state', () {
      final rxState = RxLoadingState<String>.withData('initial data');

      expect(rxState.isSuccess, isTrue);
      expect(rxState.data, equals('initial data'));
    });

    test('state transitions work correctly', () {
      final rxState = RxLoadingState<String>();

      rxState.setLoading();
      expect(rxState.isLoading, isTrue);

      rxState.setSuccess('data');
      expect(rxState.isSuccess, isTrue);
      expect(rxState.data, equals('data'));

      rxState.setError('error message');
      expect(rxState.isError, isTrue);
      expect(rxState.errorMessage, equals('error message'));

      rxState.setEmpty();
      expect(rxState.isEmpty, isTrue);

      rxState.setInitial();
      expect(rxState.isInitial, isTrue);
    });

    test('execute handles success', () async {
      final rxState = RxLoadingState<String>();

      final result = await rxState.execute(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'async result';
      });

      expect(result, equals('async result'));
      expect(rxState.isSuccess, isTrue);
      expect(rxState.data, equals('async result'));
    });

    test('execute handles error', () async {
      final rxState = RxLoadingState<String>();

      final result = await rxState.execute(() async {
        throw Exception('Test error');
      });

      expect(result, isNull);
      expect(rxState.isError, isTrue);
      expect(rxState.errorMessage, contains('Test error'));
    });
  });

  group('LoadingStateBuilder', () {
    testWidgets('shows success content', (tester) async {
      final rxState = RxLoadingState<String>.withData('test data');

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: LoadingStateBuilder<String>(
              state: rxState,
              onSuccess: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(find.text('Data: test data'), findsOneWidget);
    });

    testWidgets('shows loading indicator by default', (tester) async {
      final rxState = RxLoadingState<String>();
      rxState.setLoading();

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: LoadingStateBuilder<String>(
              state: rxState,
              onSuccess: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading widget', (tester) async {
      final rxState = RxLoadingState<String>();
      rxState.setLoading();

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: LoadingStateBuilder<String>(
              state: rxState,
              onLoading: () => const Text('Custom Loading'),
              onSuccess: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      final rxState = RxLoadingState<String>();
      rxState.setError('Something went wrong');

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: LoadingStateBuilder<String>(
              state: rxState,
              onSuccess: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
