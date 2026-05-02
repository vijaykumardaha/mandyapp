import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/widgets/selling/cart_item_list.dart';

class OrderItemScreen extends StatefulWidget {
  final List<OrderItem>? initialSales;
  final Customer? buyerCustomer;
  final String Function(Customer?)? formatCustomer;
  final String? Function(OrderItem)? sellerNameForSale;
  final String Function(OrderItem)? productTitleForSale;
  final ValueChanged<Customer?>? onBuyerChanged;

  const OrderItemScreen({
    super.key,
    this.initialSales,
    this.buyerCustomer,
    this.formatCustomer,
    this.sellerNameForSale,
    this.productTitleForSale,
    this.onBuyerChanged,
  });

  @override
  State<OrderItemScreen> createState() => _OrderItemScreenState();
}

class _OrderItemScreenState extends State<OrderItemScreen> {
  Customer? _buyerCustomer;
  final OrderDAO _orderDAO = OrderDAO();

  @override
  void initState() {
    super.initState();
    _buyerCustomer = widget.buyerCustomer;
    // Load current sales if no initial sales provided
    if (widget.initialSales == null) {
      context.read<OrderItemBloc>().add(const LoadOrderItems());
    }
  }

  List<OrderItem> _getCurrentSales() {
    if (widget.initialSales != null) {
      return widget.initialSales!;
    }
    final state = context.read<OrderItemBloc>().state;
    if (state is OrderItemsLoaded) {
      return state.orderItems;
    }
    return const [];
  }

  String _formatCustomer(Customer? customer) {
    if (widget.formatCustomer != null) {
      return widget.formatCustomer!(customer);
    }
    if (customer == null) {
      return '';
    }
    final name = customer.name?.trim() ?? '';
    final phone = customer.phone?.trim() ?? '';
    if (name.isNotEmpty && phone.isNotEmpty) {
      return '$name ($phone)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    return phone;
  }

  String? _sellerNameForSale(OrderItem sale) {
    if (widget.sellerNameForSale != null) {
      return widget.sellerNameForSale!(sale);
    }
    // Default implementation
    final customerBlocState = context.read<OrderItemBloc>().state;
    if (customerBlocState is! OrderItemsLoaded) {
      return null;
    }
    return 'Seller #${sale.sellerId}';
  }

  String _productTitleForSale(OrderItem sale) {
    if (widget.productTitleForSale != null) {
      return widget.productTitleForSale!(sale);
    }
    // Default implementation
    return 'Product #${sale.productId}';
  }

  Future<int?> _createNewCart(List<OrderItem> selectedSales) async {
    if (_buyerCustomer == null || _buyerCustomer!.id == null) {
      _showSnack('Please select a buyer name before checkout.');
      return null;
    }

    try {
      // Create a new order for the buyer
      // Use 0 as temporary ID, database will assign actual ID
      final newOrder = Order(
        customerId: _buyerCustomer!.id!,
        createdAt: DateTime.now().toIso8601String(),
        status: 'open',
        orderFor: 'buyer',
      );

      // Insert the order and get the order ID
      final orderId = await _orderDAO.insertOrder(newOrder);

      // Link the selected order items to this order
      for (final sale in selectedSales) {
        final updatedSale = sale.copyWith(
          buyerOrderId: orderId,
          buyerId: _buyerCustomer!.id!,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _orderDAO.updateOrderItem(updatedSale);
      }

      // Reload order items to update the list
      context.read<OrderItemBloc>().add(const LoadOrderItems());

      return orderId;
    } catch (e) {
      _showSnack('Failed to create cart: ${e.toString()}');
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBar(title: Text('Cart Items')),
      ),
      body: widget.initialSales != null 
          ? _buildCartContent(widget.initialSales!)
          : BlocBuilder<OrderItemBloc, OrderItemState>(
              builder: (context, state) {
                if (state is OrderItemLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final sales = _getCurrentSales();
                return _buildCartContent(sales);
              },
            ),
    );
  }

  Widget _buildCartContent(List<OrderItem> sales) {
    if (sales.isEmpty) {
      return Padding(
        padding: MySpacing.xy(16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText.bodyLarge(
                      'Cart is empty',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    MySpacing.height(8),
                    MyText.bodyMedium(
                      'Add items from selling screen to continue',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CartItemList(
      initialSales: sales,
      buyerCustomer: _buyerCustomer,
      onBuyerChanged: (customer) {
        setState(() {
          _buyerCustomer = customer;
        });
        widget.onBuyerChanged?.call(customer);
      },
      formatCustomer: _formatCustomer,
      sellerNameForSale: _sellerNameForSale,
      productTitleForSale: _productTitleForSale,
      onDeleteSale: (sale, index) async {
        if (sale.id == null) {
          return false;
        }
        context.read<OrderItemBloc>().add(DeleteOrderItemEvent(sale.id!));
        return true;
      },
      onCheckout: ( selectedSales) async {
        final cartId = await _createNewCart(selectedSales);
        if (cartId == null || !mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(orderId: cartId),
          ),
        );
      },
      showCancelButton: false,
    );
  }
}
