import 'package:flutter/material.dart';
import 'package:mandiapp/services/printer_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/printer_settings/connected_printer_card.dart';
import 'package:mandiapp/widgets/printer_settings/device_list.dart';
import 'package:mandiapp/widgets/printer_settings/permission_prompt.dart';
import 'package:mandiapp/widgets/printer_settings/printer_size_selector.dart';
import 'package:mandiapp/widgets/printer_settings/status_banner.dart';
import 'package:mandiapp/widgets/printer_settings/status_card.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService.instance;

  @override
  void initState() {
    super.initState();
    _printerService.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: MyText.titleMedium('Printer', fontWeight: 600),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _printerService.bluetoothEnabled,
          _printerService.permissionGranted,
          _printerService.connectionStatus,
          _printerService.connectedDeviceMac,
          _printerService.pairedDevices,
          _printerService.statusMessage,
          _printerService.isScanning,
          _printerService.connectingMac,
        ]),
        builder: (context, _) {
          final permissionGranted = _printerService.permissionGranted.value;
          final bluetoothEnabled = _printerService.bluetoothEnabled.value;
          final isConnected = _printerService.connectionStatus.value;
          final connectingMac = _printerService.connectingMac.value;
          final devices = _printerService.pairedDevices.value;
          final connectedMac = _printerService.connectedDeviceMac.value;
          final isScanning = _printerService.isScanning.value;
          final statusMessage = _printerService.statusMessage.value;

          final connectedDevice = devices.firstWhere(
            (device) => device.macAdress == connectedMac,
            orElse: () => BluetoothInfo(name: connectedMac ?? 'Unknown', macAdress: connectedMac ?? ''),
          );

          final availableDevices = devices.where((device) => device.macAdress != connectedMac).toList();

          return SingleChildScrollView(
            padding: MySpacing.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (statusMessage != null) ...[
                  StatusBanner(message: statusMessage),
                  MySpacing.height(12),
                ],
                BluetoothStatusCard(
                  permissionGranted: permissionGranted,
                  bluetoothEnabled: bluetoothEnabled,
                  isConnected: isConnected,
                ),
                if (!permissionGranted) ...[
                  MySpacing.height(12),
                  const PermissionPrompt(),
                ],
                MySpacing.height(24),
                ConnectedPrinterCard(
                  bluetoothEnabled: bluetoothEnabled,
                  connected: isConnected,
                  connectedDevice: connectedDevice,
                  connectedMac: connectedMac,
                ),
                MySpacing.height(24),
                PrinterSizeSelector(
                  onSizeChanged: (_) {},
                ),
                MySpacing.height(24),
                if (permissionGranted) ...[
                  BluetoothDeviceList(
                    title: 'Paired Devices',
                    devices: availableDevices,
                    connectingMac: connectingMac,
                    onConnect: (mac) => _printerService.connect(mac),
                  ),
                  MySpacing.height(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: bluetoothEnabled
                          ? () {
                              _printerService.loadPairedDevices();
                            }
                          : null,
                      icon: isScanning
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.bluetooth_searching),
                      label: MyText.bodyLarge(isScanning ? 'Scanning...' : 'Scan Bluetooth', fontWeight: 600),
                      style: ElevatedButton.styleFrom(
                        padding: MySpacing.xy(16, 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
