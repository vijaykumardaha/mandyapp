import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/widgets/reports/report_types.dart';
import 'package:mandyapp/widgets/reports/report_filter_bar.dart';
import 'package:mandyapp/widgets/reports/daily_sales_report.dart';
import 'package:mandyapp/widgets/reports/seller_purchase_report.dart';
import 'package:mandyapp/widgets/reports/buyer_sales_report.dart';
import 'package:mandyapp/widgets/reports/mandi_profit_report.dart';
import 'package:mandyapp/widgets/reports/pending_payment_report.dart';
import 'package:mandyapp/widgets/reports/customer_ledger_report.dart';
import 'package:mandyapp/widgets/reports/payment_mode_report.dart';
import 'package:mandyapp/widgets/reports/top_selling_products_report.dart';
import 'package:mandyapp/widgets/reports/charges_performance_report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportRangePreset _selectedPreset = ReportRangePreset.today;
  ReportType _selectedReportType = ReportType.dailySales;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Widget _buildReportContentBasedOnState(dynamic state, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ReportHelpers.getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                ReportHelpers.reportTypeLabel(_selectedReportType),
                fontWeight: 600,
              ),
            ],
          ),
          MySpacing.height(16),
          Expanded(
            child: _buildReportContent(state, theme, currencyFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(dynamic state, ThemeData theme, NumberFormat currencyFormat) {
    switch (_selectedReportType) {
      case ReportType.dailySales:
        if (state is DailySalesReportLoaded) {
          return DailySalesReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.sellerPurchase:
        if (state is SellerPurchaseReportLoaded) {
          return SellerPurchaseReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.buyerSales:
        if (state is BuyerSalesReportLoaded) {
          return BuyerSalesReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.mandiProfit:
        if (state is MandiProfitReportLoaded) {
          return MandiProfitReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.pendingPayment:
        if (state is PendingPaymentReportLoaded) {
          return PendingPaymentReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.customerLedger:
        if (state is CustomerLedgerReportLoaded) {
          return CustomerLedgerReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.paymentMode:
        if (state is PaymentModeReportLoaded) {
          return PaymentModeReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.topSellingProducts:
        if (state is TopSellingProductsReportLoaded) {
          return TopSellingProductsReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.chargesPerformance:
        if (state is ChargesPerformanceReportLoaded) {
          return ChargesPerformanceReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
    }

    return _buildPlaceholderReport(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ReportHelpers.getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                ReportHelpers.reportTypeLabel(_selectedReportType),
                fontWeight: 600,
              ),
            ],
          ),
          MySpacing.height(16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  MySpacing.height(16),
                  MyText.bodyMedium('Loading report data...', fontWeight: 500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ReportHelpers.getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                ReportHelpers.reportTypeLabel(_selectedReportType),
                fontWeight: 600,
              ),
            ],
          ),
          MySpacing.height(16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                  MySpacing.height(12),
                  MyText.bodyMedium('Error loading report', fontWeight: 600),
                  MySpacing.height(8),
                  MyText.bodySmall(message, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  MySpacing.height(16),
                  ElevatedButton(
                    onPressed: _loadReportData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ReportHelpers.getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                ReportHelpers.reportTypeLabel(_selectedReportType),
                fontWeight: 600,
              ),
            ],
          ),
          MySpacing.height(16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ReportHelpers.getReportIcon(_selectedReportType),
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  MySpacing.height(12),
                  MyText.bodyMedium('No data found', fontWeight: 600),
                  MySpacing.height(8),
                  MyText.bodySmall(
                    'No records found for the selected period',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderReport(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ReportHelpers.getReportIcon(_selectedReportType),
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          MySpacing.height(12),
          MyText.bodyMedium(ReportHelpers.reportTypeLabel(_selectedReportType), fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(
            'Report implementation coming soon',
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          MySpacing.height(16),
          ElevatedButton(
            onPressed: () => _loadReportData(),
            child: Text('Load ${ReportHelpers.reportTypeLabel(_selectedReportType)}'),
          ),
        ],
      ),
    );
  }

  void _loadReportData() {
    final reportsBloc = context.read<ReportsBloc>();

    switch (_selectedReportType) {
      case ReportType.dailySales:
        reportsBloc.add(LoadDailySalesReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.sellerPurchase:
        reportsBloc.add(LoadSellerPurchaseReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.buyerSales:
        reportsBloc.add(LoadBuyerSalesReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.mandiProfit:
        reportsBloc.add(LoadMandiProfitReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.pendingPayment:
        reportsBloc.add(LoadPendingPaymentReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.customerLedger:
        reportsBloc.add(LoadCustomerLedgerReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.paymentMode:
        reportsBloc.add(LoadPaymentModeReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.topSellingProducts:
        reportsBloc.add(LoadTopSellingProductsReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.chargesPerformance:
        reportsBloc.add(LoadChargesPerformanceReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
    }
  }

  DateTime _getStartDate() {
    switch (_selectedPreset) {
      case ReportRangePreset.today:
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      case ReportRangePreset.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      case ReportRangePreset.week:
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(weekStart.year, weekStart.month, weekStart.day);
      case ReportRangePreset.month:
        final now = DateTime.now();
        return DateTime(now.year, now.month, 1);
      case ReportRangePreset.custom:
        if (_customDateRange != null) {
          return DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        }
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime _getEndDate() {
    switch (_selectedPreset) {
      case ReportRangePreset.today:
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportRangePreset.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      case ReportRangePreset.week:
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportRangePreset.month:
        final now = DateTime.now();
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case ReportRangePreset.custom:
        if (_customDateRange != null) {
          return DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        }
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ReportHelpers.presetLabel(_selectedPreset),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ReportHelpers.getReportIcon(_selectedReportType),
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      ReportHelpers.reportTypeLabel(_selectedReportType),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: MySpacing.xy(16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportFilterBar(
              selectedPreset: _selectedPreset,
              selectedReportType: _selectedReportType,
              customDateRange: _customDateRange,
              onPresetChanged: (preset) {
                setState(() => _selectedPreset = preset);
                _loadReportData();
              },
              onReportTypeChanged: (type) {
                setState(() => _selectedReportType = type);
                _loadReportData();
              },
              onCustomDateRangeChanged: (range) {
                setState(() {
                  _customDateRange = range;
                  _selectedPreset = ReportRangePreset.custom;
                });
                _loadReportData();
              },
            ),
            MySpacing.height(16),
            Expanded(
              child: BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, state) {
                  if (state is ReportsLoading) {
                    return _buildLoadingState(Theme.of(context));
                  }

                  if (state is ReportsError) {
                    return _buildErrorState(Theme.of(context), state.message);
                  }

                  if (state is ReportsEmpty) {
                    return _buildEmptyState(Theme.of(context));
                  }

                  return _buildReportContentBasedOnState(state, Theme.of(context));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
