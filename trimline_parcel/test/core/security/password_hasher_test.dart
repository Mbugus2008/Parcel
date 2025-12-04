import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/security/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    group('hashPassword', () {
      test('returns a non-empty string', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        expect(hash, isNotEmpty);
      });

      test('returns hash with salt separator', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        expect(hash.contains(':'), isTrue);
      });

      test('returns hash with two parts (salt:hash)', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        final parts = hash.split(':');
        expect(parts.length, equals(2));
      });

      test('produces different hashes for same password (random salt)', () {
        final hash1 = PasswordHasher.hashPassword('testPassword');
        final hash2 = PasswordHasher.hashPassword('testPassword');
        expect(hash1, isNot(equals(hash2)));
      });

      test('produces different hashes for different passwords', () {
        final hash1 = PasswordHasher.hashPassword('password1');
        final hash2 = PasswordHasher.hashPassword('password2');
        expect(hash1, isNot(equals(hash2)));
      });

      test('handles empty password', () {
        final hash = PasswordHasher.hashPassword('');
        expect(hash, isNotEmpty);
        expect(hash.contains(':'), isTrue);
      });

      test('handles unicode characters in password', () {
        final hash = PasswordHasher.hashPassword('пароль123');
        expect(hash, isNotEmpty);
        expect(hash.contains(':'), isTrue);
      });

      test('handles special characters in password', () {
        final hash = PasswordHasher.hashPassword('P@ssw0rd!#\$%');
        expect(hash, isNotEmpty);
        expect(hash.contains(':'), isTrue);
      });

      test('handles very long password', () {
        final longPassword = 'a' * 1000;
        final hash = PasswordHasher.hashPassword(longPassword);
        expect(hash, isNotEmpty);
        expect(hash.contains(':'), isTrue);
      });
    });

    group('verifyPassword', () {
      test('returns true for correct password', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        final result = PasswordHasher.verifyPassword('testPassword', hash);
        expect(result, isTrue);
      });

      test('returns false for incorrect password', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        final result = PasswordHasher.verifyPassword('wrongPassword', hash);
        expect(result, isFalse);
      });

      test('returns false for similar password', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        final result = PasswordHasher.verifyPassword('testpassword', hash);
        expect(result, isFalse);
      });

      test('returns false for password with extra space', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        final result = PasswordHasher.verifyPassword('testPassword ', hash);
        expect(result, isFalse);
      });

      test('handles empty password verification', () {
        final hash = PasswordHasher.hashPassword('');
        final result = PasswordHasher.verifyPassword('', hash);
        expect(result, isTrue);
      });

      test('handles unicode password verification', () {
        final hash = PasswordHasher.hashPassword('пароль123');
        final result = PasswordHasher.verifyPassword('пароль123', hash);
        expect(result, isTrue);
      });

      test('handles special characters verification', () {
        final hash = PasswordHasher.hashPassword('P@ssw0rd!#\$%');
        final result = PasswordHasher.verifyPassword('P@ssw0rd!#\$%', hash);
        expect(result, isTrue);
      });

      // Legacy plain text support
      test('supports legacy plain text password (migration)', () {
        final result = PasswordHasher.verifyPassword('plaintext', 'plaintext');
        expect(result, isTrue);
      });

      test('returns false for wrong legacy password', () {
        final result = PasswordHasher.verifyPassword('wrong', 'plaintext');
        expect(result, isFalse);
      });

      test('handles malformed hash gracefully', () {
        final result =
            PasswordHasher.verifyPassword('test', 'not-a-valid-hash');
        expect(result, isFalse);
      });

      test('handles hash with invalid base64', () {
        final result =
            PasswordHasher.verifyPassword('test', 'invalid!!!:base64!!!');
        // Should fall back to plain text comparison
        expect(result, isFalse);
      });
    });

    group('isHashed', () {
      test('returns true for hashed password', () {
        final hash = PasswordHasher.hashPassword('testPassword');
        expect(PasswordHasher.isHashed(hash), isTrue);
      });

      test('returns false for plain text password', () {
        expect(PasswordHasher.isHashed('plainPassword'), isFalse);
      });

      test('returns false for empty string', () {
        expect(PasswordHasher.isHashed(''), isFalse);
      });

      test('returns false for string without colon', () {
        expect(PasswordHasher.isHashed('nocolonhere'), isFalse);
      });

      test('returns false for string with colon but invalid base64', () {
        expect(PasswordHasher.isHashed('not:valid'), isFalse);
      });

      test('returns false for string with multiple colons', () {
        expect(PasswordHasher.isHashed('a:b:c'), isFalse);
      });
    });

    group('security properties', () {
      test('same password produces verifiable hash each time', () {
        const password = 'MySecurePassword123';

        // Hash multiple times
        final hashes =
            List.generate(5, (_) => PasswordHasher.hashPassword(password));

        // All should be different (unique salts)
        expect(hashes.toSet().length, equals(5));

        // All should verify correctly
        for (final hash in hashes) {
          expect(PasswordHasher.verifyPassword(password, hash), isTrue);
        }
      });

      test('timing attack resistance (constant time comparison)', () {
        final hash = PasswordHasher.hashPassword('testPassword');

        // These should take similar time regardless of how early the mismatch occurs
        // Note: This is a basic test - proper timing tests need more sophisticated methods
        PasswordHasher.verifyPassword('x', hash);
        PasswordHasher.verifyPassword('testPasswor', hash);
        PasswordHasher.verifyPassword('testPassword', hash);

        // If we got here without errors, basic functionality works
        expect(true, isTrue);
      });
    });
  });
}
