import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/security/password_hasher.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../models/pricing_rate.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _tableName = 'parcels';
  static const String _parcelDetailsTable = 'parcel_details';
  static const String _inspectionTable = 'bus_inspections';
  static const String _pricingRatesTable = 'pricing_rates';
  static const String _usersTable = 'users';
  static const String _sequenceCountersTable = 'parcel_sequence_counters';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'parcels_database.db');
    return await openDatabase(
      path,
      version: 6, // Version 6: Added indexes and timestamps
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        Document_No TEXT PRIMARY KEY,
        Date_sent TEXT NOT NULL,
        Sender_Name TEXT NOT NULL,
        Sender_ID TEXT,
        Sender_Phone TEXT NOT NULL,
        From_Location TEXT NOT NULL, 
        To_Location TEXT NOT NULL,
        Receiver_Name TEXT NOT NULL,
        Receiver_ID TEXT,
        Receiver_Phone TEXT NOT NULL,
        Status TEXT NOT NULL,
        Driver TEXT NOT NULL,
        Vehicle TEXT NOT NULL,
        WhoToPay TEXT NOT NULL, 
        Amount_Paid REAL NOT NULL,
        Paid INTEGER NOT NULL,
        Date_Collected TEXT,
        Date_Delivered TEXT,
        Out_For_Delivery_Time TEXT,
        Date_Returned TEXT,
        Description TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        sync_version INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indexes for frequently queried columns
    await _createParcelsIndexes(db);

    await _createInspectionTable(db);
    await _createPricingRatesTable(db);
    await _createParcelDetailsTable(db);
    await _createUsersTable(db);
    await _createSequenceCountersTable(db);
    // Sample data seeding disabled - uncomment to re-enable for testing
    // await _seedSampleUsers(db);
    // await _seedSampleParcels(db);
  }

  /// Create indexes on parcels table for query optimization
  Future<void> _createParcelsIndexes(Database db) async {
    // Index for status-based queries (dashboard tabs)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_status ON $_tableName(Status)
    ''');

    // Index for date-based queries (sorting, filtering)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_date_sent ON $_tableName(Date_sent)
    ''');

    // Index for sender phone lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_sender_phone ON $_tableName(Sender_Phone)
    ''');

    // Index for receiver phone lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_receiver_phone ON $_tableName(Receiver_Phone)
    ''');

    // Composite index for common dashboard query: status + date
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_status_date ON $_tableName(Status, Date_sent)
    ''');

    // Index for soft delete (exclude deleted records)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_deleted_at ON $_tableName(deleted_at)
    ''');

    // Index for sync status
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_parcels_sync_status ON $_tableName(sync_status)
    ''');

    if (kDebugMode) {
      debugPrint('📊 Created database indexes for optimized queries');
    }
  }

  Future<void> _createParcelDetailsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_parcelDetailsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        Document_No TEXT NOT NULL,
        Description TEXT,
        Amount REAL NOT NULL DEFAULT 0,
        Remarks TEXT,
        FOREIGN KEY (Document_No) REFERENCES $_tableName(Document_No) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createInspectionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_inspectionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bus_identifier TEXT NOT NULL,
        inspector_name TEXT,
        inspection_date TEXT NOT NULL,
        fields_json TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPricingRatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_pricingRatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT,
        location_from TEXT,
        location_to TEXT,
        weight_from REAL,
        weight_to REAL,
        subsequent REAL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable (
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
      )
    ''');
  }

  Future<void> _createSequenceCountersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sequenceCountersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agent_code TEXT NOT NULL,
        date TEXT NOT NULL,
        counter INTEGER NOT NULL DEFAULT 0,
        UNIQUE(agent_code, date)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createInspectionTable(db);
      await _createPricingRatesTable(db);
    }
    if (oldVersion < 3) {
      await _createParcelDetailsTable(db);
    }
    if (oldVersion < 4) {
      await _createUsersTable(db);
    }
    if (oldVersion < 5) {
      await _createSequenceCountersTable(db);
    }
    if (oldVersion < 6) {
      // Add new columns to parcels table
      await _upgradeToVersion6(db);
    }
  }

  /// Upgrade to version 6: Add timestamps, soft delete, sync support, and indexes
  Future<void> _upgradeToVersion6(Database db) async {
    if (kDebugMode) {
      debugPrint('🔄 Upgrading database to version 6...');
    }

    // Add new columns (SQLite doesn't support IF NOT EXISTS for columns, so we try-catch)
    final columnsToAdd = [
      'ALTER TABLE $_tableName ADD COLUMN created_at TEXT',
      'ALTER TABLE $_tableName ADD COLUMN updated_at TEXT',
      'ALTER TABLE $_tableName ADD COLUMN deleted_at TEXT',
      'ALTER TABLE $_tableName ADD COLUMN sync_status INTEGER DEFAULT 0',
      'ALTER TABLE $_tableName ADD COLUMN sync_version INTEGER DEFAULT 1',
    ];

    for (final sql in columnsToAdd) {
      try {
        await db.execute(sql);
      } catch (e) {
        // Column might already exist
        if (kDebugMode) {
          debugPrint('Column may already exist: $e');
        }
      }
    }

    // Set default timestamps for existing records
    final now = DateTime.now().toIso8601String();
    await db.execute('''
      UPDATE $_tableName 
      SET created_at = COALESCE(created_at, Date_sent, '$now'),
          updated_at = COALESCE(updated_at, '$now'),
          sync_status = COALESCE(sync_status, 0),
          sync_version = COALESCE(sync_version, 1)
      WHERE created_at IS NULL OR updated_at IS NULL
    ''');

    // Create indexes
    await _createParcelsIndexes(db);

    // Migrate passwords to hashed format
    await _migratePasswordsToHashed(db);

    if (kDebugMode) {
      debugPrint('✅ Database upgraded to version 6');
    }
  }

  /// Migrate existing plain text passwords to hashed format
  Future<void> _migratePasswordsToHashed(Database db) async {
    if (kDebugMode) {
      debugPrint('🔐 Migrating passwords to hashed format...');
    }

    final users = await db.query(_usersTable);
    int migratedCount = 0;

    for (final user in users) {
      final password = user['password'] as String?;
      if (password != null && !PasswordHasher.isHashed(password)) {
        final hashedPassword = PasswordHasher.hashPassword(password);
        await db.update(
          _usersTable,
          {
            'password': hashedPassword,
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'key = ?',
          whereArgs: [user['key']],
        );
        migratedCount++;
      }
    }

    if (kDebugMode) {
      debugPrint('✅ Migrated $migratedCount passwords to hashed format');
    }
  }

  /// Seeds sample users for development and testing
  Future<void> _seedSampleUsers(Database db) async {
    // Check if users already exist
    final existingUsers = await db.query(_usersTable, limit: 1);
    if (existingUsers.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ Skipping user seeding - ${existingUsers.length} users already exist');
      }
      return; // Don't seed if users already exist
    }

    if (kDebugMode) {
      debugPrint('🌱 Seeding sample users with hashed passwords...');
    }

    final sampleUsers = [
      {
        'key': 'admin-001',
        'account': 'admin',
        'password': PasswordHasher.hashPassword('admin123'),
        'name': 'System Administrator',
        'account_type': 1, // Admin
        'status': 1,
        'mobile_no': '0712345678',
        'agent_code': 'ADM001',
        'account_balance': 0.0,
      },
      {
        'key': 'super-001',
        'account': 'supervisor',
        'password': PasswordHasher.hashPassword('super123'),
        'name': 'Warehouse Supervisor',
        'account_type': 2, // Supervisor
        'status': 1,
        'mobile_no': '0723456789',
        'agent_code': 'SUP001',
        'account_balance': 0.0,
      },
      {
        'key': 'user-001',
        'account': 'john',
        'password': PasswordHasher.hashPassword('john123'),
        'name': 'John Kamau',
        'account_type': 0, // Regular User
        'status': 1,
        'mobile_no': '0734567890',
        'agent_code': 'USR001',
        'account_balance': 150.0,
      },
      {
        'key': 'user-002',
        'account': 'mary',
        'password': PasswordHasher.hashPassword('mary123'),
        'name': 'Mary Achieng',
        'account_type': 0, // Regular User
        'status': 1,
        'mobile_no': '0745678901',
        'agent_code': 'USR002',
        'account_balance': 250.0,
      },
      {
        'key': 'depot-001',
        'account': 'depot',
        'password': PasswordHasher.hashPassword('depot123'),
        'name': 'Nairobi Depot',
        'account_type': 3, // Depot
        'status': 1,
        'mobile_no': '0756789012',
        'agent_code': 'DEP001',
        'account_balance': 0.0,
      },
      {
        'key': 'parcel-001',
        'account': 'parcel',
        'password': PasswordHasher.hashPassword('parcel123'),
        'name': 'Parcel Handler',
        'account_type': 5, // Parcel
        'status': 1,
        'mobile_no': '0767890123',
        'agent_code': 'PRC001',
        'account_balance': 0.0,
      },
    ];

    final batch = db.batch();
    for (final user in sampleUsers) {
      batch.insert(_usersTable, user);
    }
    await batch.commit(noResult: true);

    if (kDebugMode) {
      debugPrint('✅ Seeded ${sampleUsers.length} sample users for testing');
    }
  }

  Future<void> _seedSampleParcels(Database db) async {
    final now = DateTime.now();
    const origins = <String>[
      'Nairobi',
      'Mombasa',
      'Kisumu',
      'Nakuru',
      'Eldoret',
      'Thika',
      'Malindi',
      'Nyeri',
    ];
    const destinations = <String>[
      'Mombasa',
      'Nairobi',
      'Kampala',
      'Dar es Salaam',
      'Kigali',
      'Arusha',
      'Dodoma',
      'Bujumbura',
    ];
    const drivers = <String>[
      'Kamau',
      'Achieng',
      'Otieno',
      'Mwangi',
      'Karanja',
      'Wanjiru',
      'Mutua',
      'Chebet',
    ];
    const vehicles = <String>[
      'KBA 123X',
      'KBB 456Y',
      'KBC 789Z',
      'KBD 234A',
      'KBE 567B',
      'KBF 890C',
      'KBG 135D',
      'KBH 246E',
    ];
    const notes = <String>[
      'Fragile items, handle with care.',
      'Priority customer delivery.',
      'Include weekend delivery instructions.',
      'Requires signature on delivery.',
      'High value electronics enclosed.',
      'Temperature-sensitive goods in transit.',
      'Consolidated shipment with other parcels.',
      'Notify receiver before delivery.',
    ];
    const statusLabels = <ParcelStatus, String>{
      ParcelStatus.pending: 'Pending',
      ParcelStatus.inTransit: 'In Transit',
      ParcelStatus.received: 'Received',
      ParcelStatus.collected: 'Collected',
    };

    final samples = List<Parcel>.generate(32, (index) {
      final status = ParcelStatus.values[index % ParcelStatus.values.length];
      final cycleIndex = index % origins.length;
      final sentDate = now.subtract(Duration(days: (index * 2) + cycleIndex));
      final routeDuration = 1 + (index % 4);
      final outForDelivery = status == ParcelStatus.pending
          ? null
          : sentDate.add(Duration(hours: 6 + (index % 5) * 2));
      final deliveredDate =
          (status == ParcelStatus.received || status == ParcelStatus.collected)
              ? sentDate.add(Duration(days: routeDuration))
              : null;
      final collectedDate = status == ParcelStatus.collected
          ? sentDate.add(Duration(days: routeDuration + 1))
          : null;
      final returnedDate = (status == ParcelStatus.pending && index % 7 == 3)
          ? sentDate.add(Duration(days: routeDuration + 2))
          : null;
      final whoPays = WhoToPay.values[index % WhoToPay.values.length];

      return Parcel(
        Document_No: 'SAMPLE-${(index + 1).toString().padLeft(3, '0')}',
        Date_sent: sentDate,
        Sender_Name: 'Sender ${index + 1}',
        Sender_ID: 'SID${(index + 1).toString().padLeft(4, '0')}',
        Sender_Phone: '070${(index + 1234567).toString().padLeft(7, '0')}',
        From: origins[cycleIndex],
        To: destinations[index % destinations.length],
        Receiver_Name: 'Receiver ${index + 1}',
        Receiver_ID: 'RID${(index + 1).toString().padLeft(4, '0')}',
        Receiver_Phone: '079${(index + 7654321).toString().padLeft(7, '0')}',
        Status: status,
        Driver: drivers[index % drivers.length],
        Vehicle: vehicles[index % vehicles.length],
        Who_to_Pay: whoPays,
        Amount_Paid: (1350 + (index * 55) + (cycleIndex * 10)).toDouble(),
        Paid: status == ParcelStatus.collected ||
            status == ParcelStatus.received && index.isOdd ||
            index % 5 == 0,
        Date_Delivered: deliveredDate,
        Date_Collected: collectedDate,
        Out_For_Delivery_Time: outForDelivery,
        Date_Returned: returnedDate,
        Notes:
            '${notes[index % notes.length]} (${origins[cycleIndex]} → ${destinations[index % destinations.length]} - ${statusLabels[status]})',
      );
    });

    final batch = db.batch();
    for (final parcel in samples) {
      batch.insert(
        _tableName,
        parcel.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  // --- CRUD Operations ---

  /// Inserts a parcel into the database with proper transaction handling.
  /// Returns the id of the last inserted row.
  Future<int> insertParcel(Parcel parcel) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Use transaction for atomicity
    return await db.transaction((txn) async {
      // Add timestamps to the parcel data
      final parcelData = parcel.toDbMap();
      parcelData['created_at'] = now;
      parcelData['updated_at'] = now;
      parcelData['sync_status'] = 0; // 0 = pending sync
      parcelData['sync_version'] = 1;

      final result = await txn.insert(
        _tableName,
        parcelData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert parcel details if any
      if (parcel.parcelDetails.isNotEmpty && parcel.Document_No != null) {
        for (final detail in parcel.parcelDetails) {
          await txn.insert(_parcelDetailsTable, {
            'Document_No': parcel.Document_No,
            'Description': detail.Description,
            'Amount': detail.Amount ?? 0.0,
            'Remarks': detail.Remarks,
          });
        }
      }

      return result;
    });
  }

  /// Retrieves a single parcel by its Document_No.
  /// Returns the Parcel if found, otherwise null.
  Future<Parcel?> getParcel(String documentNo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );

    if (maps.isNotEmpty) {
      final parcel = Parcel.fromDbMap(maps.first);
      // Load parcel details
      parcel.parcelDetails = await _getParcelDetails(db, documentNo);
      return parcel;
    }
    return null;
  }

  /// Retrieves all parcels from the database.
  /// Uses LEFT JOIN to efficiently load parcel details in a single query.
  /// Excludes soft-deleted records.
  Future<List<Parcel>> getAllParcels() async {
    final db = await database;

    // Use LEFT JOIN to get parcels with their details in one query
    final results = await db.rawQuery('''
      SELECT 
        p.*,
        pd.id as detail_id,
        pd.Description as detail_description,
        pd.Amount as detail_amount,
        pd.Remarks as detail_remarks
      FROM $_tableName p
      LEFT JOIN $_parcelDetailsTable pd ON p.Document_No = pd.Document_No
      WHERE p.deleted_at IS NULL
      ORDER BY p.Date_sent DESC
    ''');

    // Group results by parcel and build objects
    final parcelMap = <String, Parcel>{};

    for (final row in results) {
      final documentNo = row['Document_No'] as String?;
      if (documentNo == null) continue;

      // Get or create parcel
      if (!parcelMap.containsKey(documentNo)) {
        parcelMap[documentNo] = Parcel.fromDbMap(row);
      }

      // Add detail if exists
      final detailId = row['detail_id'];
      if (detailId != null) {
        parcelMap[documentNo]!.parcelDetails.add(
              Parcel_Details(
                Document_No: documentNo,
                Description: row['detail_description'] as String?,
                Amount: (row['detail_amount'] as num?)?.toDouble() ?? 0.0,
                Remarks: row['detail_remarks'] as String?,
              ),
            );
      }
    }

    return parcelMap.values.toList();
  }

  /// Retrieves parcels filtered by status.
  /// Optimized query using status index.
  Future<List<Parcel>> getParcelsByStatus(String status) async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT 
        p.*,
        pd.id as detail_id,
        pd.Description as detail_description,
        pd.Amount as detail_amount,
        pd.Remarks as detail_remarks
      FROM $_tableName p
      LEFT JOIN $_parcelDetailsTable pd ON p.Document_No = pd.Document_No
      WHERE p.Status = ? AND p.deleted_at IS NULL
      ORDER BY p.Date_sent DESC
    ''', [status]);

    final parcelMap = <String, Parcel>{};

    for (final row in results) {
      final documentNo = row['Document_No'] as String?;
      if (documentNo == null) continue;

      if (!parcelMap.containsKey(documentNo)) {
        parcelMap[documentNo] = Parcel.fromDbMap(row);
      }

      final detailId = row['detail_id'];
      if (detailId != null) {
        parcelMap[documentNo]!.parcelDetails.add(
              Parcel_Details(
                Document_No: documentNo,
                Description: row['detail_description'] as String?,
                Amount: (row['detail_amount'] as num?)?.toDouble() ?? 0.0,
                Remarks: row['detail_remarks'] as String?,
              ),
            );
      }
    }

    return parcelMap.values.toList();
  }

  /// Search parcels by phone number (sender or receiver)
  Future<List<Parcel>> searchParcelsByPhone(String phone) async {
    final db = await database;
    final searchPattern = '%$phone%';

    final results = await db.rawQuery('''
      SELECT 
        p.*,
        pd.id as detail_id,
        pd.Description as detail_description,
        pd.Amount as detail_amount,
        pd.Remarks as detail_remarks
      FROM $_tableName p
      LEFT JOIN $_parcelDetailsTable pd ON p.Document_No = pd.Document_No
      WHERE (p.Sender_Phone LIKE ? OR p.Receiver_Phone LIKE ?)
        AND p.deleted_at IS NULL
      ORDER BY p.Date_sent DESC
    ''', [searchPattern, searchPattern]);

    final parcelMap = <String, Parcel>{};

    for (final row in results) {
      final documentNo = row['Document_No'] as String?;
      if (documentNo == null) continue;

      if (!parcelMap.containsKey(documentNo)) {
        parcelMap[documentNo] = Parcel.fromDbMap(row);
      }

      final detailId = row['detail_id'];
      if (detailId != null) {
        parcelMap[documentNo]!.parcelDetails.add(
              Parcel_Details(
                Document_No: documentNo,
                Description: row['detail_description'] as String?,
                Amount: (row['detail_amount'] as num?)?.toDouble() ?? 0.0,
                Remarks: row['detail_remarks'] as String?,
              ),
            );
      }
    }

    return parcelMap.values.toList();
  }

  /// Updates an existing parcel in the database with transaction handling.
  /// Returns the number of rows affected.
  Future<int> updateParcel(Parcel parcel) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // Add updated timestamp and increment sync version
      final parcelData = parcel.toDbMap();
      parcelData['updated_at'] = now;
      parcelData['sync_status'] = 0; // Mark as needing sync

      // Get current sync version and increment
      final currentVersion = await txn.query(
        _tableName,
        columns: ['sync_version'],
        where: 'Document_No = ?',
        whereArgs: [parcel.Document_No],
      );

      if (currentVersion.isNotEmpty) {
        final version = (currentVersion.first['sync_version'] as int?) ?? 1;
        parcelData['sync_version'] = version + 1;
      }

      final result = await txn.update(
        _tableName,
        parcelData,
        where: 'Document_No = ?',
        whereArgs: [parcel.Document_No],
      );

      // Update parcel details - delete old and insert new
      if (parcel.Document_No != null) {
        await txn.delete(
          _parcelDetailsTable,
          where: 'Document_No = ?',
          whereArgs: [parcel.Document_No],
        );

        for (final detail in parcel.parcelDetails) {
          await txn.insert(_parcelDetailsTable, {
            'Document_No': parcel.Document_No,
            'Description': detail.Description,
            'Amount': detail.Amount ?? 0.0,
            'Remarks': detail.Remarks,
          });
        }
      }

      return result;
    });
  }

  /// Soft deletes a parcel (marks as deleted but keeps data)
  Future<int> softDeleteParcel(String documentNo) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      _tableName,
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 0,
      },
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  /// Restores a soft-deleted parcel
  Future<int> restoreParcel(String documentNo) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      _tableName,
      {
        'deleted_at': null,
        'updated_at': now,
        'sync_status': 0,
      },
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  /// Hard deletes a parcel from the database by its Document_No.
  /// Use softDeleteParcel for normal operations.
  /// Returns the number of rows affected.
  Future<int> deleteParcel(String documentNo) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  /// Get parcels that need to be synced
  Future<List<Parcel>> getUnsyncedParcels() async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT 
        p.*,
        pd.id as detail_id,
        pd.Description as detail_description,
        pd.Amount as detail_amount,
        pd.Remarks as detail_remarks
      FROM $_tableName p
      LEFT JOIN $_parcelDetailsTable pd ON p.Document_No = pd.Document_No
      WHERE p.sync_status = 0
      ORDER BY p.updated_at ASC
    ''');

    final parcelMap = <String, Parcel>{};

    for (final row in results) {
      final documentNo = row['Document_No'] as String?;
      if (documentNo == null) continue;

      if (!parcelMap.containsKey(documentNo)) {
        parcelMap[documentNo] = Parcel.fromDbMap(row);
      }

      final detailId = row['detail_id'];
      if (detailId != null) {
        parcelMap[documentNo]!.parcelDetails.add(
              Parcel_Details(
                Document_No: documentNo,
                Description: row['detail_description'] as String?,
                Amount: (row['detail_amount'] as num?)?.toDouble() ?? 0.0,
                Remarks: row['detail_remarks'] as String?,
              ),
            );
      }
    }

    return parcelMap.values.toList();
  }

  /// Mark a parcel as synced
  Future<int> markParcelSynced(String documentNo) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'sync_status': 1}, // 1 = synced
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  Future<int> markInspectionSynced(int id) async {
    final db = await database;
    return db.update(
      _inspectionTable,
      <String, Object?>{
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteInspection(int id) async {
    final db = await database;
    return db.delete(
      _inspectionTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // --- Pricing Rates Operations ---
  Future<int> insertPricingRate(PricingRate rate) async {
    final db = await database;
    return await db.insert(_pricingRatesTable, rate.toJson());
  }

  Future<List<PricingRate>> getPricingRates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_pricingRatesTable);
    return maps.map((map) => PricingRate.fromJson(map)).toList();
  }

  Future<int> deleteAllPricingRates() async {
    final db = await database;
    return await db.delete(_pricingRatesTable);
  }

  // --- Parcel Details Operations ---

  /// Inserts multiple parcel details for a given parcel
  Future<void> _insertParcelDetails(
    Database db,
    String documentNo,
    List<Parcel_Details> details,
  ) async {
    if (kDebugMode) {
      debugPrint(
          '📦 Inserting ${details.length} parcel details for $documentNo');
    }
    final batch = db.batch();
    for (final detail in details) {
      batch.insert(
        _parcelDetailsTable,
        {
          'Document_No': documentNo,
          'Description': detail.Description,
          'Amount': detail.Amount ?? 0.0,
          'Remarks': detail.Remarks,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (kDebugMode) {
        debugPrint('  - ${detail.Description}: ${detail.Amount}');
      }
    }
    await batch.commit(noResult: true);
  }

  /// Retrieves all parcel details for a given parcel
  Future<List<Parcel_Details>> _getParcelDetails(
    Database db,
    String documentNo,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      _parcelDetailsTable,
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );

    final details = List.generate(maps.length, (i) {
      return Parcel_Details(
        Document_No: maps[i]['Document_No'] as String?,
        Description: maps[i]['Description'] as String?,
        Amount: (maps[i]['Amount'] as num?)?.toDouble(),
        Remarks: maps[i]['Remarks'] as String?,
      );
    });

    if (kDebugMode) {
      debugPrint('📥 Loaded ${details.length} parcel details for $documentNo');
      for (final detail in details) {
        debugPrint('  - ${detail.Description}: ${detail.Amount}');
      }
    }

    return details;
  }

  /// Deletes all parcel details for a given parcel
  Future<void> _deleteParcelDetails(Database db, String documentNo) async {
    await db.delete(
      _parcelDetailsTable,
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  // ==================== USER OPERATIONS ====================

  /// Insert or update multiple users (used for API sync)
  Future<void> insertOrUpdateUsers(List<User> users) async {
    final db = await database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert(
        _usersTable,
        user.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    if (kDebugMode) {
      debugPrint('👥 Inserted/Updated ${users.length} users in database');
    }
  }

  /// Get all users from database
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      orderBy: 'name ASC',
    );

    final users = maps.map((map) => User.fromDbMap(map)).toList();

    if (kDebugMode) {
      debugPrint('👥 Loaded ${users.length} users from database');
    }

    return users;
  }

  /// Get user by account (username)
  Future<User?> getUserByAccount(String account) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      where: 'account = ?',
      whereArgs: [account],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromDbMap(maps.first);
    }
    return null;
  }

  /// Get user by key
  Future<User?> getUserByKey(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromDbMap(maps.first);
    }
    return null;
  }

  /// Get users by account type
  Future<List<User>> getUsersByAccountType(AccountType accountType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      where: 'account_type = ?',
      whereArgs: [accountType.value],
      orderBy: 'name ASC',
    );

    return maps.map((map) => User.fromDbMap(map)).toList();
  }

  /// Delete all users (used before fresh API sync)
  Future<void> clearAllUsers() async {
    final db = await database;
    await db.delete(_usersTable);

    if (kDebugMode) {
      debugPrint('👥 Cleared all users from database');
    }
  }

  /// Get users count
  Future<int> getUsersCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_usersTable');
    return result.first['count'] as int;
  }

  /// Force reseed sample users (clears existing and adds fresh sample users)
  Future<void> forceReseedSampleUsers() async {
    final db = await database;

    if (kDebugMode) {
      debugPrint('🔄 Force reseeding sample users...');
    }

    // Delete existing sample users (those with specific keys)
    await db.delete(
      _usersTable,
      where: 'key LIKE ?',
      whereArgs: ['%-001'],
    );

    // Seed fresh sample users
    await _seedSampleUsers(db);

    if (kDebugMode) {
      final count = await getUsersCount();
      debugPrint('✅ Force reseed complete. Total users: $count');
    }
  }

  /// Clear all sample test data from the database
  Future<void> clearSampleData() async {
    final db = await database;

    if (kDebugMode) {
      debugPrint('🗑️ Clearing all sample test data...');
    }

    // Delete sample parcels (Document_No starts with 'SAMPLE-')
    final deletedParcels = await db.delete(
      _tableName,
      where: 'Document_No LIKE ?',
      whereArgs: ['SAMPLE-%'],
    );

    // Delete sample users (key ends with '-001')
    final deletedUsers = await db.delete(
      _usersTable,
      where: 'key LIKE ?',
      whereArgs: ['%-001'],
    );

    if (kDebugMode) {
      debugPrint(
          '✅ Cleared $deletedParcels sample parcels and $deletedUsers sample users');
    }
  }

  /// Ensure sample users exist (call on app startup)
  Future<void> ensureSampleUsersExist() async {
    final db = await database;

    // Check if admin sample user exists
    final adminUser = await db.query(
      _usersTable,
      where: 'key = ?',
      whereArgs: ['admin-001'],
      limit: 1,
    );

    if (adminUser.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Sample users missing - seeding now...');
      }
      await _seedSampleUsers(db);
    } else {
      if (kDebugMode) {
        debugPrint('✅ Sample users already exist');
      }
    }
  }

  // ============================================
  // PARCEL SEQUENCE COUNTER METHODS
  // ============================================

  /// Get the next sequence number for a given agent on a given date
  /// Returns the next counter value (1-based) after incrementing
  Future<int> getNextSequenceNumber(String agentCode, String date) async {
    final db = await database;

    // Try to get existing counter for this agent/date combo
    final existing = await db.query(
      _sequenceCountersTable,
      where: 'agent_code = ? AND date = ?',
      whereArgs: [agentCode, date],
      limit: 1,
    );

    int nextCounter;

    if (existing.isEmpty) {
      // No record exists, create new one with counter = 1
      await db.insert(_sequenceCountersTable, {
        'agent_code': agentCode,
        'date': date,
        'counter': 1,
      });
      nextCounter = 1;
    } else {
      // Record exists, increment counter
      final currentCounter = existing.first['counter'] as int;
      nextCounter = currentCounter + 1;

      await db.update(
        _sequenceCountersTable,
        {'counter': nextCounter},
        where: 'agent_code = ? AND date = ?',
        whereArgs: [agentCode, date],
      );
    }

    if (kDebugMode) {
      debugPrint('🔢 Sequence counter for $agentCode on $date: $nextCounter');
    }

    return nextCounter;
  }

  /// Get the current sequence number for a given agent on a given date
  /// Returns 0 if no parcels have been created yet
  Future<int> getCurrentSequenceNumber(String agentCode, String date) async {
    final db = await database;

    final existing = await db.query(
      _sequenceCountersTable,
      where: 'agent_code = ? AND date = ?',
      whereArgs: [agentCode, date],
      limit: 1,
    );

    if (existing.isEmpty) {
      return 0;
    }

    return existing.first['counter'] as int;
  }

  /// Reset the sequence counter for a given agent on a given date
  /// Useful for testing or corrections
  Future<void> resetSequenceCounter(String agentCode, String date) async {
    final db = await database;

    await db.delete(
      _sequenceCountersTable,
      where: 'agent_code = ? AND date = ?',
      whereArgs: [agentCode, date],
    );

    if (kDebugMode) {
      debugPrint('🔄 Reset sequence counter for $agentCode on $date');
    }
  }
}
