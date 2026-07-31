import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  PrinterService._();

  static final PrinterService instance = PrinterService._();

  final ValueNotifier<bool> bluetoothEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);
  final ValueNotifier<String?> connectedDeviceMac =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> connectingMac = ValueNotifier<String?>(null);
  final ValueNotifier<List<BluetoothInfo>> pairedDevices =
      ValueNotifier<List<BluetoothInfo>>(<BluetoothInfo>[]);
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);
  final ValueNotifier<bool> permissionGranted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);

  Future<void> init() async {
    await checkPermissions();
    await _refreshBluetoothEnabled();
    await loadPairedDevices();
    await refreshConnectionStatus();
  }

  Future<void> checkPermissions() async {
    try {
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      permissionGranted.value = granted;
      if (!granted) {
        statusMessage.value =
            'Bluetooth permission not granted. Please enable it in system settings.';
      }
    } catch (error) {
      permissionGranted.value = false;
      statusMessage.value = 'Unable to verify Bluetooth permissions: $error';
    }
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      permissionGranted.value = true;
      return true;
    }

    try {
      final List<Permission> permissions = <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ];

      final locationStatus = await Permission.locationWhenInUse.status;
      if (!locationStatus.isGranted) {
        permissions.add(Permission.locationWhenInUse);
      }

      final Map<Permission, PermissionStatus> statuses =
          await permissions.request();
      final bool granted = statuses.entries
          .where((entry) => entry.key != Permission.bluetoothAdvertise)
          .every((entry) => entry.value.isGranted);

      permissionGranted.value = granted;

      if (!granted) {
        final bool permanentlyDenied =
            statuses.values.any((status) => status.isPermanentlyDenied);
        statusMessage.value = permanentlyDenied
            ? 'Bluetooth permission permanently denied. Please enable it in system settings.'
            : 'Bluetooth permission not granted.';
      } else {
        statusMessage.value = null;
      }

      return granted;
    } catch (error) {
      permissionGranted.value = false;
      statusMessage.value = 'Unable to request Bluetooth permissions: $error';
      return false;
    }
  }

  Future<void> _refreshBluetoothEnabled() async {
    try {
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      bluetoothEnabled.value = enabled;
      if (!enabled) {
        connectionStatus.value = false;
        connectedDeviceMac.value = null;
      }
    } catch (error) {
      bluetoothEnabled.value = false;
      statusMessage.value = 'Failed to read Bluetooth status: $error';
    }
  }

  Future<void> loadPairedDevices() async {
    if (isScanning.value) return;
    isScanning.value = true;
    try {
      await checkPermissions();
      await _refreshBluetoothEnabled();
      if (!bluetoothEnabled.value) {
        pairedDevices.value = [];
        statusMessage.value = 'Enable Bluetooth to view paired printers.';
        return;
      }
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      pairedDevices.value = devices;
      if (devices.isEmpty) {
        statusMessage.value =
            'No paired printers found. Pair a device in system Bluetooth settings.';
      } else {
        statusMessage.value = null;
      }
    } catch (error) {
      pairedDevices.value = [];
      statusMessage.value = 'Unable to fetch paired devices: $error';
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> refreshConnectionStatus() async {
    try {
      final connected = await PrintBluetoothThermal.connectionStatus;
      connectionStatus.value = connected;
      if (!connected) {
        connectedDeviceMac.value = null;
      }
    } catch (error) {
      connectionStatus.value = false;
      statusMessage.value = 'Failed to determine connection: $error';
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      connectingMac.value = macAddress;
      statusMessage.value = 'Connecting to printer...';
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      connectionStatus.value = result;
      connectedDeviceMac.value = result ? macAddress : null;
      statusMessage.value =
          result ? 'Connected to printer.' : 'Failed to connect to printer.';
      return result;
    } catch (error) {
      connectionStatus.value = false;
      connectedDeviceMac.value = null;
      statusMessage.value = 'Error while connecting: $error';
      return false;
    } finally {
      connectingMac.value = null;
      await refreshConnectionStatus();
    }
  }

  Future<void> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      if (result) {
        connectionStatus.value = false;
        connectedDeviceMac.value = null;
        statusMessage.value = 'Printer disconnected.';
      }
    } catch (error) {
      statusMessage.value = 'Failed to disconnect: $error';
    } finally {
      await refreshConnectionStatus();
    }
  }

  Future<void> toggleBluetooth(bool enable) async {
    // print_bluetooth_thermal does not provide enable/disable APIs.
    // Notify users to change the state manually and refresh the status.
    statusMessage.value =
        'Bluetooth state must be changed from system settings.';
    await _refreshBluetoothEnabled();
    if (bluetoothEnabled.value) {
      await loadPairedDevices();
    }
  }

  Future<void> refreshAll() async {
    await checkPermissions();
    await _refreshBluetoothEnabled();
    await loadPairedDevices();
    await refreshConnectionStatus();
  }

  Future<bool> printInvoice({
    required int cartId,
    required String customerName,
    required String cartType,
    required List<InvoiceItem> items,
    required double itemTotal,
    required double chargesTotal,
    required double expensesTotal,
    required double grandTotal,
    required double receivedAmount,
    required double pendingAmount,
    required String paymentMethod,
  }) async {
    if (!connectionStatus.value) {
      statusMessage.value = 'No printer connected';
      return false;
    }

    try {
      statusMessage.value = 'Printing bill...';

      final StringBuffer invoiceText = StringBuffer();

      // Header
      invoiceText.writeln('=' * 32);
      invoiceText.writeln(_centerText('Bill No #$cartId'));
      invoiceText.writeln('=' * 32);

      // Date and customer info
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year} ${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';

      invoiceText.writeln('Date:           $dateStr');
      invoiceText.writeln('Customer:       $customerName');
      invoiceText.writeln('Type:           ${cartType.toUpperCase()}');

      // Items header
      invoiceText.writeln('Product         Amount');
      invoiceText.writeln('-' * 32);

      for (final item in items) {
        final productName = item.productName.length > 20
            ? '${item.productName.substring(0, 15)}...'
            : item.productName;
        final qty = item.quantity.toInt();
        final amount = item.total.toStringAsFixed(2);

        invoiceText.writeln(
            '${productName.padRight(12)} $qty x ${item.price.toStringAsFixed(2)}   $amount');
        if (item.partnerName != null && item.partnerName!.isNotEmpty) {
          invoiceText
              .writeln('${item.partnerType}: ${item.partnerName}'.padLeft(20));
        }
      }
      invoiceText.writeln('-' * 32);

      // Summary
      final chargesPrefix = cartType == 'seller' ? '-' : '+';
      final expensesPrefix = cartType == 'seller' ? '-' : '+';
      invoiceText
          .writeln('Item Total:               ${itemTotal.toStringAsFixed(2)}');
      invoiceText.writeln(
          'Total Charges:           $chargesPrefix ${chargesTotal.toStringAsFixed(2)}');
      invoiceText.writeln(
          'Total Expenses:          $expensesPrefix ${expensesTotal.toStringAsFixed(2)}');

      invoiceText.writeln('-' * 32);
      invoiceText.writeln(
          'GRAND TOTAL:              ${grandTotal.toStringAsFixed(2)}');

      // Payment info
      invoiceText.writeln();
      invoiceText.writeln('Payment Info:');
      invoiceText.writeln('-' * 32);
      invoiceText.writeln(
          'Amount Paid:              ${receivedAmount.toStringAsFixed(2)}');
      invoiceText.writeln(
          'Amount Due:               ${pendingAmount.toStringAsFixed(2)}');

      if (paymentMethod.isNotEmpty && paymentMethod != 'Not recorded') {
        invoiceText.writeln('Payment Method:           $paymentMethod');
      }

      invoiceText.writeln();
      invoiceText.writeln(_centerText('Thank you!'));
      invoiceText.writeln();
      invoiceText.writeln();

      final bool result = await PrintBluetoothThermal.writeBytes(
          invoiceText.toString().codeUnits);

      if (result) {
        statusMessage.value = 'Bill printed successfully';
      } else {
        statusMessage.value = 'Failed to print bill. Please try again.';
      }

      return result;
    } catch (error) {
      statusMessage.value = 'Print error: $error';
      return false;
    }
  }

  String _centerText(String text) {
    const int maxWidth = 32;
    final int padding = (maxWidth - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  void clearStatus() {
    statusMessage.value = null;
  }
}

class InvoiceItem {
  final String productName;
  final double quantity;
  final String unit;
  final double price;
  final double total;
  final String? partnerName;
  final String partnerType;

  const InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.total,
    this.partnerName,
    this.partnerType = 'Seller',
  });
}
