import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/sync/socket_config.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/widgets/common/connection_status_indicator.dart';
import 'package:mandyapp/widgets/home_tab/financial_metric.dart';
import 'package:mandyapp/widgets/home_tab/dashboard_overview_card.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late ThemeData theme;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _hasLoadedData = false;
  DashboardDataLoaded? _cachedData;
  String _userName = 'Dashboard';

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserName();
      _loadDashboardData();
    });
  }

  Future<void> _loadUserName() async {
    final userData = await AppHelper.getPreferences(SocketConfig.userKey);
    if (userData != null && mounted) {
      final user = User.fromJson(userData);
      setState(() => _userName = user.name ?? 'Dashboard');
    }
  }

  void _loadDashboardData({bool forceRefresh = false}) {
    print('_loadDashboardData called: forceRefresh=$forceRefresh, _hasLoadedData=$_hasLoadedData, _cachedData=${_cachedData != null}');
    
    // Only load if we explicitly force refresh OR we have no data at all
    if (forceRefresh || (_cachedData == null && !_hasLoadedData)) {
      print('Loading dashboard data...');
      context.read<ReportsBloc>().add(const LoadDashboardData());
      _hasLoadedData = true;
    } else {
      print('Skipping dashboard data load - using cached data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocConsumer<ReportsBloc, ReportsState>(
            listener: (context, state) {
              if (state is DashboardDataLoaded) {
                _cachedData = state;
                _hasLoadedData = true;
              }
            },
            builder: (context, state) {
              // Debug: Print current state to understand what's happening
              print('Current state: ${state.runtimeType}, _hasLoadedData: $_hasLoadedData, _cachedData: ${_cachedData != null}');
              
              // Always show cached data if available, regardless of current state
              if (_cachedData != null) {
                return _buildDashboard(_cachedData!);
              }

              // Only show loading if we have never loaded data before
              if (state is ReportsLoading && _cachedData == null) {
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
          // Header with reports link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleLarge(_userName, fontWeight: 700),
                  MyText.bodyMedium(
                    _dateFormat.format(DateTime.now()),
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              const ConnectionStatusIndicator(),
            ],
          ),
          const SizedBox(height: 24),

          // Financial Overview Card (Single unified card)
          DashboardOverviewCard(
            title: "Financial Overview",
            theme: theme,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FinancialMetric(
                      title: "Net Balance",
                      value: _currencyFormat.format(data.netBalance),
                      icon: Icons.account_balance,
                      color: data.netBalance >= 0 ? Colors.green : Colors.red,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FinancialMetric(
                      title: "Profit Today",
                      value: _currencyFormat.format(data.grossProfit),
                      icon: Icons.trending_up,
                      color: data.grossProfit >= 0 ? Colors.green : Colors.red,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FinancialMetric(
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
                      child: FinancialMetric(
                        title: "Total Received",
                        value: _currencyFormat.format(data.totalReceived),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
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
                      child: FinancialMetric(
                        title: "Paid to Sellers",
                        value: _currencyFormat.format(data.paidToSellers),
                        icon: Icons.payments,
                        color: Colors.teal,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
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

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'See Bills',
                  color: Colors.orange,
                  theme: theme,
                  onTap: () => context.push('/search-bills'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.receipt_long,
                  label: 'See Report',
                  color: Colors.purple,
                  theme: theme,
                  onTap: () => context.push('/bills'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            MyText.bodyMedium(label, fontWeight: 600),
          ],
        ),
      ),
    );
  }
}
