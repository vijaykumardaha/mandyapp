import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/services/report_pdf_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_types.dart';
import 'package:mandiapp/widgets/reports/daily_sales_report.dart';
import 'package:mandiapp/widgets/reports/daily_purchase_report.dart';
import 'package:mandiapp/widgets/reports/mandi_profit_report.dart';
import 'package:mandiapp/widgets/reports/pending_payment_report.dart';
import 'package:mandiapp/widgets/reports/customer_ledger_report.dart';
import 'package:mandiapp/widgets/reports/stock_transaction_report.dart';
import 'package:mandiapp/widgets/reports/stock_summary_report.dart';
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
          return DailySalesReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.dailyPurchase:
        if (state is DailyPurchaseReportLoaded) {
          return DailyPurchaseReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
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
      case ReportType.stockTransaction:
        if (state is StockTransactionReportLoaded) {
          return StockTransactionReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
        }
        break;
      case ReportType.stockSummary:
        if (state is StockSummaryReportLoaded) {
          return StockSummaryReportWidget(state: state, theme: theme, currencyFormat: currencyFormat);
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
    if (state is ReportsLoading || state is ReportsEmpty || state is ReportsError) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.primary;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.filter_list_outlined, size: 20, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filter Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Date Range', Icons.date_range, theme),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent
                                        : accent.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? accent
                                          : theme.colorScheme.outline.withOpacity(0.12),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    preset.name[0].toUpperCase() + preset.name.substring(1),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_selectedPreset == ReportRangePreset.custom) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  _showCustomDateRangePicker().then((_) {
                                    setDialogState(() {});
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accent.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 16, color: accent),
                                      const SizedBox(width: 8),
                                      Text(
                                        _customDateRange != null
                                            ? '${ReportHelpers.formatDate(_customDateRange!.start)} - ${ReportHelpers.formatDate(_customDateRange!.end)}'
                                            : 'Select Date Range',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Container(
                            height: 1,
                            color: theme.colorScheme.outline.withOpacity(0.1),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Report Type', Icons.assessment_outlined, theme),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: ReportType.values.length,
                            itemBuilder: (context, index) {
                              final reportType = ReportType.values[index];
                              final isSelected = _selectedReportType == reportType;
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent
                                        : accent.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? accent
                                          : theme.colorScheme.outline.withOpacity(0.12),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _loadReportData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    final accent = theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 16, color: accent.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
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
        showBackButton: false,
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
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
          if (state is ReportsLoading || state is ReportsError || state is ReportsEmpty || state is ReportsInitial) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _downloadPdf,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Download',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}
