import '../models/bus_inspection.dart';
import '../../database/database_helper.dart';

class BusInspectionRepository {
  BusInspectionRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  Future<BusInspection> saveInspection(BusInspection inspection) async {
    final DateTime now = DateTime.now();
    if (inspection.id == null) {
      final BusInspection record = inspection.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      final int id = await _dbHelper.insertInspection(record);
      return record.copyWith(id: id);
    }

    final BusInspection record = inspection.copyWith(updatedAt: now);
    await _dbHelper.updateInspection(record);
    return record;
  }

  Future<List<BusInspection>> fetchAllInspections() {
    return _dbHelper.getAllInspections();
  }

  Future<List<BusInspection>> fetchPendingInspections() {
    return _dbHelper.getPendingInspections();
  }

  Future<BusInspection?> fetchInspectionById(int id) {
    return _dbHelper.getInspectionById(id);
  }

  Future<void> markInspectionSynced(int id) async {
    await _dbHelper.markInspectionSynced(id);
  }

  Future<void> deleteInspection(int id) async {
    await _dbHelper.deleteInspection(id);
  }
}
