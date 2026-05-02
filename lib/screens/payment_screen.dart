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
import 'package:mandyapp/widgets/billing/seller_sale_selection_sheet.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late ThemeData theme;
  late TextEditingController _customerController;
  late FocusNode _customerFocusNode;
  Customer? _selectedCustomer;
  String _customerSearchText = '';
  Customer? _selectedSellerForBill;
  bool _isCreatingBill = false;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _customerController = TextEditingController();
    _customerFocusNode = FocusNode();

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
    final seller = _selectedCustomer;
    if (seller == null) {
      _showSnack('First pick a seller using the "Filter by customer" field.');
      _resetBillCreationState();
      return;
    }

    if (seller.id == null) {
      _showSnack('Selected seller is missing an ID.');
      _resetBillCreationState();
      return;
    }

    _selectedSellerForBill = seller;
    await _showSellerSaleSelectionSheet();
  }

  Future<void> _showSellerSaleSelectionSheet() async {
    final seller = _selectedSellerForBill;
    if (seller?.id == null) {
      _showSnack('Please select a seller to continue.');
      _resetBillCreationState();
      return;
    }

    final itemSaleBloc = context.read<OrderItemBloc>();
    itemSaleBloc.add(LoadBillableOrderItems(sellerId: seller!.id!));

    var confirmed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BlocBuilder<OrderItemBloc, OrderItemState>(
          builder: (context, saleState) {
            final sales = _salesFromState(saleState)
                .where((sale) =>
                    sale.sellerId == seller.id &&
                    sale.sellerOrderId == null)
                .toList(growable: false);
            return SellerSaleSelectionSheet(
              key: const ValueKey('seller_sale_selection_sheet'),
              seller: seller,
              sales: sales,
              formatCustomer: (customer) => _formatCustomer(customer),
              onReload: () {
                if (seller.id != null) {
                  itemSaleBloc.add(LoadBillableOrderItems(sellerId: seller.id!));
                }
              },
              onDeleteSale: (sale, index) {
                if (!mounted) {
                  return;
                }
                if (sale.id != null) {
                  final bloc = context.read<OrderItemBloc>();
                  bloc.add(DeleteOrderItemEvent(sale.id!));
                  if (seller.id != null) {
                    bloc.add(LoadBillableOrderItems(sellerId: seller.id!));
                  }
                }
              },
              onConfirm: (selected) async {
                confirmed = true;
                if (!mounted) {
                  return;
                }
                await _handleCreateSellerBill(selected, seller);
              },
            );
          },
        );
      },
    );

    if (!mounted) {
      _resetBillCreationState();
      return;
    }

    if (!confirmed) {
      _resetBillCreationState();
      return;
    }
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
        buyerId: null,
        createdAt: now,
        updatedAt: now,
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
        builder: (_) => CheckoutScreen(orderId: orderId),
      ),
    );

    if (!mounted) {
      _resetBillCreationState();
      return;
    }

    billListBloc.add(const LoadBillSummaries(forceRefresh: true));
    _resetBillCreationState();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _customerFocusNode.dispose();
    super.dispose();
  }

  void _loadSummaries({bool forceRefresh = false}) {
    context.read<BillListBloc>().add(
          LoadBillSummaries(
            forceRefresh: forceRefresh,
            customerId: _selectedCustomer?.id,
          ),
        );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildCustomerSearchField(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.post_add_outlined),
          tooltip: 'Create bill',
          onPressed: _createBill,
        ),
      ],
    );
  }

  Widget _buildCustomerSearchField() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final customers =
            customerState is CustomerLoaded ? customerState.customers : <Customer>[];

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RawAutocomplete<Customer>(
            textEditingController: _customerController,
            focusNode: _customerFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return customers.take(15);
              }
              return customers.where((customer) {
                final name = customer.name?.toLowerCase() ?? '';
                final phone = customer.phone ?? '';
                return name.contains(query) || phone.contains(query);
              }).take(15);
            },
            displayStringForOption: _formatCustomer,
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              if (textController.text != _customerSearchText) {
                textController.value = textController.value.copyWith(
                  text: _customerSearchText,
                  selection: TextSelection.collapsed(offset: _customerSearchText.length),
                );
              }

              return TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Filter by customer',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            focusNode.unfocus();
                            textController.clear();
                            setState(() {
                              _customerSearchText = '';
                              _selectedCustomer = null;
                            });
                            _loadSummaries();
                            context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _customerSearchText = value;
                    if (value.isEmpty) {
                      _selectedCustomer = null;
                    }
                  });
                  context.read<CustomerBloc>().add(FetchCustomer(query: value));
                  if (value.isEmpty) {
                    _loadSummaries();
                  }
                },
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              if (options.isEmpty) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260, minWidth: 280),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                      itemBuilder: (context, index) {
                        final customer = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          onTap: () {
                            onSelected(customer);
                          },
                          leading: const Icon(Icons.person_outline, size: 20),
                          title: MyText.bodySmall(
                            customer.name ?? 'Unnamed',
                            fontWeight: 600,
                          ),
                          subtitle: customer.phone != null
                              ? MyText.bodySmall(
                                  customer.phone!,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (customer) {
              setState(() {
                _selectedCustomer = customer;
                _customerSearchText = _formatCustomer(customer);
                _customerController
                  ..text = _customerSearchText
                  ..selection = TextSelection.collapsed(offset: _customerSearchText.length);
              });
              _customerFocusNode.unfocus();
              _loadSummaries();
            },
          ),
        );
      },
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [],
          ),
        ),
      ),
    );
  }
}

