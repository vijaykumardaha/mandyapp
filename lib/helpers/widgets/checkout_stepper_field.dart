import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class CheckoutStepperField extends StatefulWidget {
  final String label;
  final double initialValue;
  final double step;
  final double minValue;
  final String? prefixText;
  final ValueChanged<double> onChanged;

  const CheckoutStepperField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.step,
    required this.minValue,
    this.prefixText,
    required this.onChanged,
  });

  @override
  State<CheckoutStepperField> createState() => _CheckoutStepperFieldState();
}

class _CheckoutStepperFieldState extends State<CheckoutStepperField> {
  late double _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _formatValue(_value));
  }

  @override
  void didUpdateWidget(covariant CheckoutStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _controller.text = _formatValue(_value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  void _commitValue(double newValue) {
    if (newValue < widget.minValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('Enter a valid ${widget.label}.'),
        ),
      );
      _controller.text = _formatValue(_value);
      return;
    }
    setState(() {
      _value = newValue;
      _controller.text = _formatValue(_value);
    });
    widget.onChanged(_value);
  }

  void _step(bool increase) {
    final delta = increase ? widget.step : -widget.step;
    final adjusted = (_value + delta).clamp(widget.minValue, double.infinity);
    _commitValue(adjusted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodySmall(widget.label, fontWeight: 600),
          const SizedBox(height: 4),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: widget.prefixText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    onFieldSubmitted: (raw) {
                      final parsed = double.tryParse(raw.trim());
                      if (parsed == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                            content: Text('Enter a valid ${widget.label}.'),
                          ),
                        );
                        _controller.text = _formatValue(_value);
                        return;
                      }
                      _commitValue(parsed);
                    },
                  ),
                ),
                _StepperColumn(
                  onIncrement: () => _step(true),
                  onDecrement: () => _step(false),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperColumn extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color color;

  const _StepperColumn({
    required this.onIncrement,
    required this.onDecrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepperButton(
            icon: Icons.keyboard_arrow_up,
            color: color,
            onTap: onIncrement,
          ),
          const SizedBox(height: 2),
          _StepperButton(
            icon: Icons.keyboard_arrow_down,
            color: color,
            onTap: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 18,
        width: 26,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}