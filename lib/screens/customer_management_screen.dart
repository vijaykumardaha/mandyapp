import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/customer/customer_bloc.dart';
import 'package:krishimandi/dao/customer_payment_dao.dart';
import 'package:krishimandi/dao/order_dao.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/services/report_pdf_service.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/customer_management/customer_form_sheet.dart';
import 'package:krishimandi/widgets/customer_management/customer_tile.dart';
import 'package:open_file/open_file.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ThemeData theme;
  bool _isAdmin = true;
  CustomerBloc get _customerBloc => context.read<CustomerBloc>();
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadRole();
    _customerBloc.add(const FetchCustomer(query: ''));

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.customers) {
        final state = context.read<CustomerBloc>().state;
        if (state is CustomerLoaded) {
          context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
        }
      }
    });
  }

  Future<void> _loadRole() async {
    final user = await AppHelper.getCurrentUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.isAdmin ?? true;
      });
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _customerBloc.add(FetchCustomer(query: query.trim()));
  }

  Future<void> _onRefresh() async {
    _customerBloc.add(FetchCustomer(query: _searchController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        showBackButton: false,
        titleWidget: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search customers...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: _isAdmin
                ? IconButton(
                    icon: Icon(Icons.person_add_outlined,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add Customer',
                    onPressed: _showAddCustomerSheet,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            if (state is CustomerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SyncCustomerError) {
              return _buildErrorState(state.errorMsg);
            }

            if (state is CustomerLoaded) {
              if (state.customers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  padding: MySpacing.xy(16, 8),
                  itemCount: state.customers.length,
                  itemBuilder: (context, index) {
                    final customer = state.customers[index];
                    return CustomerTile(
                      customer: customer,
                      theme: theme,
                      isAdmin: _isAdmin,
                      onEdit: () => _showAddCustomerSheet(customer: customer),
                      onDelete: () => _confirmDeleteCustomer(customer),
                    );
                  },
                ),
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is! CustomerLoaded || state.customers.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _downloadPdf(state.customers),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.download_rounded, size: 22),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: MySpacing.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            MySpacing.height(16),
            MyText.bodyLarge(
              'No customers found',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: MySpacing.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            MySpacing.height(12),
            MyText.bodyMedium(
              message,
              textAlign: TextAlign.center,
            ),
            MySpacing.height(12),
            ElevatedButton(
              onPressed: () => _onRefresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerSheet({Customer? customer}) {
    CustomerFormSheet.show(
      context,
      customer: customer,
      query: _searchController.text.trim(),
    );
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final orders = await OrderDAO().getOrdersByCustomer(customer.id!);
    final payments =
        await CustomerPaymentDAO().getPaymentsByCustomerId(customer.id!);

    if (orders.isNotEmpty || payments.isNotEmpty) {
      if (!mounted) return;
      final reasons = <String>[
        if (orders.isNotEmpty) '${orders.length} order(s)',
        if (payments.isNotEmpty) '${payments.length} payment record(s)',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete customer: ${reasons.join(' and ')} found against them.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const MyText.titleMedium('Delete Customer', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete '
          '${(customer.name?.trim().isNotEmpty == true ? customer.name!.trim() : 'this customer')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CustomerBloc>().add(
                    DeleteCustomer(
                      customerId: customer.id!,
                      query: _searchController.text.trim(),
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(List<Customer> customers) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );
      final file = await ReportPdfService.generateCustomersPdf(customers);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
