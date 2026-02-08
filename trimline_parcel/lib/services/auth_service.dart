import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'user_service.dart';

/// Service to manage user authentication and session persistence
class AuthService extends GetxService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyUserKey = 'user_key';
  static const String _keyAccountType = 'account_type';
  static const String _keyRememberMe = 'remember_me';

  final Rxn<User> _currentUser = Rxn<User>();
  final RxBool _isLoggedIn = false.obs;

  User? get currentUser => _currentUser.value;
  bool get isLoggedIn => _isLoggedIn.value;

  Rxn<User> get currentUserRx => _currentUser;
  RxBool get isLoggedInRx => _isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    // Session restoration is called explicitly from main.dart
    // to ensure proper initialization order
  }

  /// Public method to restore session - call after UserService is ready
  Future<void> restoreSession() async {
    await _restoreSession();
  }

  /// Restore session from SharedPreferences
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      if (!rememberMe) {
        if (kDebugMode) {
          debugPrint('⏭️ Remember Me disabled - skipping session restore');
        }
        return;
      }

      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userKey = prefs.getString(_keyUserKey);

      if (kDebugMode) {
        debugPrint(
            '🔄 Restoring session - isLoggedIn: $isLoggedIn, userKey: $userKey');
      }

      if (isLoggedIn && userKey != null) {
        final userService = Get.find<UserService>();

        // Wait for users to load if not already loaded
        if (userService.users.isEmpty) {
          if (kDebugMode) {
            debugPrint('⏳ Waiting for UserService to load users...');
          }
          await userService.loadUsersFromDatabase();
        }

        final user = userService.users.firstWhereOrNull(
          (u) => u.key == userKey,
        );

        if (user != null) {
          _currentUser.value = user;
          _isLoggedIn.value = true;
          if (kDebugMode) {
            debugPrint(
                '✅ Session restored - Welcome back ${user.name} (${user.account})');
          }
        } else {
          // User not found, clear session
          if (kDebugMode) {
            debugPrint(
                '❌ User not found in database - clearing session (userKey: $userKey)');
          }
          await logout();
        }
      }
    } catch (e) {
      // Error restoring session, clear it
      if (kDebugMode) {
        debugPrint('❌ Error restoring session: $e');
      }
      await logout();
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final userService = Get.find<UserService>();

      if (kDebugMode) {
        debugPrint(
            '🔐 Login attempt - Username: "$username", Password: "${password.isNotEmpty ? "***" : "(empty)"}');
        debugPrint('   Users available: ${userService.users.length}');
        for (var u in userService.users) {
          debugPrint(
              '   - Account: "${u.account}", Password: "${u.password}", Name: ${u.name}');
        }
      }

      final user = userService.validateCredentials(username, password);

      if (user != null) {
        _currentUser.value = user;
        _isLoggedIn.value = true;

        if (kDebugMode) {
          debugPrint('✅ Login successful for: ${user.account} (${user.name})');
        }

        // Save session
        await _saveSession(user, rememberMe);

        return true;
      }

      if (kDebugMode) {
        debugPrint('❌ Login failed - Invalid credentials');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login error: $e');
      }
      return false;
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(User user, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setBool(_keyRememberMe, rememberMe);
      await prefs.setString(_keyUsername, user.account ?? '');
      if (user.key != null) {
        await prefs.setString(_keyUserKey, user.key!);
      }
      await prefs.setInt(_keyAccountType, user.accountType?.index ?? 0);
    } catch (e) {
      // Log error but don't crash - session save is non-critical
      if (kDebugMode) {
        debugPrint('⚠️ Error saving session: $e');
      }
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyUserKey);
      await prefs.remove(_keyAccountType);
      // Keep rememberMe preference

      _currentUser.value = null;
      _isLoggedIn.value = false;
    } catch (e) {
      // Log error but don't crash - still clear local state
      if (kDebugMode) {
        debugPrint('⚠️ Error clearing session: $e');
      }
      _currentUser.value = null;
      _isLoggedIn.value = false;
    }
  }

  /// Check if user has specific account type
  bool hasAccountType(AccountType type) {
    return _currentUser.value?.accountType == type;
  }

  /// Check if user is admin
  bool get isAdmin => hasAccountType(AccountType.admin);

  /// Check if user is supervisor
  bool get isSupervisor => hasAccountType(AccountType.supervisor);
}
