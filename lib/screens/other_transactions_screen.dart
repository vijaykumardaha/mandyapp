import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/other_transaction/other_transaction_bloc.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/other_transaction_model.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/other_transactions/other_transaction_list_item.dart';

class OtherTransactionsScreen extends StatefulWidget {
  const OtherTransactionsScreen({super.key});

  @override
  State<OtherTransactionsScreen> createState() =>
      _OtherTransactionsScreenState();
}

class _OtherTransactionsScreenState extends State<OtherTransactionsScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = true;
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadRole();
    context.read<OtherTransactionBloc>().add(LoadOtherTransactions());

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.otherTransactions) {
        final state = context.read<OtherTransactionBloc>().state;
        if (state is OtherTransactionLoaded) {
          context.read<OtherTransactionBloc>().add(LoadOtherTransactions());
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

  List<OtherTransaction> _filterTransactions(
      List<OtherTransaction> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    return transactions
        .where((t) =>
            t.transactionNote
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            t.transactionType
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showTransactionDialog([OtherTransaction? transaction]) {
    final isEditing = transaction != null;
    final noteController =
        TextEditingController(text: transaction?.transactionNote ?? '');
    final amountController = TextEditingController(
      text: transaction != null
          ? transaction.transactionAmount.toStringAsFixed(2)
          : '',
    );
    String selectedType = transaction?.transactionType ?? 'debit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText.titleMedium(
                  isEditing ? 'Edit Transaction' : 'Add Transaction',
                  fontWeight: 600,
                ),
                MySpacing.height(16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Note',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Market fee, Electricity bill',
                  ),
                ),
                MySpacing.height(12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                    hintText: '0.00',
                  ),
                ),
                MySpacing.height(16),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 16),
                            SizedBox(width: 6),
                            Text('Debit'),
                          ],
                        ),
                        selected: selectedType == 'debit',
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              selectedType = 'debit';
                            });
                          }
                        },
                        selectedColor: Colors.red.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: selectedType == 'debit'
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward, size: 16),
                            SizedBox(width: 6),
                            Text('Credit'),
                          ],
                        ),
                        selected: selectedType == 'credit',
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              selectedType = 'credit';
                            });
                          }
                        },
                        selectedColor: Colors.green.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: selectedType == 'credit'
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                  ],
                ),
                MySpacing.height(16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const MyText.bodyMedium('Cancel'),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final note = noteController.text.trim();
                          if (note.isEmpty) {
                            Info.message('Please enter a transaction note',
                                context: sheetContext);
                            return;
                          }
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            Info.message('Please enter a valid amount',
                                context: sheetContext);
                            return;
                          }

                          final newTransaction = OtherTransaction(
                            id: transaction?.id,
                            mandiId: transaction?.mandiId,
                            transactionNote: note,
                            transactionType: selectedType,
                            transactionAmount: amount,
                          );

                          if (isEditing) {
                            context
                                .read<OtherTransactionBloc>()
                                .add(UpdateOtherTransaction(newTransaction));
                          } else {
                            context
                                .read<OtherTransactionBloc>()
                                .add(CreateOtherTransaction(newTransaction));
                          }
                          Navigator.pop(sheetContext);
                        },
                        child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
                MySpacing.height(16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteTransaction(OtherTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const MyText.titleMedium('Delete Transaction', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete "${transaction.transactionNote}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<OtherTransactionBloc>()
                  .add(DeleteOtherTransaction(transaction.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
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
                    icon: Icon(Icons.add,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add Transaction',
                    onPressed: () => _showTransactionDialog(),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<OtherTransactionBloc, OtherTransactionState>(
          listener: (context, state) {
            if (state is OtherTransactionError) {
              Info.error(state.message, context: context);
            } else if (state is OtherTransactionOperationSuccess) {
              Info.message(state.message, context: context);
              context.read<OtherTransactionBloc>().add(LoadOtherTransactions());
            }
          },
          builder: (context, state) {
            if (state is OtherTransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OtherTransactionLoaded) {
              final transactions = _filterTransactions(state.transactions);
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(16),
                      MyText.bodyLarge(
                        'No transactions found',
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(8),
                      MyText.bodyMedium(
                        'Tap the + button to add your first transaction',
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: MySpacing.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return OtherTransactionListItem(
                    transaction: transaction,
                    theme: theme,
                    isAdmin: _isAdmin,
                    onEdit: () => _showTransactionDialog(transaction),
                    onDelete: () => _deleteTransaction(transaction),
                  );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
