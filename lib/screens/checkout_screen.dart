import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_event.dart';
import 'package:mandyapp/blocs/charges/charges_state.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/helpers/widgets/checkout_stepper_field.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/helpers/widgets/payment_method_selector.dart' as pms;
import 'package:mandyapp/models/charge_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/models/cart_charge_model.dart';
import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/dao/cart_charge_dao.dart';
import 'package:mandyapp/dao/cart_payment_dao.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';

class CheckoutScreen extends StatefulWidget {
  final int cartId;
  final List<CartCharge>? initialCartCharges;
  final CartPayment? initialPayment;

  const CheckoutScreen({
    Key? key,
    required this.cartId,
    this.initialCartCharges,
    this.initialPayment,
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
  final CartChargeDAO _cartChargeDAO = CartChargeDAO();
  final CartPaymentDAO _cartPaymentDAO = CartPaymentDAO();
  final Map<int, Charge> _chargesById = {};
  CartPayment? _currentPayment;
  bool _isPersistingCheckout = false;
  bool _pendingPersist = false;
  DateTime? _lastPersistTrigger;

  @override
  void initState() {
    super.initState();
    _applyInitialPayment();
    // Load cart details using CheckoutBloc
    context.read<CheckoutBloc>().add(LoadCheckoutCart(widget.cartId));
    // Load charges for the charges section
    context.read<ChargesBloc>().add(LoadCharges());
  }

  @override
  void deactivate() {
    // Load item sales when checkout is being removed from the widget tree
    if (mounted) {
      context.read<ItemSaleBloc>().add(const LoadItemSales());
    }
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

    // Get cart from CheckoutBloc to check cartFor
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is! CheckoutDataLoaded) {
      return;
    }
    final cart = checkoutState.cart;

    final Map<pms.PaymentMethod, double> initialAmounts = {};

    void addMethod(pms.PaymentMethod method, bool flag, double amount) {
      // Skip credit payment for seller carts
      if (method == pms.PaymentMethod.credit && cart.cartFor == 'seller') {
        return;
      }
      if (flag || amount > 0) {
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

  void _applyInitialCharges(List<Charge> availableCharges) {
    if (_initialChargesApplied) return;
    final initialCharges = widget.initialCartCharges;
    if (initialCharges == null || initialCharges.isEmpty) {
      _initialChargesApplied = true;
      return;
    }

    // Get cart information to filter charges by type
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is! CheckoutDataLoaded) {
      _initialChargesApplied = true;
      return;
    }
    final cart = checkoutState.cart;

    // Filter available charges by cart type
    final relevantCharges = availableCharges.where((charge) => charge.chargeFor == cart.cartFor).toList();

    final Map<int, double> matched = {};
    for (final saved in initialCharges) {
      for (final charge in relevantCharges) {
        if (charge.chargeName.toLowerCase() == saved.chargeName.toLowerCase()) {
          if (charge.id != null) {
            // Use calculated amount for percentage charges, fixed amount for fixed charges
            final calculatedAmount = charge.chargeType == 'percentage'
                ? cart.totalPrice * charge.chargeAmount / 100
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
      await _persistCartCharges();
      await _persistCartPayment();
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

  Future<void> _persistCartCharges() async {
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is! CheckoutDataLoaded) return;
    final cartId = checkoutState.cart.id.toString();

    List<CartCharge> chargesToSave = [];
    for (final entry in _chargeControllers.entries) {
      final chargeId = entry.key;
      final text = entry.value.text.trim();
      final amount = double.tryParse(text) ?? 0.0;

      if (_selectedChargeIds.contains(chargeId)) {
        chargesToSave.add(
          CartCharge(
            cartId: cartId,
            chargeName: _chargesById[chargeId]?.chargeName ?? 'Charge',
            chargeAmount: amount,
          ),
        );
      }
    }

    await _cartChargeDAO.bulkInsertForCart(cartId, chargesToSave);
  }

  Future<void> _persistCartPayment() async {
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is! CheckoutDataLoaded) return;
    final cart = checkoutState.cart;

    final subtotal = cart.totalPrice;
    double chargesTotal = 0.0;
    for (final entry in _chargeControllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0.0;
      if (_selectedChargeIds.contains(entry.key)) {
        chargesTotal += amount;
      }
    }

    double receivedAmount = _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    double grandTotal = cart.cartFor == 'seller'
        ? subtotal - chargesTotal
        : subtotal + chargesTotal;
    double pendingAmount = grandTotal - receivedAmount;

    // Calculate paymentAmount and pendingPayment based on cart type
    double paymentAmount, pendingPayment;
    if (cart.cartFor == 'seller') {
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

    CartPayment? existingPayment = _currentPayment ??
        await _cartPaymentDAO.getCartPaymentByCartId(cart.id);

    final nowIso = DateTime.now().toIso8601String();
    final paymentPayload = CartPayment(
      id: existingPayment?.id ?? DBHelper.generateUuidInt(),
      cartId: cart.id,
      itemTotal: subtotal,
      chargesTotal: chargesTotal,
      receiveAmount: receivedAmount,
      pendingAmount: pendingAmount,
      pendingPayment: pendingPayment,
      paymentAmount: paymentAmount,
      cashPayment: _paymentAmounts.containsKey(pms.PaymentMethod.cash) && (_paymentAmounts[pms.PaymentMethod.cash] ?? 0) > 0,
      upiPayment: _paymentAmounts.containsKey(pms.PaymentMethod.upi) && (_paymentAmounts[pms.PaymentMethod.upi] ?? 0) > 0,
      cardPayment: _paymentAmounts.containsKey(pms.PaymentMethod.card) && (_paymentAmounts[pms.PaymentMethod.card] ?? 0) > 0,
      creditPayment: cart.cartFor != 'seller' && _paymentAmounts.containsKey(pms.PaymentMethod.credit) && (_paymentAmounts[pms.PaymentMethod.credit] ?? 0) > 0,
      cashAmount: _paymentAmounts[pms.PaymentMethod.cash] ?? 0.0,
      upiAmount: _paymentAmounts[pms.PaymentMethod.upi] ?? 0.0,
      cardAmount: _paymentAmounts[pms.PaymentMethod.card] ?? 0.0,
      createdAt: existingPayment?.createdAt ?? nowIso,
      updatedAt: nowIso,
    );

    if (existingPayment != null) {
      await _cartPaymentDAO.updateCartPayment(paymentPayload);
    } else {
      await _cartPaymentDAO.insertCartPayment(paymentPayload);
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
      body: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          if (state is CheckoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CheckoutCartLoaded) {
            final cart = state.cart;
            if (cart.items == null || cart.items!.isEmpty) {
              return _buildEmptyCart();
            }

            return _buildCheckoutContent(cart, {}, {});
          }

          if (state is CheckoutDataLoaded) {
            return _buildCheckoutContent(state.cart, state.products, state.variants);
          }

          if (state is CheckoutError) {
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
                      context.read<CheckoutBloc>().add(LoadCheckoutCart(widget.cartId));
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
          MyText.bodyLarge('Cart is empty', color: Theme.of(context).colorScheme.outline),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent(Cart cart, Map<int, Product> products, Map<int, ProductVariant> variants) {
    return Column(
      children: [
        // Cart Summary Header
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
                final product = products[item.productId];
                final variant = variants[item.variantId];

                if (product == null || variant == null) {
                  return const SizedBox.shrink();
                }

                return _buildBillSummaryTile(context, item, product, variant);
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
    ItemSale item,
    Product product,
    ProductVariant variant,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: MyText.bodyMedium(
                variant.variantName,
                fontWeight: 600,
              ),
            ),
          ),
          CheckoutStepperField(
            key: ValueKey('qty-${item.id ?? item.variantId}-${item.buyerCartId}'),
            label: 'Qty (${variant.unit})',
            initialValue: item.quantity,
            step: 1,
            minValue: 0.1,
            onChanged: (value) {
              if (value == item.quantity) return;
              final updatedItem = item.copyWith(quantity: value);
              context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
              _schedulePersistCheckout();
            },
          ),
          MySpacing.width(6),
          CheckoutStepperField(
            key: ValueKey('rate-${item.id ?? item.variantId}-${item.buyerCartId}'),
            label: 'Rate',
            initialValue: item.sellingPrice,
            step: 0.5,
            minValue: 0.1,
            prefixText: '₹',
            onChanged: (value) {
              if (value == item.sellingPrice) return;
              final updatedItem = item.copyWith(sellingPrice: value);
              context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
              _schedulePersistCheckout();
            },
          ),
          MySpacing.width(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText.bodyLarge(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                fontWeight: 700,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _showChargeSelectionDialog(List<Charge> availableCharges) {
    // Get cart information from CheckoutBloc state
    final checkoutState = context.read<CheckoutBloc>().state;
    if (checkoutState is! CheckoutDataLoaded) {
      return;
    }
    final cart = checkoutState.cart;

    // Filter charges based on cart type
    final filteredCharges = availableCharges.where((charge) => charge.chargeFor == cart.cartFor).toList();

    // Create a temporary set for dialog selection
    Set<int> tempSelectedIds = Set.from(_selectedChargeIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: MyText.titleMedium('Select Charges', fontWeight: 600),
          content: SizedBox(
            width: double.maxFinite,
            child: filteredCharges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        MySpacing.height(16),
                        MyText.bodyMedium(
                          'No charges available for ${cart.cartFor == 'buyer' ? 'buyers' : 'sellers'}',
                          color: Theme.of(context).colorScheme.outline,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCharges.length,
                    itemBuilder: (context, index) {
                      final charge = filteredCharges[index];
                      final isSelected = tempSelectedIds.contains(charge.id);

                      return Container(
                        margin: MySpacing.bottom(8),
                        padding: MySpacing.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  dialogSetState(() {
                                    if (value == true) {
                                      tempSelectedIds.add(charge.id!);
                                    } else {
                                      tempSelectedIds.remove(charge.id!);
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            MySpacing.width(12),

                            // Charge Name
                            Expanded(
                              flex: 3,
                              child: MyText.bodyMedium(
                                charge.chargeName,
                                fontWeight: 500,
                              ),
                            ),

                            // Charge Type Badge
                            Container(
                              padding: MySpacing.xy(4, 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: MyText.bodySmall(
                                charge.chargeType == 'percentage'
                                    ? '${charge.chargeAmount.toStringAsFixed(1)}%'
                                    : 'Fixed',
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: 500,
                                fontSize: 10,
                              ),
                            ),

                            MySpacing.width(8),

                            // Amount - Show calculated amount for both types
                            MyText.bodyMedium(
                              charge.chargeType == 'percentage'
                                  ? '₹${(cart.totalPrice * charge.chargeAmount / 100).toStringAsFixed(2)}'
                                  : '₹${charge.chargeAmount.toStringAsFixed(2)}',
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: 600,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('Cancel'),
            ),
            if (filteredCharges.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  // Update parent state with selected charges
                  setState(() {
                    _selectedChargeIds = tempSelectedIds;
                    _chargesExpanded = true;
                  });
                  _schedulePersistCheckout();
                  Navigator.pop(context);
                },
                child: MyText.bodyMedium('Apply'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesSection() {
    return BlocBuilder<ChargesBloc, ChargesState>(
      builder: (context, state) {
        if (state is ChargesLoaded) {
          if (!_initialChargesApplied) {
            _applyInitialCharges(state.charges);
          }

          // Get cart information to filter charges by type
          final checkoutState = context.read<CheckoutBloc>().state;
          if (checkoutState is! CheckoutDataLoaded) {
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
          final cart = checkoutState.cart;

          // Filter active charges by cart type
          final activeCharges = state.charges
              .where((charge) => charge.isActive == 1 && charge.chargeFor == cart.cartFor)
              .toList();

          _chargesById
            ..clear()
            ..addEntries(activeCharges.where((charge) => charge.id != null).map((charge) => MapEntry(charge.id!, charge)));

          if (activeCharges.isEmpty) {
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
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      MySpacing.width(8),
                      MyText.bodyMedium('Charges', fontWeight: 600),
                    ],
                  ),
                  MySpacing.height(8),
                  MyText.bodySmall(
                    'No active charges for ${cart.cartFor == 'buyer' ? 'buyers' : 'sellers'}',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            );
          }

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
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    MySpacing.width(8),
                    MyText.bodyMedium('Charges', fontWeight: 600),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showChargeSelectionDialog(state.charges.where((charge) => charge.isActive == 1).toList()),
                      child: MyText.bodySmall(
                        'Add Charges',
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: 600,
                      ),
                    ),
                  ],
                ),

                if (_chargesExpanded) ...[
                  MySpacing.height(12),
                  ...activeCharges.where((charge) => _selectedChargeIds.contains(charge.id)).map((charge) {
                    // Create controller for this charge if it doesn't exist
                    if (!_chargeControllers.containsKey(charge.id)) {
                      final calculatedAmount = charge.chargeType == 'percentage'
                          ? cart.totalPrice * charge.chargeAmount / 100
                          : charge.chargeAmount;
                      _chargeControllers[charge.id!] = TextEditingController(
                        text: calculatedAmount.toStringAsFixed(2),
                      );
                    }

                    return Padding(
                      padding: MySpacing.bottom(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MyText.bodySmall(
                              charge.chargeName,
                              fontWeight: 500,
                            ),
                          ),
                          MySpacing.width(8),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _chargeControllers[charge.id!],
                                decoration: InputDecoration(
                                  contentPadding: MySpacing.xy(8, 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  prefixText: '₹',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                onChanged: (value) {
                                  setState(() {});
                                  _schedulePersistCheckout();
                                },
                              ),
                            ),
                          ),
                          MySpacing.width(8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedChargeIds.remove(charge.id!);
                                _chargeControllers.remove(charge.id!);
                              });
                              _schedulePersistCheckout();
                            },
                            child: Container(
                              padding: MySpacing.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        }

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
      },
    );
  }


  Widget _buildPaymentSection(Cart cart) {
    return BlocBuilder<ChargesBloc, ChargesState>(
      builder: (context, chargesState) {
        double subtotal = cart.totalPrice;
        double chargesTotal = 0.0;

        if (chargesState is ChargesLoaded) {
          // Get cart information to filter charges by type
          final checkoutState = context.read<CheckoutBloc>().state;
          if (checkoutState is CheckoutDataLoaded) {
            final cart = checkoutState.cart;

            // Calculate total from edited charge amounts for selected charges only, filtered by cart type
            for (var charge in chargesState.charges) {
              if (charge.isActive == 1 && charge.chargeFor == cart.cartFor && _selectedChargeIds.contains(charge.id) && _chargeControllers.containsKey(charge.id)) {
                final editedAmount = double.tryParse(_chargeControllers[charge.id!]!.text) ?? charge.chargeAmount;
                chargesTotal += editedAmount;
              }
            }
          }
        }

        double grandTotal = cart.cartFor == 'seller'
            ? subtotal - chargesTotal
            : subtotal + chargesTotal;

        // Calculate received amount from payment methods
        double receivedAmount = _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);
        double pendingAmount = grandTotal - receivedAmount;

        // Calculate paymentAmount and pendingPayment based on cart type
        double paymentAmount, pendingPayment;
        if (cart.cartFor == 'seller') {
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

        return Container(
          padding: MySpacing.all(0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: MyText.bodySmall('Summary', fontWeight: 600),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: MyText.bodySmall('Amount', fontWeight: 600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _summaryRow('Item Totals', subtotal, context),
                    _summaryRow('Charge Total', chargesTotal, context),
                    _summaryRow('Grand Total', grandTotal, context, emphasized: true),
                    _summaryRow(
                      cart.cartFor == 'seller' ? 'Amount Owed' : 'Payment Amount',
                      paymentAmount,
                      context,
                      valueColor: Colors.blue,
                    ),
                    _summaryRow(
                      cart.cartFor == 'seller' ? 'Amount Received' : 'Received Amount',
                      receivedAmount,
                      context,
                      valueColor: Colors.green,
                    ),
                    _summaryRow(
                      cart.cartFor == 'seller' ? 'Amount Pending' : (pendingPayment >= 0 ? 'Pending Payment' : 'Payment Due'),
                      pendingPayment.abs(),
                      context,
                      valueColor: pendingPayment > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              MySpacing.height(16),
              pms.PaymentMethodSelector(
                selectedPaymentMethods: _selectedPaymentMethods,
                paymentAmounts: _paymentAmounts,
                cartFor: cart.cartFor,
                onSelectionChanged: (selectedMethods, paymentAmounts) {
                  setState(() {
                    _selectedPaymentMethods = selectedMethods;
                    _paymentAmounts = paymentAmounts;
                  });
                  _schedulePersistCheckout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, double amount, BuildContext context, {bool emphasized = false, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: MyText.bodyMedium(
              label,
              fontWeight: emphasized ? 700 : 600,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: MyText.bodyMedium(
                '₹${amount.toStringAsFixed(2)}',
                fontWeight: emphasized ? 700 : 600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
