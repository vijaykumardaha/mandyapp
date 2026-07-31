import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class PrinterSizeSelector extends StatefulWidget {
  final String initialSize;
  final ValueChanged<String> onSizeChanged;

  const PrinterSizeSelector({
    super.key,
    this.initialSize = '3 inch',
    required this.onSizeChanged,
  });

  @override
  State<PrinterSizeSelector> createState() => _PrinterSizeSelectorState();
}

class _PrinterSizeSelectorState extends State<PrinterSizeSelector> {
  late String _selectedPrinterSize;

  @override
  void initState() {
    super.initState();
    _selectedPrinterSize = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          const MyText.bodyLarge('Printer Size:', fontWeight: 600),
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
          widget.onSizeChanged(label);
        },
        child: Container(
          padding: MySpacing.xy(16, 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
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
}
