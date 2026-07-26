import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/services/printer_service.dart';

class StatusBanner extends StatelessWidget {
  final String message;

  const StatusBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printerService = PrinterService.instance;

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
            onPressed: () => printerService.clearStatus(),
          ),
        ],
      ),
    );
  }
}
