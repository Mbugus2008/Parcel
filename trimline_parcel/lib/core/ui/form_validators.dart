/// Form validation utilities
class FormValidators {
  FormValidators._();

  /// Validates that a field is not empty
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates phone number format
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces, dashes, and parentheses for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Allow optional + at the start, then 7-15 digits
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates minimum length
  static String? Function(String?) minLength(int min,
      [String fieldName = 'This field']) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }
      if (value.length < min) {
        return '$fieldName must be at least $min characters';
      }
      return null;
    };
  }

  /// Validates maximum length
  static String? Function(String?) maxLength(int max,
      [String fieldName = 'This field']) {
    return (String? value) {
      if (value != null && value.length > max) {
        return '$fieldName must be at most $max characters';
      }
      return null;
    };
  }

  /// Validates password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates password confirmation matches
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  /// Validates a number is within range
  static String? Function(String?) numberInRange(double min, double max,
      [String fieldName = 'Value']) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      if (number < min || number > max) {
        return '$fieldName must be between $min and $max';
      }
      return null;
    };
  }

  /// Validates positive number
  static String? positiveNumber(String? value, [String fieldName = 'Value']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates tracking number format
  static String? trackingNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tracking number is required';
    }
    // Allow alphanumeric characters, dashes, and underscores
    final trackingRegex = RegExp(r'^[A-Za-z0-9\-_]{5,50}$');
    if (!trackingRegex.hasMatch(value.trim())) {
      return 'Please enter a valid tracking number';
    }
    return null;
  }

  /// Validates address format (basic)
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  /// Validates recipient name
  static String? recipientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Recipient name is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter a valid name';
    }
    // Only allow letters, spaces, and common name characters
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  /// Combines multiple validators
  static String? Function(String?) combine(
      List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Optional validator - only runs if value is not empty
  static String? Function(String?) optional(
      String? Function(String?) validator) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return validator(value);
    };
  }
}
