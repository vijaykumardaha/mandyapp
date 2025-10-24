import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/bill_summary_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/screens/bill_details_screen.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/utils/db_helper.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _SellerSaleSelectionSheet extends StatefulWidget {
  final Customer seller;
  final List<ItemSale> sales;
  final String Function(Customer) formatCustomer;
  final VoidCallback onReload;
  final void Function(ItemSale sale, int index) onDeleteSale;
  final Future<void> Function(List<ItemSale> selected) onConfirm;

  const _SellerSaleSelectionSheet({
    required this.seller,
    required this.sales,
    required this.formatCustomer,
    required this.onReload,
    required this.onDeleteSale,
    required this.onConfirm,
  });

  @override
  State<_SellerSaleSelectionSheet> createState() => _SellerSaleSelectionSheetState();
}

class _SellerSaleSelectionSheetState extends State<_SellerSaleSelectionSheet> {
  final Set<int> _selectedIndices = {};
  List<ItemSale> _sales = [];

  @override
  void initState() {
    super.initState();
    _sales = widget.sales;
  }

  @override
  void didUpdateWidget(covariant _SellerSaleSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sales != widget.sales) {
      setState(() {
        _sales = widget.sales;
        _selectedIndices
          ..clear()
          ..addAll(_selectedIndices.where((index) => index < _sales.length));
      });
    }
  }

  void _toggleSelection(int index, bool value) {
    setState(() {
      if (value) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  Future<void> _confirm() async {
    final selected = _selectedIndices.map((index) => _sales[index]).toList(growable: false);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one sale item.')),
      );
      return;
    }

    Navigator.of(context).pop();
    await widget.onConfirm(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                MySpacing.height(16),
                MyText.titleMedium('Create seller bill', fontWeight: 700),
                MySpacing.height(8),
                MyText.bodySmall(
                  'Seller: ${widget.formatCustomer(widget.seller)}',
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                MySpacing.height(20),
                SizedBox(
                  height: 360,
                  child: _sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_outlined, size: 48),
                              MySpacing.height(12),
                              MyText.bodyMedium('No unsold items recorded for this seller.'),
                              MySpacing.height(12),
                              OutlinedButton.icon(
                                onPressed: widget.onReload,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _sales.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            final isChecked = _selectedIndices.contains(index);
                            final quantityLabel = '${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 2)} ${sale.unit}';


                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _toggleSelection(index, !isChecked),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isChecked
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline.withOpacity(0.15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow.withOpacity(isChecked ? 0.16 : 0.08),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (value) => _toggleSelection(index, value ?? false),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            MyText.bodyMedium(
                                              'Sale #${sale.id ?? '-'}',
                                              fontWeight: 700,
                                            ),
                                            MySpacing.height(4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                MyText.bodySmall('Qty: $quantityLabel'),
                                                MyText.bodySmall('Rate: ₹${sale.sellingPrice.toStringAsFixed(2)}'),
                                                MyText.bodySmall(
                                                  'Total: ₹${sale.totalPrice.toStringAsFixed(2)}',
                                                  fontWeight: 600,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                MySpacing.height(24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    MySpacing.width(16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Select Items'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillListScreenState extends State<BillListScreen> {
  late ThemeData theme;
  late TextEditingController _customerController;
  late FocusNode _customerFocusNode;
  Customer? _selectedCustomer;
  String? _statusFilter; // 'open', 'completed', or null for all
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

    final itemSaleBloc = context.read<ItemSaleBloc>();
    itemSaleBloc.add(LoadItemSales(sellerId: seller!.id, excludeCartLinked: false));

    var confirmed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BlocBuilder<ItemSaleBloc, ItemSaleState>(
          builder: (context, saleState) {
            final sales = _salesFromState(saleState)
                .where((sale) =>
                    sale.sellerId == seller.id &&
                    sale.sellerCartId == null)
                .toList(growable: false);
            return _SellerSaleSelectionSheet(
              seller: seller,
              sales: sales,
              formatCustomer: (customer) => _formatCustomer(customer),
              onReload: () => itemSaleBloc.add(LoadItemSales(sellerId: seller.id, excludeCartLinked: false)),
              onDeleteSale: (sale, index) {
                if (!mounted) {
                  return;
                }
                if (sale.id != null) {
                  final bloc = context.read<ItemSaleBloc>();
                  bloc.add(DeleteItemSaleEvent(sale.id!));
                  bloc.add(LoadItemSales(sellerId: seller.id, excludeCartLinked: false));
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

  Future<void> _handleCreateSellerBill(List<ItemSale> selectedSales, Customer seller) async {
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
    final cartBloc = context.read<CartBloc>();
    final itemSaleBloc = context.read<ItemSaleBloc>();
    final billListBloc = context.read<BillListBloc>();

    final cartId = DBHelper.generateUuidInt();
    final now = DateTime.now().toIso8601String();

    final cart = Cart(
      id: cartId,
      customerId: sellerId,
      createdAt: now,
      cartFor: 'seller',
      status: 'open',
    );

    cartBloc.add(CreateCart(cart));

    for (final sale in selectedSales) {
      final originalSaleId = sale.id;
      final cartLinkedSale = sale.copyWith(
        id: DBHelper.generateUuidInt(),
        sellerCartId: cartId,
        sellerId: sellerId,
        buyerCartId: null,
        buyerId: null,
        createdAt: now,
        updatedAt: now,
      );
      cartBloc.add(AddItemToCart(cartLinkedSale));

      if (originalSaleId != null) {
        itemSaleBloc.add(DeleteItemSaleEvent(originalSaleId));
      }
    }

    if (!mounted) {
      _resetBillCreationState();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cartId: cartId),
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
            statusFilter: _statusFilter,
            customerId: _selectedCustomer?.id,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomer = null;
      _statusFilter = null;
      _customerSearchText = '';
      _customerController.clear();
    });
    _loadSummaries();
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
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
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: _hasFilters ? theme.colorScheme.primary : null,
          ),
          tooltip: 'Filter status',
          onPressed: _showStatusFilterSheet,
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

  void _showStatusFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.xy(20, 16),
                child: MyText.titleMedium('Bill status', fontWeight: 600),
              ),
              _buildStatusTile(label: 'All bills', value: null),
              _buildStatusTile(label: 'Open bills', value: 'open'),
              _buildStatusTile(label: 'Completed bills', value: 'completed'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTile({required String label, String? value}) {
    final isSelected = value == _statusFilter || (value == null && _statusFilter == null);
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _statusFilter = value;
        });
        _loadSummaries();
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

  bool get _hasFilters => _statusFilter != null || _selectedCustomer != null;

  List<ItemSale> _salesFromState(ItemSaleState state) {
    if (state is ItemSalesLoaded) {
      return state.sales;
    }
    if (state is ItemSaleOperationSuccess) {
      return state.sales;
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

  Widget _buildActiveFilters() {
    if (!_hasFilters) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (_statusFilter != null) {
      final label = _statusFilter == 'completed' ? 'Status: Completed' : 'Status: Open';
      chips.add(_buildFilterChip(label, () {
        setState(() {
          _statusFilter = null;
        });
        _loadSummaries();
      }));
    }

    if (_selectedCustomer != null) {
      chips.add(_buildFilterChip('Customer: ${_formatCustomer(_selectedCustomer!)}', () {
        setState(() {
          _selectedCustomer = null;
          _customerSearchText = '';
          _customerController.clear();
        });
        _loadSummaries();
      }));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _buildPaymentSummary(BillListLoaded summary) {
    final paidBills = summary.bills.where((bill) => bill.isPaid).length;
    final unpaidBills = summary.bills.where((bill) => bill.isUnpaid).length;
    final paidAmount = summary.bills.where((bill) => bill.isPaid).fold(0.0, (sum, bill) => sum + bill.receiveAmount);
    final unpaidAmount = summary.totalPending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Payment Summary', fontWeight: 600),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Paid Bills',
                  paidBills.toString(),
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(paidAmount),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Unpaid Bills',
                  unpaidBills.toString(),
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(unpaidAmount),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSummaryCard(String title, String count, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodySmall(title, color: color, fontWeight: 600),
          const SizedBox(height: 4),
          MyText.titleSmall(count, fontWeight: 700, color: color),
          MyText.bodySmall(amount, color: color.withOpacity(0.8), fontWeight: 500),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: BlocBuilder<BillListBloc, BillListState>(
          builder: (context, state) {
            if (state is BillListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BillListError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.titleMedium('Failed to load bills'),
                    const SizedBox(height: 8),
                    MyText.bodyMedium(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadSummaries(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is BillListEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 80, color: theme.primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    MyText.titleMedium('No bills yet', fontWeight: 600),
                    const SizedBox(height: 8),
                    MyText.bodyMedium(
                      'Completed bills will appear here',
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    if (_hasFilters) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              );
            }

            if (state is! BillListLoaded) {
              return const SizedBox.shrink();
            }

            final summary = state;
            final customerState = context.watch<CustomerBloc>().state;
            final Map<int, Customer> customersById =
                customerState is CustomerLoaded
                    ? {
                        for (final customer in customerState.customers)
                          if (customer.id != null) customer.id!: customer
                      }
                    : {};

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActiveFilters(),
                        const SizedBox(height: 12),
                        if (summary.bills.isNotEmpty) _buildPaymentSummary(summary),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bill = summary.bills[index];
                      final customer = customersById[bill.customerId];
                      final customerName = (customer?.name?.trim().isNotEmpty ?? false)
                          ? customer!.name!.trim()
                          : 'Customer ${bill.customerId}';
                      final billLabel = 'Bill #${bill.billNumber ?? bill.cartId} ($customerName)';
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 8, 16, 8),
                        child: _BillCard(
                          bill: bill,
                          theme: theme,
                          billLabel: billLabel,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BillDetailsScreen(cartId: bill.cartId),
                              ),
                            );
                          },
                          onDelete: () => _confirmDeleteBill(bill),
                        ),
                      );
                    },
                    childCount: summary.bills.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBill(BillSummary bill) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete bill?'),
            content: Text(
              'This will remove the selected bill and its details.\nBill ID: ${bill.billNumber ?? bill.cartId}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    if (!mounted) return;

    context.read<BillListBloc>().add(DeleteBillRequested(bill));
  }
}

class _BillCard extends StatelessWidget {
  final BillSummary bill;
  final ThemeData theme;
  final String billLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _BillCard({
    required this.bill,
    required this.theme,
    required this.billLabel,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = (bill.status.isNotEmpty)
        ? bill.status[0].toUpperCase() + bill.status.substring(1).toLowerCase()
        : 'Unknown';

    final billTypeText = (bill.billType.isNotEmpty)
        ? bill.billType[0].toUpperCase() + bill.billType.substring(1).toLowerCase()
        : 'Unknown';

    Color statusColor;
    switch (bill.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'open':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = theme.colorScheme.primary;
    }

    Color typeColor;
    switch (bill.billType.toLowerCase()) {
      case 'seller':
        typeColor = Colors.indigo;
        break;
      case 'buyer':
        typeColor = Colors.teal;
        break;
      default:
        typeColor = theme.colorScheme.secondary;
    }

    // Payment status color
    Color paymentStatusColor;
    switch (bill.paymentStatus.toLowerCase()) {
      case 'paid':
        paymentStatusColor = Colors.green;
        break;
      case 'unpaid':
        paymentStatusColor = Colors.red;
        break;
      default:
        paymentStatusColor = theme.colorScheme.primary;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodyMedium(
                    billLabel,
                    fontWeight: 600,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          'Status: $statusText',
                          color: statusColor,
                          fontWeight: 600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentStatusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          'Payment: ${bill.paymentStatus}',
                          color: paymentStatusColor,
                          fontWeight: 600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          'Type: $billTypeText',
                          color: typeColor,
                          fontWeight: 600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.titleMedium(
                      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                      fontWeight: 600,
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete bill',
                        color: theme.colorScheme.error,
                        onPressed: onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
