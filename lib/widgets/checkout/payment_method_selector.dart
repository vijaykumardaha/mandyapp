import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

enum PaymentType { single, split }
enum PaymentMethod { cash, upi, card, credit }

class PaymentMethodSelector extends StatefulWidget {
  final Set<PaymentMethod> selectedPaymentMethods;
  final Map<PaymentMethod, double> paymentAmounts;
  final Function(Set<PaymentMethod>, Map<PaymentMethod, double>) onSelectionChanged;
  final String? orderFor; // 'seller' or 'buyer' - if seller, hide credit option
  final double subtotal;
  final double chargesTotal;
  final double grandTotal;

  const PaymentMethodSelector({
    super.key,
    Set<PaymentMethod>? selectedPaymentMethods,
    Map<PaymentMethod, double>? paymentAmounts,
    required this.onSelectionChanged,
    this.orderFor,
    required this.subtotal,
    required this.chargesTotal,
    required this.grandTotal,
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
    if (widget.orderFor != 'seller') {
      methods.add(PaymentMethod.credit);
    }
    return methods;
  }

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethods = Set.from(widget.selectedPaymentMethods);

    // If orderFor is seller, remove credit payment method if it was selected
    if (widget.orderFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
      _selectedPaymentMethods.remove(PaymentMethod.credit);
    }

    _controllers = {};
    _focusNodes = {};
    _createControllers();
    _syncControllersFromWidget();

    // Pre-fill with grand total
    if (_selectedPaymentMethods.isNotEmpty) {
      final controller = _controllers[_selectedPaymentMethods.first];
      if (controller != null && controller.text.isEmpty) {
        controller.text = widget.grandTotal.toStringAsFixed(2);
        _updatePaymentAmount(_selectedPaymentMethods.first, controller.text);
      }
    }
  }

  @override
  void didUpdateWidget(PaymentMethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle orderFor changes
    if (oldWidget.orderFor != widget.orderFor) {
      if (widget.orderFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
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
    if (widget.orderFor == 'seller' && method == PaymentMethod.credit) {
      return;
    }

    final updatedSelected = Set<PaymentMethod>.from(_selectedPaymentMethods);
    final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);

    // Clear all existing selections and amounts
    for (final existingMethod in updatedSelected) {
      _focusNodes[existingMethod]?.unfocus();
      updatedAmounts.remove(existingMethod);
      _controllers[existingMethod]?.clear();
    }
    updatedSelected.clear();

    // Add the new selection
    updatedSelected.add(method);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[method]?.requestFocus();
    });
    final currentText = _controllers[method]?.text ?? '';
    final amount = double.tryParse(currentText);
    if (amount != null && amount > 0) {
      updatedAmounts[method] = amount;
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
    // Calculate payment amounts
    double receivedAmount = totalAmount;
    double pendingAmount = widget.grandTotal - receivedAmount;
    
    // Calculate paymentAmount and pendingPayment based on order type
    double paymentAmount, pendingPayment;
    if (widget.orderFor == 'seller') {
      paymentAmount = widget.grandTotal;
      pendingPayment = paymentAmount - receivedAmount;
    } else {
      paymentAmount = receivedAmount;
      pendingPayment = pendingAmount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Method Section
        Container(
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
            ],
          ),
        ),

        // Payment Summary Section
        Container(
          margin: MySpacing.bottom(12),
          padding: MySpacing.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MySpacing.width(8),
                  MyText.bodyMedium('Payment Summary', fontWeight: 600),
                ],
              ),
              MySpacing.height(12),
              Column(
                children: [
                  // Item Total, Charges, and Grand Total in Row
                  Row(
                    children: [
                      Expanded(
                        child: _modernSummaryCard(
                          'Item Total',
                          widget.subtotal,
                          Icons.shopping_bag_outlined,
                          context,
                        ),
                      ),
                      MySpacing.width(12),
                      Expanded(
                        child: _modernSummaryCard(
                          'Charges',
                          widget.chargesTotal,
                          Icons.add_circle_outline,
                          context,
                        ),
                      ),
                      MySpacing.width(12),
                      Expanded(
                        child: _modernSummaryCard(
                          'Grand Total',
                          widget.grandTotal,
                          Icons.account_balance_wallet,
                          context,
                        ),
                      ),
                    ],
                  ),
      
                  MySpacing.height(8),

                  // Payment Details
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            padding: MySpacing.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_circle_down,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    MySpacing.width(8),
                                    MyText.bodySmall(
                                      widget.orderFor == 'seller'
                                          ? 'Amount Owed'
                                          : 'Amount to Pay',
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ],
                                ),
                                MySpacing.height(8),
                                SizedBox(
                                  height: 36,
                                  child: TextField(
                                    key: const ValueKey('payment_amount'),
                                    controller: _selectedPaymentMethods.isNotEmpty
                                        ? _controllers[_selectedPaymentMethods.first]
                                        : null,
                                    focusNode: _selectedPaymentMethods.isNotEmpty
                                        ? _focusNodes[_selectedPaymentMethods.first]
                                        : null,
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
                                      hintText: widget.grandTotal.toStringAsFixed(2),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (value) {
                                      if (_selectedPaymentMethods.isNotEmpty) {
                                        _updatePaymentAmount(_selectedPaymentMethods.first, value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        MySpacing.width(12),
                        Expanded(
                          child: _modernSummaryCard(
                            widget.orderFor == 'seller'
                                ? 'Amount Pending'
                                : (pendingPayment >= 0
                                    ? 'Pending Payment'
                                    : 'Payment Due'),
                            pendingPayment.abs(),
                            pendingPayment > 0
                                ? Icons.pending
                                : Icons.done_all,
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, String label) {
    final isSelected = _selectedPaymentMethods.contains(method);
    return Expanded(
      child: InkWell(
        onTap: () => _togglePaymentMethod(method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: MySpacing.xy(8, 8),
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
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              MySpacing.height(2),
              MyText.bodySmall(
                label,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? 600 : 500,
                textAlign: TextAlign.center,
                fontSize: 10,
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

  Widget _modernSummaryCard(
      String label, double amount, IconData icon, BuildContext context) {
    return Container(
      padding: MySpacing.xy(8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              MySpacing.width(4),
              Flexible(
                child: MyText.bodySmall(
                  label,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          MySpacing.height(4),
          MyText.bodySmall(
            '₹${amount.toStringAsFixed(2)}',
            fontWeight: 600,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
          ),
        ],
      ),
    );
  }
}
