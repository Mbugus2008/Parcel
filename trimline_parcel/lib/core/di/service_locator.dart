import 'package:get/get.dart';

import '../../database/database_helper.dart';
import '../config/app_config.dart';
import '../repositories/parcel_repository.dart';
import '../repositories/user_repository.dart';

/// Service locator for dependency injection
/// Uses GetX for service registration and retrieval
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  static ServiceLocator get instance => _instance;

  bool _initialized = false;

  /// Initialize all services and dependencies
  Future<void> init({Environment environment = Environment.production}) async {
    if (_initialized) return;

    // Initialize app configuration
    AppConfig().initialize(env: environment);

    // Register database helper
    Get.lazyPut<DatabaseHelper>(() => DatabaseHelper(), fenix: true);

    // Register repositories
    Get.lazyPut<ParcelRepository>(
      () => SqliteParcelRepository(db: Get.find<DatabaseHelper>()),
      fenix: true,
    );
    Get.lazyPut<UserRepository>(
      () => SqliteUserRepository(db: Get.find<DatabaseHelper>()),
      fenix: true,
    );

    _initialized = true;
  }

  /// Get a registered service
  T get<T>() => Get.find<T>();

  /// Check if a service is registered
  bool isRegistered<T>() => Get.isRegistered<T>();

  /// Reset all services (useful for testing)
  void reset() {
    Get.reset();
    _initialized = false;
  }

  /// Register a mock service (for testing)
  void registerMock<T>(T instance) {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
    Get.put<T>(instance);
  }
}

/// Convenience getters for common services
extension ServiceLocatorExtensions on ServiceLocator {
  DatabaseHelper get database => get<DatabaseHelper>();
  ParcelRepository get parcelRepository => get<ParcelRepository>();
  UserRepository get userRepository => get<UserRepository>();
}

/// Mixin for easy service access in controllers
mixin ServiceLocatorMixin {
  ServiceLocator get locator => ServiceLocator.instance;

  DatabaseHelper get database => locator.get<DatabaseHelper>();
  ParcelRepository get parcelRepository => locator.get<ParcelRepository>();
  UserRepository get userRepository => locator.get<UserRepository>();
}
