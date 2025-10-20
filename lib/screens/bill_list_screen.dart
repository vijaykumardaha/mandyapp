import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/bill_summary_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/screens/bill_details_screen.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  late ThemeData theme;
  late TextEditingController _customerController;
  late FocusNode _customerFocusNode;
  Customer? _selectedCustomer;
  String? _statusFilter; // 'open', 'completed', or null for all
  String _customerSearchText = '';
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

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

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
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

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSummary(summary),
                        const SizedBox(height: 16),
                        MyText.titleMedium(
                          'Bills',
                          fontWeight: 600,
                        ),
                        _buildActiveFilters(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bill = summary.bills[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 8, 16, 8),
                        child: _BillCard(
                          bill: bill,
                          theme: theme,
                          timeFormat: _timeFormat,
                          dateFormat: _dateFormat,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BillDetailsScreen(cartId: bill.cartId),
                              ),
                            );
                          },
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

  Widget _buildHeaderSummary(BillListLoaded summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.bodySmall(
                _dateFormat.format(DateTime.now()),
                color: Colors.black.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              MyText.displaySmall(
                NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.totalSales),
                color: Colors.black,
                fontWeight: 700,
              ),
              const SizedBox(height: 8),
              MyText.bodySmall(
                "Today's Sales",
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Avg. Sale',
                value: NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.averageSale),
                theme: theme,
                icon: Icons.show_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Bills Count',
                value: summary.billCount.toString(),
                theme: theme,
                icon: Icons.receipt_long,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          label: 'Pending Amount',
          value: NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.totalPending),
          theme: theme,
          icon: Icons.hourglass_bottom,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.theme,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onInverseSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.bodySmall(
                label,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              MyText.titleMedium(value, fontWeight: 600),
            ],
          ),
          Icon(icon, color: theme.primaryColor),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillSummary bill;
  final ThemeData theme;
  final DateFormat timeFormat;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  const _BillCard({
    required this.bill,
    required this.theme,
    required this.timeFormat,
    required this.dateFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_outlined, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium(
                    'Bill: ${bill.billNumber ?? bill.cartId}',
                    fontWeight: 600,
                  ),
                  const SizedBox(height: 4),
                  MyText.bodySmall(
                    '${timeFormat.format(bill.createdAt)}  •  ${dateFormat.format(bill.createdAt)}',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MyText.titleMedium(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                  fontWeight: 600,
                ),
                const SizedBox(height: 4),
                MyText.bodySmall(
                  bill.isPending
                      ? 'Pending: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.pendingAmount)}'
                      : 'Paid',
                  color: bill.isPending
                      ? Colors.orange
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
