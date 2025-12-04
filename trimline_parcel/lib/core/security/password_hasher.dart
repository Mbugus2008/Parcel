/// Password hashing utility using PBKDF2
/// Provides secure password hashing without external dependencies
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _saltLength = 32;
  static const int _iterations = 10000;
  static const int _keyLength = 32;

  /// Hash a password with a random salt
  /// Returns a string in format: salt:hash (both base64 encoded)
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _pbkdf2(password, salt);

    final saltBase64 = base64Encode(salt);
    final hashBase64 = base64Encode(hash);

    return '$saltBase64:$hashBase64';
  }

  /// Verify a password against a stored hash
  /// [password] - The plain text password to verify
  /// [storedHash] - The stored hash in format salt:hash
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        // Legacy plain text password - compare directly but log warning
        // This allows migration from old system
        return password == storedHash;
      }

      final salt = base64Decode(parts[0]);
      final expectedHash = base64Decode(parts[1]);
      final actualHash = _pbkdf2(password, salt);

      return _constantTimeEquals(expectedHash, actualHash);
    } catch (e) {
      // If parsing fails, try plain text comparison for legacy support
      return password == storedHash;
    }
  }

  /// Check if a stored password is already hashed
  static bool isHashed(String storedPassword) {
    if (storedPassword.isEmpty) return false;
    final parts = storedPassword.split(':');
    if (parts.length != 2) return false;

    try {
      base64Decode(parts[0]);
      base64Decode(parts[1]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a cryptographically secure random salt
  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// PBKDF2 key derivation function using SHA-256
  static Uint8List _pbkdf2(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);

    Uint8List result = Uint8List(_keyLength);
    int resultOffset = 0;
    int blockNum = 1;

    while (resultOffset < _keyLength) {
      final block = _pbkdf2Block(passwordBytes, salt, blockNum);
      final bytesToCopy = min(_keyLength - resultOffset, block.length);

      for (int i = 0; i < bytesToCopy; i++) {
        result[resultOffset + i] = block[i];
      }

      resultOffset += bytesToCopy;
      blockNum++;
    }

    return result;
  }

  /// Generate a single PBKDF2 block
  static Uint8List _pbkdf2Block(
    List<int> password,
    Uint8List salt,
    int blockNum,
  ) {
    // U1 = PRF(Password, Salt || INT(i))
    final blockBytes = Uint8List(4);
    blockBytes[0] = (blockNum >> 24) & 0xff;
    blockBytes[1] = (blockNum >> 16) & 0xff;
    blockBytes[2] = (blockNum >> 8) & 0xff;
    blockBytes[3] = blockNum & 0xff;

    final hmacKey = Hmac(sha256, password);
    var u = hmacKey.convert([...salt, ...blockBytes]).bytes;
    var result = Uint8List.fromList(u);

    // U2, U3, ... UN
    for (int i = 1; i < _iterations; i++) {
      u = hmacKey.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
