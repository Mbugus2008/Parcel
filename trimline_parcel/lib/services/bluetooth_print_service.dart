import 'dart:async';
import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parcel_model.dart';

class BluetoothPrintService {
  BluetoothPrintService._internal();

  static final BluetoothPrintService _instance =
      BluetoothPrintService._internal();

  factory BluetoothPrintService() => _instance;

  final PrinterManager _printerManager = PrinterManager.instance;
  final BluetoothPrinterConnector _connector =
      PrinterManager.instance.bluetoothPrinterConnector;

  static const String _preferredPrinterKey = 'preferred_printer_device';

  final List<PrinterDevice> _devices = <PrinterDevice>[];
  final StreamController<List<PrinterDevice>> _scanController =
      StreamController<List<PrinterDevice>>.broadcast();
  StreamSubscription<PrinterDevice>? _scanSubscription;
  Timer? _scanTimer;
  Completer<void>? _scanCompleter;

  PrinterDevice? _selectedDevice;

  // Default receipt header used for printed parcel receipts
  static const String _defaultReceiptHeader = '''PARCEL CASH RECEIPT
REMBO CLASSIC SERVICES LTD
PSV: “For all your quality services & safety”

NOTE
GOODS CARRIED AT OWNER’S RISK
''';

  PrinterDevice? get selectedDevice => _selectedDevice;

  Stream<List<PrinterDevice>> get scanResults => _scanController.stream;

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 6),
    bool isBle = false,
  }) async {
    await stopScan();
    _devices.clear();
    _scanController.add(const []);
    _scanSubscription = _printerManager
        .discovery(type: PrinterType.bluetooth, isBle: isBle)
        .listen(
      (device) {
        if (device.address == null && device.name.isEmpty) {
          return;
        }
        final alreadyAdded = _devices.any((existing) {
          if (device.address != null && device.address!.isNotEmpty) {
            return existing.address == device.address;
          }
          return existing.address == null && existing.name == device.name;
        });
        if (alreadyAdded) {
          return;
        }
        _devices.add(device);
        _scanController.add(List.unmodifiable(_devices));
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Printer scan error: $error');
        }
        _scanController.addError(error, stackTrace);
      },
      onDone: () {
        _scanController.add(List.unmodifiable(_devices));
      },
    );

    if (timeout > Duration.zero) {
      _scanTimer = Timer(timeout, () async {
        await stopScan();
      });
    }

    _scanCompleter = Completer<void>();
    return _scanCompleter!.future;
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await _connector.stopScan();
    } catch (_) {
      // Ignore platform-specific stop errors.
    }
    _scanCompleter?.complete();
    _scanCompleter = null;
  }

  Future<bool> get isConnected async =>
      _printerManager.currentStatusBT == BTStatus.connected;

  Future<void> connect(
    PrinterDevice device, {
    bool autoConnect = true,
    bool isBle = false,
  }) async {
    if (device.address == null || device.address!.isEmpty) {
      throw StateError('Selected printer does not expose a Bluetooth address.');
    }

    await stopScan();

    final input = BluetoothPrinterInput(
      address: device.address!,
      name: device.name,
      autoConnect: autoConnect,
      isBle: isBle,
    );

    final connected = await _printerManager.connect(
      type: PrinterType.bluetooth,
      model: input,
    );
    if (!connected) {
      throw StateError('Unable to connect to the Bluetooth printer.');
    }

    _selectedDevice = device;
  }

  Future<void> ensureConnection(PrinterDevice device) async {
    final connected = await isConnected;
    if (!connected || _selectedDevice?.address != device.address) {
      await connect(device);
    }
  }

  Future<void> disconnect() async {
    await _printerManager.disconnect(type: PrinterType.bluetooth);
    _selectedDevice = null;
  }

  Future<void> printParcelDispatchTicket({
    required Parcel parcel,
    required PrinterDevice device,
    String headerTitle = _defaultReceiptHeader,
  }) async {
    if (device.address == null || device.address!.isEmpty) {
      throw StateError('Selected printer does not expose a Bluetooth address.');
    }

    await ensureConnection(device);

    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm58, profile);
    final nowLabel = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());
    final dispatchStatus = parcel.Status?.name ?? ParcelStatus.pending.name;

    final bytes = <int>[];
    // Print the multi-line header; split into lines and print each centered
    // Print header with sensible sizing: big title, medium company, regular for other lines
    final headerLines = headerTitle
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    int? underlineIndex;
    for (var i = 0; i < headerLines.length; i++) {
      var line = headerLines[i];
      final PosStyles styles;

      // Detect the NOTE line (case-insensitive) and mark it for underlining.
      if (line.toUpperCase() == 'NOTE') {
        underlineIndex = i;
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          underline: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      } else if (i == 1) {
        // Second line (larger)
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      } else if (underlineIndex != null && i == underlineIndex + 1) {
        // The line immediately after NOTE: printers typically don't support
        // italic. We'll simulate an italic appearance by surrounding the text
        // with slashes and printing it slightly smaller.
        line = '/$line/';
        styles = const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
        // Clear underline index so only the next line is affected.
        underlineIndex = null;
      } else if (i == 0) {
        // First line (smaller)
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      } else {
        // Remaining lines (standard)
        styles = const PosStyles(align: PosAlign.center);
      }

      bytes.addAll(
        generator.text(
          _sanitizePrintable(line),
          styles: styles,
        ),
      );
    }
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Generated: $nowLabel'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        _sanitizePrintable('Ref: ${parcel.Document_No ?? '-'}'),
        styles: const PosStyles(bold: true),
      ),
    );
    if (parcel.Date_sent != null) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable(
            'Date: ${DateFormat('dd MMM yyyy').format(parcel.Date_sent!)}',
          ),
        ),
      );
    }

    final from = parcel.From?.trim();
    final to = parcel.To?.trim();
    if ((from?.isNotEmpty ?? false) || (to?.isNotEmpty ?? false)) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable(
            'Route: ${from?.isNotEmpty == true ? from! : '-'} -> ${to?.isNotEmpty == true ? to! : '-'}',
          ),
        ),
      );
    }

    final senderLine = _formatContact(parcel.Sender_Name, parcel.Sender_Phone,
        maskPhone: true);
    if (senderLine != null) {
      bytes.addAll(generator.text(_sanitizePrintable('Sender: $senderLine')));
    }

    final receiverLine = _formatContact(
      parcel.Receiver_Name,
      parcel.Receiver_Phone,
      maskPhone: true,
    );
    if (receiverLine != null) {
      bytes.addAll(
        generator.text(_sanitizePrintable('Receiver: $receiverLine')),
      );
    }

    final driver = parcel.Driver?.trim();
    if (driver != null && driver.isNotEmpty) {
      final vehicle = parcel.Vehicle?.trim();
      final driverLine = vehicle != null && vehicle.isNotEmpty
          ? 'Driver: $driver ($vehicle)'
          : 'Driver: $driver';
      bytes.addAll(generator.text(_sanitizePrintable(driverLine)));
    }

    bytes.addAll(
      generator.text(_sanitizePrintable('Status: $dispatchStatus')),
    );

    if (parcel.Who_to_Pay != null) {
      final responsibility =
          parcel.Who_to_Pay == WhoToPay.Receiver ? 'Receiver' : 'Sender';
      bytes.addAll(
        generator.text(_sanitizePrintable('Charge to: $responsibility')),
      );
    }

    final currency = NumberFormat('#,##0.00');
    final totalDetails = parcel.parcelDetails.fold<double>(
      0,
      (previousValue, detail) => previousValue + (detail.Amount ?? 0),
    );
    if (totalDetails > 0) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable('Items total: ${currency.format(totalDetails)}'),
        ),
      );
    }
    if (parcel.Amount_Paid != null) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable(
            'Amount paid: ${currency.format(parcel.Amount_Paid!)}',
          ),
        ),
      );
    }
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Paid: ${(parcel.Paid ?? false) ? 'Yes' : 'No'}'),
      ),
    );

    if (parcel.parcelDetails.isNotEmpty) {
      bytes.addAll(generator.hr(ch: '-'));
      bytes.addAll(
        generator.text(
          _sanitizePrintable('Items'),
          styles: const PosStyles(bold: true),
        ),
      );
      for (var i = 0; i < parcel.parcelDetails.length; i++) {
        final detail = parcel.parcelDetails[i];
        final hasDescription = detail.Description?.trim().isNotEmpty == true;
        final label = hasDescription
            ? detail.Description!.trim()
            : 'Item ${i + 1}';
        final qty = detail.No_Of_Items ?? 0;
        final qtyLabel = qty > 0 ? 'x$qty ' : '';
        final amount = detail.Amount;
        final line = StringBuffer('- ')
          ..write(qtyLabel)
          ..write(label);
        bytes.addAll(generator.text(_sanitizePrintable(line.toString())));
        if (amount != null && amount > 0) {
          bytes.addAll(
            generator.text(
              _sanitizePrintable('  Amt: ${currency.format(amount)}'),
              styles: const PosStyles(align: PosAlign.right),
            ),
          );
        }
        final note = detail.Remarks?.trim();
        if (note != null && note.isNotEmpty) {
          bytes.addAll(generator.text(_sanitizePrintable('  Note: $note')));
        }
      }
      bytes.addAll(generator.hr(ch: '-'));
    }

    final note = parcel.Notes?.trim();
    if (note != null && note.isNotEmpty) {
      bytes.addAll(generator.text(_sanitizePrintable('Notes: $note')));
    }

    bytes.addAll(
      generator.text(
        _sanitizePrintable('--- ready for dispatch ---'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> printPendingParcels({
    required List<Parcel> parcels,
    required PrinterDevice device,
    String headerTitle = _defaultReceiptHeader,
  }) async {
    if (parcels.isEmpty) {
      throw StateError('No pending parcels to print');
    }

    if (device.address == null || device.address!.isEmpty) {
      throw StateError('Selected printer does not expose a Bluetooth address.');
    }

    await ensureConnection(device);

    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm58, profile);
    final nowLabel = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    final bytes = <int>[];
    final pendingHeaderLines = headerTitle
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    int? pendingUnderlineIndex;
    for (var i = 0; i < pendingHeaderLines.length; i++) {
      var line = pendingHeaderLines[i];
      final PosStyles styles;

      if (line.toUpperCase() == 'NOTE') {
        pendingUnderlineIndex = i;
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          underline: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      } else if (pendingUnderlineIndex != null &&
          i == pendingUnderlineIndex + 1) {
        // Simulate italic for the following line
        line = '/$line/';
        styles = const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
        pendingUnderlineIndex = null;
      } else if (i == 1) {
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        );
      } else if (i == 0) {
        styles = const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      } else {
        styles = const PosStyles(align: PosAlign.center);
      }

      bytes.addAll(
        generator.text(
          _sanitizePrintable(line),
          styles: styles,
        ),
      );
    }
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Generated: $nowLabel'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Total pending: ${parcels.length}'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    for (final parcel in parcels) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable('Ref: ${parcel.Document_No ?? '-'}'),
          styles: const PosStyles(bold: true),
        ),
      );

      final from = parcel.From?.trim();
      final to = parcel.To?.trim();
      if ((from?.isNotEmpty ?? false) || (to?.isNotEmpty ?? false)) {
        bytes.addAll(
          generator.text(
            _sanitizePrintable(
              'Route: ${from?.isNotEmpty == true ? from! : '-'} -> ${to?.isNotEmpty == true ? to! : '-'}',
            ),
          ),
        );
      }

      final senderLine = _formatContact(
        parcel.Sender_Name,
        parcel.Sender_Phone,
        maskPhone: true,
      );
      if (senderLine != null) {
        bytes.addAll(
          generator.text(_sanitizePrintable('Sender: $senderLine')),
        );
      }

      final receiverLine = _formatContact(
        parcel.Receiver_Name,
        parcel.Receiver_Phone,
        maskPhone: true,
      );
      if (receiverLine != null) {
        bytes.addAll(
          generator.text(_sanitizePrintable('Receiver: $receiverLine')),
        );
      }

      final sentDate = parcel.Date_sent != null
          ? DateFormat('dd MMM yyyy').format(parcel.Date_sent!)
          : 'N/A';
      bytes.addAll(generator.text(_sanitizePrintable('Date: $sentDate')));
      bytes.addAll(generator.hr(ch: '-'));
    }

    bytes.addAll(
      generator.text(
        _sanitizePrintable('--- end of report ---'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
  }

  Future<void> savePreferredPrinter(PrinterDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferredPrinterKey,
      jsonEncode(_encodeDevice(device)),
    );
  }

  Future<PrinterDevice?> loadPreferredPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferredPrinterKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      final device = _decodeDevice(data);
      _selectedDevice = device;
      return device;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to decode stored printer: $e');
      }
      return null;
    }
  }

  Future<void> clearPreferredPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferredPrinterKey);
    _selectedDevice = null;
  }

  Map<String, dynamic> _encodeDevice(PrinterDevice device) {
    return {
      'name': device.name,
      'address': device.address,
      'vendorId': device.vendorId,
      'productId': device.productId,
      'operatingSystem': device.operatingSystem,
    };
  }

  PrinterDevice _decodeDevice(Map<String, dynamic> data) {
    final printer = PrinterDevice(
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Saved printer',
      address: data['address'] as String?,
      vendorId: data['vendorId'] as String?,
      productId: data['productId'] as String?,
    );
    final os = data['operatingSystem'] as String?;
    if (os != null && os.isNotEmpty) {
      printer.operatingSystem = os;
    }
    return printer;
  }

  String _sanitizePrintable(String value) {
    const Map<String, String> replacements = {
      '‘': "'",
      '’': "'",
      '“': '"',
      '”': '"',
      '–': '-',
      '—': '-',
      '→': '->',
      '←': '<-',
    };

    var sanitized = value;
    replacements.forEach((key, replacement) {
      sanitized = sanitized.replaceAll(key, replacement);
    });

    final buffer = StringBuffer();
    for (final codePoint in sanitized.runes) {
      if ((codePoint >= 32 && codePoint <= 126) || codePoint == 10) {
        buffer.writeCharCode(codePoint);
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 3) return digits;
    final visible = digits.substring(digits.length - 3);
    // mask the rest with x characters, preserve formatting minimally
    return '***$visible';
  }

  String? _formatContact(String? name, String? phone,
      {bool maskPhone = false}) {
    final cleanName = name?.trim() ?? '';
    var cleanPhone = phone?.trim() ?? '';
    if (maskPhone && cleanPhone.isNotEmpty) {
      cleanPhone = _maskPhone(cleanPhone);
    }
    if (cleanName.isEmpty && cleanPhone.isEmpty) {
      return null;
    }
    if (cleanName.isNotEmpty && cleanPhone.isNotEmpty) {
      return '$cleanName ($cleanPhone)';
    }
    return cleanName.isNotEmpty ? cleanName : cleanPhone;
  }
}
