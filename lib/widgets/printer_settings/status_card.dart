import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class BluetoothStatusCard extends StatelessWidget {
  final bool permissionGranted;
  final bool bluetoothEnabled;
  final bool isConnected;

  const BluetoothStatusCard({
    super.key,
    required this.permissionGranted,
    required this.bluetoothEnabled,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}
