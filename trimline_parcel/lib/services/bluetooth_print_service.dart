import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:intl/intl.dart';

import '../models/parcel_model.dart';

class BluetoothPrintService {
  BluetoothPrintService._internal();

  static final BluetoothPrintService _instance =
      BluetoothPrintService._internal();

  factory BluetoothPrintService() => _instance;

  final BluetoothPrint _bluetooth = BluetoothPrint.instance;

  BluetoothDevice? _selectedDevice;

  BluetoothDevice? get selectedDevice => _selectedDevice;

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await _bluetooth.startScan(timeout: timeout);
  }

  Stream<List<BluetoothDevice>> get scanResults => _bluetooth.scanResults;

  Future<void> stopScan() async {
    await _bluetooth.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _selectedDevice = device;
    await _bluetooth.connect(device);
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _selectedDevice = null;
  }

  Future<bool> get isConnected async {
    final connected = await _bluetooth.isConnected;
    return connected ?? false;
  }

  Future<void> ensureConnection(BluetoothDevice device) async {
    final connected = await isConnected;
    if (!connected || (_selectedDevice?.address != device.address)) {
      await connect(device);
    }
  }

  Future<void> printPendingParcels({
    required List<Parcel> parcels,
    required BluetoothDevice device,
    String headerTitle = 'Pending Parcels Summary',
  }) async {
    if (parcels.isEmpty) {
      throw StateError('No pending parcels to print');
    }

    await ensureConnection(device);

    final formatter = DateFormat('dd MMM yyyy HH:mm');
    final List<LineText> lines = [];

    lines
      ..add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: headerTitle,
          weight: 2,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
      )
      ..add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Generated: ${formatter.format(DateTime.now())}',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
      )
      ..add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Total pending: ${parcels.length}',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 2,
        ),
      );

    for (final parcel in parcels) {
      lines
        ..add(
          LineText(
            type: LineText.TYPE_TEXT,
            content: 'Ref: ${parcel.Document_No ?? '-'}',
            weight: 1,
            align: LineText.ALIGN_LEFT,
            linefeed: 1,
          ),
        )
        ..add(
          LineText(
            type: LineText.TYPE_TEXT,
            content: 'From: ${parcel.From ?? '-'} -> To: ${parcel.To ?? '-'}',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1,
          ),
        )
        ..add(
          LineText(
            type: LineText.TYPE_TEXT,
            content:
                'Sender: ${parcel.Sender_Name ?? '-'} (${parcel.Sender_Phone ?? 'N/A'})',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1,
          ),
        )
        ..add(
          LineText(
            type: LineText.TYPE_TEXT,
            content:
                'Receiver: ${parcel.Receiver_Name ?? '-'} (${parcel.Receiver_Phone ?? 'N/A'})',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1,
          ),
        )
        ..add(
          LineText(
            type: LineText.TYPE_TEXT,
            content:
                'Date: ${parcel.Date_sent != null ? formatter.format(parcel.Date_sent!) : 'N/A'}',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 2,
          ),
        );
    }

    lines.add(
      LineText(
        type: LineText.TYPE_TEXT,
        content: '--- end of report ---',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 3,
      ),
    );

    await _bluetooth.printReceipt({'width': 58, 'height': 0, 'gap': 0}, lines);
  }
}
