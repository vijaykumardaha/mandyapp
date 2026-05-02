import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart' as pms;
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/checkout/bill_summary_tile.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/widgets/checkout/payment_section.dart';
import 'package:mandyapp/widgets/checkout/charges_section.dart';
import 'package:mandyapp/widgets/checkout/charge_selection_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  final int orderId;
  final List<OrderCharge>? initialOrderCharges;
  final OrderPayment? initialPayment;
  final bool isEdit;

  const CheckoutScreen({
    Key? key,
    required this.orderId,
    this.initialOrderCharges,
    this.initialPayment,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Map<int, TextEditingController> _chargeControllers = {};
  bool _chargesExpanded = false;
  Set<int> _selectedChargeIds = {};
  Set<pms.PaymentMethod> _selectedPaymentMethods = {pms.PaymentMethod.cash};
  Map<pms.PaymentMethod, double> _paymentAmounts = {};
  bool _initialChargesApplied = false;
  final OrderChargeDAO _OrderChargeDAO = OrderChargeDAO();
  final OrderPaymentDAO _OrderPaymentDAO = OrderPaymentDAO();
  final Map<int, ChargeType> _chargesById = {};
  OrderPayment? _currentPayment;
  bool _isPersistingCheckout = false;
  bool _pendingPersist = false;
  DateTime? _lastPersistTrigger;

  @override
  void initState() {
    super.initState();
    _applyInitialPayment();
    // Only load cart details if cartId is valid (not 0)
    if (widget.orderId > 0) {
      context.read<OrderBloc>().add(LoadOrderById(widget.orderId));
    }
    // Load charges for the charges section
    context.read<ChargeTypesBloc>().add(LoadChargeTypes());
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _chargeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _applyInitialPayment() {
    final payment = widget.initialPayment;
    if (payment == null) {
      return;
    }

    // Get cart from OrderBloc to check cartFor
    final orderState = context.read<OrderBloc>().state;
    if (orderState is! OrderWithItemsLoaded) {
      return;
    }
    final order = orderState.order;

    final Map<pms.PaymentMethod, double> initialAmounts = {};

    void addMethod(pms.PaymentMethod method, int flag, double amount) {
      // Skip credit payment for seller carts
      if (method == pms.PaymentMethod.credit && order.orderFor == 'seller') {
        return;
      }
      if (flag == 1 || amount > 0) {
        initialAmounts[method] = amount; // allow zero to show explicitly
      }
    }

    addMethod(pms.PaymentMethod.cash, payment.cashPayment, payment.cashAmount);
    addMethod(pms.PaymentMethod.upi, payment.upiPayment, payment.upiAmount);
    addMethod(pms.PaymentMethod.card, payment.cardPayment, payment.cardAmount);
    addMethod(pms.PaymentMethod.credit, payment.creditPayment, payment.pendingAmount > 0 ? payment.pendingAmount : 0.0);

    if (initialAmounts.isNotEmpty) {
      _selectedPaymentMethods = initialAmounts.keys.toSet();
      _paymentAmounts = initialAmounts;
    }

    _currentPayment = payment;
  }

  void _applyInitialCharges(List<ChargeType> availableCharges) {
    if (_initialChargesApplied) return;
    final initialCharges = widget.initialOrderCharges;
    if (initialCharges == null || initialCharges.isEmpty) {
      _initialChargesApplied = true;
      return;
    }

    // Get cart information to filter charges by type
    final orderState = context.read<OrderBloc>().state;
    if (orderState is! OrderWithItemsLoaded) {
      _initialChargesApplied = true;
      return;
    }
    final order = orderState.order;

    // Filter available charges by cart type
    final relevantCharges = availableCharges.where((charge) => charge.chargeFor == order.orderFor).toList();

    final Map<int, double> matched = {};
    for (final saved in initialCharges) {
      for (final charge in relevantCharges) {
        if (order.id.toString() == saved.orderId.toString()) {
          if (charge.id != null) {
            // Use calculated amount for percentage charges, fixed amount for fixed charges
            final calculatedAmount = charge.chargeType == 'percentage'
                ? order.totalPrice * charge.chargeAmount / 100
                : charge.chargeAmount;
            matched[charge.id!] = calculatedAmount;
          }
          break;
        }
      }
    }

    if (matched.isEmpty) {
      _initialChargesApplied = true;
      return;
    }

    _updateChargeControllers(matched);
  }

  void _updateChargeControllers(Map<int, double> matched) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final entry in matched.entries) {
          final controller = _chargeControllers.remove(entry.key);
          controller?.dispose();
          _chargeControllers[entry.key] = TextEditingController(text: entry.value.toStringAsFixed(2));
        }
        _selectedChargeIds = matched.keys.toSet();
        _chargesExpanded = true;
        _initialChargesApplied = true;
      });
      _schedulePersistCheckout();
    });
  }

  void _schedulePersistCheckout() {
    final now = DateTime.now();
    if (_lastPersistTrigger != null && now.difference(_lastPersistTrigger!).inMilliseconds < 300) {
      _pendingPersist = true;
      return;
    }

    _lastPersistTrigger = now;

    if (_isPersistingCheckout) {
      _pendingPersist = true;
      return;
    }

    _persistCheckout();
  }

  Future<void> _persistCheckout() async {
    if (!mounted) return;
    _isPersistingCheckout = true;
    try {
      await _persistOrderCharges();
      await _persistOrderPayment();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to persist checkout: $error');
        debugPrint(stack.toString());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            content: Text('Failed to save checkout changes. Please retry.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _isPersistingCheckout = false;
      if (_pendingPersist) {
        _pendingPersist = false;
        _schedulePersistCheckout();
      }
    }
  }

  Future<void> _persistOrderCharges() async {
    final orderState = context.read<OrderBloc>().state;
    if (orderState is! OrderWithItemsLoaded) return;
    final orderId = orderState.order.id.toString();

    List<OrderCharge> chargesToSave = [];
    for (final entry in _chargeControllers.entries) {
      final chargeId = entry.key;
      final text = entry.value.text.trim();
      final amount = double.tryParse(text) ?? 0.0;

      if (_selectedChargeIds.contains(chargeId)) {
        chargesToSave.add(
          OrderCharge(
            orderId: orderId,
            chargeName: _chargesById[chargeId]?.chargeName ?? 'ChargeType',
            chargeAmount: amount,
          ),
        );
      }
    }

    await _OrderChargeDAO.bulkInsertForOrder(orderId, chargesToSave);
  }

  Future<void> _persistOrderPayment() async {
    final orderState = context.read<OrderBloc>().state;
    if (orderState is! OrderWithItemsLoaded) return;
    final order = orderState.order;

    final subtotal = order.totalPrice;
    double chargesTotal = 0.0;
    for (final entry in _chargeControllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (_selectedChargeIds.contains(entry.key)) {
        chargesTotal += amount;
      }
    }

    double receivedAmount = _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    double grandTotal = order.orderFor == 'seller'
        ? subtotal - chargesTotal
        : subtotal + chargesTotal;
    double pendingAmount = grandTotal - receivedAmount;

    // Calculate paymentAmount and pendingPayment based on order type
    double paymentAmount, pendingPayment;
    if (order.orderFor == 'seller') {
      // For seller carts: paymentAmount is the amount to be paid to seller
      paymentAmount = grandTotal;
      // pendingPayment is the amount still owed to seller
      pendingPayment = paymentAmount - receivedAmount;
    } else {
      // For buyer carts: paymentAmount is the amount received
      paymentAmount = receivedAmount;
      // pendingPayment is the remaining amount to be paid
      pendingPayment = pendingAmount;
    }

    OrderPayment? existingPayment = _currentPayment ??
        await _OrderPaymentDAO.getOrderPaymentByOrderId(order.id!);

    final nowIso = DateTime.now().toIso8601String();
    final paymentPayload = OrderPayment(
      id: existingPayment?.id ?? 0,
      orderId: order.id!,
      itemTotal: subtotal,
      chargeTotal: chargesTotal,
      receiveAmount: receivedAmount,
      pendingAmount: pendingAmount,
      pendingPayment: pendingPayment,
      paymentAmount: paymentAmount,
      cashPayment: (_paymentAmounts.containsKey(pms.PaymentMethod.cash) && (_paymentAmounts[pms.PaymentMethod.cash] ?? 0) > 0) ? 1 : 0,
      upiPayment: (_paymentAmounts.containsKey(pms.PaymentMethod.upi) && (_paymentAmounts[pms.PaymentMethod.upi] ?? 0) > 0) ? 1 : 0,
      cardPayment: (_paymentAmounts.containsKey(pms.PaymentMethod.card) && (_paymentAmounts[pms.PaymentMethod.card] ?? 0) > 0) ? 1 : 0,
      creditPayment: (order.orderFor != 'seller' && _paymentAmounts.containsKey(pms.PaymentMethod.credit) && (_paymentAmounts[pms.PaymentMethod.credit] ?? 0) > 0) ? 1 : 0,
      cashAmount: _paymentAmounts[pms.PaymentMethod.cash] ?? 0.0,
      upiAmount: _paymentAmounts[pms.PaymentMethod.upi] ?? 0.0,
      cardAmount: _paymentAmounts[pms.PaymentMethod.card] ?? 0.0,
      createdAt: existingPayment?.createdAt ?? nowIso,
      updatedAt: nowIso,
    );

    if (existingPayment != null) {
      await _OrderPaymentDAO.updateOrderPayment(paymentPayload);
    } else {
      await _OrderPaymentDAO.insertOrderPayment(paymentPayload);
    }

    _currentPayment = paymentPayload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('Checkout'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Done'),
            ),
          ),
        ),
      ),
      body: widget.orderId == 0 
          ? _buildEmptyCart()
          : BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is OrderWithItemsLoaded) {
                  return _buildCheckoutContent(state.order, {}, {});
                }

                if (state is OrderError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                        MySpacing.height(16),
                        MyText.bodyLarge('Error loading cart', color: Theme.of(context).colorScheme.error),
                        MySpacing.height(8),
                        MyText.bodyMedium(state.message, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        MySpacing.height(16),
                        ElevatedButton(
                          onPressed: () {
                            // Retry loading cart
                            context.read<OrderBloc>().add(LoadOrderById(widget.orderId));
                          },
                          child: MyText.bodyMedium('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildEmptyCart();
              },
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          MySpacing.height(16),
          MyText.bodyLarge('Order is empty', color: Theme.of(context).colorScheme.outline),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent(Order cart, Map<int, Product> products, Map<int, ProductVariant> variants) {
    return Column(
      children: [
        // Order Summary Header
        Container(
          padding: MySpacing.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.bodyLarge('Bill Summary', fontWeight: 600),
              MyText.bodyLarge(
                '${cart.itemCount} items',
                color: Theme.of(context).colorScheme.primary,
                fontWeight: 600,
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: MySpacing.all(16),
            itemCount: cart.items!.length + 2, // +2 for charges and payment sections
            itemBuilder: (context, index) {
              if (index < cart.items!.length) {
                final item = cart.items![index];
                return _buildBillSummaryTile(context, item);
              } else if (index == cart.items!.length) {
                return _buildChargesSection();
              } else {
                return _buildPaymentSection(cart);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillSummaryTile(
    BuildContext context,
    OrderItem item,
  ) {
    return BillSummaryTile(
      isEdit: widget.isEdit,
      item: item,
      onPersistCheckout: _schedulePersistCheckout,
    );
  }

  Future<void> _showChargeSelectionDialog(List<ChargeType> availableCharges) async {
    final selectedIds = await ChargeSelectionDialog.show(
      context,
      availableCharges: availableCharges,
      selectedChargeIds: _selectedChargeIds,
    );

    if (selectedIds != null) {
      setState(() {
        _selectedChargeIds = selectedIds;
        _chargesExpanded = true;
      });
      _schedulePersistCheckout();
    }
  }

  Widget _buildChargesSection() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
        if (orderState is! OrderWithItemsLoaded) {
          return Container(
            margin: MySpacing.bottom(12),
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MySpacing.width(8),
                MyText.bodyMedium('Charges', fontWeight: 600),
                const Spacer(),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        return ChargesSection(
          order: orderState.order,
          selectedChargeIds: _selectedChargeIds,
          chargeControllers: _chargeControllers,
          initialChargesApplied: _initialChargesApplied,
          applyInitialCharges: _applyInitialCharges,
          onChargesChanged: (selectedIds, controllers) {
            setState(() {
              _selectedChargeIds = selectedIds;
              _chargeControllers.clear();
              _chargeControllers.addAll(controllers);
            });
          },
          onSchedulePersistCheckout: _schedulePersistCheckout,
          onShowChargeSelectionDialog: _showChargeSelectionDialog,
        );
      },
    );
  }

  Widget _buildPaymentSection(Order order) {
    return PaymentSection(
      order: order,
      selectedChargeIds: _selectedChargeIds,
      chargeControllers: _chargeControllers,
      selectedPaymentMethods: _selectedPaymentMethods,
      paymentAmounts: _paymentAmounts,
      onPaymentMethodChanged: (selectedMethods, paymentAmounts) {
        setState(() {
          _selectedPaymentMethods = selectedMethods;
          _paymentAmounts = paymentAmounts;
        });
      },
      onSchedulePersistCheckout: _schedulePersistCheckout,
    );
  }
}
