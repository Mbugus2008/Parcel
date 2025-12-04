/// Validation utilities for form fields
class ValidationUtils {
  ValidationUtils._();

  /// Validates Kenyan phone numbers
  /// Accepts formats: +254XXXXXXXXX, 254XXXXXXXXX, 07XXXXXXXX, 01XXXXXXXX
  static String? validateKenyanPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, hyphens, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check for valid Kenyan phone formats
    final patterns = [
      RegExp(r'^\+254[17]\d{8}$'), // +254 format (9 digits after)
      RegExp(r'^254[17]\d{8}$'), // 254 format (9 digits after)
      RegExp(r'^0[17]\d{8}$'), // Local format starting with 07 or 01
    ];

    final isValid = patterns.any((pattern) => pattern.hasMatch(cleaned));

    if (!isValid) {
      return 'Enter a valid Kenyan phone number';
    }

    return null;
  }

  /// Validates phone numbers (lenient version)
  /// Use when international numbers might be entered
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length < 10) {
      return 'Phone number is too short';
    }

    if (cleaned.length > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Validates amount/currency fields
  static String? validateAmount(String? value, {double? maxAmount}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);

    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (maxAmount != null && amount > maxAmount) {
      return 'Amount seems too large. Please verify.';
    }

    return null;
  }

  /// Validates required text fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates ID/Passport numbers
  static String? validateIdNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final cleaned = value.replaceAll(RegExp(r'\s'), '');

    if (cleaned.length < 5) {
      return 'ID/Passport number is too short';
    }

    if (cleaned.length > 20) {
      return 'ID/Passport number is too long';
    }

    return null;
  }

  /// Formats phone number to standard format
  static String formatKenyanPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Convert to +254 format
    if (cleaned.startsWith('0')) {
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('+254')) {
      return cleaned;
    }

    return phone; // Return as-is if format is unclear
  }
}
