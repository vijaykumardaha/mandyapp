import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late ThemeData theme;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  void _loadSummary({bool forceRefresh = false}) {
    context.read<BillListBloc>().add(LoadBillSummaries(forceRefresh: forceRefresh));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<BillListBloc, BillListState>(
            builder: (context, state) {
              if (state is BillListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BillListError) {
                return _buildError(state.message);
              }

              if (state is BillListEmpty) {
                return _buildEmpty();
              }

              if (state is! BillListLoaded) {
                return const SizedBox.shrink();
              }

              return _buildSummary(state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
        const SizedBox(height: 12),
        MyText.titleMedium('Failed to load summary', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          message,
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _loadSummary(forceRefresh: true),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long, size: 64, color: theme.primaryColor.withOpacity(0.4)),
        const SizedBox(height: 12),
        MyText.titleMedium('No bills yet', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          'Create bills to see your sales summary here.',
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _loadSummary(forceRefresh: true),
          child: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildSummary(BillListLoaded summary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Today's Overview", fontWeight: 600),
          const SizedBox(height: 16),
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
                  _currencyFormat.format(summary.totalSales),
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
                  value: _currencyFormat.format(summary.averageSale),
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
            value: _currencyFormat.format(summary.totalPending),
            theme: theme,
            icon: Icons.hourglass_bottom,
          ),
        ],
      ),
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
