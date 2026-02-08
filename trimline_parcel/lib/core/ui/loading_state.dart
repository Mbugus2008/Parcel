/// Loading state management for UI components
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Represents the current state of an async operation
enum LoadingStatus {
  initial,
  loading,
  success,
  error,
  empty,
}

/// Generic class to wrap data with loading state
class LoadingState<T> {
  final LoadingStatus status;
  final T? data;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const LoadingState._({
    required this.status,
    this.data,
    this.errorMessage,
    this.lastUpdated,
  });

  /// Initial state - no data loaded yet
  factory LoadingState.initial() =>
      const LoadingState._(status: LoadingStatus.initial);

  /// Loading state - operation in progress
  factory LoadingState.loading({T? previousData}) => LoadingState._(
        status: LoadingStatus.loading,
        data: previousData,
      );

  /// Success state with data
  factory LoadingState.success(T data) => LoadingState._(
        status: LoadingStatus.success,
        data: data,
        lastUpdated: DateTime.now(),
      );

  /// Error state with message
  factory LoadingState.error(String message, {T? previousData}) =>
      LoadingState._(
        status: LoadingStatus.error,
        data: previousData,
        errorMessage: message,
      );

  /// Empty state - no data available
  factory LoadingState.empty() =>
      const LoadingState._(status: LoadingStatus.empty);

  bool get isInitial => status == LoadingStatus.initial;
  bool get isLoading => status == LoadingStatus.loading;
  bool get isSuccess => status == LoadingStatus.success;
  bool get isError => status == LoadingStatus.error;
  bool get isEmpty => status == LoadingStatus.empty;
  bool get hasData => data != null;

  /// Map the data to another type
  LoadingState<R> map<R>(R Function(T data) mapper) {
    if (data != null) {
      return LoadingState._(
        status: status,
        data: mapper(data as T),
        errorMessage: errorMessage,
        lastUpdated: lastUpdated,
      );
    }
    return LoadingState._(
      status: status,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated,
    );
  }

  /// Execute callback based on state
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message) error,
    required R Function() empty,
  }) {
    switch (status) {
      case LoadingStatus.initial:
        return initial();
      case LoadingStatus.loading:
        return loading();
      case LoadingStatus.success:
        return success(data as T);
      case LoadingStatus.error:
        return error(errorMessage ?? 'Unknown error');
      case LoadingStatus.empty:
        return empty();
    }
  }

  /// Execute callback with optional handlers
  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(String message)? error,
    R Function()? empty,
    required R Function() orElse,
  }) {
    switch (status) {
      case LoadingStatus.initial:
        return initial?.call() ?? orElse();
      case LoadingStatus.loading:
        return loading?.call() ?? orElse();
      case LoadingStatus.success:
        return success?.call(data as T) ?? orElse();
      case LoadingStatus.error:
        return error?.call(errorMessage ?? 'Unknown error') ?? orElse();
      case LoadingStatus.empty:
        return empty?.call() ?? orElse();
    }
  }
}

/// Reactive loading state for GetX
class RxLoadingState<T> {
  final Rx<LoadingState<T>> _state;

  RxLoadingState() : _state = LoadingState<T>.initial().obs;
  RxLoadingState.withData(T data) : _state = LoadingState<T>.success(data).obs;

  LoadingState<T> get value => _state.value;
  Stream<LoadingState<T>> get stream => _state.stream;

  bool get isInitial => _state.value.isInitial;
  bool get isLoading => _state.value.isLoading;
  bool get isSuccess => _state.value.isSuccess;
  bool get isError => _state.value.isError;
  bool get isEmpty => _state.value.isEmpty;
  bool get hasData => _state.value.hasData;
  T? get data => _state.value.data;
  String? get errorMessage => _state.value.errorMessage;

  void setInitial() => _state.value = LoadingState.initial();
  void setLoading() =>
      _state.value = LoadingState.loading(previousData: _state.value.data);
  void setSuccess(T data) => _state.value = LoadingState.success(data);
  void setError(String message) => _state.value =
      LoadingState.error(message, previousData: _state.value.data);
  void setEmpty() => _state.value = LoadingState.empty();

  /// Execute an async operation with automatic state management
  Future<T?> execute(Future<T> Function() operation) async {
    setLoading();
    try {
      final result = await operation();
      setSuccess(result);
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
}

/// Widget that builds based on loading state
class LoadingStateBuilder<T> extends StatelessWidget {
  final RxLoadingState<T> state;
  final Widget Function()? onInitial;
  final Widget Function()? onLoading;
  final Widget Function(T data) onSuccess;
  final Widget Function(String message)? onError;
  final Widget Function()? onEmpty;

  const LoadingStateBuilder({
    super.key,
    required this.state,
    this.onInitial,
    this.onLoading,
    required this.onSuccess,
    this.onError,
    this.onEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return state.value.when(
        initial: () => onInitial?.call() ?? const SizedBox.shrink(),
        loading: () =>
            onLoading?.call() ??
            const Center(child: CircularProgressIndicator()),
        success: onSuccess,
        error: (message) => onError?.call(message) ?? _defaultError(message),
        empty: () => onEmpty?.call() ?? _defaultEmpty(),
      );
    });
  }

  Widget _defaultError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _defaultEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No data available'),
        ],
      ),
    );
  }
}
