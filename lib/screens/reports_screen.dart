import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/widgets/common/common_app_bar.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_types.dart';
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

  Widget _buildReportContent(dynamic state, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
          MySpacing.height(12),
          MyText.bodyMedium('Error loading report', fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(message, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          MySpacing.height(16),
          ElevatedButton(
            onPressed: _loadReportData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ReportHelpers.getReportIcon(_selectedReportType),
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          MySpacing.height(12),
          MyText.bodyMedium('No data found', fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(
            'No records found for the selected period',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.filter_list_outlined),
              const SizedBox(width: 8),
              Text('Filter Reports'),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReportRangePreset.values.map((preset) {
                        final isSelected = _selectedPreset == preset;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _selectedPreset = preset;
                            });
                            setState(() {
                              _selectedPreset = preset;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              preset.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedPreset == ReportRangePreset.custom)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showCustomDateRangePicker().then((_) {
                              setDialogState(() {});
                            });
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(_customDateRange != null
                              ? '${ReportHelpers.formatDate(_customDateRange!.start)} - ${ReportHelpers.formatDate(_customDateRange!.end)}'
                              : 'Select Custom Range'),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Text(
                      'Report Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...ReportType.values.map((reportType) {
                      final isSelected = _selectedReportType == reportType;
                      final icon = ReportHelpers.getReportIcon(reportType);
                      final name = ReportHelpers.reportTypeLabel(reportType);

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _selectedReportType = reportType;
                          });
                          setState(() {
                            _selectedReportType = reportType;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadReportData();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 7),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPreset = ReportRangePreset.custom;
      });
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: Row(
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
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filter Reports',
          ),
        ],
      ),
      body: Padding(
        padding: MySpacing.xy(16, 20),
        child: BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            if (state is ReportsLoading) return _buildLoadingState();
            if (state is ReportsError) return _buildErrorState(state.message);
            if (state is ReportsEmpty) return _buildEmptyState();
            return _buildReportContent(state, Theme.of(context));
          },
        ),
      ),
    );
  }
}
