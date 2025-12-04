/// Centralized error handling for the application
/// Provides typed errors with user-friendly messages
library;

import 'dart:io';

/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? technicalDetails;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
  });

  /// User-friendly message to display
  String get userMessage => message;

  /// Technical details for logging
  String get logMessage => technicalDetails ?? '$runtimeType: $message';

  @override
  String toString() => logMessage;
}

/// Network-related errors
class NetworkError extends AppError {
  final int? statusCode;
  final NetworkErrorType type;

  const NetworkError({
    required super.message,
    this.statusCode,
    this.type = NetworkErrorType.unknown,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkError.noConnection(
      {dynamic originalError, StackTrace? stackTrace}) {
    return NetworkError(
      message: 'No internet connection. Please check your network.',
      type: NetworkErrorType.noConnection,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.timeout(
      {dynamic originalError, StackTrace? stackTrace}) {
    return NetworkError(
      message: 'Request timed out. Please try again.',
      type: NetworkErrorType.timeout,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.serverError({
    int? statusCode,
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkError(
      message: 'Server error. Please try again later.',
      statusCode: statusCode,
      type: NetworkErrorType.serverError,
      technicalDetails: details ?? 'HTTP $statusCode',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.unauthorized(
      {dynamic originalError, StackTrace? stackTrace}) {
    return NetworkError(
      message: 'Session expired. Please log in again.',
      statusCode: 401,
      type: NetworkErrorType.unauthorized,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.forbidden(
      {dynamic originalError, StackTrace? stackTrace}) {
    return NetworkError(
      message: 'You don\'t have permission for this action.',
      statusCode: 403,
      type: NetworkErrorType.forbidden,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.notFound(
      {String? resource, dynamic originalError, StackTrace? stackTrace}) {
    return NetworkError(
      message: resource != null
          ? '$resource not found.'
          : 'The requested resource was not found.',
      statusCode: 404,
      type: NetworkErrorType.notFound,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Create NetworkError from exception
  factory NetworkError.fromException(dynamic error, [StackTrace? stackTrace]) {
    if (error is SocketException) {
      return NetworkError.noConnection(
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (error is HttpException) {
      return NetworkError(
        message: 'Network error occurred.',
        type: NetworkErrorType.unknown,
        technicalDetails: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return NetworkError(
      message: 'An unexpected network error occurred.',
      type: NetworkErrorType.unknown,
      technicalDetails: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  unauthorized,
  forbidden,
  notFound,
  unknown,
}

/// Database-related errors
class DatabaseError extends AppError {
  final DatabaseErrorType type;

  const DatabaseError({
    required super.message,
    this.type = DatabaseErrorType.unknown,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseError.notFound(
      {String? entity, dynamic originalError, StackTrace? stackTrace}) {
    return DatabaseError(
      message: entity != null ? '$entity not found.' : 'Record not found.',
      type: DatabaseErrorType.notFound,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.duplicate(
      {String? entity, dynamic originalError, StackTrace? stackTrace}) {
    return DatabaseError(
      message:
          entity != null ? '$entity already exists.' : 'Record already exists.',
      type: DatabaseErrorType.duplicate,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.constraint(
      {String? details, dynamic originalError, StackTrace? stackTrace}) {
    return DatabaseError(
      message: 'Data validation failed.',
      type: DatabaseErrorType.constraintViolation,
      technicalDetails: details,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.corruption(
      {dynamic originalError, StackTrace? stackTrace}) {
    return DatabaseError(
      message: 'Database error. Please restart the app.',
      type: DatabaseErrorType.corruption,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.fromException(dynamic error, [StackTrace? stackTrace]) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('unique constraint') ||
        errorString.contains('duplicate')) {
      return DatabaseError.duplicate(
          originalError: error, stackTrace: stackTrace);
    }
    if (errorString.contains('foreign key') ||
        errorString.contains('constraint')) {
      return DatabaseError.constraint(
        details: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return DatabaseError(
      message: 'A database error occurred.',
      type: DatabaseErrorType.unknown,
      technicalDetails: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

enum DatabaseErrorType {
  notFound,
  duplicate,
  constraintViolation,
  corruption,
  unknown,
}

/// Validation errors
class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError({
    required super.message,
    this.fieldErrors = const {},
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationError.field({
    required String field,
    required String error,
  }) {
    return ValidationError(
      message: error,
      fieldErrors: {field: error},
    );
  }

  factory ValidationError.multiple({
    required Map<String, String> errors,
  }) {
    final firstError = errors.values.first;
    return ValidationError(
      message: firstError,
      fieldErrors: errors,
    );
  }

  bool hasFieldError(String field) => fieldErrors.containsKey(field);
  String? getFieldError(String field) => fieldErrors[field];
}

/// Authentication errors
class AuthError extends AppError {
  final AuthErrorType type;

  const AuthError({
    required super.message,
    this.type = AuthErrorType.unknown,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });

  factory AuthError.invalidCredentials() {
    return const AuthError(
      message: 'Invalid username or password.',
      type: AuthErrorType.invalidCredentials,
    );
  }

  factory AuthError.sessionExpired() {
    return const AuthError(
      message: 'Your session has expired. Please log in again.',
      type: AuthErrorType.sessionExpired,
    );
  }

  factory AuthError.accountLocked() {
    return const AuthError(
      message: 'Account is locked. Please contact support.',
      type: AuthErrorType.accountLocked,
    );
  }

  factory AuthError.accountDisabled() {
    return const AuthError(
      message: 'Account is disabled. Please contact support.',
      type: AuthErrorType.accountDisabled,
    );
  }
}

enum AuthErrorType {
  invalidCredentials,
  sessionExpired,
  accountLocked,
  accountDisabled,
  unknown,
}

/// Sync-related errors
class SyncError extends AppError {
  final SyncErrorType type;

  const SyncError({
    required super.message,
    this.type = SyncErrorType.unknown,
    super.technicalDetails,
    super.originalError,
    super.stackTrace,
  });

  factory SyncError.conflict(
      {String? details, dynamic originalError, StackTrace? stackTrace}) {
    return SyncError(
      message: 'Data conflict detected. Please refresh and try again.',
      type: SyncErrorType.conflict,
      technicalDetails: details,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory SyncError.versionMismatch(
      {dynamic originalError, StackTrace? stackTrace}) {
    return SyncError(
      message: 'Data was modified. Please refresh and try again.',
      type: SyncErrorType.versionMismatch,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory SyncError.partialFailure({
    required int succeeded,
    required int failed,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return SyncError(
      message:
          'Sync partially completed: $succeeded succeeded, $failed failed.',
      type: SyncErrorType.partialFailure,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}

enum SyncErrorType {
  conflict,
  versionMismatch,
  partialFailure,
  unknown,
}
