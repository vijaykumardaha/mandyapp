import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/services/report_pdf_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/customer_ledger_report.dart';
import 'package:mandiapp/widgets/reports/daily_purchase_report.dart';
import 'package:mandiapp/widgets/reports/daily_sales_report.dart';
import 'package:mandiapp/widgets/reports/mandi_profit_report.dart';
import 'package:mandiapp/widgets/reports/pending_payment_report.dart';
import 'package:mandiapp/widgets/reports/report_filter_sheet.dart';
import 'package:mandiapp/widgets/reports/report_types.dart';
import 'package:mandiapp/widgets/reports/stock_summary_report.dart';
import 'package:mandiapp/widgets/reports/stock_transaction_report.dart';
import 'package:open_file/open_file.dart';

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
          return DailySalesReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.dailyPurchase:
        if (state is DailyPurchaseReportLoaded) {
          return DailyPurchaseReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.mandiProfit:
        if (state is MandiProfitReportLoaded) {
          return MandiProfitReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.pendingPayment:
        if (state is PendingPaymentReportLoaded) {
          return PendingPaymentReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.customerLedger:
        if (state is CustomerLedgerReportLoaded) {
          return CustomerLedgerReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.stockTransaction:
        if (state is StockTransactionReportLoaded) {
          return StockTransactionReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.stockSummary:
        if (state is StockSummaryReportLoaded) {
          return StockSummaryReportWidget(
              state: state, theme: theme, currencyFormat: currencyFormat);
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
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          MySpacing.height(12),
          MyText.bodyMedium(ReportHelpers.reportTypeLabel(_selectedReportType),
              fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(
            'Report implementation coming soon',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          MySpacing.height(16),
          ElevatedButton(
            onPressed: () => _loadReportData(),
            child: Text(
                'Load ${ReportHelpers.reportTypeLabel(_selectedReportType)}'),
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
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error, size: 48),
          MySpacing.height(12),
          const MyText.bodyMedium('Error loading report', fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(message,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          MySpacing.height(12),
          const MyText.bodyMedium('No data found', fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(
            'No records found for the selected period',
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
      case ReportType.dailyPurchase:
        reportsBloc.add(LoadDailyPurchaseReport(
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
      case ReportType.stockTransaction:
        reportsBloc.add(LoadStockTransactionReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.stockSummary:
        reportsBloc.add(LoadStockSummaryReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
    }
  }

  String _getDateRangeString() {
    final start = _getStartDate();
    final end = _getEndDate();
    return '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
  }

  Future<void> _downloadPdf() async {
    final state = context.read<ReportsBloc>().state;
    if (state is ReportsLoading ||
        state is ReportsEmpty ||
        state is ReportsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data to download')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final file = await ReportPdfService.generatePdf(
        state: state,
        reportType: _selectedReportType,
        dateRange: _getDateRangeString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        return DateTime(now.year, now.month);
      case ReportRangePreset.custom:
        if (_customDateRange != null) {
          return DateTime(_customDateRange!.start.year,
              _customDateRange!.start.month, _customDateRange!.start.day);
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
        return DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      case ReportRangePreset.week:
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportRangePreset.month:
        final now = DateTime.now();
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case ReportRangePreset.custom:
        if (_customDateRange != null) {
          return DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59);
        }
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ReportFilterSheet(
          initialPreset: _selectedPreset,
          initialReportType: _selectedReportType,
          initialCustomDateRange: _customDateRange,
          onPresetChanged: (preset) {
            setState(() {
              _selectedPreset = preset;
            });
          },
          onReportTypeChanged: (reportType) {
            setState(() {
              _selectedReportType = reportType;
            });
          },
          onCustomDateRangeChanged: (range) {
            setState(() {
              _customDateRange = range;
              _selectedPreset = ReportRangePreset.custom;
            });
            _loadReportData();
          },
          onApply: _loadReportData,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        showBackButton: false,
        titleWidget: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
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
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.2),
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
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: MySpacing.xy(16, 12),
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) return _buildLoadingState();
              if (state is ReportsError) return _buildErrorState(state.message);
              if (state is ReportsEmpty) return _buildEmptyState();
              return _buildReportContent(state, Theme.of(context));
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading ||
              state is ReportsError ||
              state is ReportsEmpty ||
              state is ReportsInitial) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _downloadPdf,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.download_rounded, size: 22),
          );
        },
      ),
    );
  }
}
