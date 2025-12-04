import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/errors/app_error.dart';

void main() {
  group('AppError', () {
    group('NetworkError', () {
      test('creates error with message', () {
        final error = NetworkError(message: 'Test error');
        expect(error.message, equals('Test error'));
        expect(error.userMessage, equals('Test error'));
      });

      test('noConnection factory creates correct error', () {
        final error = NetworkError.noConnection();
        expect(error.type, equals(NetworkErrorType.noConnection));
        expect(error.message, contains('internet'));
      });

      test('timeout factory creates correct error', () {
        final error = NetworkError.timeout();
        expect(error.type, equals(NetworkErrorType.timeout));
        expect(error.message, contains('timed out'));
      });

      test('serverError factory creates correct error', () {
        final error = NetworkError.serverError(statusCode: 500);
        expect(error.type, equals(NetworkErrorType.serverError));
        expect(error.statusCode, equals(500));
      });

      test('unauthorized factory creates correct error', () {
        final error = NetworkError.unauthorized();
        expect(error.type, equals(NetworkErrorType.unauthorized));
        expect(error.statusCode, equals(401));
      });

      test('forbidden factory creates correct error', () {
        final error = NetworkError.forbidden();
        expect(error.type, equals(NetworkErrorType.forbidden));
        expect(error.statusCode, equals(403));
      });

      test('notFound factory creates correct error', () {
        final error = NetworkError.notFound(resource: 'Parcel');
        expect(error.type, equals(NetworkErrorType.notFound));
        expect(error.statusCode, equals(404));
      });

      test('fromException creates error from SocketException', () {
        final socketException = SocketException('Connection refused');
        final error = NetworkError.fromException(socketException);
        expect(error.type, equals(NetworkErrorType.noConnection));
      });

      test('preserves original error', () {
        final original = Exception('Original');
        final error = NetworkError(
          message: 'Test',
          originalError: original,
        );
        expect(error.originalError, equals(original));
      });
    });

    group('DatabaseError', () {
      test('creates error with message', () {
        final error = DatabaseError(message: 'Database failed');
        expect(error.message, equals('Database failed'));
      });

      test('notFound factory creates correct error', () {
        final error = DatabaseError.notFound(entity: 'User');
        expect(error.type, equals(DatabaseErrorType.notFound));
        expect(error.message, contains('User'));
      });

      test('duplicate factory creates correct error', () {
        final error = DatabaseError.duplicate(entity: 'Parcel');
        expect(error.type, equals(DatabaseErrorType.duplicate));
        expect(error.message, contains('exists'));
      });

      test('constraint factory creates correct error', () {
        final error = DatabaseError.constraint(details: 'Foreign key');
        expect(error.type, equals(DatabaseErrorType.constraintViolation));
      });

      test('corruption factory creates correct error', () {
        final error = DatabaseError.corruption();
        expect(error.type, equals(DatabaseErrorType.corruption));
      });
    });

    group('AuthError', () {
      test('creates error with message', () {
        final error = AuthError(message: 'Auth failed');
        expect(error.message, equals('Auth failed'));
      });

      test('invalidCredentials factory creates correct error', () {
        final error = AuthError.invalidCredentials();
        expect(error.type, equals(AuthErrorType.invalidCredentials));
      });

      test('sessionExpired factory creates correct error', () {
        final error = AuthError.sessionExpired();
        expect(error.type, equals(AuthErrorType.sessionExpired));
      });

      test('accountLocked factory creates correct error', () {
        final error = AuthError.accountLocked();
        expect(error.type, equals(AuthErrorType.accountLocked));
      });

      test('accountDisabled factory creates correct error', () {
        final error = AuthError.accountDisabled();
        expect(error.type, equals(AuthErrorType.accountDisabled));
      });
    });

    group('ValidationError', () {
      test('creates error with message', () {
        final error = ValidationError(message: 'Invalid data');
        expect(error.message, equals('Invalid data'));
      });

      test('field factory creates error for specific field', () {
        final error = ValidationError.field(
          field: 'email',
          error: 'Invalid format',
        );
        expect(error.fieldErrors['email'], equals('Invalid format'));
      });

      test('multiple factory creates error for multiple fields', () {
        final error = ValidationError.multiple(
          errors: {
            'email': 'Invalid format',
            'phone': 'Too short',
          },
        );
        expect(error.fieldErrors, hasLength(2));
      });

      test('hasFieldError returns true for existing field', () {
        final error = ValidationError.field(
          field: 'email',
          error: 'Invalid',
        );
        expect(error.hasFieldError('email'), isTrue);
        expect(error.hasFieldError('phone'), isFalse);
      });

      test('getFieldError returns error for existing field', () {
        final error = ValidationError.field(
          field: 'email',
          error: 'Invalid',
        );
        expect(error.getFieldError('email'), equals('Invalid'));
        expect(error.getFieldError('phone'), isNull);
      });
    });

    group('SyncError', () {
      test('creates error with message', () {
        final error = SyncError(message: 'Sync failed');
        expect(error.message, equals('Sync failed'));
      });

      test('conflict factory creates correct error', () {
        final error = SyncError.conflict();
        expect(error.type, equals(SyncErrorType.conflict));
        expect(error.message, contains('conflict'));
      });

      test('versionMismatch factory creates correct error', () {
        final error = SyncError.versionMismatch();
        expect(error.type, equals(SyncErrorType.versionMismatch));
      });

      test('partialFailure factory creates correct error', () {
        final error = SyncError.partialFailure(
          succeeded: 5,
          failed: 2,
        );
        expect(error.type, equals(SyncErrorType.partialFailure));
        expect(error.message, contains('5'));
        expect(error.message, contains('2'));
      });
    });

    group('Error messages', () {
      test('userMessage returns message by default', () {
        final error = NetworkError(message: 'User friendly message');
        expect(error.userMessage, equals('User friendly message'));
      });

      test('logMessage includes technical details', () {
        final error = NetworkError(
          message: 'User message',
          technicalDetails: 'Technical info',
        );
        expect(error.logMessage, contains('Technical info'));
      });

      test('toString returns logMessage', () {
        final error = NetworkError(
          message: 'Test',
          technicalDetails: 'Details',
        );
        expect(error.toString(), equals(error.logMessage));
      });
    });
  });
}
