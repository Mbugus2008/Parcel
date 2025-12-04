/// User model representing a user account in the system
class User {
  final String? key;
  final String? agentCode;
  final String? customerIdNo;
  final String? mobileNo;
  final int? status;
  final bool? statusSpecified;
  final String? name;
  final String? account;
  final String? password;
  final AccountType? accountType;
  final bool? accountTypeSpecified;
  final double? accountBalance;
  final bool? accountBalanceSpecified;

  User({
    this.key,
    this.agentCode,
    this.customerIdNo,
    this.mobileNo,
    this.status,
    this.statusSpecified,
    this.name,
    this.account,
    this.password,
    this.accountType,
    this.accountTypeSpecified,
    this.accountBalance,
    this.accountBalanceSpecified,
  });

  /// Create User from API JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      key: json['Key'] as String?,
      agentCode: json['Agent_Code'] as String?,
      customerIdNo: json['Customer_ID_No'] as String?,
      mobileNo: json['Mobile_No'] as String?,
      status: json['Status'] as int?,
      statusSpecified: json['StatusSpecified'] as bool?,
      name: json['Name'] as String?,
      account: json['Account'] as String?,
      password: json['Password'] as String?,
      accountType: json['Account_type'] != null
          ? AccountType.fromValue(json['Account_type'] as int)
          : null,
      accountTypeSpecified: json['Account_typeSpecified'] as bool?,
      accountBalance: (json['Account_Balance'] as num?)?.toDouble(),
      accountBalanceSpecified: json['Account_BalanceSpecified'] as bool?,
    );
  }

  /// Create User from database map
  factory User.fromDbMap(Map<String, dynamic> map) {
    return User(
      key: map['key'] as String?,
      agentCode: map['agent_code'] as String?,
      customerIdNo: map['customer_id_no'] as String?,
      mobileNo: map['mobile_no'] as String?,
      status: map['status'] as int?,
      statusSpecified: map['status_specified'] == 1,
      name: map['name'] as String?,
      account: map['account'] as String?,
      password: map['password'] as String?,
      accountType: map['account_type'] != null
          ? AccountType.fromValue(map['account_type'] as int)
          : null,
      accountTypeSpecified: map['account_type_specified'] == 1,
      accountBalance: (map['account_balance'] as num?)?.toDouble(),
      accountBalanceSpecified: map['account_balance_specified'] == 1,
    );
  }

  /// Convert User to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'Key': key,
      'Agent_Code': agentCode,
      'Customer_ID_No': customerIdNo,
      'Mobile_No': mobileNo,
      'Status': status,
      'StatusSpecified': statusSpecified,
      'Name': name,
      'Account': account,
      'Password': password,
      'Account_type': accountType?.value,
      'Account_typeSpecified': accountTypeSpecified,
      'Account_Balance': accountBalance,
      'Account_BalanceSpecified': accountBalanceSpecified,
    };
  }

  /// Convert User to database map
  Map<String, dynamic> toDbMap() {
    return {
      'key': key,
      'agent_code': agentCode,
      'customer_id_no': customerIdNo,
      'mobile_no': mobileNo,
      'status': status,
      'status_specified': statusSpecified == true ? 1 : 0,
      'name': name,
      'account': account,
      'password': password,
      'account_type': accountType?.value,
      'account_type_specified': accountTypeSpecified == true ? 1 : 0,
      'account_balance': accountBalance,
      'account_balance_specified': accountBalanceSpecified == true ? 1 : 0,
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? key,
    String? agentCode,
    String? customerIdNo,
    String? mobileNo,
    int? status,
    bool? statusSpecified,
    String? name,
    String? account,
    String? password,
    AccountType? accountType,
    bool? accountTypeSpecified,
    double? accountBalance,
    bool? accountBalanceSpecified,
  }) {
    return User(
      key: key ?? this.key,
      agentCode: agentCode ?? this.agentCode,
      customerIdNo: customerIdNo ?? this.customerIdNo,
      mobileNo: mobileNo ?? this.mobileNo,
      status: status ?? this.status,
      statusSpecified: statusSpecified ?? this.statusSpecified,
      name: name ?? this.name,
      account: account ?? this.account,
      password: password ?? this.password,
      accountType: accountType ?? this.accountType,
      accountTypeSpecified: accountTypeSpecified ?? this.accountTypeSpecified,
      accountBalance: accountBalance ?? this.accountBalance,
      accountBalanceSpecified:
          accountBalanceSpecified ?? this.accountBalanceSpecified,
    );
  }

  @override
  String toString() {
    return 'User(key: $key, name: $name, account: $account, accountType: $accountType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Account type enumeration based on XSD definition
enum AccountType {
  user(0, 'User'),
  admin(1, 'Admin'),
  supervisor(2, 'Supervisor'),
  deport(3, 'Deport'),
  fuel(4, 'Fuel'),
  parcel(5, 'Parcel');

  const AccountType(this.value, this.displayName);

  final int value;
  final String displayName;

  /// Get AccountType from integer value
  static AccountType? fromValue(int value) {
    for (AccountType type in AccountType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  /// Get AccountType from string name
  static AccountType? fromName(String name) {
    for (AccountType type in AccountType.values) {
      if (type.displayName.toLowerCase() == name.toLowerCase()) return type;
    }
    return null;
  }

  @override
  String toString() => displayName;
}

/// API response wrapper for users
class UsersApiResponse {
  final int code;
  final String desc;
  final List<User> contents;

  UsersApiResponse({
    required this.code,
    required this.desc,
    required this.contents,
  });

  factory UsersApiResponse.fromJson(Map<String, dynamic> json) {
    return UsersApiResponse(
      code: json['Code'] as int? ?? 0,
      desc: json['Desc'] as String? ?? '',
      contents: (json['Contents'] as List<dynamic>?)
              ?.map((item) => User.fromJson(item as Map<String, dynamic>))
              .toList() ??
          <User>[],
    );
  }

  bool get isSuccess => code == 0;
}
