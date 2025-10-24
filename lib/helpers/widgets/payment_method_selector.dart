import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

enum PaymentType { single, split }
enum PaymentMethod { cash, upi, card, credit }

class PaymentMethodSelector extends StatefulWidget {
  final Set<PaymentMethod> selectedPaymentMethods;
  final Map<PaymentMethod, double> paymentAmounts;
  final Function(Set<PaymentMethod>, Map<PaymentMethod, double>) onSelectionChanged;
  final String? cartFor; // 'seller' or 'buyer' - if seller, hide credit option

  const PaymentMethodSelector({
    super.key,
    Set<PaymentMethod>? selectedPaymentMethods,
    Map<PaymentMethod, double>? paymentAmounts,
    required this.onSelectionChanged,
    this.cartFor,
  }) : selectedPaymentMethods = selectedPaymentMethods ?? const {PaymentMethod.cash},
       paymentAmounts = paymentAmounts ?? const {};

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  late Set<PaymentMethod> _selectedPaymentMethods;
  late final Map<PaymentMethod, TextEditingController> _controllers;
  late final Map<PaymentMethod, FocusNode> _focusNodes;

  // Get available payment methods based on cart type
  List<PaymentMethod> get _availablePaymentMethods {
    final methods = [PaymentMethod.cash, PaymentMethod.upi, PaymentMethod.card];
    if (widget.cartFor != 'seller') {
      methods.add(PaymentMethod.credit);
    }
    return methods;
  }

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethods = Set.from(widget.selectedPaymentMethods);

    // If cartFor is seller, remove credit payment method if it was selected
    if (widget.cartFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
      _selectedPaymentMethods.remove(PaymentMethod.credit);
    }

    _controllers = {};
    _focusNodes = {};
    _createControllers();
    _syncControllersFromWidget();
  }

  @override
  void didUpdateWidget(PaymentMethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle cartFor changes
    if (oldWidget.cartFor != widget.cartFor) {
      if (widget.cartFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
        _selectedPaymentMethods.remove(PaymentMethod.credit);
        // Clear credit controller and focus node if they exist
        _controllers[PaymentMethod.credit]?.dispose();
        _focusNodes[PaymentMethod.credit]?.dispose();
        _controllers.remove(PaymentMethod.credit);
        _focusNodes.remove(PaymentMethod.credit);
        // Remove credit from payment amounts
        final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);
        updatedAmounts.remove(PaymentMethod.credit);
        widget.onSelectionChanged(_selectedPaymentMethods, updatedAmounts);
      }
    }

    if (oldWidget.selectedPaymentMethods != widget.selectedPaymentMethods) {
      _selectedPaymentMethods = Set.from(widget.selectedPaymentMethods);
    }
    if (oldWidget.paymentAmounts != widget.paymentAmounts) {
      _syncControllersFromWidget();
    }
  }

  void _createControllers() {
    for (var method in _availablePaymentMethods) {
      _controllers[method] = TextEditingController();
      _focusNodes[method] = FocusNode();
    }
  }

  void _syncControllersFromWidget() {
    for (var method in _availablePaymentMethods) {
      final controller = _controllers[method];
      if (controller == null) continue;
      final focusNode = _focusNodes[method];
      final amount = widget.paymentAmounts[method];
      final formatted = (amount != null && amount > 0) ? amount.toStringAsFixed(2) : '';
      if (focusNode != null && focusNode.hasFocus) {
        continue;
      }
      if (controller.text != formatted) {
        controller.value = controller.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _togglePaymentMethod(PaymentMethod method) {
    // Prevent selecting credit for seller carts
    if (widget.cartFor == 'seller' && method == PaymentMethod.credit) {
      return;
    }

    final updatedSelected = Set<PaymentMethod>.from(_selectedPaymentMethods);
    final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);

    if (updatedSelected.contains(method)) {
      updatedSelected.remove(method);
      _focusNodes[method]?.unfocus();
      updatedAmounts.remove(method);
      _controllers[method]?.clear();
    } else {
      updatedSelected.add(method);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[method]?.requestFocus();
      });
      final currentText = _controllers[method]?.text ?? '';
      final amount = double.tryParse(currentText);
      if (amount != null && amount > 0) {
        updatedAmounts[method] = amount;
      }
    }

    setState(() {
      _selectedPaymentMethods = updatedSelected;
    });

    widget.onSelectionChanged(updatedSelected, updatedAmounts);
  }

  void _updatePaymentAmount(PaymentMethod method, String value) {
    final amount = double.tryParse(value) ?? 0.0;

    final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);
    if (amount > 0) {
      updatedAmounts[method] = amount;
    } else {
      updatedAmounts.remove(method);
    }

    widget.onSelectionChanged(_selectedPaymentMethods, updatedAmounts);
  }

  double get totalAmount {
    return widget.paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.payment,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.bodyMedium('Payment Method', fontWeight: 600),
            ],
          ),

          MySpacing.height(16),

          // Payment Method Selection Row
          Row(
            children: [
              ..._availablePaymentMethods.map((method) {
                final label = _getPaymentMethodLabel(method);
                return [
                  _buildPaymentMethodOption(method, label),
                  if (method != _availablePaymentMethods.last) MySpacing.width(8),
                ];
              }).expand((element) => element),
            ],
          ),

          // Amount Input Fields for Selected Methods
          if (_selectedPaymentMethods.isNotEmpty) ...[
            MySpacing.height(16),
            Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            MySpacing.height(12),
            ..._selectedPaymentMethods
                .where((method) => _availablePaymentMethods.contains(method))
                .map((method) => Padding(
              padding: MySpacing.bottom(12),
              child: Row(
                children: [
                  // Payment Method Icon and Name
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        MySpacing.width(8),
                        MyText.bodyMedium(
                          _getPaymentMethodLabel(method),
                          fontWeight: 500,
                        ),
                      ],
                    ),
                  ),

                  MySpacing.width(12),

                  // Amount Input Field
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        key: ValueKey(method), // Ensure unique key for each field
                        controller: _controllers[method],
                        focusNode: _focusNodes[method],
                        decoration: InputDecoration(
                          contentPadding: MySpacing.xy(12, 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          prefixText: '₹',
                          hintText: '0.00',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        onChanged: (value) => _updatePaymentAmount(method, value),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, String label) {
    final isSelected = _selectedPaymentMethods.contains(method);
    return Expanded(
      child: InkWell(
        onTap: () => _togglePaymentMethod(method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: MySpacing.xy(8, 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _getPaymentMethodIcon(method),
                size: 20,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              MySpacing.height(4),
              MyText.bodySmall(
                label,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? 600 : 500,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.upi:
        return Icons.account_balance_wallet;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.credit:
        return Icons.credit_score;
    }
  }
}
