# User Management Implementation

This document explains the User model and UserService implementation for the Parcel tracking app.

## Overview

The user management system consists of:
1. **User Model** (`lib/models/user_model.dart`) - Data model for users with account types
2. **Database Integration** - Users table in SQLite with CRUD operations
3. **UserService** (`lib/services/user_service.dart`) - Service for API sync and user management
4. **API Integration** - Fetches users from `{baseUrl}/Users` endpoint

## User Model Features

### Account Types
- **User** (0) - Regular user
- **Admin** (1) - Administrator
- **Supervisor** (2) - Supervisor 
- **Deport** (3) - Depot user
- **Fuel** (4) - Fuel management
- **Parcel** (5) - Parcel operations

### Fields
- `key` - Unique identifier
- `agentCode` - Agent code
- `customerIdNo` - Customer ID number
- `mobileNo` - Mobile phone number  
- `status` - User status (active/inactive)
- `name` - Display name
- `account` - Username (unique)
- `password` - User password
- `accountType` - Account type enum
- `accountBalance` - Account balance

## UserService Usage

### Basic Operations

```dart
// Get the service instance
final userService = Get.find<UserService>();

// Get all users
List<User> allUsers = userService.users;

// Search users
List<User> searchResults = userService.searchUsers("john");

// Get user by account
User? user = userService.getUserByAccount("john.doe");

// Validate login credentials
User? validUser = userService.validateCredentials("john.doe", "password123");

// Get users by type
List<User> admins = userService.getUsersByAccountType(AccountType.admin);

// Force refresh from API
bool success = await userService.refreshUsers();
```

### Observable Data

```dart
// Listen to users changes in UI
Obx(() => Text('Users loaded: ${userService.users.length}')),

// Loading states
Obx(() => userService.isLoading 
  ? CircularProgressIndicator() 
  : UsersList()),

// Sync status
Obx(() => userService.isSyncing 
  ? Text('Syncing users...') 
  : Text('Last sync: ${userService.lastSyncTime}')),
```

### Login Example

```dart
class LoginController extends GetxController {
  final UserService _userService = Get.find<UserService>();
  
  Future<bool> login(String username, String password) async {
    // Validate credentials against local database
    final user = _userService.validateCredentials(username, password);
    
    if (user != null) {
      // Store current user session
      // Navigate to dashboard
      return true;
    }
    
    return false;
  }
}
```

## Database Schema

The users table is automatically created with these fields:

```sql
CREATE TABLE users (
  key TEXT PRIMARY KEY,
  agent_code TEXT,
  customer_id_no TEXT,
  mobile_no TEXT,
  status INTEGER,
  status_specified INTEGER NOT NULL DEFAULT 0,
  name TEXT,
  account TEXT UNIQUE,
  password TEXT,
  account_type INTEGER,
  account_type_specified INTEGER NOT NULL DEFAULT 0,
  account_balance REAL,
  account_balance_specified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Automatic Initialization

Users are automatically loaded when the app starts:

1. **App Launch** → UserService initializes
2. **Database Load** → Loads cached users from SQLite
3. **API Sync** → Fetches latest users from server
4. **UI Updates** → Observable lists update automatically

## API Response Format

The service expects this JSON format from `{baseUrl}/Users`:

```json
{
  "Code": 0,
  "Desc": "Success",
  "Contents": [
    {
      "Key": "user123",
      "Agent_Code": "AG001", 
      "Customer_ID_No": "12345678",
      "Mobile_No": "+254712345678",
      "Status": 1,
      "StatusSpecified": true,
      "Name": "John Doe",
      "Account": "john.doe",
      "Password": "password123",
      "Account_type": 1,
      "Account_typeSpecified": true,
      "Account_Balance": 1000.50,
      "Account_BalanceSpecified": true
    }
  ]
}
```

## Error Handling

The service handles:
- Network failures (falls back to cached data)
- API errors (logs and continues with local data)
- Database errors (graceful degradation)

## Security Notes

⚠️ **Important**: Passwords are stored in plain text for demo purposes. In production:
- Hash passwords before storage
- Use secure authentication tokens
- Implement proper session management
- Add encryption for sensitive data

## Testing

To test the implementation:

1. Run the app - users will be fetched automatically
2. Check debug console for sync logs
3. Use login screen to test credential validation
4. Verify users persist after app restart