import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/services/socket_config.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/widgets/common/connection_status_indicator.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/home_tab/dashboard_overview_card.dart';
import 'package:krishimandi/widgets/home_tab/financial_metric.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late ThemeData theme;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _hasLoadedData = false;
  DashboardDataLoaded? _cachedData;
  String _userName = 'Dashboard';
  DateTime _selectedDate = DateTime.now();
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserName();
      _loadDashboardData();
    });

    final relevantTables = {
      DbTables.orders,
      DbTables.orderItems,
      DbTables.orderPayments,
      DbTables.orderCharges,
      DbTables.orderExpenses,
      DbTables.customerPayments,
      DbTables.customers,
    };
    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (relevantTables.contains(table)) {
        final state = context.read<ReportsBloc>().state;
        if (state is DashboardDataLoaded) {
          _loadDashboardData(forceRefresh: true);
        }
      }
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
    debugPrint(
        '_loadDashboardData called: forceRefresh=$forceRefresh, _hasLoadedData=$_hasLoadedData, _cachedData=${_cachedData != null}');

    // Only load if we explicitly force refresh OR we have no data at all
    if (forceRefresh || (_cachedData == null && !_hasLoadedData)) {
      debugPrint('Loading dashboard data...');
      final date = _selectedDate;
      final fromDate = DateTime(date.year, date.month, date.day);
      final toDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      context.read<ReportsBloc>().add(LoadDashboardData(
            fromDate: fromDate,
            toDate: toDate,
          ));
      _hasLoadedData = true;
    } else {
      debugPrint('Skipping dashboard data load - using cached data');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked == null || picked == _selectedDate) return;
    setState(() {
      _selectedDate = picked;
      _cachedData = null;
      _hasLoadedData = false;
    });
    _loadDashboardData(forceRefresh: true);
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText.titleLarge(_userName, fontWeight: 700),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyText.bodyMedium(
                    _dateFormat.format(_selectedDate),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: ConnectionStatusIndicator(),
          ),
        ],
      ),
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
              debugPrint(
                  'Current state: ${state.runtimeType}, _hasLoadedData: $_hasLoadedData, _cachedData: ${_cachedData != null}');

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
        const MyText.titleMedium('Failed to load dashboard', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          message,
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
        Icon(Icons.dashboard,
            size: 64, color: theme.primaryColor.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        const MyText.titleMedium('Loading Dashboard...', fontWeight: 600),
        const SizedBox(height: 8),
        MyText.bodyMedium(
          'Please wait while we load your business summary.',
          textAlign: TextAlign.center,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  Widget _buildDashboard(DashboardDataLoaded data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Financial Overview Card (Single unified card)
          DashboardOverviewCard(
            title: 'Financial Overview',
            theme: theme,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FinancialMetric(
                      title: 'Net Balance',
                      value: _currencyFormat.format(data.netBalance),
                      icon: Icons.account_balance,
                      color: data.netBalance >= 0 ? Colors.green : Colors.red,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FinancialMetric(
                      title: 'Profit Today',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText.titleMedium('Buyer Overview', fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FinancialMetric(
                        title: 'Total Received',
                        value: _currencyFormat.format(data.totalReceived),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
                        title: 'Pending Payments',
                        value: _currencyFormat.format(data.totalPending),
                        icon: Icons.pending,
                        color: Colors.orange,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
                        title: 'Pending Checkout',
                        value:
                            _currencyFormat.format(data.buyerPendingCheckout),
                        icon: Icons.shopping_cart_checkout,
                        color: Colors.purple,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText.titleMedium('Seller Overview', fontWeight: 600),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FinancialMetric(
                        title: 'Paid to Sellers',
                        value: _currencyFormat.format(data.paidToSellers),
                        icon: Icons.payments,
                        color: Colors.teal,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
                        title: 'Pending to Sellers',
                        value: _currencyFormat.format(data.pendingToSellers),
                        icon: Icons.schedule,
                        color: Colors.red,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FinancialMetric(
                        title: 'Pending Checkout',
                        value:
                            _currencyFormat.format(data.sellerPendingCheckout),
                        icon: Icons.shopping_cart_checkout,
                        color: Colors.purple,
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
