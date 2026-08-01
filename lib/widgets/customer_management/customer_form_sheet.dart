import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/customer/customer_bloc.dart';
import 'package:krishimandi/blocs/product/product_bloc.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class CustomerFormSheet extends StatefulWidget {
  final Customer? customer;
  final String query;

  const CustomerFormSheet({super.key, this.customer, required this.query});

  static void show(BuildContext context,
      {Customer? customer, required String query}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerFormSheet(customer: customer, query: query),
    );
  }

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late Set<int> selectedProductIds;
  late ThemeData theme;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer?.name ?? '');
    phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    selectedProductIds =
        Set<int>.from(widget.customer?.selectedProductIds ?? []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleMedium(isEditing ? 'Edit Customer' : 'Add Customer',
                    fontWeight: 600),
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
                const MyText.bodyMedium('Customer Products', fontWeight: 600),
                MySpacing.height(4),
                MyText.bodySmall(
                  'Select products this customer is selling it.',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 80,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: productState.products.length,
                          itemBuilder: (context, index) {
                            final product = productState.products[index];
                            final productId = product.id!;
                            final isSelected =
                                selectedProductIds.contains(productId);
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
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.05)
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
                                          color: theme.colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: defaultVariant != null &&
                                                defaultVariant
                                                    .imagePath.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: defaultVariant.imagePath
                                                        .startsWith('assets/')
                                                    ? Image.asset(
                                                        defaultVariant
                                                            .imagePath,
                                                        fit: BoxFit.cover)
                                                    : Image.file(
                                                        File(defaultVariant
                                                            .imagePath),
                                                        fit: BoxFit.cover,
                                                      ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.inventory_2,
                                                  size: 24,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      child: Text(
                                        defaultVariant?.variantName ??
                                            'Product #${product.id}',
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
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
                        ),
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    MySpacing.width(12),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          Info.message('Please enter both name and phone.',
                              context: context);
                          return;
                        }
                        final productIdsStr = selectedProductIds.join(',');
                        if (isEditing) {
                          final updatedCustomer = widget.customer!.copyWith(
                            name: name,
                            phone: phone,
                            productIds: productIdsStr,
                          );
                          context.read<CustomerBloc>().add(
                                UpdateCustomer(
                                    customer: updatedCustomer,
                                    query: widget.query),
                              );
                        } else {
                          context.read<CustomerBloc>().add(
                                AddCustomer(
                                  name: name,
                                  phone: phone,
                                  productIds: productIdsStr,
                                  query: widget.query,
                                ),
                              );
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
      ),
    );
  }
}
