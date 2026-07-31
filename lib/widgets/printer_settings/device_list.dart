import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothDeviceList extends StatelessWidget {
  final String title;
  final List<BluetoothInfo> devices;
  final String? connectingMac;
  final ValueChanged<String> onConnect;

  const BluetoothDeviceList({
    super.key,
    required this.title,
    required this.devices,
    this.connectingMac,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('$title:', fontWeight: 600),
          MySpacing.height(12),
          if (devices.isEmpty)
            MyText.bodyMedium(
              'No devices found. Tap "Scan Bluetooth".',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.1)),
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
                            MyText.bodySmall('MAC: ${device.macAdress}',
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isConnecting
                            ? null
                            : () => onConnect(device.macAdress),
                        style: ElevatedButton.styleFrom(
                          padding: MySpacing.xy(12, 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const MyText.bodySmall('Connect',
                                fontWeight: 600),
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
