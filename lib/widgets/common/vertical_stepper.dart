import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/stepper_button.dart';

class VerticalStepper extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<double>? onValueChanged;
  final double step;
  final double minValue;
  final double? maxValue;

  const VerticalStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onValueChanged,
    this.step = 1,
    this.minValue = 0,
    this.maxValue,
  });

  void _adjust(bool increment) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    double nextValue = increment ? current + step : current - step;
    if (nextValue < minValue) nextValue = minValue;
    if (maxValue != null && nextValue > maxValue!) nextValue = maxValue!;
    
    if (nextValue != current) {
      controller.text = nextValue == nextValue.truncateToDouble()
          ? nextValue.toStringAsFixed(0)
          : nextValue.toStringAsFixed(2);
      onChanged();
      onValueChanged?.call(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final canIncrement = maxValue == null || current < maxValue!;
    final canDecrement = current > minValue;
    
    void handleIncrement() => _adjust(true);
    void handleDecrement() => _adjust(false);
    
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepperButton(
            icon: Icons.keyboard_arrow_up,
            color: canIncrement ? color : color.withOpacity(0.3),
            onTap: canIncrement ? handleIncrement : () {},
          ),
          const SizedBox(height: 2),
          StepperButton(
            icon: Icons.keyboard_arrow_down,
            color: canDecrement ? color : color.withOpacity(0.3),
            onTap: canDecrement ? handleDecrement : () {},
          ),
        ],
      ),
    );
  }
}
