import 'package:flutter/material.dart';
import 'package:mandyapp/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/widgets/common/common_app_bar.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/widgets/selling/cart_item_list.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Customer? _selectedCustomer;
  bool _isBuyerMode = true;

  String get _orderFor => _isBuyerMode ? 'buyer' : 'seller';

  @override
  void initState() {
    super.initState();
    if (_isBuyerMode) {
      context.read<OrderItemBloc>().add(const LoadAllUnlinkedOrderItems());
    }
  }

  String _formatCustomer(Customer? customer) {
    if (customer == null) return '';
    final name = customer.name?.trim() ?? '';
    final phone = customer.phone?.trim() ?? '';
    if (name.isNotEmpty && phone.isNotEmpty) return '$name ($phone)';
    if (name.isNotEmpty) return name;
    return phone;
  }

  void _onCustomerChanged(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
    });
    if (_isBuyerMode) {
      // In buyer mode, items are already loaded — don't reload by customer
      return;
    }
    if (customer != null && customer.id != null) {
      context.read<OrderItemBloc>().add(LoadOrderItems(sellerId: customer.id, excludeOrderLinked: true));
    }
  }

  void _toggleMode() {
    setState(() {
      _isBuyerMode = !_isBuyerMode;
      _selectedCustomer = null;
    });
    if (_isBuyerMode) {
      context.read<OrderItemBloc>().add(const LoadAllUnlinkedOrderItems());
    } else {
      context.read<OrderItemBloc>().add(const ClearOrderItems());
    }
  }

  Future<void> _createNewCart(List<OrderItem> selectedSales) async {
    if (_selectedCustomer == null || _selectedCustomer!.id == null) {
      Info.error('Please select a ${_isBuyerMode ? 'buyer' : 'seller'} name before checkout.', context: context);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: selectedSales,
          customerId: _selectedCustomer!.id,
          orderFor: _orderFor,
        ),
      ),
    );

    if (mounted) {
      if (_isBuyerMode) {
        context.read<OrderItemBloc>().add(const LoadAllUnlinkedOrderItems());
      } else if (_selectedCustomer != null && _selectedCustomer!.id != null) {
        context.read<OrderItemBloc>().add(LoadOrderItems(sellerId: _selectedCustomer!.id, excludeOrderLinked: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${_isBuyerMode ? 'Buyer' : 'Seller'} Billing',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: _isBuyerMode ? 'Switch to Seller' : 'Switch to Buyer',
              child: GestureDetector(
                onTap: _toggleMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isBuyerMode
                        ? Theme.of(context).colorScheme.tertiaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBuyerMode ? Icons.shopping_cart : Icons.store,
                        size: 16,
                        color: _isBuyerMode
                            ? Theme.of(context).colorScheme.onTertiaryContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_isBuyerMode ? 'Buyer' : 'Seller'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isBuyerMode
                              ? Theme.of(context).colorScheme.onTertiaryContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<OrderItemBloc, OrderItemState>(
        builder: (context, state) {
          if (state is OrderItemLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = state is OrderItemsLoaded ? state.orderItems : <OrderItem>[];
          return _buildCartContent(sales);
        },
      ),
    );
  }

  Widget _buildCartContent(List<OrderItem> sales) {
    return CartItemList(
      key: ValueKey(_isBuyerMode),
      initialSales: sales,
      buyerCustomer: _selectedCustomer,
      onBuyerChanged: _onCustomerChanged,
      formatCustomer: _formatCustomer,
      sellerNameForSale: (sale) => sale.sellerName,
      productTitleForSale: (sale) => sale.productName ?? 'Product #${sale.productId}',
      onDeleteSale: (sale, index) async {
        if (sale.id == null) return false;
        context.read<OrderItemBloc>().add(DeleteOrderItemEvent(
          sale.id!,
          sellerId: _isBuyerMode ? null : _selectedCustomer?.id,
          buyerId: _isBuyerMode ? _selectedCustomer?.id : null,
        ));
        return true;
      },
      onCheckout: (selectedSales) async {
        await _createNewCart(selectedSales);
      },
      showCancelButton: false,
      customerLabel: _isBuyerMode ? 'Buyer' : 'Seller',
      buyerMode: _isBuyerMode,
    );
  }
}
