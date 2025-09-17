import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../database/database_helper.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';

class ParcelController extends GetxController {
  ParcelController({Parcel? initialParcel}) {
    parcel = initialParcel ?? _buildSampleParcel();
    populateFormWithParcel(parcel!);
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final RxList<Parcel> _parcels = <Parcel>[].obs;
  final RxList<Parcel> _filteredParcels = <Parcel>[].obs;
  final RxBool _isLoading = true.obs;
  final RxString _searchQuery = ''.obs;
  final Rx<ParcelStatus?> _statusFilter = Rx<ParcelStatus?>(null);

  static const List<ParcelStatus> _statusOrder = <ParcelStatus>[
    ParcelStatus.pending,
    ParcelStatus.inTransit,
    ParcelStatus.received,
    ParcelStatus.collected,
  ];

  Parcel? parcel;

  List<Parcel> get parcels => _parcels;
  List<Parcel> get filteredParcels => _filteredParcels;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  ParcelStatus? get statusFilter => _statusFilter.value;
  List<ParcelStatus> get supportedStatuses => _statusOrder;

  Map<ParcelStatus, List<Parcel>> get parcelsByStatus {
    final Map<ParcelStatus, List<Parcel>> grouped = {
      for (final status in _statusOrder) status: <Parcel>[],
    };
    for (final parcel in _parcels) {
      final status = parcel.Status ?? ParcelStatus.pending;
      grouped.putIfAbsent(status, () => <Parcel>[]).add(parcel);
    }
    return grouped;
  }

  String statusLabel(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return 'Pending';
      case ParcelStatus.inTransit:
        return 'In Transit';
      case ParcelStatus.received:
        return 'Received';
      case ParcelStatus.collected:
        return 'Collected';
    }
  }

  final formKey = GlobalKey<FormState>();

  final documentNoController = TextEditingController();
  final senderNameController = TextEditingController();
  final senderIdController = TextEditingController();
  final senderPhoneController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final receiverNameController = TextEditingController();
  final receiverIdController = TextEditingController();
  final receiverPhoneController = TextEditingController();
  final driverController = TextEditingController();
  final vehicleController = TextEditingController();
  final amountPaidController = TextEditingController();

  ParcelStatus selectedStatus = ParcelStatus.pending;
  WhoToPay paymentResponsibility = WhoToPay.Sender;
  DateTime selectedDate = DateTime.now();
  bool paid = false;

  RxString parcelinformationError = ''.obs;
  RxString senderinformationError = ''.obs;
  RxString receiverinformationError = ''.obs;
  RxString deliveryinformationError = ''.obs;
  RxString paymentinformationError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadParcels();
  }

  Future<void> loadParcels() async {
    _isLoading.value = true;
    try {
      final items = await _dbHelper.getAllParcels();
      _parcels.assignAll(items);
      _filterParcels();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading parcels: ');
      }
      _parcels.clear();
      _filteredParcels.clear();
      Get.snackbar('Error', 'Failed to load parcels', snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _filterParcels();
  }

  void setStatusFilter(ParcelStatus? status) {
    _statusFilter.value = status;
    _filterParcels();
  }
  void _filterParcels() {
    final query = _searchQuery.value.trim().toLowerCase();
    final status = _statusFilter.value;

    Iterable<Parcel> filtered = _parcels;

    if (status != null) {
      filtered = filtered.where(
        (parcel) => (parcel.Status ?? ParcelStatus.pending) == status,
      );
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((parcel) {
        bool matches(String? value) => value?.toLowerCase().contains(query) ?? false;

        return matches(parcel.Document_No) ||
            matches(parcel.Sender_Name) ||
            matches(parcel.Sender_Phone) ||
            matches(parcel.Receiver_Name) ||
            matches(parcel.Receiver_Phone) ||
            matches(parcel.From) ||
            matches(parcel.To) ||
            parcel.parcelDetails.any((detail) => matches(detail.Description));
      });
    }

    _filteredParcels.assignAll(filtered);
  }

  void addParcelDetail() {
    final docNo = documentNoController.text.isEmpty
        ? 'TEMP-'
        : documentNoController.text;
    parcel ??= _buildEmptyParcel(docNo);
    parcel!.parcelDetails.add(
      Parcel_Details(
        Document_No: docNo,
        Description: '',
        Amount: 0,
        Remarks: '',
      ),
    );
  }

  Future<void> updateParcelStatus(Parcel parcel, ParcelStatus newStatus) async {
    final currentStatus = parcel.Status ?? ParcelStatus.pending;
    if (currentStatus == newStatus) return;

    final currentIndex = _statusOrder.indexOf(currentStatus);
    final nextIndex = _statusOrder.indexOf(newStatus);
    if (nextIndex < currentIndex || nextIndex - currentIndex > 1) {
      Get.snackbar(
        'Invalid transition',
        'Status can only advance one step at a time.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = parcel.copyWith(
      Status: newStatus,
      Date_Delivered: newStatus == ParcelStatus.received ? DateTime.now() : parcel.Date_Delivered,
      Date_Collected: newStatus == ParcelStatus.collected ? DateTime.now() : parcel.Date_Collected,
    );

    try {
      await _dbHelper.updateParcel(updated);
      final index = _parcels.indexWhere((p) => p.Document_No == updated.Document_No);
      if (index != -1) {
        _parcels[index] = updated;
        _parcels.refresh();
      }
      _filterParcels();

      // TODO: PUT status update to backend endpoint when available.
      // TODO: Trigger backend SMS when status becomes received.

      Get.snackbar(
        'Status updated',
        'Parcel ${updated.Document_No ?? ''} is now ${statusLabel(newStatus)}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update parcel status: ');
      }
      Get.snackbar(
        'Error',
        'Unable to update parcel status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> addParcel(Parcel parcel) async {
    _isLoading.value = true;
    try {
      await _dbHelper.insertParcel(parcel);

      // TODO: POST parcel to backend create endpoint once provided.

      await loadParcels();
      Get.snackbar(
        'Success',
        'Parcel  added successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding parcel: ');
      }
      Get.snackbar(
        'Error',
        'Failed to add parcel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateParcel(Parcel parcel) async {
    _isLoading.value = true;
    try {
      await _dbHelper.updateParcel(parcel);

      // TODO: PUT updated parcel to backend endpoint once available.

      await loadParcels();
      Get.snackbar(
        'Success',
        'Parcel  updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating parcel: ');
      }
      Get.snackbar(
        'Error',
        'Failed to update parcel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteParcel(String documentNo) async {
    _isLoading.value = true;
    try {
      await _dbHelper.deleteParcel(documentNo);

      // TODO: DELETE parcel on backend once endpoint is available.

      await loadParcels();
      Get.snackbar(
        'Deleted',
        'Parcel  deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting parcel: ');
      }
      Get.snackbar(
        'Error',
        'Failed to delete parcel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Parcel> newparcel() async {
    final docNo = await _generateDocumentNumber();
    final fresh = _buildEmptyParcel(docNo);
    parcel = fresh;
    populateFormWithParcel(fresh);
    return fresh;
  }

  Future<String> _generateDocumentNumber() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? 'IOSDEVICE';
      } else {
        deviceId = 'UNKNOWNDEVICE';
      }
      final sanitized = deviceId.replaceAll(RegExp('[^A-Za-z0-9]'), '').padRight(6, 'X');
      final normalized = sanitized.substring(0, 6).toUpperCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final suffix = timestamp.substring(timestamp.length - 6);
      return '$normalized-$suffix';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating document number: ');
      }
      return 'DOC';
    }
  }

  Parcel _buildEmptyParcel(String documentNo) {
    return Parcel(
      Document_No: documentNo,
      Date_sent: DateTime.now(),
      Status: ParcelStatus.pending,
      parcelDetails: <Parcel_Details>[],
    );
  }

  Parcel _buildSampleParcel() {
    return Parcel(
      Document_No: 'PENDING-SAMPLE',
      Date_sent: DateTime.now(),
      Sender_Name: 'Sample Sender',
      Sender_ID: 'S123456',
      Sender_Phone: '0712345678',
      From: 'Nairobi',
      To: 'Mombasa',
      Receiver_Name: 'Sample Receiver',
      Receiver_ID: 'R987654',
      Receiver_Phone: '0798765432',
      Status: ParcelStatus.pending,
      Driver: 'Sample Driver',
      Vehicle: 'KBA 123X',
      Amount_Paid: 0,
      Paid: false,
      Notes: 'Sample data for testing',
    );
  }

  void populateFormWithParcel(Parcel parcel) {
    documentNoController.text = parcel.Document_No ?? '';
    senderNameController.text = parcel.Sender_Name ?? '';
    senderIdController.text = parcel.Sender_ID ?? '';
    senderPhoneController.text = parcel.Sender_Phone ?? '';
    fromController.text = parcel.From ?? '';
    toController.text = parcel.To ?? '';
    receiverNameController.text = parcel.Receiver_Name ?? '';
    receiverIdController.text = parcel.Receiver_ID ?? '';
    receiverPhoneController.text = parcel.Receiver_Phone ?? '';
    driverController.text = parcel.Driver ?? '';
    vehicleController.text = parcel.Vehicle ?? '';
    amountPaidController.text = (parcel.Amount_Paid ?? 0).toString();
    selectedStatus = parcel.Status ?? ParcelStatus.pending;
    paymentResponsibility = parcel.Who_to_Pay ?? WhoToPay.Sender;
    selectedDate = parcel.Date_sent ?? DateTime.now();
    paid = parcel.Paid ?? false;
  }

  void PopulateFormWithParcel(Parcel parcel) => populateFormWithParcel(parcel);
}
