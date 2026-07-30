import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/widgets/customer_management/customer_form_sheet.dart';
import 'package:mandiapp/widgets/customer_management/customer_tile.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
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
      if (table == 'customers') {
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
        titleWidget: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search customers...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: _isAdmin
                ? IconButton(
                    icon: Icon(Icons.person_add_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add customer',
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
                    );
                  },
                ),
              );
            }

            return _buildEmptyState();
          },
        ),
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
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            MySpacing.height(16),
            MyText.bodyLarge(
              'No customers found',
              color: theme.colorScheme.onBackground.withOpacity(0.6),
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

}
