import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/ui/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('required', () {
      test('returns error for null value', () {
        expect(FormValidators.required(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(FormValidators.required(''), isNotNull);
      });

      test('returns error for whitespace only', () {
        expect(FormValidators.required('   '), isNotNull);
      });

      test('returns null for valid value', () {
        expect(FormValidators.required('test'), isNull);
      });

      test('uses custom field name in error message', () {
        final result = FormValidators.required(null, 'Username');
        expect(result, contains('Username'));
      });
    });

    group('email', () {
      test('returns error for null value', () {
        expect(FormValidators.email(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(FormValidators.email(''), isNotNull);
      });

      test('returns error for invalid email - no @', () {
        expect(FormValidators.email('testemail.com'), isNotNull);
      });

      test('returns error for invalid email - no domain', () {
        expect(FormValidators.email('test@'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(FormValidators.email('test@email.com'), isNull);
      });

      test('returns null for valid email with subdomain', () {
        expect(FormValidators.email('test@mail.email.com'), isNull);
      });
    });

    group('phone', () {
      test('returns error for null value', () {
        final result = FormValidators.phone(null);
        expect(result, isNotNull);
      });

      test('returns error for empty string', () {
        final result = FormValidators.phone('');
        expect(result, isNotNull);
      });

      test('returns error for too short number', () {
        final result = FormValidators.phone('12345');
        expect(result, isNotNull);
      });

      test('returns null for valid phone number', () {
        final result = FormValidators.phone('0712345678');
        expect(result, isNull);
      });

      test('returns null for phone with country code', () {
        final result = FormValidators.phone('+254712345678');
        expect(result, isNull);
      });
    });

    group('minLength', () {
      test('returns error for null value', () {
        final validator = FormValidators.minLength(5);
        expect(validator(null), isNotNull);
      });

      test('returns error for string shorter than min', () {
        final validator = FormValidators.minLength(5);
        expect(validator('test'), isNotNull);
      });

      test('returns null for string equal to min', () {
        final validator = FormValidators.minLength(5);
        expect(validator('tests'), isNull);
      });

      test('returns null for string longer than min', () {
        final validator = FormValidators.minLength(5);
        expect(validator('testing'), isNull);
      });
    });

    group('maxLength', () {
      test('returns null for null value', () {
        final validator = FormValidators.maxLength(10);
        expect(validator(null), isNull);
      });

      test('returns null for string shorter than max', () {
        final validator = FormValidators.maxLength(10);
        expect(validator('test'), isNull);
      });

      test('returns error for string longer than max', () {
        final validator = FormValidators.maxLength(10);
        expect(validator('12345678901'), isNotNull);
      });
    });

    group('password', () {
      test('returns error for null value', () {
        expect(FormValidators.password(null), isNotNull);
      });

      test('returns error for password shorter than 8 chars', () {
        expect(FormValidators.password('Pass1'), isNotNull);
      });

      test('returns error for password without uppercase', () {
        expect(FormValidators.password('password1'), isNotNull);
      });

      test('returns error for password without lowercase', () {
        expect(FormValidators.password('PASSWORD1'), isNotNull);
      });

      test('returns error for password without number', () {
        expect(FormValidators.password('Password'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(FormValidators.password('Password1'), isNull);
      });
    });

    group('confirmPassword', () {
      test('returns error for non-matching password', () {
        final validator = FormValidators.confirmPassword('Password1');
        expect(validator('Password2'), isNotNull);
      });

      test('returns null for matching password', () {
        final validator = FormValidators.confirmPassword('Password1');
        expect(validator('Password1'), isNull);
      });
    });

    group('numberInRange', () {
      test('returns error for non-numeric value', () {
        final validator = FormValidators.numberInRange(0, 100);
        expect(validator('abc'), isNotNull);
      });

      test('returns error for number below min', () {
        final validator = FormValidators.numberInRange(0, 100);
        expect(validator('-1'), isNotNull);
      });

      test('returns error for number above max', () {
        final validator = FormValidators.numberInRange(0, 100);
        expect(validator('101'), isNotNull);
      });

      test('returns null for number in range', () {
        final validator = FormValidators.numberInRange(0, 100);
        expect(validator('50'), isNull);
      });
    });

    group('positiveNumber', () {
      test('returns error for zero', () {
        expect(FormValidators.positiveNumber('0'), isNotNull);
      });

      test('returns error for negative number', () {
        expect(FormValidators.positiveNumber('-5'), isNotNull);
      });

      test('returns null for positive integer', () {
        expect(FormValidators.positiveNumber('5'), isNull);
      });
    });

    group('trackingNumber', () {
      test('returns error for empty string', () {
        expect(FormValidators.trackingNumber(''), isNotNull);
      });

      test('returns error for too short tracking number', () {
        expect(FormValidators.trackingNumber('ABC'), isNotNull);
      });

      test('returns null for valid alphanumeric tracking number', () {
        expect(FormValidators.trackingNumber('ABC123456'), isNull);
      });
    });

    group('address', () {
      test('returns error for too short address', () {
        expect(FormValidators.address('123 Main'), isNotNull);
      });

      test('returns null for valid address', () {
        expect(FormValidators.address('123 Main Street, City'), isNull);
      });
    });

    group('recipientName', () {
      test('returns error for single character', () {
        expect(FormValidators.recipientName('J'), isNotNull);
      });

      test('returns null for valid name', () {
        expect(FormValidators.recipientName('John Doe'), isNull);
      });
    });

    group('combine', () {
      test('returns first error when first validator fails', () {
        final validator = FormValidators.combine([
          FormValidators.required,
          FormValidators.email,
        ]);
        final result = validator(null);
        expect(result, contains('required'));
      });

      test('returns null when all validators pass', () {
        final validator = FormValidators.combine([
          FormValidators.required,
          FormValidators.email,
        ]);
        expect(validator('test@email.com'), isNull);
      });
    });

    group('optional', () {
      test('returns null for empty string', () {
        final validator = FormValidators.optional(FormValidators.email);
        expect(validator(''), isNull);
      });

      test('runs validation for non-empty value', () {
        final validator = FormValidators.optional(FormValidators.email);
        expect(validator('invalid'), isNotNull);
      });

      test('returns null for valid value', () {
        final validator = FormValidators.optional(FormValidators.email);
        expect(validator('test@email.com'), isNull);
      });
    });
  });
}
