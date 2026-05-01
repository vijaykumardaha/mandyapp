import 'package:flutter/material.dart';

class CheckoutStepperField extends StatefulWidget {
  final String label;
  final double initialValue;
  final double step;
  final double minValue;
  final double? maxValue;
  final String? unit;
  final TextEditingController? controller;
  final ValueChanged<double> onChanged;
  final bool enabled;
  
  const CheckoutStepperField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.step,
    required this.minValue,
    this.maxValue,
    this.unit,
    this.controller,
    required this.onChanged,
    this.enabled = true,
  });
  
  @override
  State<CheckoutStepperField> createState() => _CheckoutStepperFieldState();
}

class _CheckoutStepperFieldState extends State<CheckoutStepperField> {
  late final TextEditingController _controller;
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = _formatValue(_value);
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
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatValue(double value) {
    return value == value.toInt() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      height: 40, // Fixed height for the field
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        readOnly: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12, // Slightly smaller font size
            ),
        decoration: InputDecoration(
          labelText: widget.unit != null ? '${widget.label} (${widget.unit})' : widget.label,
          labelStyle: const TextStyle(fontSize: 12), // Smaller label
          border: const OutlineInputBorder(
            borderSide: BorderSide(width: 1.0),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(width: 1.0),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4, // Reduced vertical padding
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: VerticalStepper(
              controller: _controller,
              onChanged: (value) {
                setState(() {
                  _value = value;
                  widget.onChanged(value);
                });
              },
              step: widget.step,
              minValue: widget.minValue,
              maxValue: widget.maxValue,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 24,
            maxWidth: 24,
            maxHeight: 32,
          ),
        ),
      ),
    );
  }
}

class VerticalStepper extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<double> onChanged;
  final double step;
  final double minValue;
  final double? maxValue;

  const VerticalStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.step,
    required this.minValue,
    this.maxValue,
  });

  void _increment() {
    double currentValue = double.tryParse(controller.text) ?? minValue;
    double newValue = currentValue + step;
    if (maxValue != null) {
      newValue = newValue.clamp(minValue, maxValue!);
    } else {
      newValue = newValue.clamp(minValue, double.infinity);
    }
    controller.text = newValue == newValue.toInt() 
        ? newValue.toInt().toString() 
        : newValue.toStringAsFixed(1);
    onChanged(newValue);
  }

  void _decrement() {
    double currentValue = double.tryParse(controller.text) ?? minValue;
    double newValue = currentValue - step;
    newValue = newValue.clamp(minValue, maxValue ?? double.infinity);
    controller.text = newValue == newValue.toInt() 
        ? newValue.toInt().toString() 
        : newValue.toStringAsFixed(1);
    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 14,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _increment,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 0),
          SizedBox(
            width: 20,
            height: 14,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _decrement,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}