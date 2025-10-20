import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/utils/printer/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService.instance;
  String _selectedPrinterSize = '3 inch';

  @override
  void initState() {
    super.initState();
    _printerService.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('Printer', fontWeight: 600),
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
                  _buildStatusBanner(theme, statusMessage),
                  MySpacing.height(12),
                ],
                _buildStatusCard(theme, permissionGranted, bluetoothEnabled, isConnected),
                if (!permissionGranted) ...[
                  MySpacing.height(12),
                  _buildPermissionPrompt(theme),
                ],
                MySpacing.height(24),
                _buildConnectedPrinter(theme, bluetoothEnabled, isConnected, connectedDevice, connectedMac),
                MySpacing.height(24),
                _buildPrinterSizeSelector(theme),
                MySpacing.height(24),
                if (permissionGranted) ...[
                  _buildDeviceList(
                    theme,
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

  Widget _buildPermissionPrompt(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Bluetooth permission required', fontWeight: 600, color: theme.colorScheme.error),
          MySpacing.height(8),
          MyText.bodySmall(
            'Grant Bluetooth permission to discover and connect thermal printers.',
            color: theme.colorScheme.error,
            fontWeight: 500,
          ),
          MySpacing.height(12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final granted = await _printerService.requestPermissions();
                if (granted) {
                  await _printerService.refreshAll();
                }
              },
              child: MyText.bodySmall('Allow Bluetooth Access', fontWeight: 600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    bool permissionGranted,
    bool bluetoothEnabled,
    bool isConnected,
  ) {
    final statusColor = !permissionGranted
        ? Colors.orange
        : bluetoothEnabled
            ? Colors.green
            : Colors.red;
    final statusText = !permissionGranted
        ? 'Permission Required'
        : bluetoothEnabled
            ? 'Bluetooth Active'
            : 'Bluetooth Not Active';
    final helperText = !permissionGranted
        ? 'Bluetooth permission is required. Grant it from system settings.'
        : bluetoothEnabled
            ? (isConnected ? 'Printer connected and ready.' : 'Tap "Scan Bluetooth" to discover nearby printers.')
            : 'Please activate your Bluetooth to connect devices.';

    return Container(
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth, color: statusColor),
              MySpacing.width(12),
              MyText.titleSmall(statusText, fontWeight: 600, color: statusColor),
            ],
          ),
          MySpacing.height(12),
          MyText.bodySmall(
            helperText,
            color: statusColor,
            fontWeight: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: MySpacing.xy(16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.error),
          MySpacing.width(12),
          Expanded(
            child: MyText.bodySmall(
              message,
              color: theme.colorScheme.error,
              fontWeight: 500,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            onPressed: _printerService.clearStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedPrinter(
    ThemeData theme,
    bool bluetoothEnabled,
    bool connected,
    BluetoothInfo connectedDevice,
    String? connectedMac,
  ) {
    final hasConnection = bluetoothEnabled && connected && (connectedMac?.isNotEmpty ?? false);
    return Container(
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Connected Printer:', fontWeight: 600),
          MySpacing.height(8),
          if (hasConnection) ...[
            MyText.bodyMedium('${connectedDevice.name}', fontWeight: 600),
            MySpacing.height(4),
            MyText.bodySmall('MAC: ${connectedDevice.macAdress}', color: theme.colorScheme.onSurface.withOpacity(0.6)),
            MySpacing.height(12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _printerService.disconnect,
                icon: const Icon(Icons.link_off),
                label: MyText.bodySmall('Disconnect', fontWeight: 600),
              ),
            ),
          ] else ...[
            MyText.bodyMedium(
              bluetoothEnabled
                  ? 'No printer connected yet.'
                  : 'Enable Bluetooth to view connected printer info.',
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrinterSizeSelector(ThemeData theme) {
    return Container(
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Printer Size:', fontWeight: 600),
          MySpacing.height(12),
          Row(
            children: [
              _buildSizeChip(theme, label: '2 inch'),
              MySpacing.width(12),
              _buildSizeChip(theme, label: '3 inch'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChip(ThemeData theme, {required String label}) {
    final isSelected = _selectedPrinterSize == label;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedPrinterSize = label;
          });
        },
        child: Container(
          padding: MySpacing.xy(16, 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          alignment: Alignment.center,
          child: MyText.bodyMedium(
            label,
            fontWeight: 600,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(
    ThemeData theme, {
    required String title,
    required List<BluetoothInfo> devices,
    required String? connectingMac,
    required ValueChanged<String> onConnect,
  }) {
    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('$title:', fontWeight: 600),
          MySpacing.height(12),
          if (devices.isEmpty)
            MyText.bodyMedium(
              'No devices found. Tap "Scan Bluetooth".',
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (_, __) => MySpacing.height(8),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isConnecting = connectingMac == device.macAdress;
                return Container(
                  padding: MySpacing.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.print, color: theme.colorScheme.primary),
                      MySpacing.width(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.bodyMedium(device.name, fontWeight: 600),
                            MySpacing.height(2),
                            MyText.bodySmall('MAC: ${device.macAdress}', color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isConnecting ? null : () => onConnect(device.macAdress),
                        style: ElevatedButton.styleFrom(
                          padding: MySpacing.xy(12, 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isConnecting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : MyText.bodySmall('Connect', fontWeight: 600),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
