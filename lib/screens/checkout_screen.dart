import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart' as customer_bloc;
import 'package:mandyapp/blocs/charges/charges_event.dart';
import 'package:mandyapp/blocs/charges/charges_state.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/helpers/widgets/payment_method_selector.dart' as pms;
import 'package:mandyapp/models/charge_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/cart_item_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';

class CheckoutScreen extends StatefulWidget {
  final int cartId;

  const CheckoutScreen({Key? key, required this.cartId}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Map<int, TextEditingController> _chargeControllers = {};
  bool _chargesExpanded = false;
  Set<int> _selectedChargeIds = {};
  Set<pms.PaymentMethod> _selectedPaymentMethods = {pms.PaymentMethod.cash};
  Map<pms.PaymentMethod, double> _paymentAmounts = {};
  Customer? _selectedSeller;
  Customer? _selectedBuyer;

  @override
  void dispose() {
    // Dispose all controllers
    _chargeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load cart details using CheckoutBloc
    context.read<CheckoutBloc>().add(LoadCheckoutCart(widget.cartId));
    // Load charges for the charges section
    context.read<ChargesBloc>().add(LoadCharges());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            if (state is CheckoutCartLoaded || state is CheckoutDataLoaded) {
              final cart = state is CheckoutCartLoaded ? state.cart :
                          (state as CheckoutDataLoaded).cart;
              return MyText.titleMedium('Checkout - ${cart.name ?? 'Cart'}');
            }
            return MyText.titleMedium('Checkout');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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

                return _buildBillItem(context, item, product, variant);
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

  Widget _buildBillItem(BuildContext context, CartItem item, Product product, ProductVariant variant) {
    final theme = Theme.of(context);

    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: variant.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      variant.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.inventory_2,
                          size: 24,
                          color: theme.colorScheme.onSurfaceVariant,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.inventory_2,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),

          MySpacing.width(8),

          // Product Details & Quantity Controls
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Product Name
                MyText.bodySmall(
                  product.name,
                  fontWeight: 600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 12,
                ),

                MySpacing.height(2),

                // Variant Name
                MyText.bodySmall(
                  '${variant.variantName ?? '${variant.quantity}${variant.unit}'}',
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),

                MySpacing.height(6),

                // Quantity Controls (Horizontal Layout)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrement Button
                    InkWell(
                      onTap: () => _updateItemQuantity(context, item, -1),
                      child: Container(
                        padding: MySpacing.xy(6, 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    MySpacing.width(8),

                    // Quantity Display
                    Container(
                      padding: MySpacing.xy(8, 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: MyText.bodySmall(
                        '${item.quantity.toInt()}',
                        color: Colors.white,
                        fontWeight: 700,
                        fontSize: 11,
                      ),
                    ),

                    MySpacing.width(8),

                    // Increment Button
                    InkWell(
                      onTap: () => _updateItemQuantity(context, item, 1),
                      child: Container(
                        padding: MySpacing.xy(6, 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          MySpacing.width(8),

          // Price Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.bodyMedium(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                fontWeight: 700,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
              MySpacing.height(2),
              MyText.bodySmall(
                '₹${item.unitPrice.toStringAsFixed(2)} each',
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 9,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChargeSelectionDialog(List<Charge> availableCharges) {
    // Create a temporary set for dialog selection
    Set<int> tempSelectedIds = Set.from(_selectedChargeIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: MyText.titleMedium('Select Charges', fontWeight: 600),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableCharges.length,
              itemBuilder: (context, index) {
                final charge = availableCharges[index];
                final isSelected = tempSelectedIds.contains(charge.id);

                return CheckboxListTile(
                  title: MyText.bodyMedium(charge.chargeName),
                  subtitle: MyText.bodySmall('₹${charge.chargeAmount.toStringAsFixed(2)}'),
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
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update parent state with selected charges
                setState(() {
                  _selectedChargeIds = tempSelectedIds;
                  _chargesExpanded = true;
                });
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
          final activeCharges = state.charges.where((charge) => charge.isActive == 1).toList();

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
                    'No active charges',
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
                      onPressed: () => _showChargeSelectionDialog(activeCharges),
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
                      _chargeControllers[charge.id!] = TextEditingController(
                        text: charge.chargeAmount.toStringAsFixed(2),
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
          // Calculate total from edited charge amounts for selected charges only
          for (var charge in chargesState.charges) {
            if (charge.isActive == 1 && _selectedChargeIds.contains(charge.id) && _chargeControllers.containsKey(charge.id)) {
              final editedAmount = double.tryParse(_chargeControllers[charge.id!]!.text) ?? charge.chargeAmount;
              chargesTotal += editedAmount;
            }
          }
        }

        double grandTotal = subtotal + chargesTotal;

        // Calculate received amount from payment methods
        double receivedAmount = _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);

        return Container(
          padding: MySpacing.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Column(
            children: [
              // Payment Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium('Subtotal', fontWeight: 500),
                  MyText.bodyMedium('₹${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              MySpacing.height(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium('Charges', fontWeight: 500),
                  MyText.bodyMedium('₹${chargesTotal.toStringAsFixed(2)}'),
                ],
              ),

              MySpacing.height(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium('Received Amount', fontWeight: 500),
                  MyText.bodyMedium(
                    '₹${receivedAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                ],
              ),

              MySpacing.height(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium('Pending Amount', fontWeight: 500),
                  MyText.bodyMedium(
                    '₹${(grandTotal - receivedAmount).toStringAsFixed(2)}',
                    color: (grandTotal - receivedAmount) > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),

  
                MySpacing.height(16),
                Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                MySpacing.height(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.bodyMedium('Payment Total', fontWeight: 600),
                    MyText.bodyLarge(
                      '₹${receivedAmount.toStringAsFixed(2)}',
                      fontWeight: 700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),

              MySpacing.height(16),

              // Payment Method Selector
              pms.PaymentMethodSelector(
                selectedPaymentMethods: _selectedPaymentMethods,
                paymentAmounts: _paymentAmounts,
                onSelectionChanged: (selectedMethods, paymentAmounts) {
                  setState(() {
                    _selectedPaymentMethods = selectedMethods;
                    _paymentAmounts = paymentAmounts;
                  });
                },
              ),

              MySpacing.height(16),

              // Customer Section
              _buildCustomerSection(),

              MySpacing.height(16),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _completeCheckout(context, cart.id, grandTotal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: MySpacing.y(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: MyText.bodyLarge(
                    'Complete Order',
                    fontWeight: 700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateItemQuantity(BuildContext context, CartItem item, int change) {
    if (change > 0) {
      // Increment quantity
      final updatedItem = item.copyWith(
        quantity: item.quantity + 1,
        totalPrice: (item.quantity + 1) * item.unitPrice,
      );
      context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
    } else if (change < 0) {
      // Decrement quantity
      if (item.quantity > 1) {
        final updatedItem = item.copyWith(
          quantity: item.quantity - 1,
          totalPrice: (item.quantity - 1) * item.unitPrice,
        );
        context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
      } else {
        // Remove item if quantity would become 0
        context.read<CheckoutBloc>().add(RemoveCheckoutItem(item));
      }
    }
  }

  void _completeCheckout(BuildContext context, int cartId, double totalAmount) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Complete Order?', fontWeight: 600),
        content: MyText.bodyMedium(
          'This will mark the cart as completed and finalize the order for ₹${totalAmount.toStringAsFixed(2)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Complete checkout using CheckoutBloc
              context.read<CheckoutBloc>().add(CompleteCheckout(cartId));

              // Show success message and navigate back
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order completed successfully for ₹${totalAmount.toStringAsFixed(2)}!')),
              );

              // Navigate back
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to selling screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: MyText.bodyMedium('Complete', color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
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
                Icons.people,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.bodyMedium('Customer Selection', fontWeight: 600),
            ],
          ),

          MySpacing.height(16),

          // Seller and Buyer Dropdowns
          Row(
            children: [
              // Seller Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodySmall('Seller', fontWeight: 500),
                    MySpacing.height(8),
                    BlocBuilder<customer_bloc.CustomerBloc, customer_bloc.CustomerState>(
                      builder: (context, state) {
                        if (state is customer_bloc.CustomerLoaded) {
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<Customer>(
                              value: _selectedSeller,
                              hint: MyText.bodySmall('Select Seller'),
                              isExpanded: true,
                              underline: SizedBox(),
                              items: state.customers.map((customer) {
                                return DropdownMenuItem<Customer>(
                                  value: customer,
                                  child: Padding(
                                    padding: MySpacing.x(12),
                                    child: MyText.bodySmall('${customer.name} (${customer.phone})'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (customer) {
                                setState(() {
                                  _selectedSeller = customer;
                                });
                              },
                            ),
                          );
                        }
                        return Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: MyText.bodySmall('Loading...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              MySpacing.width(16),

              // Buyer Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodySmall('Buyer', fontWeight: 500),
                    MySpacing.height(8),
                    BlocBuilder<customer_bloc.CustomerBloc, customer_bloc.CustomerState>(
                      builder: (context, state) {
                        if (state is customer_bloc.CustomerLoaded) {
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<Customer>(
                              value: _selectedBuyer,
                              hint: MyText.bodySmall('Select Buyer'),
                              isExpanded: true,
                              underline: SizedBox(),
                              items: state.customers.map((customer) {
                                return DropdownMenuItem<Customer>(
                                  value: customer,
                                  child: Padding(
                                    padding: MySpacing.x(12),
                                    child: MyText.bodySmall('${customer.name} (${customer.phone})'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (customer) {
                                setState(() {
                                  _selectedBuyer = customer;
                                });
                              },
                            ),
                          );
                        }
                        return Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: MyText.bodySmall('Loading...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
