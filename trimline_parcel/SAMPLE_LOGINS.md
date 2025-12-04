# Sample Login Credentials

## 🔐 Test Users Available

✅ **Sample users are now seeded automatically** when the app first runs!

---

## 📋 Available Test Accounts

### 👨‍💼 Administrator Account
```
Username: admin
Password: admin123
Type: Admin (Account Type 1)
Name: System Administrator
Mobile: 0712345678
```
**Access Level:** Full administrative access to all features

---

### 👔 Supervisor Account
```
Username: supervisor
Password: super123
Type: Supervisor (Account Type 2)
Name: Warehouse Supervisor
Mobile: 0723456789
```
**Access Level:** Management and oversight capabilities

---

### 👤 Regular User Accounts

**User 1:**
```
Username: john
Password: john123
Type: User (Account Type 0)
Name: John Kamau
Mobile: 0734567890
Account Balance: KES 150.00
```

**User 2:**
```
Username: mary
Password: mary123
Type: User (Account Type 0)
Name: Mary Achieng
Mobile: 0745678901
Account Balance: KES 250.00
```
**Access Level:** Basic parcel operations

---

### 🏢 Depot Account
```
Username: depot
Password: depot123
Type: Depot (Account Type 3)
Name: Nairobi Depot
Mobile: 0756789012
```
**Access Level:** Depot management operations

---

### 📦 Parcel Handler Account
```
Username: parcel
Password: parcel123
Type: Parcel (Account Type 5)
Name: Parcel Handler
Mobile: 0767890123
```
**Access Level:** Parcel handling operations

---

## 🚀 Quick Start

1. **Launch the app**
2. **Check the login screen** - Should show "Users loaded: 6"
3. **Choose an account** from the list above
4. **Check "Remember Me"** to stay logged in
5. **Click Login**

---

## 🔄 How It Works

### Initial Setup (First Launch)
1. App creates local SQLite database
2. **Automatically seeds 6 sample users** into the database
3. UserService loads these users for authentication
4. Users are available immediately for login

### Backend Sync
- App also tries to sync users from backend API: `http://197.136.16.164:5019/api/Users`
- If backend is available, it will merge/update users
- If offline, sample users still work for testing

### Persistent Login
- Check "Remember Me" to save credentials
- Next app launch → automatic login
- Credentials stored securely in SharedPreferences

---

## 🧪 Testing Different User Types

### Test Admin Features
```
Login as: admin / admin123
Test: Full access to all features
```

### Test Supervisor Features
```
Login as: supervisor / super123
Test: Management capabilities
```

### Test Regular User Flow
```
Login as: john / john123
or
Login as: mary / mary123
Test: Basic parcel operations
```

### Test Depot Operations
```
Login as: depot / depot123
Test: Depot-specific features
```

---

## 🔍 Verifying Users Loaded

### In the App
Look at the bottom of the login screen for:
```
Users loaded: 6
```

### In Debug Console
You'll see:
```
👥 UserService: Loaded 6 users from database
✅ Seeded 6 sample users for testing
```

---

## 📋 Getting Sample Credentials

Since users are synced from your backend API, you'll need to:

### Option 1: Use Existing Backend Users
Contact your backend administrator or check the backend database for existing user accounts.

### Option 2: Create Test Users in Backend
Add test users to your backend system with the following account types:

| Account Type | Code | Purpose |
|-------------|------|---------|
| User | 0 | Regular user access |
| Admin | 1 | Administrator access |
| Supervisor | 2 | Supervisor privileges |
| Depot | 3 | Depot management |
| Fuel | 4 | Fuel management |
| Parcel | 5 | Parcel operations |

### Option 3: Check Synced Users
After the app launches, you can check how many users were synced:

1. Launch the app
2. On the login screen, look for the text showing "Users loaded: X"
3. This indicates how many users were successfully synced from the API

---

## 🧪 Development/Testing Setup

If you need to test without a backend connection:

### Mock User Creation
You can temporarily add sample users to the database initialization. Edit `lib/database/database_helper.dart` and add a method like:

```dart
Future<void> _seedSampleUsers(Database db) async {
  await db.insert('users', {
    'key': 'test-admin-001',
    'account': 'admin',
    'password': 'admin123',
    'name': 'Test Admin',
    'accountType': 1, // Admin
    'status': 1,
    'mobileNo': '0712345678',
  });
  
  await db.insert('users', {
    'key': 'test-user-001',
    'account': 'user',
    'password': 'user123',
    'name': 'Test User',
    'accountType': 0, // User
    'status': 1,
    'mobileNo': '0723456789',
  });
}
```

Call this method in `_onCreate()` after creating the users table.

### Recommended Test Accounts

```
👤 Admin Account
Username: admin
Password: admin123
Type: Admin (full access)

👤 Supervisor Account
Username: supervisor
Password: super123
Type: Supervisor (management access)

👤 Regular User Account
Username: user
Password: user123
Type: User (basic access)
```

---

## 🔍 Checking Current Users

### Via Database
You can query the SQLite database to see available users:

```sql
SELECT account, name, accountType, status FROM users;
```

### Via Code
Add debug output in `UserService`:

```dart
@override
Future<void> onInit() async {
  super.onInit();
  await loadUsersFromDatabase();
  
  // Debug: Print available users
  if (kDebugMode) {
    debugPrint('=== Available Users ===');
    for (var user in _users) {
      debugPrint('Account: ${user.account} | Name: ${user.name} | Type: ${user.accountType}');
    }
  }
  
  await syncUsersFromApi();
}
```

---

## ⚙️ API Configuration

Check your API endpoint configuration in `lib/utilities/Apis.dart`:

```dart
static const String baseUrl = 'http://197.136.16.164:5019/api';
```

Make sure:
- ✅ Backend server is running
- ✅ Network connectivity is available
- ✅ `/Users` endpoint returns valid user data
- ✅ Response format matches `UsersApiResponse` model

---

## 🚨 Troubleshooting

### "Users loaded: 0"
- Backend server not reachable
- API endpoint incorrect
- No users in backend database
- Network/firewall blocking connection

### "Invalid username or password"
- User exists but credentials don't match
- Case sensitivity in username
- User status is inactive (status != 1)

### Can't Login After Sync
- Check if users have `account` and `password` fields populated
- Verify `status` field is set to 1 (active)
- Check debug console for sync errors

---

## 📱 Current Implementation

### Persistent Login Feature
- ✅ "Remember Me" checkbox saves credentials
- ✅ Auto-login on app restart
- ✅ Logout clears saved session
- ✅ Credentials stored in SharedPreferences

### Security Notes
⚠️ Current implementation stores passwords in plain text in SharedPreferences.

**For production, consider:**
- Using `flutter_secure_storage` for encrypted storage
- Token-based authentication (JWT)
- Biometric authentication
- Password hashing

---

## 📞 Need Help?

Contact your backend administrator to:
1. Get existing user credentials
2. Create test accounts
3. Verify API endpoint configuration
4. Check user data format

Or check the backend database directly if you have access.
