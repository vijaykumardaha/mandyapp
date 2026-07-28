import 'package:flutter/material.dart';
import 'package:mandiapp/services/printer_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class ConnectedPrinterCard extends StatelessWidget {
  final bool bluetoothEnabled;
  final bool connected;
  final BluetoothInfo connectedDevice;
  final String? connectedMac;

  const ConnectedPrinterCard({
    super.key,
    required this.bluetoothEnabled,
    required this.connected,
    required this.connectedDevice,
    this.connectedMac,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printerService = PrinterService.instance;
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
                onPressed: printerService.disconnect,
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
}
