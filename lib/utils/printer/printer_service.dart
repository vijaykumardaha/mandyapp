import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  PrinterService._();

  static final PrinterService instance = PrinterService._();

  final ValueNotifier<bool> bluetoothEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);
  final ValueNotifier<String?> connectedDeviceMac = ValueNotifier<String?>(null);
  final ValueNotifier<String?> connectingMac = ValueNotifier<String?>(null);
  final ValueNotifier<List<BluetoothInfo>> pairedDevices = ValueNotifier<List<BluetoothInfo>>(<BluetoothInfo>[]);
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
        statusMessage.value = 'Bluetooth permission not granted. Please enable it in system settings.';
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

      final Map<Permission, PermissionStatus> statuses = await permissions.request();
      final bool granted = statuses.entries
          .where((entry) => entry.key != Permission.bluetoothAdvertise)
          .every((entry) => entry.value.isGranted);

      permissionGranted.value = granted;

      if (!granted) {
        final bool permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
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
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      pairedDevices.value = devices;
      if (devices.isEmpty) {
        statusMessage.value = 'No paired printers found. Pair a device in system Bluetooth settings.';
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
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      connectionStatus.value = result;
      connectedDeviceMac.value = result ? macAddress : null;
      statusMessage.value = result ? 'Connected to printer.' : 'Failed to connect to printer.';
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
    statusMessage.value = 'Bluetooth state must be changed from system settings.';
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

  void clearStatus() {
    statusMessage.value = null;
  }
}
