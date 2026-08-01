import 'package:flutter/material.dart';
import 'package:krishimandi/services/printer_service.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class PermissionPrompt extends StatelessWidget {
  const PermissionPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printerService = PrinterService.instance;

    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Bluetooth permission required',
              fontWeight: 600, color: theme.colorScheme.error),
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
                final granted = await printerService.requestPermissions();
                if (granted) {
                  await printerService.refreshAll();
                }
              },
              child: const MyText.bodySmall('Allow Bluetooth Access',
                  fontWeight: 600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
