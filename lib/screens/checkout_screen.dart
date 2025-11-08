import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_event.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart' as pms;
import 'package:mandyapp/models/charge_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/checkout/bill_summary_tile.dart';
import 'package:mandyapp/models/cart_charge_model.dart';
import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/dao/cart_charge_dao.dart';
import 'package:mandyapp/dao/cart_payment_dao.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';
import 'package:mandyapp/widgets/checkout/payment_section.dart';
import 'package:mandyapp/widgets/checkout/charges_section.dart';
import 'package:mandyapp/widgets/checkout/charge_selection_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  final int cartId;
  final List<CartCharge>? initialCartCharges;
  final CartPayment? initialPayment;
  final bool isEdit;

  const CheckoutScreen({
    Key? key,
    required this.cartId,
    this.initialCartCharges,
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
    return BillSummaryTile(
      isEdit: widget.isEdit,
      item: item,
      product: product,
      variant: variant,
      onPersistCheckout: _schedulePersistCheckout,
    );
  }

  Future<void> _showChargeSelectionDialog(List<Charge> availableCharges) async {
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
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, checkoutState) {
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

        return ChargesSection(
          cart: checkoutState.cart,
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

  Widget _buildPaymentSection(Cart cart) {
    return PaymentSection(
      cart: cart,
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
