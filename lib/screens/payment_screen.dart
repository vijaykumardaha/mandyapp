import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/widgets/billing/payment_item_widget.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late ThemeData theme;
  Customer? _selectedSellerForBill;
  bool _isCreatingBill = false;
  String? _selectedAlphabet;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
      _loadSummaries();
    });
  }

  void _createBill() {
    if (_isCreatingBill) {
      return;
    }
    _showSellerSelectionSheet();
  }

  void _resetBillCreationState() {
    _isCreatingBill = false;
    _selectedSellerForBill = null;
  }

  Future<void> _showSellerSelectionSheet() async {
    _showSnack('Use the Create Bill button to create bills for sellers.');
    _resetBillCreationState();
    return;
  }

  
  Future<void> _handleCreateSellerBill(List<OrderItem> selectedSales, Customer seller) async {
    if (_isCreatingBill) {
      return;
    }

    if (selectedSales.isEmpty) {
      _showSnack('Select at least one sale item.');
      return;
    }

    final sellerId = seller.id;
    if (sellerId == null) {
      _showSnack('Seller information is incomplete.');
      return;
    }

    _isCreatingBill = true;
    final cartBloc = context.read<OrderBloc>();
    final itemSaleBloc = context.read<OrderItemBloc>();
    final billListBloc = context.read<BillListBloc>();

    final orderId = DBHelper.generateUuidInt();
    final now = DateTime.now().toIso8601String();

    final order = Order(
      id: orderId,
      customerId: sellerId,
      createdAt: now,
      orderFor: 'seller',
      status: 'open',
    );

    cartBloc.add(CreateOrder(order));

    for (final sale in selectedSales) {
      final originalSaleId = sale.id;
      final cartLinkedSale = sale.copyWith(
        id: DBHelper.generateUuidInt(),
        sellerOrderId: orderId,
        sellerId: sellerId,
        buyerOrderId: null,
        buyerId: null
      );
      cartBloc.add(AddItemToOrder(cartLinkedSale));

      if (originalSaleId != null) {
        itemSaleBloc.add(DeleteOrderItemEvent(originalSaleId));
      }
    }

    if (!mounted) {
      _resetBillCreationState();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: cartBloc.state is OrderWithItemsLoaded 
              ? (cartBloc.state as OrderWithItemsLoaded).order.items ?? []
              : [],
          customerId: cartBloc.state is OrderWithItemsLoaded 
              ? (cartBloc.state as OrderWithItemsLoaded).order.customerId
              : null,
          orderId: orderId,
          orderFor: 'seller',
        ),
      ),
    );

    if (!mounted) {
      _resetBillCreationState();
      return;
    }

    billListBloc.add(const LoadBillSummaries(forceRefresh: true));
    _resetBillCreationState();
  }

  void _loadSummaries({bool forceRefresh = false}) {
    context.read<BillListBloc>().add(
          LoadBillSummaries(
            forceRefresh: forceRefresh,
          ),
        );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: AppBar( title: Text('Payment Management')),
    );
  }

  

  Widget _buildCustomerSelection() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        // Only show loading if we're actually in customer selection mode
        if (_selectedSellerForBill != null) {
          return const SizedBox.shrink();
        }
        
        final allCustomers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;
        final hasError = customerState is SyncCustomerError;

        // Filter customers by selected alphabet
        List<Customer> customers = allCustomers;
        if (_selectedAlphabet != null) {
          customers = allCustomers.where((customer) {
            final name = customer.name?.trim().toUpperCase() ?? '';
            return name.startsWith(_selectedAlphabet!);
          }).toList();
        }

        if (isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading customers...'),
              ],
            ),
          );
        }

        if (hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                MyText.bodyMedium(
                  'Failed to load customers',
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                MyText.bodyMedium(
                  _selectedAlphabet != null 
                      ? 'No customers found starting with "${_selectedAlphabet}"'
                      : 'No customers found',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (_selectedAlphabet != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedAlphabet = null;
                      });
                    },
                    child: MyText.bodySmall(
                      'Show all customers',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (_selectedAlphabet == null && allCustomers.isEmpty) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                    },
                    child: const Text('Refresh Customers'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alphabet filter
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" tag
                    _buildAlphabetTag('All', _selectedAlphabet == null),
                    const SizedBox(width: 8),
                    // A-Z tags
                    ...List.generate(26, (index) {
                      final alphabet = String.fromCharCode(65 + index); // A-Z
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAlphabetTag(
                            alphabet, _selectedAlphabet == alphabet),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Customer grid - takes remaining available space
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSellerForBill = customer;
                        // Reload sales for the newly selected seller
                        if (customer.id != null) {
                          final itemSaleBloc = context.read<OrderItemBloc>();
                          itemSaleBloc.add(LoadBillableOrderItems(sellerId: customer.id!));
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyText.bodySmall(
                            customer.name ?? 'Unnamed',
                            fontWeight: 600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customer.phone != null)
                            MyText.bodySmall(
                              customer.phone!,
                              color: theme.colorScheme.onSurfaceVariant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlphabetTag(String alphabet, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlphabet =
              isSelected ? null : (alphabet == 'All' ? null : alphabet);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          alphabet,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatCustomer(Customer customer) {
    final name = customer.name?.trim();
    final phone = customer.phone?.trim();
    if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) {
      return '$name ($phone)';
    }
    if (name != null && name.isNotEmpty) return name;
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Unnamed customer';
  }

  List<OrderItem> _salesFromState(OrderItemState state) {
    if (state is OrderItemsLoaded) {
      return state.orderItems;
    }
    return const [];
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
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
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _selectedSellerForBill == null
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 140, // Account for app bar and padding
                  child: _buildCustomerSelection(),
                )
              : BlocBuilder<OrderItemBloc, OrderItemState>(
                  builder: (context, saleState) {
                    final sales = _salesFromState(saleState)
                        .where((sale) =>
                            sale.sellerId == _selectedSellerForBill!.id &&
                            sale.sellerOrderId == null)
                        .toList(growable: false);
                    
                    return PaymentItemWidget(
                      seller: _selectedSellerForBill!,
                      sales: sales,
                      formatCustomer: (customer) => _formatCustomer(customer),
                      onDeleteSale: (sale, index) {
                        if (!mounted) {
                          return;
                        }
                        if (sale.id != null) {
                          final bloc = context.read<OrderItemBloc>();
                          bloc.add(DeleteOrderItemEvent(sale.id!));
                          if (_selectedSellerForBill?.id != null) {
                            bloc.add(LoadBillableOrderItems(sellerId: _selectedSellerForBill!.id!));
                          }
                        }
                      },
                      onConfirm: (selected) async {
                        if (!mounted) {
                          return;
                        }
                        await _handleCreateSellerBill(selected, _selectedSellerForBill!);
                      },
                      onEditSeller: () {
                        setState(() {
                          _selectedSellerForBill = null;
                        });
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

