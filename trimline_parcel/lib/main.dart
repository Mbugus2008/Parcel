import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/parcel_controller.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'database/database_helper.dart';
import 'pages/login.dart';
import 'pages/parcel_dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/parcel_number_service.dart';
import 'services/user_service.dart';
import 'utilities/Apis.dart';
import 'utilities/logger.dart';
import 'utils/app_colors.dart';
import 'utils/updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  // Use development for debug builds, production for release
  final environment =
      kDebugMode ? Environment.development : Environment.production;
  AppConfig().initialize(env: environment);

  // Initialize service locator (registers repositories and database helper)
  await ServiceLocator.instance.init(environment: environment);

  // Initialize core services
  Get.put(LoggerService());
  Get.put(ApiClient());
  Get.put(ConnectivityService());

  // Initialize business services
  final userService = Get.put(UserService());
  final authService = Get.put(AuthService());

  // Ensure a single app-scoped ParcelController is available
  Get.put(ParcelController());

  // Initialize parcel number service
  Get.put(ParcelNumberService());

  // Initialize update controller
  Get.put(UpdateController());

  // Sample users disabled - uncomment to re-enable for testing
  // await userService.ensureSampleUsers();

  // Clear existing sample test data (one-time cleanup)
  await DatabaseHelper().clearSampleData();

  // Load users from database
  await userService.loadUsersFromDatabase();

  // Now restore auth session after users are loaded
  await authService.restoreSession();

  // Start background sync (non-blocking)
  userService.syncUsersFromApi();

  runApp(MyApp(isLoggedIn: authService.isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Parcel Tracker',
      theme: _buildLightTheme(),
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const ParcelDashboardPage() : const LoginScreen(),
    );
  }
}

ThemeData _buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(secondary: AppColors.accent);

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.scaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.surface,
      elevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: AppColors.surface,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.4)),
      prefixIconColor: colorScheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconTheme: IconThemeData(color: colorScheme.primary),
    tabBarTheme: base.tabBarTheme.copyWith(
      indicatorColor: colorScheme.secondary,
      labelColor: AppColors.surface,
      unselectedLabelColor: AppColors.surface.withOpacity(0.7),
      labelStyle: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: base.textTheme.labelLarge,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: AppColors.surface,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: colorScheme.primary,
      labelStyle: base.textTheme.labelMedium?.copyWith(
        color: AppColors.onSurface,
      ),
      secondarySelectedColor: colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
