import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../inspection/models/bus_inspection.dart';
import '../models/parcel_model.dart';
import '../models/pricing_rate.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _tableName = 'parcels';

  static const String _inspectionTable = 'bus_inspections';
  static const String _pricingRatesTable = 'pricing_rates';

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
      version: 2,
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
        Description TEXT 
      )
    ''');
    // Note: Removed Created_At and Ref_No as they are not in the Parcel model
    await _createInspectionTable(db);
    await _createPricingRatesTable(db);
    await _seedSampleParcels(db);
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createInspectionTable(db);
      await _createPricingRatesTable(db);
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
      final outForDelivery =
          status == ParcelStatus.pending
              ? null
              : sentDate.add(Duration(hours: 6 + (index % 5) * 2));
      final deliveredDate =
          (status == ParcelStatus.received || status == ParcelStatus.collected)
              ? sentDate.add(Duration(days: routeDuration))
              : null;
      final collectedDate =
          status == ParcelStatus.collected
              ? sentDate.add(Duration(days: routeDuration + 1))
              : null;
      final returnedDate =
          (status == ParcelStatus.pending && index % 7 == 3)
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
        Paid:
            status == ParcelStatus.collected ||
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

  /// Inserts a parcel into the database.
  /// Returns the id of the last inserted row.
  Future<int> insertParcel(Parcel parcel) async {
    final db = await database;
    return await db.insert(
      _tableName,
      parcel.toDbMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace if Document_No already exists
    );
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
      return Parcel.fromDbMap(maps.first);
    }
    return null;
  }

  /// Retrieves all parcels from the database.
  /// Returns a list of Parcels.
  Future<List<Parcel>> getAllParcels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      return Parcel.fromDbMap(maps[i]);
    });
  }

  /// Updates an existing parcel in the database.
  /// Returns the number of rows affected.
  Future<int> updateParcel(Parcel parcel) async {
    final db = await database;
    return await db.update(
      _tableName,
      parcel.toDbMap(),
      where: 'Document_No = ?',
      whereArgs: [parcel.Document_No],
    );
  }

  /// Deletes a parcel from the database by its Document_No.
  /// Returns the number of rows affected.
  Future<int> deleteParcel(String documentNo) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'Document_No = ?',
      whereArgs: [documentNo],
    );
  }

  // Example of a more specific query (can be added later if needed)
  // Future<List<Parcel>> getParcelsByStatus(ParcelStatus status) async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     _tableName,
  //     where: 'Status = ?',
  //     whereArgs: [status.toString().split('.').last],
  //   );
  //   return List.generate(maps.length, (i) {
  //     return Parcel.fromDbMap(maps[i]);
  //   });
  // }
  Future<int> insertInspection(BusInspection inspection) async {
    final db = await database;
    return db.insert(
      _inspectionTable,
      inspection.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateInspection(BusInspection inspection) async {
    if (inspection.id == null) {
      throw ArgumentError('Cannot update an inspection without an id');
    }
    final db = await database;
    return db.update(
      _inspectionTable,
      inspection.toDbMap(),
      where: 'id = ?',
      whereArgs: <Object?>[inspection.id],
    );
  }

  Future<List<BusInspection>> getAllInspections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inspectionTable,
      orderBy: 'inspection_date DESC',
    );
    return maps.map(BusInspection.fromDbMap).toList();
  }

  Future<List<BusInspection>> getPendingInspections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inspectionTable,
      where: 'is_synced = ?',
      whereArgs: const <Object?>[0],
      orderBy: 'inspection_date DESC',
    );
    return maps.map(BusInspection.fromDbMap).toList();
  }

  Future<BusInspection?> getInspectionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inspectionTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return BusInspection.fromDbMap(maps.first);
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
}
