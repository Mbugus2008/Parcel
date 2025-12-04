import '../../../database/database_helper.dart';
import '../../../models/parcel_model.dart';
import '../errors/app_error.dart';

/// Abstract repository interface for parcels
abstract class ParcelRepository {
  Future<List<Parcel>> getAllParcels();
  Future<List<Parcel>> getParcelsByStatus(ParcelStatus status);
  Future<Parcel?> getParcelByDocumentNo(String documentNo);
  Future<int> insertParcel(Parcel parcel);
  Future<int> updateParcel(Parcel parcel);
  Future<int> deleteParcel(String documentNo);
  Future<List<Parcel>> searchParcels(String query);
  Future<int> getParcelCount();
  Future<Map<ParcelStatus, int>> getStatusCounts();
}

/// SQLite implementation of ParcelRepository
class SqliteParcelRepository implements ParcelRepository {
  final DatabaseHelper _db;

  SqliteParcelRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  @override
  Future<List<Parcel>> getAllParcels() async {
    try {
      return await _db.getAllParcels();
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch parcels',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Parcel>> getParcelsByStatus(ParcelStatus status) async {
    try {
      final allParcels = await _db.getAllParcels();
      return allParcels.where((p) => p.Status == status).toList();
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch parcels by status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Parcel?> getParcelByDocumentNo(String documentNo) async {
    try {
      final parcels = await _db.getAllParcels();
      return parcels.where((p) => p.Document_No == documentNo).firstOrNull;
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to fetch parcel',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> insertParcel(Parcel parcel) async {
    try {
      return await _db.insertParcel(parcel);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to insert parcel',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> updateParcel(Parcel parcel) async {
    try {
      return await _db.updateParcel(parcel);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to update parcel',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> deleteParcel(String documentNo) async {
    try {
      return await _db.deleteParcel(documentNo);
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to delete parcel',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Parcel>> searchParcels(String query) async {
    try {
      final allParcels = await _db.getAllParcels();
      final lowerQuery = query.toLowerCase();
      return allParcels.where((p) {
        return (p.Document_No?.toLowerCase().contains(lowerQuery) ?? false) ||
            (p.Receiver_Name?.toLowerCase().contains(lowerQuery) ?? false) ||
            (p.Receiver_Phone?.contains(lowerQuery) ?? false) ||
            (p.Sender_Name?.toLowerCase().contains(lowerQuery) ?? false) ||
            (p.Sender_Phone?.contains(lowerQuery) ?? false);
      }).toList();
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to search parcels',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> getParcelCount() async {
    try {
      final parcels = await _db.getAllParcels();
      return parcels.length;
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to get parcel count',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<ParcelStatus, int>> getStatusCounts() async {
    try {
      final parcels = await _db.getAllParcels();
      final counts = <ParcelStatus, int>{};
      for (final parcel in parcels) {
        if (parcel.Status != null) {
          counts[parcel.Status!] = (counts[parcel.Status!] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e, stackTrace) {
      throw DatabaseError(
        message: 'Failed to get status counts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
