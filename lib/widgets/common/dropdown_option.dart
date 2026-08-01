import 'package:flutter/material.dart';

class DropdownOption extends StatelessWidget {
  final Widget child;
  final bool selected;
  final Color? selectedColor;

  const DropdownOption({
    super.key,
    required this.child,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selectedColor ?? scheme.primary;
    return Row(
      children: [
        Expanded(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: selected ? color : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
            child: child,
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_rounded, size: 18, color: color),
        ],
      ],
    );
  }
}
