import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';

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
      appBar: AppBar(
        title: MyText.titleMedium('Customers', fontWeight: 600),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add customer',
            onPressed: _showAddCustomerSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: MySpacing.xy(16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search customers',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
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
                        return _buildCustomerTile(customer);
                      },
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final hasName = customer.name?.trim().isNotEmpty == true;
    final hasPhone = customer.phone?.trim().isNotEmpty == true;
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';
    final displayPhone = hasPhone ? customer.phone!.trim() : null;
    final title = displayPhone != null ? '$displayName (${displayPhone})' : displayName;

    return Card(
      margin: MySpacing.bottom(12),
      child: Padding(
        padding: MySpacing.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodyLarge(
                    title,
                    fontWeight: 600,
                  ),
                  MySpacing.height(6),
                  Row(
                    children: [
                      _buildAmountChip('Borrowed', customer.borrowAmount),
                      MySpacing.width(8),
                      _buildAmountChip('Advanced', customer.advancedAmount),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit customer',
              onPressed: () => _showAddCustomerSheet(customer: customer),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Delete customer',
              onPressed: () => _confirmDelete(customer),
            ),
          ],
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
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final borrowController = TextEditingController(text: (customer?.borrowAmount ?? 0).toString());
    final advanceController = TextEditingController(text: (customer?.advancedAmount ?? 0).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.titleMedium(isEditing ? 'Edit customer' : 'Add customer', fontWeight: 600),
              MySpacing.height(16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(12),
              TextField(
                controller: borrowController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Borrow amount',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(12),
              TextField(
                controller: advanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Advanced amount',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  MySpacing.width(12),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final borrow = double.tryParse(borrowController.text.trim()) ?? 0.0;
                      final advance = double.tryParse(advanceController.text.trim()) ?? 0.0;
                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter both name and phone.')),
                        );
                        return;
                      }
                      if (isEditing) {
                        final updatedCustomer = customer.copyWith(
                          name: name,
                          phone: phone,
                          borrowAmount: borrow,
                          advancedAmount: advance,
                        );
                        _customerBloc.add(UpdateCustomer(customer: updatedCustomer, query: _searchController.text.trim()));
                      } else {
                        _customerBloc.add(AddCustomer(
                          name: name,
                          phone: phone,
                          query: _searchController.text.trim(),
                          borrowAmount: borrow,
                          advancedAmount: advance,
                        ));
                      }
                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? 'Update' : 'Save'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete customer'),
          content: Text('Are you sure you want to delete ${customer.name ?? 'this customer'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (customer.id != null) {
                  _customerBloc.add(DeleteCustomer(customerId: customer.id!, query: _searchController.text.trim()));
                }
              },
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountChip(String label, double amount) {
    return Container(
      padding: MySpacing.xy(10, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MyText.bodySmall(
        '$label: ₹${amount.toStringAsFixed(2)}',
        fontWeight: 600,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
