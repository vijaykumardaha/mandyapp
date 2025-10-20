import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/bill_summary_model.dart';
import 'package:mandyapp/screens/bill_details_screen.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  late ThemeData theme;
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<BillListBloc>().add(const LoadBillSummaries());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: BlocBuilder<BillListBloc, BillListState>(
          builder: (context, state) {
            if (state is BillListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BillListError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.titleMedium('Failed to load bills'),
                    const SizedBox(height: 8),
                    MyText.bodyMedium(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BillListBloc>().add(const LoadBillSummaries(forceRefresh: true)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is BillListEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 80, color: theme.primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    MyText.titleMedium('No bills yet', fontWeight: 600),
                    const SizedBox(height: 8),
                    MyText.bodyMedium(
                      'Completed bills will appear here',
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              );
            }

            if (state is! BillListLoaded) {
              return const SizedBox.shrink();
            }

            final summary = state;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSummary(summary),
                        const SizedBox(height: 16),
                        MyText.titleMedium(
                          'Bills',
                          fontWeight: 600,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bill = summary.bills[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 8, 16, 8),
                        child: _BillCard(
                          bill: bill,
                          theme: theme,
                          timeFormat: _timeFormat,
                          dateFormat: _dateFormat,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BillDetailsScreen(cartId: bill.cartId),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: summary.bills.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSummary(BillListLoaded summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.bodySmall(
                _dateFormat.format(DateTime.now()),
                color: Colors.black.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              MyText.displaySmall(
                NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.totalSales),
                color: Colors.black,
                fontWeight: 700,
              ),
              const SizedBox(height: 8),
              MyText.bodySmall(
                "Today's Sales",
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Avg. Sale',
                value: NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.averageSale),
                theme: theme,
                icon: Icons.show_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Bills Count',
                value: summary.billCount.toString(),
                theme: theme,
                icon: Icons.receipt_long,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          label: 'Pending Amount',
          value: NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(summary.totalPending),
          theme: theme,
          icon: Icons.hourglass_bottom,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.theme,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onInverseSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.bodySmall(
                label,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              MyText.titleMedium(value, fontWeight: 600),
            ],
          ),
          Icon(icon, color: theme.primaryColor),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillSummary bill;
  final ThemeData theme;
  final DateFormat timeFormat;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  const _BillCard({
    required this.bill,
    required this.theme,
    required this.timeFormat,
    required this.dateFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_outlined, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleMedium(
                    'Bill: ${bill.billNumber ?? bill.cartId}',
                    fontWeight: 600,
                  ),
                  const SizedBox(height: 4),
                  MyText.bodySmall(
                    '${timeFormat.format(bill.createdAt)}  •  ${dateFormat.format(bill.createdAt)}',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MyText.titleMedium(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                  fontWeight: 600,
                ),
                const SizedBox(height: 4),
                MyText.bodySmall(
                  bill.isPending
                      ? 'Pending: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.pendingAmount)}'
                      : 'Paid',
                  color: bill.isPending
                      ? Colors.orange
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
