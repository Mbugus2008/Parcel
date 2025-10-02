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
    String headerTitle = 'Parcel Dispatch Ticket',
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
    bytes.addAll(
      generator.text(
        _sanitizePrintable(headerTitle),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Generated: ' + nowLabel),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        _sanitizePrintable('Ref: ' + (parcel.Document_No ?? '-')),
        styles: const PosStyles(bold: true),
      ),
    );
    if (parcel.Date_sent != null) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable(
            'Date: ' + DateFormat('dd MMM yyyy').format(parcel.Date_sent!),
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
            'Route: ' +
                (from?.isNotEmpty == true ? from! : '-') +
                ' -> ' +
                (to?.isNotEmpty == true ? to! : '-'),
          ),
        ),
      );
    }

    final senderLine = _formatContact(parcel.Sender_Name, parcel.Sender_Phone);
    if (senderLine != null) {
      bytes.addAll(generator.text(_sanitizePrintable('Sender: ' + senderLine)));
    }

    final receiverLine = _formatContact(
      parcel.Receiver_Name,
      parcel.Receiver_Phone,
    );
    if (receiverLine != null) {
      bytes.addAll(
        generator.text(_sanitizePrintable('Receiver: ' + receiverLine)),
      );
    }

    final driver = parcel.Driver?.trim();
    if (driver != null && driver.isNotEmpty) {
      final vehicle = parcel.Vehicle?.trim();
      final driverLine =
          vehicle != null && vehicle.isNotEmpty
              ? 'Driver: ' + driver + ' (' + vehicle + ')'
              : 'Driver: ' + driver;
      bytes.addAll(generator.text(_sanitizePrintable(driverLine)));
    }

    bytes.addAll(
      generator.text(_sanitizePrintable('Status: ' + dispatchStatus)),
    );

    if (parcel.Who_to_Pay != null) {
      final responsibility =
          parcel.Who_to_Pay == WhoToPay.Receiver ? 'Receiver' : 'Sender';
      bytes.addAll(
        generator.text(_sanitizePrintable('Charge to: ' + responsibility)),
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
          _sanitizePrintable('Items total: ' + currency.format(totalDetails)),
        ),
      );
    }
    if (parcel.Amount_Paid != null) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable(
            'Amount paid: ' + currency.format(parcel.Amount_Paid!),
          ),
        ),
      );
    }
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Paid: ' + ((parcel.Paid ?? false) ? 'Yes' : 'No')),
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
        final label =
            hasDescription
                ? detail.Description!.trim()
                : 'Item ' + (i + 1).toString();
        final qty = detail.No_Of_Items ?? 0;
        final qtyLabel = qty > 0 ? 'x' + qty.toString() + ' ' : '';
        final amount = detail.Amount;
        final line =
            StringBuffer('- ')
              ..write(qtyLabel)
              ..write(label);
        bytes.addAll(generator.text(_sanitizePrintable(line.toString())));
        if (amount != null && amount > 0) {
          bytes.addAll(
            generator.text(
              _sanitizePrintable('  Amt: ' + currency.format(amount)),
              styles: const PosStyles(align: PosAlign.right),
            ),
          );
        }
        final note = detail.Remarks?.trim();
        if (note != null && note.isNotEmpty) {
          bytes.addAll(generator.text(_sanitizePrintable('  Note: ' + note)));
        }
      }
      bytes.addAll(generator.hr(ch: '-'));
    }

    final note = parcel.Notes?.trim();
    if (note != null && note.isNotEmpty) {
      bytes.addAll(generator.text(_sanitizePrintable('Notes: ' + note)));
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
    String headerTitle = 'Pending Parcels Summary',
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
    bytes.addAll(
      generator.text(
        _sanitizePrintable(headerTitle),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Generated: ' + nowLabel),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizePrintable('Total pending: ' + parcels.length.toString()),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    for (final parcel in parcels) {
      bytes.addAll(
        generator.text(
          _sanitizePrintable('Ref: ' + (parcel.Document_No ?? '-')),
          styles: const PosStyles(bold: true),
        ),
      );

      final from = parcel.From?.trim();
      final to = parcel.To?.trim();
      if ((from?.isNotEmpty ?? false) || (to?.isNotEmpty ?? false)) {
        bytes.addAll(
          generator.text(
            _sanitizePrintable(
              'Route: ' +
                  (from?.isNotEmpty == true ? from! : '-') +
                  ' -> ' +
                  (to?.isNotEmpty == true ? to! : '-'),
            ),
          ),
        );
      }

      final senderLine = _formatContact(
        parcel.Sender_Name,
        parcel.Sender_Phone,
      );
      if (senderLine != null) {
        bytes.addAll(
          generator.text(_sanitizePrintable('Sender: ' + senderLine)),
        );
      }

      final receiverLine = _formatContact(
        parcel.Receiver_Name,
        parcel.Receiver_Phone,
      );
      if (receiverLine != null) {
        bytes.addAll(
          generator.text(_sanitizePrintable('Receiver: ' + receiverLine)),
        );
      }

      final sentDate =
          parcel.Date_sent != null
              ? DateFormat('dd MMM yyyy').format(parcel.Date_sent!)
              : 'N/A';
      bytes.addAll(generator.text(_sanitizePrintable('Date: ' + sentDate)));
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
      name:
          (data['name'] as String?)?.trim().isNotEmpty == true
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

  String? _formatContact(String? name, String? phone) {
    final cleanName = name?.trim() ?? '';
    final cleanPhone = phone?.trim() ?? '';
    if (cleanName.isEmpty && cleanPhone.isEmpty) {
      return null;
    }
    if (cleanName.isNotEmpty && cleanPhone.isNotEmpty) {
      return '$cleanName ($cleanPhone)';
    }
    return cleanName.isNotEmpty ? cleanName : cleanPhone;
  }
}
