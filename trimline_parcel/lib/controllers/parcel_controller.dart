import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
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

  StreamSubscription<List<PrinterDevice>>? _printerScanSub;

  final RxList<PrinterDevice> _availablePrinters = <PrinterDevice>[].obs;
  final RxBool _isScanningPrinters = false.obs;
  final RxBool _isPrinting = false.obs;
  final Rx<PrinterDevice?> _activePrinter = Rx<PrinterDevice?>(null);

  final RxList<Parcel> _parcels = <Parcel>[].obs;
  final RxList<Parcel> _filteredParcels = <Parcel>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isSavingParcel = false.obs;
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
  List<Parcel> get pendingParcels => _parcels
      .where(
        (parcel) =>
            (parcel.Status ?? ParcelStatus.pending) == ParcelStatus.pending,
      )
      .toList();
  List<Parcel> get filteredParcels => _filteredParcels;
  bool get isLoading => _isLoading.value;
  bool get isSavingParcel => _isSavingParcel.value;
  String get searchQuery => _searchQuery.value;
  ParcelStatus? get statusFilter => _statusFilter.value;
  List<ParcelStatus> get supportedStatuses => _statusOrder;

  List<PrinterDevice> get availablePrinters => _availablePrinters;
  bool get isScanningPrinters => _isScanningPrinters.value;
  bool get isPrinting => _isPrinting.value;
  PrinterDevice? get activePrinter => _activePrinter.value;

  RxList<PrinterDevice> get availablePrintersRx => _availablePrinters;
  RxBool get isScanningPrintersRx => _isScanningPrinters;
  RxBool get isPrintingRx => _isPrinting;
  Rx<PrinterDevice?> get activePrinterRx => _activePrinter;

  // Expose reactive values for UI observers (Obx/GetX)
  RxList<Parcel> get parcelsRx => _parcels;
  RxList<Parcel> get filteredParcelsRx => _filteredParcels;
  RxBool get isLoadingRx => _isLoading;
  RxBool get isSavingParcelRx => _isSavingParcel;
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
  // Make 'paid' reactive so UI can listen with minimal rebuilds
  final RxBool paidRx = false.obs;
  bool get paid => paidRx.value;
  set paid(bool v) => paidRx.value = v;

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
    Future.microtask(_restoreSavedPrinter);
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

  Future<void> _restoreSavedPrinter() async {
    try {
      final saved = await _bluetoothService.loadPreferredPrinter();
      if (saved == null) {
        return;
      }

      _activePrinter.value = saved;
      if (!_availablePrinters.any(
        (printer) => _isSamePrinter(printer, saved),
      )) {
        _availablePrinters.add(saved);
      }

      try {
        await _bluetoothService.ensureConnection(saved);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Auto-connect to saved printer failed: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to restore saved printer: $e');
      }
    }
  }

  bool _isSamePrinter(PrinterDevice a, PrinterDevice b) {
    final addrA = a.address?.trim();
    final addrB = b.address?.trim();
    if (addrA?.isNotEmpty == true && addrB?.isNotEmpty == true) {
      return addrA == addrB;
    }
    return a.name.trim() == b.name.trim();
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

  Future<void> selectPrinter(PrinterDevice device) async {
    try {
      await _bluetoothService.ensureConnection(device);
      if (!_availablePrinters.any(
        (printer) => _isSamePrinter(printer, device),
      )) {
        _availablePrinters.add(device);
      }
      _activePrinter.value = device;
      await _bluetoothService.savePreferredPrinter(device);
      final displayName = device.name.trim().isNotEmpty
          ? device.name.trim()
          : (device.address ?? 'Bluetooth printer connected.');
      Get.snackbar(
        'Printer ready',
        displayName,
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
      await _bluetoothService.clearPreferredPrinter();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Printer disconnect failed: ');
      }
    } finally {
      _activePrinter.value = null;
    }
  }

  Future<void> dispatchParcelWithDetails(
    Parcel parcel, {
    String? driver,
    String? vehicle,
  }) async {
    final trimmedDriver = driver?.trim();
    final trimmedVehicle = vehicle?.trim();

    var working = parcel;
    final hasDriverChange =
        (trimmedDriver ?? '') != (parcel.Driver?.trim() ?? '');
    final hasVehicleChange =
        (trimmedVehicle ?? '') != (parcel.Vehicle?.trim() ?? '');

    if (hasDriverChange || hasVehicleChange) {
      working = parcel.copyWith(
        Driver: trimmedDriver?.isNotEmpty == true ? trimmedDriver : null,
        Vehicle: trimmedVehicle?.isNotEmpty == true ? trimmedVehicle : null,
      );
      try {
        await _dbHelper.updateParcel(working);
        final index = _parcels.indexWhere(
          (p) => p.Document_No == working.Document_No,
        );
        if (index != -1) {
          _parcels[index] = working;
          _parcels.refresh();
        }
        _filterParcels();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to update parcel transport info: $e');
        }
        Get.snackbar(
          'Error',
          'Unable to save driver or vehicle details. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    await dispatchParcel(working);
  }

  Future<void> dispatchParcel(Parcel parcel) async {
    final currentStatus = parcel.Status ?? ParcelStatus.pending;
    if (currentStatus != ParcelStatus.pending) {
      await updateParcelStatus(parcel, ParcelStatus.inTransit);
      return;
    }

    final device = _activePrinter.value;
    if (device == null) {
      Get.snackbar(
        'Printer unavailable',
        'Dispatch recorded without printing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await updateParcelStatus(parcel, ParcelStatus.inTransit);
      return;
    }

    if (_isPrinting.value) {
      Get.snackbar(
        'Printer busy',
        'Please wait for the current print job to finish.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    var printed = false;
    _isPrinting.value = true;
    try {
      await _bluetoothService.printParcelDispatchTicket(
        parcel: parcel,
        device: device,
      );
      printed = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Dispatch printing failed: $e');
      }
      Get.snackbar(
        'Print failed',
        'Could not print the dispatch ticket. Check the printer and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPrinting.value = false;
    }

    if (!printed) {
      await updateParcelStatus(parcel, ParcelStatus.inTransit);
      return;
    }

    Get.snackbar(
      'Print job sent',
      'Dispatch ticket sent to the printer.',
      snackPosition: SnackPosition.BOTTOM,
    );

    await updateParcelStatus(parcel, ParcelStatus.inTransit);
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
      Date_Delivered: newStatus == ParcelStatus.received
          ? DateTime.now()
          : parcel.Date_Delivered,
      Date_Collected: newStatus == ParcelStatus.collected
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

  Future<bool> addParcel(Parcel parcel) async {
    _isSavingParcel.value = true;
    try {
      if (kDebugMode) {
        debugPrint('📦 Adding parcel: ${parcel.Document_No}');
        debugPrint('   Sender: ${parcel.Sender_Name}');
        debugPrint('   From: ${parcel.From} → To: ${parcel.To}');
      }

      await _dbHelper.insertParcel(parcel);

      if (kDebugMode) {
        debugPrint('✅ Parcel inserted into database');
      }

      // TODO: POST parcel to backend create endpoint once provided.

      await loadParcels();

      if (kDebugMode) {
        debugPrint('✅ Parcels reloaded. Total count: ${_parcels.length}');
      }

      Get.snackbar(
        'Success',
        'Parcel ${parcel.Document_No} added successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error adding parcel: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      Get.snackbar(
        'Error',
        'Failed to add parcel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isSavingParcel.value = false;
    }
  }

  Future<bool> updateParcel(Parcel parcel) async {
    _isSavingParcel.value = true;
    try {
      await _dbHelper.updateParcel(parcel);

      // TODO: PUT updated parcel to backend endpoint once available.

      await loadParcels();
      Get.snackbar(
        'Success',
        'Parcel  updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating parcel: ');
      }
      Get.snackbar(
        'Error',
        'Failed to update parcel. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isSavingParcel.value = false;
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
    // Cancel any active subscriptions
    _printerScanSub?.cancel();

    // Dispose long-lived TextEditingControllers to free native resources
    try {
      documentNoController.dispose();
      senderNameController.dispose();
      senderIdController.dispose();
      senderPhoneController.dispose();
      fromController.dispose();
      toController.dispose();
      receiverNameController.dispose();
      receiverIdController.dispose();
      receiverPhoneController.dispose();
      driverController.dispose();
      vehicleController.dispose();
      amountPaidController.dispose();
    } catch (_) {}

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
      final sanitized =
          deviceId.replaceAll(RegExp('[^A-Za-z0-9]'), '').padRight(6, 'X');
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
