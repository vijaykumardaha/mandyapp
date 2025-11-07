import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
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
      _loadDashboardData();
    });
  }

  void _loadDashboardData({bool forceRefresh = false}) {
    context.read<ReportsBloc>().add(const LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReportsError) {
                return _buildError(state.message);
              }

              if (state is DashboardDataLoaded) {
                return _buildDashboard(state);
              }

              return _buildInitial();
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
        MyText.titleMedium('Failed to load dashboard', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          message,
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _loadDashboardData(forceRefresh: true),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildInitial() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dashboard, size: 64, color: theme.primaryColor.withOpacity(0.4)),
        const SizedBox(height: 12),
        MyText.titleMedium('Loading Dashboard...', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          'Please wait while we load your business summary.',
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildDashboard(DashboardDataLoaded data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleLarge("Business Dashboard", fontWeight: 700),
                  MyText.bodyMedium(
                    _dateFormat.format(DateTime.now()),
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _loadDashboardData(forceRefresh: true),
                icon: Icon(
                  Icons.refresh,
                  color: theme.primaryColor,
                  size: 28,
                ),
                tooltip: 'Refresh Dashboard',
                style: IconButton.styleFrom(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Financial Overview Card (Single unified card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleMedium("Financial Overview", fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialMetric(
                        title: "Net Balance",
                        value: _currencyFormat.format(data.netBalance),
                        icon: Icons.account_balance,
                        color: data.netBalance >= 0 ? Colors.green : Colors.red,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FinancialMetric(
                        title: "Gross Profit Today",
                        value: _currencyFormat.format(data.grossProfit),
                        icon: Icons.trending_up,
                        color: data.grossProfit >= 0 ? Colors.green : Colors.red,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FinancialMetric(
                        title: "Today's Sales",
                        value: _currencyFormat.format(data.todaySales),
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Purchase Overview Card (Single unified card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleMedium("Buyer Overview", fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialMetric(
                        title: "Total Received",
                        value: _currencyFormat.format(data.totalReceived),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FinancialMetric(
                        title: "Pending Payments",
                        value: _currencyFormat.format(data.totalPending),
                        icon: Icons.pending,
                        color: Colors.orange,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Seller Overview Card (Single unified card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleMedium("Seller Overview", fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialMetric(
                        title: "Paid to Sellers",
                        value: _currencyFormat.format(data.paidToSellers),
                        icon: Icons.payments,
                        color: Colors.teal,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FinancialMetric(
                        title: "Pending to Sellers",
                        value: _currencyFormat.format(data.pendingToSellers),
                        icon: Icons.schedule,
                        color: Colors.red,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stock Overview Card (Single unified card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.titleMedium("Stock Overview", fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _FinancialMetric(
                        title: "Available Stock",
                        value: "${data.availableStock.toStringAsFixed(1)} Kg",
                        icon: Icons.inventory,
                        color: Colors.purple,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FinancialMetric(
                        title: "Out of Stock",
                        value: "${data.outOfStockItems} items",
                        icon: Icons.report_problem,
                        color: Colors.redAccent,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _FinancialMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MyText.bodySmall(
          title,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: 500,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        MyText.titleSmall(
          value,
          fontWeight: 700,
          color: theme.colorScheme.onSurface,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
