import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/customer_payment_model.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/dropdown_option.dart';
import 'package:krishimandi/widgets/payment_histories/payment_item.dart';
import 'package:krishimandi/widgets/payment_histories/type_tab.dart';

const _paymentSources = ['cash', 'upi', 'card', 'credit'];

String _paymentSourceLabel(String source) => switch (source) {
      'cash' => 'Cash',
      'upi' => 'UPI',
      'card' => 'Card',
      'credit' => 'Credit',
      _ => source,
    };

class PaymentHistoriesScreen extends StatefulWidget {
  final Customer customer;

  const PaymentHistoriesScreen({
    super.key,
    required this.customer,
  });

  @override
  State<PaymentHistoriesScreen> createState() => _PaymentHistoriesScreenState();
}

class _PaymentHistoriesScreenState extends State<PaymentHistoriesScreen> {
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    context
        .read<CustomerPaymentBloc>()
        .add(FetchPayments(customerId: widget.customer.id!));
    _checkStaffRole();
  }

  Future<void> _checkStaffRole() async {
    final user = await AppHelper.getCurrentUser();
    if (mounted && user?.isStaff == true) {
      setState(() => _isStaff = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.customer.name ?? 'Customer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isStaff)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 26),
                tooltip: 'Add Payment',
                onPressed: () => _showAddPaymentSheet(context),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CustomerPaymentBloc, CustomerPaymentState>(
          builder: (context, state) {
            if (state is CustomerPaymentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CustomerPaymentError) {
              return Center(child: Text(state.message));
            }

            if (state is CustomerPaymentsLoaded) {
              return ListView(
                children: [
                  _buildHeader(theme, state.totalReceived, state.totalPaid),
                  if (state.payments.isEmpty)
                    _buildEmptyState(theme)
                  else
                    ...state.payments.map((p) => PaymentItem(payment: p)),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, double totalReceived, double totalPaid) {
    final netBalance = totalReceived - totalPaid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme: theme,
              icon: netBalance >= 0
                  ? Icons.account_balance_wallet_rounded
                  : Icons.trending_down_rounded,
              label: 'Balance',
              amount: netBalance,
              color: netBalance >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              theme: theme,
              icon: Icons.arrow_downward_rounded,
              label: 'Received',
              amount: totalReceived,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              theme: theme,
              icon: Icons.arrow_upward_rounded,
              label: 'Paid',
              amount: totalPaid,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No payments yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    String selectedType = 'received';
    String selectedSource = 'cash';
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isReceived = selectedType == 'received';
            final accentColor = isReceived ? Colors.green : Colors.red;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Payment',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: PaymentTypeTab(
                              label: 'Received',
                              icon: Icons.arrow_downward_rounded,
                              isSelected: isReceived,
                              color: Colors.green,
                              onTap: () => setSheetState(
                                  () => selectedType = 'received'),
                            ),
                          ),
                          Expanded(
                            child: PaymentTypeTab(
                              label: 'Paid',
                              icon: Icons.arrow_upward_rounded,
                              isSelected: !isReceived,
                              color: Colors.red,
                              onTap: () =>
                                  setSheetState(() => selectedType = 'paid'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSource,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      menuMaxHeight: 300,
                      elevation: 4,
                      decoration: InputDecoration(
                        labelText: 'Source',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      items: [
                        for (final source in _paymentSources)
                          DropdownMenuItem(
                            value: source,
                            child: DropdownOption(
                              selected: selectedSource == source,
                              child: Text(_paymentSourceLabel(source)),
                            ),
                          ),
                      ],
                      selectedItemBuilder: (context) => [
                        for (final source in _paymentSources)
                          Text(_paymentSourceLabel(source)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedSource = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a note';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final payment = CustomerPayment(
                            customerId: widget.customer.id!,
                            amount: double.parse(amountController.text.trim()),
                            type: selectedType,
                            source: selectedSource,
                            note: noteController.text.trim(),
                            paymentDate: DateTime.now().millisecondsSinceEpoch,
                          );
                          context
                              .read<CustomerPaymentBloc>()
                              .add(AddPayment(payment: payment));
                          Navigator.pop(context);
                        },
                        child: Text(
                          isReceived
                              ? 'Add Received Payment'
                              : 'Add Paid Payment',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
