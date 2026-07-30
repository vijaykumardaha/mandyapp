import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/models/order_item_model.dart';
import 'package:mandiapp/screens/checkout_screen.dart';
import 'package:mandiapp/widgets/selling/cart_item_list.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Customer? _selectedCustomer;
  bool _isBuyerMode = true;
  StreamSubscription<String>? _syncSubscription;
  TextEditingController? _searchController;
  List<Customer> _allCustomers = [];

  String get _orderFor => _isBuyerMode ? 'buyer' : 'seller';

  LoadAllUnlinkedOrderItems get _loadEventForMode => LoadAllUnlinkedOrderItems(
    excludeBuyerOrderLinked: _isBuyerMode,
    excludeSellerOrderLinked: !_isBuyerMode,
  );

  @override
  void initState() {
    super.initState();
    context.read<OrderItemBloc>().add(_loadEventForMode);
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == 'order_items') {
        final state = context.read<OrderItemBloc>().state;
        if (state is OrderItemsLoaded) {
          context.read<OrderItemBloc>().add(_loadEventForMode);
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
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
    _searchController?.text = customer != null ? _formatCustomer(customer) : '';
    setState(() {
      _selectedCustomer = customer;
    });
    if (_isBuyerMode) {
      return;
    }
    if (customer != null && customer.id != null) {
      context.read<OrderItemBloc>().add(LoadOrderItems(sellerId: customer.id, excludeOrderLinked: true));
    } else {
      context.read<OrderItemBloc>().add(LoadAllUnlinkedOrderItems(excludeBuyerOrderLinked: false, excludeSellerOrderLinked: true));
    }
  }

  void _toggleMode() {
    _searchController?.clear();
    setState(() {
      _isBuyerMode = !_isBuyerMode;
      _selectedCustomer = null;
    });
    context.read<OrderItemBloc>().add(_loadEventForMode);
  }

  Future<void> _createNewCart(List<OrderItem> selectedSales) async {
    final customer = _selectedCustomer;
    if (customer == null || customer.id == null) {
      Info.error('Please select a ${_isBuyerMode ? 'buyer' : 'seller'} name before checkout.', context: context);
      return;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: selectedSales,
          customerId: customer.id,
          orderFor: _orderFor,
        ),
      ),
    );

    if (mounted) {
      _searchController?.clear();
      setState(() {
        _selectedCustomer = null;
      });

      if (result != null && result['orderId'] != null) {
        context.push('/bill-details/${result['orderId']}');
      }
      if (_isBuyerMode) {
        context.read<OrderItemBloc>().add(LoadAllUnlinkedOrderItems(excludeBuyerOrderLinked: true, excludeSellerOrderLinked: false));
      } else {
        context.read<OrderItemBloc>().add(LoadAllUnlinkedOrderItems(excludeBuyerOrderLinked: false, excludeSellerOrderLinked: true));
      }
    }
  }

  List<Customer> _filteredCustomers(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _allCustomers.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final phone = (c.phone ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  Widget _buildModeChip() {
    final colors = Theme.of(context).colorScheme;
    final isBuyer = _isBuyerMode;
    return GestureDetector(
      onTap: _toggleMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isBuyer ? colors.tertiaryContainer : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBuyer ? Icons.shopping_cart : Icons.store,
              size: 16,
              color: isBuyer ? colors.onTertiaryContainer : colors.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              isBuyer ? 'Buyer' : 'Seller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isBuyer ? colors.onTertiaryContainer : colors.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Autocomplete<Customer>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return [];
        return _filteredCustomers(textEditingValue.text);
      },
      onSelected: (customer) {
        _onCustomerChanged(customer);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        _searchController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: _selectedCustomer != null
                ? _formatCustomer(_selectedCustomer)
                : 'Search ${_isBuyerMode ? 'buyer' : 'seller'}...',
            prefixIcon: const Icon(Icons.person, size: 18),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.clear();
                      _onCustomerChanged(null);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final customers = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final name = customer.name ?? 'Unnamed';
                  final initials = name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase();
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: MyText.bodySmall(
                        initials,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: 600,
                        fontSize: 11,
                      ),
                    ),
                    title: MyText.bodyMedium(name, fontWeight: 600),
                    subtitle: customer.phone != null
                        ? MyText.bodySmall(customer.phone!, color: Theme.of(context).colorScheme.onSurfaceVariant)
                        : null,
                    onTap: () => onSelected(customer),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = context.watch<CustomerBloc>().state;
    if (customerState is CustomerLoaded) {
      _allCustomers = customerState.customers;
    }

    return Scaffold(
      appBar: CommonAppBar(
        showBackButton: false,
        centerTitle: false,
        titleWidget: _buildAppBarTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildModeChip(),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<OrderItemBloc, OrderItemState>(
          builder: (context, state) {
            if (state is OrderItemLoading) {
              return const Center(child: CircularProgressIndicator());
            }
  
            final sales = state is OrderItemsLoaded ? state.orderItems : <OrderItem>[];
            return _buildCartContent(sales);
          },
        ),
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
      buyerMode: _isBuyerMode,
    );
  }
}
