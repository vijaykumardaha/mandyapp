import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/stepper_button.dart';

class VerticalStepper extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final double step;
  final double minValue;

  const VerticalStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    this.step = 1,
    this.minValue = 0,
  });

  void _adjust(bool increment) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    double nextValue = increment ? current + step : current - step;
    if (nextValue < minValue) nextValue = minValue;
    controller.text = nextValue == nextValue.truncateToDouble()
        ? nextValue.toStringAsFixed(0)
        : nextValue.toStringAsFixed(2);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepperButton(
            icon: Icons.keyboard_arrow_up,
            color: color,
            onTap: () => _adjust(true),
          ),
          const SizedBox(height: 2),
          StepperButton(
            icon: Icons.keyboard_arrow_down,
            color: color,
            onTap: () => _adjust(false),
          ),
        ],
      ),
    );
  }
}
