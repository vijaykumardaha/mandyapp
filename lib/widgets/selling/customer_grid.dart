import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';

class CustomerGrid extends StatelessWidget {
  final String? selectedAlphabet;
  final ValueChanged<Customer> onCustomerSelected;

  const CustomerGrid({
    super.key,
    this.selectedAlphabet,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final allCustomers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;

        List<Customer> customers = allCustomers;
        if (selectedAlphabet != null) {
          customers = allCustomers.where((customer) {
            final name = customer.name?.trim().toUpperCase() ?? '';
            return name.startsWith(selectedAlphabet!);
          }).toList();
        }

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (customers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  MyText.bodyMedium(
                    'No customers found',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  MyText.bodySmall(
                    'Add customers to get started',
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final name = customer.name ?? 'Unnamed';
              final initials = name.length >= 2
                  ? name.substring(0, 2).toUpperCase()
                  : name.toUpperCase();
              return GestureDetector(
                onTap: () => onCustomerSelected(customer),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: MyText.bodySmall(
                          initials,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: 600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MyText.bodySmall(
                              name,
                              fontWeight: 600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 12,
                            ),
                            if (customer.phone != null)
                              MyText.bodySmall(
                                customer.phone!,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
