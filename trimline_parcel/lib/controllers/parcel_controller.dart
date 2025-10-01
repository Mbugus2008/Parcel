import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../models/pricing_rate.dart';
import '../services/bluetooth_print_service.dart';

class ParcelController extends GetxController {
  ParcelController({Parcel? initialParcel}) {
    parcel = initialParcel ?? _buildSampleParcel();
    populateFormWithParcel(parcel!);
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final BluetoothPrintService _bluetoothService = BluetoothPrintService();

  StreamSubscription<List<BluetoothDevice>>? _printerScanSub;

  final RxList<BluetoothDevice> _availablePrinters = <BluetoothDevice>[].obs;
  final RxBool _isScanningPrinters = false.obs;
  final RxBool _isPrinting = false.obs;
  final Rx<BluetoothDevice?> _activePrinter = Rx<BluetoothDevice?>(null);

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
  List<Parcel> get pendingParcels =>
      _parcels
          .where(
            (parcel) =>
                (parcel.Status ?? ParcelStatus.pending) == ParcelStatus.pending,
          )
          .toList();
  List<Parcel> get filteredParcels => _filteredParcels;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  ParcelStatus? get statusFilter => _statusFilter.value;
  List<ParcelStatus> get supportedStatuses => _statusOrder;

  List<BluetoothDevice> get availablePrinters => _availablePrinters;
  bool get isScanningPrinters => _isScanningPrinters.value;
  bool get isPrinting => _isPrinting.value;
  BluetoothDevice? get activePrinter => _activePrinter.value;

  RxList<BluetoothDevice> get availablePrintersRx => _availablePrinters;
  RxBool get isScanningPrintersRx => _isScanningPrinters;
  RxBool get isPrintingRx => _isPrinting;
  Rx<BluetoothDevice?> get activePrinterRx => _activePrinter;

  // Expose reactive values for UI observers (Obx/GetX)
  RxList<Parcel> get parcelsRx => _parcels;
  RxList<Parcel> get filteredParcelsRx => _filteredParcels;
  RxBool get isLoadingRx => _isLoading;
  RxString get searchQueryRx => _searchQuery;
  Rx<ParcelStatus?> get statusFilterRx => _statusFilter;

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

  // Field-specific error observables (used to show error only on the invalid TextFormField)
  RxString amountPaidError = ''.obs;
  RxString fromError = ''.obs;
  RxString toError = ''.obs;
  RxString senderNameFieldError = ''.obs;
  RxString receiverNameFieldError = ''.obs;
  RxString receiverPhoneFieldError = ''.obs;
  RxString vehicleFieldError = ''.obs;
  RxString driverFieldError = ''.obs;
  RxString senderPhoneFieldError = ''.obs;

  // Items step error
  RxString itemsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _printerScanSub = _bluetoothService.scanResults.listen((devices) {
      _availablePrinters.assignAll(devices);
    });
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
      Get.snackbar(
        'Error',
        'Failed to load parcels',
        snackPosition: SnackPosition.BOTTOM,
      );
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
        bool matches(String? value) =>
            value?.toLowerCase().contains(query) ?? false;

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

  Future<void> refreshPrinters({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (_isScanningPrinters.value) {
      return;
    }
    _isScanningPrinters.value = true;
    try {
      await _bluetoothService.startScan(timeout: timeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printer scan error: ');
      }
      Get.snackbar(
        'Bluetooth scan failed',
        'Unable to find printers. Ensure Bluetooth is on and the printer is discoverable.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      await _bluetoothService.stopScan();
      _isScanningPrinters.value = false;
    }
  }

  Future<void> selectPrinter(BluetoothDevice device) async {
    try {
      await _bluetoothService.ensureConnection(device);
      _activePrinter.value = device;
      Get.snackbar(
        'Printer ready',
        device.name ?? device.address ?? 'Bluetooth printer connected.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printer connection failed: ');
      }
      Get.snackbar(
        'Connection failed',
        'Unable to connect to the selected printer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      await _bluetoothService.disconnect();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printer disconnect failed: ');
      }
    } finally {
      _activePrinter.value = null;
    }
  }

  Future<void> printPendingParcelsViaBluetooth() async {
    if (_isPrinting.value) {
      return;
    }
    final device = _activePrinter.value;
    if (device == null) {
      Get.snackbar(
        'No printer selected',
        'Choose a Bluetooth printer before printing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final items = pendingParcels;
    if (items.isEmpty) {
      Get.snackbar(
        'Nothing to print',
        'There are no pending parcels at the moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _isPrinting.value = true;
    try {
      await _bluetoothService.printPendingParcels(
        parcels: items,
        device: device,
      );
      Get.snackbar(
        'Print job sent',
        'Pending parcels dispatched to the printer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printing failed: ');
      }
      Get.snackbar(
        'Print failed',
        'Could not complete printing. Check the printer and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPrinting.value = false;
    }
  }

  void addParcelDetail() {
    final docNo =
        documentNoController.text.isEmpty ? 'TEMP-' : documentNoController.text;
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

  void removeParcelDetail(int index) {
    if (parcel != null && index >= 0 && index < parcel!.parcelDetails.length) {
      parcel!.parcelDetails.removeAt(index);
    }
  }

  void updateParcelDetail(
    int index,
    String description,
    double amount,
    String remarks,
  ) {
    if (parcel != null && index >= 0 && index < parcel!.parcelDetails.length) {
      parcel!.parcelDetails[index] = Parcel_Details(
        Document_No: parcel!.parcelDetails[index].Document_No,
        Description: description,
        Amount: amount,
        Remarks: remarks,
      );
    }
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
      Date_Delivered:
          newStatus == ParcelStatus.received
              ? DateTime.now()
              : parcel.Date_Delivered,
      Date_Collected:
          newStatus == ParcelStatus.collected
              ? DateTime.now()
              : parcel.Date_Collected,
    );

    try {
      await _dbHelper.updateParcel(updated);
      final index = _parcels.indexWhere(
        (p) => p.Document_No == updated.Document_No,
      );
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

  @override
  void onClose() {
    _printerScanSub?.cancel();
    super.onClose();
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
      final sanitized = deviceId
          .replaceAll(RegExp('[^A-Za-z0-9]'), '')
          .padRight(6, 'X');
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

  Future<void> fetchAndSavePricingRates(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final rates = data.map((item) => PricingRate.fromJson(item)).toList();

        // Delete existing rates
        await _dbHelper.deleteAllPricingRates();

        // Insert new rates
        for (final rate in rates) {
          await _dbHelper.insertPricingRate(rate);
        }

        Get.snackbar('Success', 'Pricing rates updated successfully');
      } else {
        Get.snackbar('Error', 'Failed to fetch pricing rates');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching pricing rates: $e');
    }
  }
}
