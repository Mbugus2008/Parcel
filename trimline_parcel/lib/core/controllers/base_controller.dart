import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../di/service_locator.dart';
import '../errors/app_error.dart';
import '../errors/error_handler.dart';

/// Base controller with common functionality
/// Provides loading states, error handling, and service access
abstract class BaseController extends GetxController with ServiceLocatorMixin {
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Error state
  final Rx<AppError?> error = Rx<AppError?>(null);

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
  static const int defaultPageSize = 20;

  /// Error handler instance
  final ErrorHandler _errorHandler = ErrorHandler();

  /// Execute an async operation with loading state and error handling
  Future<T?> execute<T>({
    required Future<T> Function() action,
    bool showLoading = true,
    bool showError = true,
    VoidCallback? onSuccess,
    Function(AppError)? onError,
    LoadingType loadingType = LoadingType.main,
  }) async {
    try {
      _setLoading(true, loadingType);
      error.value = null;

      final result = await action();
      
      onSuccess?.call();
      return result;
    } on AppError catch (e, stackTrace) {
      _handleError(e, stackTrace, showError, onError);
      return null;
    } catch (e, stackTrace) {
      final appError = _toAppError(e, stackTrace);
      _handleError(appError, stackTrace, showError, onError);
      return null;
    } finally {
      _setLoading(false, loadingType);
    }
  }

  /// Execute with refresh loading state
  Future<T?> doRefresh<T>(Future<T> Function() action, {bool showError = true}) {
    return execute(
      action: action,
      loadingType: LoadingType.refresh,
      showError: showError,
    );
  }

  /// Execute with load more loading state
  Future<T?> loadMore<T>(Future<T> Function() action, {bool showError = true}) {
    return execute(
      action: action,
      loadingType: LoadingType.more,
      showError: showError,
    );
  }

  void _setLoading(bool value, LoadingType type) {
    switch (type) {
      case LoadingType.main:
        isLoading.value = value;
        break;
      case LoadingType.refresh:
        isRefreshing.value = value;
        break;
      case LoadingType.more:
        isLoadingMore.value = value;
        break;
    }
  }

  void _handleError(
    AppError e,
    StackTrace stackTrace,
    bool showError,
    Function(AppError)? onError,
  ) {
    error.value = e;
    _errorHandler.handleError(e, stackTrace: stackTrace, showToUser: showError);
    
    if (onError != null) {
      onError(e);
    }
  }

  /// Convert generic exception to AppError
  AppError _toAppError(dynamic e, StackTrace? stackTrace) {
    if (e is AppError) return e;
    return ValidationError(
      message: e.toString(),
      stackTrace: stackTrace,
    );
  }

  /// Clear error state
  void clearError() {
    error.value = null;
  }

  /// Reset pagination
  void resetPagination() {
    currentPage.value = 1;
    hasMore.value = true;
  }

  /// Increment page for pagination
  void nextPage() {
    currentPage.value++;
  }

  /// Check if has error
  bool get hasError => error.value != null;

  /// Check if any loading is in progress
  bool get isAnyLoading => isLoading.value || isRefreshing.value || isLoadingMore.value;
}

enum LoadingType {
  main,
  refresh,
  more,
}
