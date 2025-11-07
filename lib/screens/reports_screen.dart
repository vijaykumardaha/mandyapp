import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

enum ReportRangePreset { today, yesterday, week, month, custom }

enum ReportType {
  dailySales,
  sellerPurchase,
  buyerSales,
  mandiProfit,
  customerLedger,
  pendingPayment,
  paymentMode,
  stockMovement,
  topSellingProducts,
  chargesPerformance,
}

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
    // Load initial report data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  // Helper methods
  String _presetLabel(ReportRangePreset preset) {
    switch (preset) {
      case ReportRangePreset.today:
        return 'Today';
      case ReportRangePreset.yesterday:
        return 'Yesterday';
      case ReportRangePreset.week:
        return 'This Week';
      case ReportRangePreset.month:
        return 'This Month';
      case ReportRangePreset.custom:
        return 'Custom';
    }
  }

  String _reportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.dailySales:
        return 'Daily Sales';
      case ReportType.sellerPurchase:
        return 'Seller Purchase';
      case ReportType.buyerSales:
        return 'Buyer Sales';
      case ReportType.mandiProfit:
        return 'Mandi Profit';
      case ReportType.customerLedger:
        return 'Customer Ledger';
      case ReportType.pendingPayment:
        return 'Pending Payment';
      case ReportType.paymentMode:
        return 'Payment Mode';
      case ReportType.stockMovement:
        return 'Stock Movement';
      case ReportType.topSellingProducts:
        return 'Top Products';
      case ReportType.chargesPerformance:
        return 'Charges Performance';
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.dailySales:
        return Icons.trending_up;
      case ReportType.sellerPurchase:
        return Icons.shopping_cart;
      case ReportType.buyerSales:
        return Icons.point_of_sale;
      case ReportType.mandiProfit:
        return Icons.account_balance;
      case ReportType.customerLedger:
        return Icons.account_balance_wallet;
      case ReportType.pendingPayment:
        return Icons.pending_actions;
      case ReportType.paymentMode:
        return Icons.payment;
      case ReportType.stockMovement:
        return Icons.inventory;
      case ReportType.topSellingProducts:
        return Icons.star;
      case ReportType.chargesPerformance:
        return Icons.assessment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Date picker methods
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

  // UI building methods
  Widget _buildDatePickerCard(ThemeData theme) {
    final accent = theme.colorScheme.primary;

    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dropdown buttons row
          Row(
            children: [
              _buildPresetButton(theme, accent),
              MySpacing.width(16),
              _buildReportTypeButton(theme, accent),
            ],
          ),
          // Selected date display - Always visible
          MySpacing.height(12),
          _buildSelectedDateDisplay(theme, accent),
        ],
      ),
    );
  }

  Widget _buildPresetButton(ThemeData theme, Color accent) {
    final isCustomSelected = _selectedPreset == ReportRangePreset.custom;

    return Container(
      decoration: BoxDecoration(
        color: isCustomSelected ? accent.withOpacity(0.15) : accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: isCustomSelected ? Border.all(color: accent.withOpacity(0.3), width: 1) : null,
      ),
      child: PopupMenuButton<ReportRangePreset>(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCustomSelected ? BorderSide(color: accent.withOpacity(0.3), width: 1) : BorderSide.none,
        ),
        position: PopupMenuPosition.under,
        onSelected: (value) async {
          if (value == ReportRangePreset.custom) {
            await _showCustomDateRangePicker();
          } else {
            setState(() => _selectedPreset = value);
            _loadReportData();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: ReportRangePreset.today, child: Text('Today')),
          PopupMenuItem(value: ReportRangePreset.yesterday, child: Text('Yesterday')),
          PopupMenuItem(value: ReportRangePreset.week, child: Text('This Week')),
          PopupMenuItem(value: ReportRangePreset.month, child: Text('This Month')),
          PopupMenuItem(value: ReportRangePreset.custom, child: Text('Custom Range')),
        ],
        child: Padding(
          padding: MySpacing.xy(16, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.labelLarge(
                _presetLabel(_selectedPreset),
                fontWeight: 600,
                color: accent,
              ),
              MySpacing.width(8),
              Icon(
                isCustomSelected ? Icons.calendar_today : Icons.keyboard_arrow_down,
                color: accent,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeButton(ThemeData theme, Color accent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.16)),
      ),
      child: PopupMenuButton<ReportType>(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        position: PopupMenuPosition.under,
        onSelected: (value) {
          setState(() => _selectedReportType = value);
          _loadReportData();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: ReportType.dailySales, child: Text('Daily Sales Report')),
          PopupMenuItem(value: ReportType.sellerPurchase, child: Text('Seller Purchase Summary')),
          PopupMenuItem(value: ReportType.buyerSales, child: Text('Buyer Sales Summary')),
          PopupMenuItem(value: ReportType.mandiProfit, child: Text('Mandi Profit Report')),
          PopupMenuItem(value: ReportType.customerLedger, child: Text('Customer Ledger Report')),
          PopupMenuItem(value: ReportType.pendingPayment, child: Text('Pending Payment Report')),
          PopupMenuItem(value: ReportType.paymentMode, child: Text('Payment Mode Summary')),
          PopupMenuItem(value: ReportType.stockMovement, child: Text('Stock Movement Report')),
          PopupMenuItem(value: ReportType.topSellingProducts, child: Text('Top Selling Products')),
          PopupMenuItem(value: ReportType.chargesPerformance, child: Text('Charges Performance Report')),
        ],
        child: Padding(
          padding: MySpacing.xy(16, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.labelLarge(
                _reportTypeLabel(_selectedReportType),
                fontWeight: 600,
                color: accent,
              ),
              MySpacing.width(8),
              Icon(Icons.keyboard_arrow_down, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateDisplay(ThemeData theme, Color accent) {
    DateTime startDate;
    DateTime endDate;
    bool isCustom = false;

    switch (_selectedPreset) {
      case ReportRangePreset.today:
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportRangePreset.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case ReportRangePreset.week:
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportRangePreset.month:
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case ReportRangePreset.custom:
        isCustom = true;
        if (_customDateRange != null) {
          startDate = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
          endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        } else {
          final now = DateTime.now();
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }
        break;
    }

    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    return Container(
      padding: MySpacing.xy(16, 12),
      decoration: BoxDecoration(
        color: isCustom ? accent.withOpacity(0.08) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCustom ? accent.withOpacity(0.2) : theme.colorScheme.outline.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isCustom ? Icons.calendar_today_outlined : Icons.date_range,
            size: 18,
            color: isCustom ? accent : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          MySpacing.width(8),
          MyText.bodyMedium(
            isCustom ? 'Selected: $startDateStr - $endDateStr' : 'Range: $startDateStr - $endDateStr',
            fontWeight: 500,
            color: isCustom ? accent : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          if (isCustom) ...[
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await _showCustomDateRangePicker();
              },
              child: Icon(
                Icons.edit_calendar,
                size: 18,
                color: accent.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // State builder methods
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
                _getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                _reportTypeLabel(_selectedReportType),
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
                _getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                _reportTypeLabel(_selectedReportType),
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
                _getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                _reportTypeLabel(_selectedReportType),
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
                    _getReportIcon(_selectedReportType),
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
                _getReportIcon(_selectedReportType),
                color: theme.colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.titleMedium(
                _reportTypeLabel(_selectedReportType),
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
          return _buildDailySalesReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.sellerPurchase:
        if (state is SellerPurchaseReportLoaded) {
          return _buildSellerPurchaseReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.buyerSales:
        if (state is BuyerSalesReportLoaded) {
          return _buildBuyerSalesReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.mandiProfit:
        if (state is MandiProfitReportLoaded) {
          return _buildMandiProfitReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.customerLedger:
        if (state is CustomerLedgerReportLoaded) {
          return _buildCustomerLedgerReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.pendingPayment:
        if (state is PendingPaymentReportLoaded) {
          return _buildPendingPaymentReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.paymentMode:
        if (state is PaymentModeReportLoaded) {
          return _buildPaymentModeReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.stockMovement:
        if (state is StockMovementReportLoaded) {
          return _buildStockMovementReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.topSellingProducts:
        if (state is TopSellingProductsReportLoaded) {
          return _buildTopSellingProductsReport(state, theme, currencyFormat);
        }
        break;
      case ReportType.chargesPerformance:
        if (state is ChargesPerformanceReportLoaded) {
          return _buildChargesPerformanceReport(state, theme, currencyFormat);
        }
        break;
    }

    // Default fallback
    return _buildPlaceholderReport(theme);
  }

  // Report display methods
  Widget _buildDailySalesReport(DailySalesReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                currencyFormat.format(state.totalRevenue),
                Icons.attach_money,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: _buildSummaryCard(
                'Total Quantity',
                '${state.totalQuantity.toStringAsFixed(2)} units',
                Icons.inventory,
                theme.colorScheme.secondary,
                theme,
              ),
            ),
          ],
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Product', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Qty', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Revenue', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.productName, fontWeight: 600),
                                  MyText.bodySmall(item.unit, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.totalQuantity.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalRevenue),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerPurchaseReport(SellerPurchaseReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Cost',
                currencyFormat.format(state.totalCost),
                Icons.shopping_cart,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: _buildSummaryCard(
                'Total Quantity',
                '${state.totalQuantity.toStringAsFixed(2)} units',
                Icons.inventory,
                theme.colorScheme.secondary,
                theme,
              ),
            ),
          ],
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Seller', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Purchases', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Cost', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.sellerName, fontWeight: 600),
                                  MyText.bodySmall(item.sellerPhone, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.totalPurchases}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalCost),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerSalesReport(BuyerSalesReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                currencyFormat.format(state.totalRevenue),
                Icons.point_of_sale,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: _buildSummaryCard(
                'Total Quantity',
                '${state.totalQuantity.toStringAsFixed(2)} units',
                Icons.inventory,
                theme.colorScheme.secondary,
                theme,
              ),
            ),
          ],
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Buyer', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Bills', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Revenue', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.buyerName, fontWeight: 600),
                                  MyText.bodySmall(item.buyerPhone, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.totalBills}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalRevenue),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMandiProfitReport(MandiProfitReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Profit',
                currencyFormat.format(state.totalProfit),
                Icons.account_balance,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                currencyFormat.format(state.totalRevenue),
                Icons.trending_up,
                theme.colorScheme.secondary,
                theme,
              ),
            ),
          ],
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: MyText.bodySmall('Date', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Revenue', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Cost', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Profit', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(item.date, fontWeight: 600),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.dailyRevenue),
                                textAlign: TextAlign.center,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.dailyCost),
                                textAlign: TextAlign.center,
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.dailyProfit),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: item.dailyProfit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerLedgerReport(CustomerLedgerReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Net Balance',
          currencyFormat.format(state.totalNetBalance),
          Icons.account_balance_wallet,
          state.totalNetBalance >= 0 ? Colors.green : Colors.red,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Customer', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Purchases', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Sales', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Balance', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.customerName, fontWeight: 600),
                                  MyText.bodySmall(item.customerPhone, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalPurchases),
                                textAlign: TextAlign.center,
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalSales),
                                textAlign: TextAlign.center,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.netBalance),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: item.netBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingPaymentReport(PendingPaymentReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Total Pending',
          currencyFormat.format(state.totalPendingAmount),
          Icons.pending_actions,
          theme.colorScheme.error,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Customer', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Amount', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Days', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.customerName, fontWeight: 600),
                                  MyText.bodySmall(item.customerPhone, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.pendingAmount),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.daysPending}',
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: item.daysPending > 30 ? theme.colorScheme.error : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeReport(PaymentModeReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Total Amount',
          currencyFormat.format(state.totalAmount),
          Icons.payment,
          theme.colorScheme.primary,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Payment Mode', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Transactions', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Amount', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: MyText.bodySmall(item.paymentMethod, fontWeight: 600),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.transactionCount}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalAmount),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockMovementReport(StockMovementReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Net Stock Change',
          '${state.netStockChange >= 0 ? '+' : ''}${state.netStockChange.toStringAsFixed(2)} units',
          Icons.inventory,
          state.netStockChange >= 0 ? Colors.green : Colors.red,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Product', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('In', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Out', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Net', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.productName, fontWeight: 600),
                                  MyText.bodySmall(item.unit, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '+${item.stockIn.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '-${item.stockOut.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.netStockChange >= 0 ? '+' : ''}${item.netStockChange.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: item.netStockChange >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSellingProductsReport(TopSellingProductsReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Total Revenue',
          currencyFormat.format(state.totalRevenue),
          Icons.star,
          theme.colorScheme.primary,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Product', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Qty Sold', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Revenue', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Rank', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(item.productName, fontWeight: 600),
                                  MyText.bodySmall(item.unit, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.totalQuantitySold.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalRevenue),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: MySpacing.xy(8, 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: MyText.bodySmall(
                                  '#${index + 1}',
                                  textAlign: TextAlign.center,
                                  fontWeight: 600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargesPerformanceReport(ChargesPerformanceReportLoaded state, ThemeData theme, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildSummaryCard(
          'Total Charges',
          currencyFormat.format(state.totalChargeAmount),
          Icons.assessment,
          theme.colorScheme.primary,
          theme,
        ),
        MySpacing.height(16),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: MySpacing.xy(12, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: MyText.bodySmall('Charge Type', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Transactions', fontWeight: 600)),
                      Expanded(flex: 1, child: MyText.bodySmall('Amount', fontWeight: 600)),
                    ],
                  ),
                ),

                // Table Rows
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.data.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.data[index];
                      return Container(
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: MyText.bodySmall(item.chargeType, fontWeight: 600),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                '${item.transactionCount}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MyText.bodySmall(
                                currencyFormat.format(item.totalChargeAmount),
                                textAlign: TextAlign.center,
                                fontWeight: 600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          MySpacing.height(4),
          MyText.bodySmall(title, color: color, fontWeight: 600),
          MySpacing.height(2),
          MyText.titleSmall(value, fontWeight: 700, color: color),
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
            _getReportIcon(_selectedReportType),
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          MySpacing.height(12),
          MyText.bodyMedium(_reportTypeLabel(_selectedReportType), fontWeight: 600),
          MySpacing.height(8),
          MyText.bodySmall(
            'Report implementation coming soon',
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          MySpacing.height(16),
          ElevatedButton(
            onPressed: () => _loadReportData(),
            child: Text('Load ${_reportTypeLabel(_selectedReportType)}'),
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
      case ReportType.customerLedger:
        reportsBloc.add(LoadCustomerLedgerReport(
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
      case ReportType.paymentMode:
        reportsBloc.add(LoadPaymentModeReport(
          fromDate: _getStartDate(),
          toDate: _getEndDate(),
        ));
        break;
      case ReportType.stockMovement:
        reportsBloc.add(LoadStockMovementReport(
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
        title: MyText.titleMedium('Reports', fontWeight: 600),
      ),
      body: Padding(
        padding: MySpacing.xy(16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDatePickerCard(Theme.of(context)),
            MySpacing.height(24),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _loadReportData,
        tooltip: 'Load Report',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
