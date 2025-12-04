import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/security/password_hasher.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../utilities/Apis.dart';

/// Service to manage user data, API synchronization, and local persistence
class UserService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Observable users list
  final RxList<User> _users = <User>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSyncing = false.obs;
  final RxString _lastSyncTime = ''.obs;

  // Getters
  List<User> get users => _users.toList();
  bool get isLoading => _isLoading.value;
  bool get isSyncing => _isSyncing.value;
  String get lastSyncTime => _lastSyncTime.value;

  @override
  void onInit() {
    super.onInit();
    // Users are loaded explicitly from main.dart to ensure proper order
    // API sync happens in background after app starts
  }

  /// Ensure sample users exist in database
  Future<void> ensureSampleUsers() async {
    await _dbHelper.ensureSampleUsersExist();
  }

  /// Load users from local database
  Future<void> loadUsersFromDatabase() async {
    try {
      _isLoading.value = true;
      final usersFromDb = await _dbHelper.getAllUsers();
      _users.assignAll(usersFromDb);

      if (kDebugMode) {
        debugPrint(
            '👥 UserService: Loaded ${usersFromDb.length} users from database');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error loading users from database: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sync users from API and update local database
  Future<bool> syncUsersFromApi() async {
    try {
      _isSyncing.value = true;

      if (kDebugMode) {
        debugPrint('🔄 UserService: Starting API sync...');
      }

      final response = await _apiClient.postdata('Users', null);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = UsersApiResponse.fromJson(jsonData);

        if (apiResponse.isSuccess) {
          // Insert or update API users (keeps existing sample users)
          if (apiResponse.contents.isNotEmpty) {
            await _dbHelper.insertOrUpdateUsers(apiResponse.contents);
          }

          // Reload all users from database (includes sample + API users)
          await loadUsersFromDatabase();
          _lastSyncTime.value = DateTime.now().toIso8601String();

          if (kDebugMode) {
            debugPrint(
                '✅ UserService: Synced ${apiResponse.contents.length} API users. Total users: ${_users.length}');
          }

          return true;
        } else {
          if (kDebugMode) {
            debugPrint(
                '❌ UserService: API returned error: ${apiResponse.desc}');
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '❌ UserService: HTTP ${response.statusCode}: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Sync failed: $e');
      }
      return false;
    } finally {
      _isSyncing.value = false;
    }
  }

  /// Get user by account (username)
  User? getUserByAccount(String account) {
    try {
      return _users.firstWhere(
        (user) => user.account?.toLowerCase() == account.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get user by key
  User? getUserByKey(String key) {
    try {
      return _users.firstWhere((user) => user.key == key);
    } catch (e) {
      return null;
    }
  }

  /// Get users by account type
  List<User> getUsersByAccountType(AccountType accountType) {
    return _users.where((user) => user.accountType == accountType).toList();
  }

  /// Validate user credentials (for login)
  /// Supports both hashed passwords and legacy plain text passwords
  User? validateCredentials(String account, String password) {
    try {
      final user = _users.firstWhereOrNull(
        (user) => user.account?.toLowerCase() == account.toLowerCase(),
      );

      if (user == null || user.password == null) {
        return null;
      }

      // Use PasswordHasher which supports both hashed and legacy plain text
      if (PasswordHasher.verifyPassword(password, user.password!)) {
        return user;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error validating credentials: $e');
      }
      return null;
    }
  }

  /// Get users count by account type
  Map<AccountType, int> getUsersCountByType() {
    final counts = <AccountType, int>{};
    for (AccountType type in AccountType.values) {
      counts[type] = _users.where((user) => user.accountType == type).length;
    }
    return counts;
  }

  /// Force refresh from API
  Future<bool> refreshUsers() async {
    return await syncUsersFromApi();
  }

  /// Search users by name or account
  List<User> searchUsers(String query) {
    if (query.isEmpty) return users;
    final lowerQuery = query.toLowerCase();
    return _users.where((user) {
      final name = user.name?.toLowerCase() ?? '';
      final account = user.account?.toLowerCase() ?? '';
      return name.contains(lowerQuery) || account.contains(lowerQuery);
    }).toList();
  }

  /// Get active users (assuming status 1 means active)
  List<User> getActiveUsers() {
    return _users.where((user) => user.status == 1).toList();
  }

  /// Check if users need sync (e.g., if no users or last sync was long ago)
  bool needsSync() {
    if (_users.isEmpty) return true;
    if (_lastSyncTime.value.isEmpty) return true;
    try {
      final lastSync = DateTime.parse(_lastSyncTime.value);
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      // Sync if last sync was more than 1 hour ago
      return difference.inHours > 1;
    } catch (e) {
      return true;
    }
  }
}
