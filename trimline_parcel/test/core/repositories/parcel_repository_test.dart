import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/core/repositories/parcel_repository.dart';
import 'package:trimline_parcel/models/parcel_model.dart';

// Mock implementation for testing
class MockParcelRepository implements ParcelRepository {
  final List<Parcel> _parcels = [];
  bool shouldThrowError = false;

  void addTestParcel(Parcel parcel) {
    _parcels.add(parcel);
  }

  void clearParcels() {
    _parcels.clear();
  }

  @override
  Future<List<Parcel>> getAllParcels() async {
    if (shouldThrowError) throw Exception('Test error');
    return List.from(_parcels);
  }

  @override
  Future<List<Parcel>> getParcelsByStatus(ParcelStatus status) async {
    if (shouldThrowError) throw Exception('Test error');
    return _parcels.where((p) => p.Status == status).toList();
  }

  @override
  Future<Parcel?> getParcelByDocumentNo(String documentNo) async {
    if (shouldThrowError) throw Exception('Test error');
    return _parcels.where((p) => p.Document_No == documentNo).firstOrNull;
  }

  @override
  Future<int> insertParcel(Parcel parcel) async {
    if (shouldThrowError) throw Exception('Test error');
    _parcels.add(parcel);
    return 1;
  }

  @override
  Future<int> updateParcel(Parcel parcel) async {
    if (shouldThrowError) throw Exception('Test error');
    final index =
        _parcels.indexWhere((p) => p.Document_No == parcel.Document_No);
    if (index >= 0) {
      _parcels[index] = parcel;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteParcel(String documentNo) async {
    if (shouldThrowError) throw Exception('Test error');
    final initialLength = _parcels.length;
    _parcels.removeWhere((p) => p.Document_No == documentNo);
    return initialLength - _parcels.length;
  }

  @override
  Future<List<Parcel>> searchParcels(String query) async {
    if (shouldThrowError) throw Exception('Test error');
    final lowerQuery = query.toLowerCase();
    return _parcels.where((p) {
      return (p.Document_No?.toLowerCase().contains(lowerQuery) ?? false) ||
          (p.Receiver_Name?.toLowerCase().contains(lowerQuery) ?? false) ||
          (p.Sender_Name?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<int> getParcelCount() async {
    if (shouldThrowError) throw Exception('Test error');
    return _parcels.length;
  }

  @override
  Future<Map<ParcelStatus, int>> getStatusCounts() async {
    if (shouldThrowError) throw Exception('Test error');
    final counts = <ParcelStatus, int>{};
    for (final parcel in _parcels) {
      if (parcel.Status != null) {
        counts[parcel.Status!] = (counts[parcel.Status!] ?? 0) + 1;
      }
    }
    return counts;
  }
}

void main() {
  group('ParcelRepository', () {
    late MockParcelRepository repository;

    setUp(() {
      repository = MockParcelRepository();
    });

    tearDown(() {
      repository.clearParcels();
      repository.shouldThrowError = false;
    });

    Parcel createTestParcel({
      String? documentNo,
      String? senderName,
      String? receiverName,
      ParcelStatus? status,
    }) {
      return Parcel(
        Document_No: documentNo ?? 'DOC-001',
        Sender_Name: senderName ?? 'John Sender',
        Sender_Phone: '0712345678',
        Receiver_Name: receiverName ?? 'Jane Receiver',
        Receiver_Phone: '0787654321',
        From: 'Nairobi',
        To: 'Mombasa',
        Status: status ?? ParcelStatus.pending,
        Date_sent: DateTime.now(),
      );
    }

    group('getAllParcels', () {
      test('returns empty list when no parcels', () async {
        final parcels = await repository.getAllParcels();
        expect(parcels, isEmpty);
      });

      test('returns all parcels', () async {
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-001'));
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-002'));

        final parcels = await repository.getAllParcels();
        expect(parcels.length, equals(2));
      });
    });

    group('getParcelsByStatus', () {
      test('returns empty list when no matching parcels', () async {
        repository
            .addTestParcel(createTestParcel(status: ParcelStatus.pending));

        final parcels =
            await repository.getParcelsByStatus(ParcelStatus.received);
        expect(parcels, isEmpty);
      });

      test('returns only parcels with matching status', () async {
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-001', status: ParcelStatus.pending));
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-002', status: ParcelStatus.received));
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-003', status: ParcelStatus.pending));

        final parcels =
            await repository.getParcelsByStatus(ParcelStatus.pending);
        expect(parcels.length, equals(2));
        expect(parcels.every((p) => p.Status == ParcelStatus.pending), isTrue);
      });
    });

    group('getParcelByDocumentNo', () {
      test('returns null when parcel not found', () async {
        final parcel = await repository.getParcelByDocumentNo('NON-EXISTENT');
        expect(parcel, isNull);
      });

      test('returns parcel when found', () async {
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-001'));

        final parcel = await repository.getParcelByDocumentNo('DOC-001');
        expect(parcel, isNotNull);
        expect(parcel!.Document_No, equals('DOC-001'));
      });
    });

    group('insertParcel', () {
      test('adds parcel to repository', () async {
        final parcel = createTestParcel(documentNo: 'DOC-NEW');

        final result = await repository.insertParcel(parcel);
        expect(result, equals(1));

        final parcels = await repository.getAllParcels();
        expect(parcels.length, equals(1));
        expect(parcels.first.Document_No, equals('DOC-NEW'));
      });
    });

    group('updateParcel', () {
      test('returns 0 when parcel not found', () async {
        final parcel = createTestParcel(documentNo: 'NON-EXISTENT');

        final result = await repository.updateParcel(parcel);
        expect(result, equals(0));
      });

      test('updates existing parcel', () async {
        repository.addTestParcel(createTestParcel(
          documentNo: 'DOC-001',
          receiverName: 'Original Name',
        ));

        final updatedParcel = createTestParcel(
          documentNo: 'DOC-001',
          receiverName: 'Updated Name',
        );

        final result = await repository.updateParcel(updatedParcel);
        expect(result, equals(1));

        final parcel = await repository.getParcelByDocumentNo('DOC-001');
        expect(parcel!.Receiver_Name, equals('Updated Name'));
      });
    });

    group('deleteParcel', () {
      test('returns 0 when parcel not found', () async {
        final result = await repository.deleteParcel('NON-EXISTENT');
        expect(result, equals(0));
      });

      test('removes parcel from repository', () async {
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-001'));
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-002'));

        final result = await repository.deleteParcel('DOC-001');
        expect(result, equals(1));

        final parcels = await repository.getAllParcels();
        expect(parcels.length, equals(1));
        expect(parcels.first.Document_No, equals('DOC-002'));
      });
    });

    group('searchParcels', () {
      test('returns empty list when no matches', () async {
        repository.addTestParcel(createTestParcel(
          documentNo: 'DOC-001',
          senderName: 'John',
          receiverName: 'Jane',
        ));

        final results = await repository.searchParcels('xyz');
        expect(results, isEmpty);
      });

      test('finds parcels by document number', () async {
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-001'));
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-002'));

        final results = await repository.searchParcels('DOC-001');
        expect(results.length, equals(1));
        expect(results.first.Document_No, equals('DOC-001'));
      });

      test('finds parcels by sender name', () async {
        repository.addTestParcel(createTestParcel(senderName: 'Alice Smith'));
        repository.addTestParcel(createTestParcel(senderName: 'Bob Jones'));

        final results = await repository.searchParcels('alice');
        expect(results.length, equals(1));
        expect(results.first.Sender_Name, equals('Alice Smith'));
      });

      test('finds parcels by receiver name', () async {
        repository
            .addTestParcel(createTestParcel(receiverName: 'Charlie Brown'));
        repository
            .addTestParcel(createTestParcel(receiverName: 'Diana Prince'));

        final results = await repository.searchParcels('diana');
        expect(results.length, equals(1));
        expect(results.first.Receiver_Name, equals('Diana Prince'));
      });

      test('search is case insensitive', () async {
        repository.addTestParcel(createTestParcel(senderName: 'UPPERCASE'));

        final results = await repository.searchParcels('uppercase');
        expect(results.length, equals(1));
      });
    });

    group('getParcelCount', () {
      test('returns 0 when no parcels', () async {
        final count = await repository.getParcelCount();
        expect(count, equals(0));
      });

      test('returns correct count', () async {
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-001'));
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-002'));
        repository.addTestParcel(createTestParcel(documentNo: 'DOC-003'));

        final count = await repository.getParcelCount();
        expect(count, equals(3));
      });
    });

    group('getStatusCounts', () {
      test('returns empty map when no parcels', () async {
        final counts = await repository.getStatusCounts();
        expect(counts, isEmpty);
      });

      test('returns correct counts per status', () async {
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-001', status: ParcelStatus.pending));
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-002', status: ParcelStatus.pending));
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-003', status: ParcelStatus.received));
        repository.addTestParcel(createTestParcel(
            documentNo: 'DOC-004', status: ParcelStatus.inTransit));

        final counts = await repository.getStatusCounts();
        expect(counts[ParcelStatus.pending], equals(2));
        expect(counts[ParcelStatus.received], equals(1));
        expect(counts[ParcelStatus.inTransit], equals(1));
      });
    });
  });
}
