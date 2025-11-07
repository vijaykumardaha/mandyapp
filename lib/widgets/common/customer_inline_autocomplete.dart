import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';

class CustomerInlineAutocomplete extends StatefulWidget {
  final Customer? initialCustomer;
  final ValueChanged<Customer?> onCustomerSelected;
  final String Function(Customer?) formatCustomer;

  const CustomerInlineAutocomplete({
    super.key,
    required this.initialCustomer,
    required this.onCustomerSelected,
    required this.formatCustomer,
  });

  @override
  State<CustomerInlineAutocomplete> createState() => _CustomerInlineAutocompleteState();
}

class _CustomerInlineAutocompleteState extends State<CustomerInlineAutocomplete> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.formatCustomer(widget.initialCustomer));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CustomerInlineAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.formatCustomer(widget.initialCustomer);
    if (newText != _controller.text) {
      _controller
        ..text = newText
        ..selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final customers = customerState is CustomerLoaded ? customerState.customers : <Customer>[];

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
            textEditingController: _controller,
            focusNode: _focusNode,
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
            displayStringForOption: (customer) => widget.formatCustomer(customer),
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Select buyer for checkout',
                  prefixIcon: const Icon(Icons.person_search, size: 18),
                  suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            textEditingController.clear();
                            widget.onCustomerSelected(null);
                            context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  context.read<CustomerBloc>().add(FetchCustomer(query: value));
                },
                onSubmitted: (_) => onFieldSubmitted(),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
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
              widget.onCustomerSelected(customer);
              final formatted = widget.formatCustomer(customer);
              _controller
                ..text = formatted
                ..selection = TextSelection.fromPosition(TextPosition(offset: formatted.length));
              FocusScope.of(context).unfocus();
            },
          ),
        );
      },
    );
  }
}
