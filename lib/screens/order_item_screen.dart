import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/widgets/selling/cart_item_list.dart';

class OrderItemScreen extends StatefulWidget {
  const OrderItemScreen({super.key});

  @override
  State<OrderItemScreen> createState() => _OrderItemScreenState();
}

class _OrderItemScreenState extends State<OrderItemScreen> {
  Customer? _buyerCustomer;

  @override
  void initState() {
    super.initState();
    context.read<OrderItemBloc>().add(const LoadOrderItems());
  }

  String _formatCustomer(Customer? customer) {
    if (customer == null) return '';
    final name = customer.name?.trim() ?? '';
    final phone = customer.phone?.trim() ?? '';
    if (name.isNotEmpty && phone.isNotEmpty) return '$name ($phone)';
    if (name.isNotEmpty) return name;
    return phone;
  }

  Future<void> _createNewCart(List<OrderItem> selectedSales) async {
    if (_buyerCustomer == null || _buyerCustomer!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          content: const Text('Please select a buyer name before checkout.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: selectedSales,
          customerId: _buyerCustomer!.id,
          orderFor: 'buyer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Items'),
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
      },
      formatCustomer: _formatCustomer,
      sellerNameForSale: (sale) => sale.sellerName,
      productTitleForSale: (sale) => sale.productName ?? 'Product #${sale.productId}',
      onDeleteSale: (sale, index) async {
        if (sale.id == null) return false;
        context.read<OrderItemBloc>().add(DeleteOrderItemEvent(sale.id!));
        return true;
      },
      onCheckout: (selectedSales) async {
        await _createNewCart(selectedSales);
      },
      showCancelButton: false,
    );
  }
}
