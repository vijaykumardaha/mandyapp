import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/screens/payment_histories_screen.dart';

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
        automaticallyImplyLeading: false,
        title: TextField(
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
                  return _buildCustomerTile(customer);
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final hasName = customer.name?.trim().isNotEmpty == true;
    final hasPhone = customer.phone?.trim().isNotEmpty == true;
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';
    final displayPhone = hasPhone ? customer.phone!.trim() : null;
    final title = displayPhone != null ? '$displayName (${displayPhone})' : displayName;

    final nameParts = displayName.split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : nameParts.first[0];

    return Card(
      margin: MySpacing.bottom(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentHistoriesScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: MySpacing.xy(12, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  initials.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodyLarge(
                      title,
                      fontWeight: 600,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddCustomerSheet(customer: customer);
                  } else if (value == 'payments') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentHistoriesScreen(customer: customer),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'payments', child: Text('Payments')),
                ],
              ),
          ],
        ),
      ),
      )
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
    final selectedProductIds = Set<int>.from(customer?.selectedProductIds ?? []);

    context.read<ProductBloc>().add(LoadProducts());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
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
                    MySpacing.height(16),
                    MyText.bodyMedium('Product Choices', fontWeight: 600),
                    MySpacing.height(4),
                    MyText.bodySmall(
                      'Select products this customer is interested in',
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    MySpacing.height(8),
                    BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, productState) {
                        if (productState is ProductLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (productState is ProductLoaded) {
                          if (productState.products.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: MySpacing.all(16),
                                child: MyText.bodyMedium(
                                  'No products found. Add products first.',
                                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: productState.products.length,
                            itemBuilder: (context, index) {
                              final product = productState.products[index];
                              final productId = product.id!;
                              final isSelected = selectedProductIds.contains(productId);
                              final defaultVariant = product.defaultVariantModel;
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedProductIds.remove(productId);
                                    } else {
                                      selectedProductIds.add(productId);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isSelected
                                        ? theme.colorScheme.primary.withOpacity(0.05)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: defaultVariant != null && defaultVariant.imagePath.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: defaultVariant.imagePath.startsWith('assets/')
                                                      ? Image.asset(defaultVariant.imagePath, fit: BoxFit.cover)
                                                      : Image.file(
                                                          File(defaultVariant.imagePath),
                                                          fit: BoxFit.cover,
                                                        ),
                                                )
                                              : Center(
                                                  child: Icon(
                                                    Icons.inventory_2,
                                                    size: 24,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          defaultVariant?.variantName ?? 'Product #${product.id}',
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onBackground,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    MySpacing.height(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancel'),
                        ),
                        MySpacing.width(12),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            if (name.isEmpty || phone.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('Please enter both name and phone.')),
                              );
                              return;
                            }
                            final productIdsStr = selectedProductIds.join(',');
                            if (isEditing) {
                              final updatedCustomer = customer.copyWith(
                                name: name,
                                phone: phone,
                                productIds: productIdsStr,
                              );
                              _customerBloc.add(UpdateCustomer(customer: updatedCustomer, query: _searchController.text.trim()));
                            } else {
                              _customerBloc.add(AddCustomer(
                                name: name,
                                phone: phone,
                                productIds: productIdsStr,
                                query: _searchController.text.trim(),
                              ));
                            }
                            Navigator.pop(sheetContext);
                          },
                          child: Text(isEditing ? 'Update' : 'Save'),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

}
