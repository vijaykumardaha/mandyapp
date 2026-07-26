import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/widgets/common/common_app_bar.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/widgets/customer_management/customer_form_sheet.dart';
import 'package:mandyapp/widgets/customer_management/customer_tile.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ThemeData theme;
  CustomerBloc get _customerBloc => context.read<CustomerBloc>();

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _customerBloc.add(const FetchCustomer(query: ''));
  }

  @override
  void dispose() {
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
            suffixIcon: IconButton(
              icon: Icon(Icons.person_add_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Add customer',
              onPressed: _showAddCustomerSheet,
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
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
                    onEdit: () => _showAddCustomerSheet(customer: customer),
                  );
                },
              ),
            );
          }

          return _buildEmptyState();
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
