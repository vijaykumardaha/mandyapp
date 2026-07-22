import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/screens/reports_screen.dart';
import 'package:mandyapp/sync/sync_service.dart';

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
  bool _isSyncing = false;
  DashboardDataLoaded? _cachedData;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
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

  Future<void> _syncData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final response = await SyncService.instance.bulkSync();
      if (!mounted) return;

      if (response != null) {
        _loadDashboardData(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
              Row(
                children: [
                  GestureDetector(
                    onTap: _isSyncing ? null : _syncData,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: _isSyncing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.sync,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_chart_outlined,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          MyText.bodySmall(
                            "See Reports",
                            color: theme.primaryColor,
                            fontWeight: 600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        title: "Profit Today",
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
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            MyText.titleSmall(
              title,
              fontWeight: 600,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            MyText.bodySmall(
              description,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
