import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/widgets/selling/sale_selection_bottom_sheet.dart';

class CartItemScreen extends StatefulWidget {
  final List<ItemSale>? initialSales;
  final Customer? buyerCustomer;
  final String Function(Customer?)? formatCustomer;
  final String? Function(ItemSale)? sellerNameForSale;
  final String Function(ItemSale)? productTitleForSale;
  final ValueChanged<Customer?>? onBuyerChanged;

  const CartItemScreen({
    super.key,
    this.initialSales,
    this.buyerCustomer,
    this.formatCustomer,
    this.sellerNameForSale,
    this.productTitleForSale,
    this.onBuyerChanged,
  });

  @override
  State<CartItemScreen> createState() => _CartItemScreenState();
}

class _CartItemScreenState extends State<CartItemScreen> {
  Customer? _buyerCustomer;

  @override
  void initState() {
    super.initState();
    _buyerCustomer = widget.buyerCustomer;
    // Load current sales if no initial sales provided
    if (widget.initialSales == null) {
      context.read<ItemSaleBloc>().add(const LoadItemSales());
    }
  }

  List<ItemSale> _getCurrentSales() {
    if (widget.initialSales != null) {
      return widget.initialSales!;
    }
    final state = context.read<ItemSaleBloc>().state;
    if (state is ItemSalesLoaded) {
      return state.sales;
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

  String? _sellerNameForSale(ItemSale sale) {
    if (widget.sellerNameForSale != null) {
      return widget.sellerNameForSale!(sale);
    }
    // Default implementation
    final customerBlocState = context.read<ItemSaleBloc>().state;
    if (customerBlocState is! ItemSalesLoaded) {
      return null;
    }
    return 'Seller #${sale.sellerId}';
  }

  String _productTitleForSale(ItemSale sale) {
    if (widget.productTitleForSale != null) {
      return widget.productTitleForSale!(sale);
    }
    // Default implementation
    return 'Product #${sale.productId}';
  }

  Future<int?> _createNewCart(List<ItemSale> selectedSales) async {
    if (_buyerCustomer == null) {
      _showSnack('Please select a buyer name before checkout.');
      return null;
    }

    // This would need to be implemented based on your cart creation logic
    // For now, returning a mock cart ID
    return 1; // Replace with actual cart creation logic
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
        title: MyText.titleMedium('Cart', fontWeight: 600),
      ),
      body: widget.initialSales != null 
          ? _buildCartContent(widget.initialSales!)
          : BlocBuilder<ItemSaleBloc, ItemSaleState>(
              builder: (context, state) {
                if (state is ItemSaleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final sales = _getCurrentSales();
                return _buildCartContent(sales);
              },
            ),
    );
  }

  Widget _buildCartContent(List<ItemSale> sales) {
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
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    MySpacing.height(16),
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

    return SaleSelectionBottomSheet(
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
        context.read<ItemSaleBloc>().add(DeleteItemSaleEvent(sale.id!));
        return true;
      },
      onCheckout: ( selectedSales) async {
        final cartId = await _createNewCart(selectedSales);
        if (cartId == null || !mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(cartId: cartId),
          ),
        );
      },
      showCancelButton: false,
    );
  }
}
