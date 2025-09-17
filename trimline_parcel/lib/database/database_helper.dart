import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/parcel_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _tableName = 'parcels';

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
      version: 1,
      onCreate: _createDb,
      // onUpgrade: _onUpgrade, // For schema migrations
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
    await _seedSampleParcels(db);
  }

  Future<void> _seedSampleParcels(Database db) async {
    final now = DateTime.now();
    const origins = <String>['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'];
    const destinations = <String>['Mombasa', 'Nairobi', 'Kampala', 'Dar es Salaam', 'Kigali'];
    const drivers = <String>['Kamau', 'Achieng', 'Otieno', 'Mwangi', 'Karanja'];
    const vehicles = <String>['KBA 123X', 'KBB 456Y', 'KBC 789Z', 'KBD 234A', 'KBE 567B'];
    const statusLabels = <ParcelStatus, String>{
      ParcelStatus.pending: 'Pending',
      ParcelStatus.inTransit: 'In Transit',
      ParcelStatus.received: 'Received',
      ParcelStatus.collected: 'Collected',
    };

    final samples = List<Parcel>.generate(20, (index) {
      final status = ParcelStatus.values[index % ParcelStatus.values.length];
      final sentDate = now.subtract(Duration(days: index * 2));
      final outForDelivery = status == ParcelStatus.inTransit ||
              status == ParcelStatus.received ||
              status == ParcelStatus.collected
          ? sentDate.add(const Duration(hours: 8))
          : null;
      final deliveredDate = (status == ParcelStatus.received || status == ParcelStatus.collected)
          ? sentDate.add(const Duration(days: 1))
          : null;
      final collectedDate = status == ParcelStatus.collected
          ? sentDate.add(const Duration(days: 2))
          : null;
      final whoPays = index.isEven ? WhoToPay.Sender : WhoToPay.Receiver;

      return Parcel(
        Document_No: 'SAMPLE-${(index + 1).toString().padLeft(3, '0')}',
        Date_sent: sentDate,
        Sender_Name: 'Sender ${index + 1}',
        Sender_ID: 'SID${(index + 1).toString().padLeft(4, '0')}',
        Sender_Phone: '070${(index + 1234567).toString().padLeft(7, '0')}',
        From: origins[index % origins.length],
        To: destinations[index % destinations.length],
        Receiver_Name: 'Receiver ${index + 1}',
        Receiver_ID: 'RID${(index + 1).toString().padLeft(4, '0')}',
        Receiver_Phone: '079${(index + 7654321).toString().padLeft(7, '0')}',
        Status: status,
        Driver: drivers[index % drivers.length],
        Vehicle: vehicles[index % vehicles.length],
        Who_to_Pay: whoPays,
        Amount_Paid: (1500 + index * 75).toDouble(),
        Paid: status == ParcelStatus.collected || index % 4 == 0,
        Date_Delivered: deliveredDate,
        Date_Collected: collectedDate,
        Out_For_Delivery_Time: outForDelivery,
        Notes: 'Demo parcel ${(index + 1)} (${statusLabels[status]}).',
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
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if Document_No already exists
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
}

