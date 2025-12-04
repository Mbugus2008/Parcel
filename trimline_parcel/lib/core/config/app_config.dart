/// Application configuration management
/// Centralizes all environment-specific settings
library;

import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Current environment
  Environment _environment = Environment.development;
  Environment get environment => _environment;

  /// Initialize configuration based on environment
  void initialize({Environment env = Environment.development}) {
    _environment = env;
    if (kDebugMode) {
      debugPrint('🔧 AppConfig initialized for: ${env.name}');
    }
  }

  /// API Base URL
  String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://nav.trimline.co.ke:4010/api/Parcel/';
      case Environment.staging:
        return 'https://staging.trimline.co.ke/api/Parcel/';
      case Environment.production:
        return 'https://api.trimline.co.ke/api/Parcel/';
    }
  }

  /// Whether to use HTTPS (enforced in production)
  bool get enforceHttps {
    return _environment == Environment.production;
  }

  /// Client identifier for API requests
  String get clientIdentifier {
    switch (_environment) {
      case Environment.development:
        return 'TRIMLINE_DEV';
      case Environment.staging:
        return 'TRIMLINE_STAGING';
      case Environment.production:
        return 'TRIMLINE_PROD';
    }
  }

  /// Database name
  String get databaseName {
    switch (_environment) {
      case Environment.development:
        return 'parcels_dev.db';
      case Environment.staging:
        return 'parcels_staging.db';
      case Environment.production:
        return 'parcels_database.db';
    }
  }

  /// Enable debug logging
  bool get enableDebugLogging {
    return _environment != Environment.production;
  }

  /// Session timeout in minutes
  int get sessionTimeoutMinutes {
    switch (_environment) {
      case Environment.development:
        return 60 * 24; // 24 hours for dev
      case Environment.staging:
        return 60 * 8; // 8 hours for staging
      case Environment.production:
        return 60 * 4; // 4 hours for production
    }
  }

  /// API request timeout in seconds
  int get apiTimeoutSeconds {
    return 30;
  }

  /// Maximum retry attempts for API calls
  int get maxRetryAttempts {
    return 3;
  }

  /// Sync interval in minutes
  int get syncIntervalMinutes {
    switch (_environment) {
      case Environment.development:
        return 1;
      case Environment.staging:
        return 5;
      case Environment.production:
        return 15;
    }
  }

  /// Update URL for APK downloads
  static String get updateUrl {
    // Base URL where update.json and APK files are hosted
    return 'https://trimline.co.ke/apps/Parcel/';
  }
}
