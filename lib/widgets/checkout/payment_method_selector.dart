import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

enum PaymentMethod { cash, upi, card, credit }

class PaymentMethodSelector extends StatefulWidget {
  final Set<PaymentMethod> selectedPaymentMethods;
  final Map<PaymentMethod, double> paymentAmounts;
  final Function(Set<PaymentMethod>, Map<PaymentMethod, double>) onSelectionChanged;
  final String? orderFor;
  final double subtotal;
  final double chargesTotal;
  final double expensesTotal;
  final double grandTotal;

  const PaymentMethodSelector({
    super.key,
    Set<PaymentMethod>? selectedPaymentMethods,
    Map<PaymentMethod, double>? paymentAmounts,
    required this.onSelectionChanged,
    this.orderFor,
    required this.subtotal,
    required this.chargesTotal,
    required this.expensesTotal,
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
  bool _initialized = false;

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

    if (widget.orderFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
      _selectedPaymentMethods.remove(PaymentMethod.credit);
    }

    _controllers = {};
    _focusNodes = {};
    _createControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedPaymentMethods.isNotEmpty) {
          final method = _selectedPaymentMethods.first;
          final controller = _controllers[method];
          if (controller != null && controller.text.isEmpty) {
            controller.text = widget.grandTotal.toStringAsFixed(2);
            final amount = double.tryParse(controller.text) ?? 0.0;
            final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);
            if (amount > 0) {
              updatedAmounts[method] = amount;
            }
            widget.onSelectionChanged(_selectedPaymentMethods, updatedAmounts);
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(PaymentMethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.orderFor != widget.orderFor) {
      if (widget.orderFor == 'seller' && _selectedPaymentMethods.contains(PaymentMethod.credit)) {
        _selectedPaymentMethods.remove(PaymentMethod.credit);
        _controllers[PaymentMethod.credit]?.dispose();
        _focusNodes[PaymentMethod.credit]?.dispose();
        _controllers.remove(PaymentMethod.credit);
        _focusNodes.remove(PaymentMethod.credit);
        final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);
        updatedAmounts.remove(PaymentMethod.credit);
        final selected = Set<PaymentMethod>.from(_selectedPaymentMethods);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSelectionChanged(selected, updatedAmounts);
        });
      }
    }

    if (oldWidget.grandTotal != widget.grandTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedPaymentMethods.isNotEmpty) {
          final method = _selectedPaymentMethods.first;
          final controller = _controllers[method];
          if (controller != null && !_focusNodes[method]!.hasFocus) {
            controller.text = widget.grandTotal.toStringAsFixed(2);
            final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);
            updatedAmounts[method] = widget.grandTotal;
            widget.onSelectionChanged(_selectedPaymentMethods, updatedAmounts);
          }
        }
      });
    }

    if (oldWidget.selectedPaymentMethods != widget.selectedPaymentMethods) {
      _selectedPaymentMethods = Set.from(widget.selectedPaymentMethods);
    }

    _syncControllersFromWidget();
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
    if (widget.orderFor == 'seller' && method == PaymentMethod.credit) {
      return;
    }

    final updatedSelected = Set<PaymentMethod>.from(_selectedPaymentMethods);
    final updatedAmounts = Map<PaymentMethod, double>.from(widget.paymentAmounts);

    for (final existingMethod in updatedSelected) {
      _focusNodes[existingMethod]?.unfocus();
      updatedAmounts.remove(existingMethod);
      _controllers[existingMethod]?.clear();
    }
    updatedSelected.clear();

    updatedSelected.add(method);

      if (method == PaymentMethod.credit) {
      _controllers[method]?.text = '0';
      setState(() {
        _selectedPaymentMethods = updatedSelected;
      });
      widget.onSelectionChanged(updatedSelected, updatedAmounts);
      return;
    }

    final grandTotalText = widget.grandTotal.toStringAsFixed(2);
    _controllers[method]?.text = grandTotalText;
    final amount = double.tryParse(grandTotalText);
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
    double receivedAmount = totalAmount;
    double pendingPayment;

    if (widget.orderFor == 'seller') {
      pendingPayment = widget.grandTotal - receivedAmount;
    } else {
      pendingPayment = widget.grandTotal - receivedAmount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Method Section
        Container(
          margin: MySpacing.bottom(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: MySpacing.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodyMedium('How Would You Like to Pay?', fontWeight: 600),
                    MySpacing.height(2),
                    MyText.bodySmall(
                      'Choose your payment option',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              MySpacing.height(16),
              Padding(
                padding: MySpacing.only(left: 12),
                child: Row(
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
              ),
            ],
          ),
        ),

        // Payment Summary Section
        Container(
          margin: MySpacing.bottom(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: MySpacing.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodyMedium('Bill Summary', fontWeight: 600),
                    MySpacing.height(2),
                    MyText.bodySmall(
                      'Breakdown of your total amount',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              MySpacing.height(12),
              Padding(
                padding: MySpacing.only(left: 12),
                child: Column(
                  children: [
                    // Line items
                    _buildSummaryRow('Products', widget.subtotal, context),
                    _buildSummaryRow('Additional Charges', widget.chargesTotal, context),
                    _buildSummaryRow('Other Expenses', widget.expensesTotal, context),
                    MySpacing.height(8),
                    // Divider
                    Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                    MySpacing.height(8),
                    // Total
                    _buildSummaryRow('Total to Pay', widget.grandTotal, context, isBold: true),
                    MySpacing.height(12),
                    // Payment input
                    Container(
                      padding: MySpacing.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodySmall(
                            widget.orderFor == 'seller'
                                ? 'Amount You Will Receive'
                                : 'Enter Amount You Are Paying',
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          MySpacing.height(8),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              key: const ValueKey('payment_amount'),
                              controller: _selectedPaymentMethods.isNotEmpty
                                  ? _controllers[_selectedPaymentMethods.first]
                                  : null,
                              focusNode: _selectedPaymentMethods.isNotEmpty
                                  ? _focusNodes[_selectedPaymentMethods.first]
                                  : null,
                              enabled: _selectedPaymentMethods.isEmpty ||
                                  _selectedPaymentMethods.first != PaymentMethod.credit,
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
                                    width: 2,
                                  ),
                                ),
                                prefixText: '₹ ',
                                hintText: widget.grandTotal.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                fontSize: 16,
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
                    MySpacing.height(8),
                    // Balance
                    Container(
                      width: double.infinity,
                      padding: MySpacing.all(12),
                      decoration: BoxDecoration(
                        color: pendingPayment > 0
                            ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText.bodyMedium(
                            widget.orderFor == 'seller'
                                ? 'Remaining Amount'
                                : (pendingPayment >= 0 ? 'Balance Remaining' : 'Extra Paid'),
                            fontWeight: 500,
                          ),
                          MyText.bodyMedium(
                            '₹${pendingPayment.abs().toStringAsFixed(2)}',
                            fontWeight: 600,
                            color: pendingPayment > 0
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
        return 'Pay Later';
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

  Widget _buildSummaryRow(String label, double amount, BuildContext context, {bool isBold = false}) {
    return Padding(
      padding: MySpacing.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText.bodyMedium(
            label,
            fontWeight: isBold ? 600 : 400,
            color: isBold
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          MyText.bodyMedium(
            '₹${amount.toStringAsFixed(2)}',
            fontWeight: isBold ? 600 : 500,
            color: isBold
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
