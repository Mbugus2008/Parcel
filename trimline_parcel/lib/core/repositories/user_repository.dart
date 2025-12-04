import '../../../database/database_helper.dart';
import '../../../models/user_model.dart';
import '../errors/app_error.dart';
import '../security/password_hasher.dart';

/// Abstract repository interface for users
abstract class UserRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getUserByKey(String key);
  Future<User?> getUserByAccount(String account);
  Future<void> insertOrUpdateUsers(List<User> users);
  Future<bool> validateCredentials(String account, String password);
}

/// SQLite implementation of UserRepository
class SqliteUserRepository implements UserRepository {
  final DatabaseHelper _db;

  SqliteUserRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  @override
  Future<List<User>> getAllUsers() async {
    try {
      return await _db.getAllUsers();
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch users',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<User?> getUserByKey(String key) async {
    try {
      return await _db.getUserByKey(key);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch user',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<User?> getUserByAccount(String account) async {
    try {
      return await _db.getUserByAccount(account);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch user',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> insertOrUpdateUsers(List<User> users) async {
    try {
      // Hash passwords before storing
      final usersWithHashedPasswords = users.map((user) {
        if (user.password != null &&
            user.password!.isNotEmpty &&
            !PasswordHasher.isHashed(user.password!)) {
          final hashedPassword = PasswordHasher.hashPassword(user.password!);
          return User(
            key: user.key,
            agentCode: user.agentCode,
            customerIdNo: user.customerIdNo,
            mobileNo: user.mobileNo,
            status: user.status,
            statusSpecified: user.statusSpecified,
            name: user.name,
            account: user.account,
            password: hashedPassword,
            accountType: user.accountType,
            accountTypeSpecified: user.accountTypeSpecified,
            accountBalance: user.accountBalance,
            accountBalanceSpecified: user.accountBalanceSpecified,
          );
        }
        return user;
      }).toList();

      await _db.insertOrUpdateUsers(usersWithHashedPasswords);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to insert/update users',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> validateCredentials(String account, String password) async {
    try {
      final user = await getUserByAccount(account);
      if (user == null || user.password == null) return false;
      return PasswordHasher.verifyPassword(password, user.password!);
    } catch (e, stackTrace) {
      throw AuthError(
        message: 'Failed to validate credentials',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
