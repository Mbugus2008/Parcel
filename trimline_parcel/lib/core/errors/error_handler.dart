/// Error handling service
/// Provides centralized error handling, logging, and user feedback
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import 'app_error.dart';

/// Callback type for error handling
typedef ErrorCallback = void Function(AppError error);

/// Centralized error handler
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Custom error callbacks
  final List<ErrorCallback> _errorCallbacks = [];

  /// Stream controller for error events
  final _errorController = StreamController<AppError>.broadcast();

  /// Stream of errors for listening
  Stream<AppError> get errorStream => _errorController.stream;

  /// Register a callback for errors
  void registerCallback(ErrorCallback callback) {
    _errorCallbacks.add(callback);
  }

  /// Unregister a callback
  void unregisterCallback(ErrorCallback callback) {
    _errorCallbacks.remove(callback);
  }

  /// Handle an error
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    bool showToUser = true,
    String? context,
  }) {
    final appError = _toAppError(error, stackTrace);

    // Log the error
    _logError(appError, context: context);

    // Emit to stream
    _errorController.add(appError);

    // Notify callbacks
    for (final callback in _errorCallbacks) {
      try {
        callback(appError);
      } catch (e) {
        debugPrint('Error in error callback: $e');
      }
    }

    // Show to user if requested
    if (showToUser) {
      _showErrorToUser(appError);
    }
  }

  /// Execute a function with error handling
  Future<T?> guard<T>({
    required Future<T> Function() action,
    String? context,
    bool showToUser = true,
    T? fallback,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        showToUser: showToUser,
        context: context,
      );
      return fallback;
    }
  }

  /// Execute a function with error handling (sync version)
  T? guardSync<T>({
    required T Function() action,
    String? context,
    bool showToUser = true,
    T? fallback,
  }) {
    try {
      return action();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        showToUser: showToUser,
        context: context,
      );
      return fallback;
    }
  }

  /// Convert any error to AppError
  AppError _toAppError(dynamic error, StackTrace? stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Try to identify error type from exception type or message
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (error.runtimeType.toString().contains('SocketException') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return NetworkError.fromException(error, stackTrace);
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sqlite') ||
        errorString.contains('sqflite')) {
      return DatabaseError.fromException(error, stackTrace);
    }

    // Generic error
    return DatabaseError(
      message: 'An unexpected error occurred.',
      technicalDetails: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error based on environment
  void _logError(AppError error, {String? context}) {
    if (!AppConfig().enableDebugLogging &&
        AppConfig().environment == Environment.production) {
      // In production, would send to crash reporting service
      // For now, just skip debug output
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('🔴 ERROR${context != null ? ' [$context]' : ''}');
    buffer.writeln('Type: ${error.runtimeType}');
    buffer.writeln('Message: ${error.userMessage}');

    if (error.technicalDetails != null) {
      buffer.writeln('Details: ${error.technicalDetails}');
    }

    if (error.stackTrace != null) {
      buffer.writeln('Stack trace:');
      buffer
          .writeln(error.stackTrace.toString().split('\n').take(10).join('\n'));
    }

    buffer.writeln('═══════════════════════════════════════');

    debugPrint(buffer.toString());
  }

  /// Show error to user via snackbar
  void _showErrorToUser(AppError error) {
    // Don't show if no GetX context
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        _getErrorTitle(error),
        error.userMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _getErrorColor(error),
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
        isDismissible: true,
        margin: const EdgeInsets.all(8),
        borderRadius: 8,
      );
    }
  }

  String _getErrorTitle(AppError error) {
    if (error is NetworkError) return 'Connection Error';
    if (error is DatabaseError) return 'Data Error';
    if (error is ValidationError) return 'Validation Error';
    if (error is AuthError) return 'Authentication Error';
    if (error is SyncError) return 'Sync Error';
    return 'Error';
  }

  dynamic _getErrorColor(AppError error) {
    return Get.theme.colorScheme.error.withValues(alpha: 0.9);
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
    _errorCallbacks.clear();
  }
}

/// Extension for easy error handling
extension ErrorHandlerExtension<T> on Future<T> {
  /// Handle errors with ErrorHandler
  Future<T?> handleErrors({
    String? context,
    bool showToUser = true,
    T? fallback,
  }) async {
    return ErrorHandler().guard(
      action: () => this,
      context: context,
      showToUser: showToUser,
      fallback: fallback,
    );
  }
}
