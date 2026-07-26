import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_types.dart';

class ReportFilterBar extends StatefulWidget {
  final ReportRangePreset selectedPreset;
  final ReportType selectedReportType;
  final DateTimeRange? customDateRange;
  final ValueChanged<ReportRangePreset> onPresetChanged;
  final ValueChanged<ReportType> onReportTypeChanged;
  final ValueChanged<DateTimeRange> onCustomDateRangeChanged;

  const ReportFilterBar({
    super.key,
    required this.selectedPreset,
    required this.selectedReportType,
    this.customDateRange,
    required this.onPresetChanged,
    required this.onReportTypeChanged,
    required this.onCustomDateRangeChanged,
  });

  @override
  State<ReportFilterBar> createState() => _ReportFilterBarState();
}

class _ReportFilterBarState extends State<ReportFilterBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Row(
            children: [
              _buildPresetButton(theme, accent),
              MySpacing.width(16),
              _buildReportTypeButton(theme, accent),
            ],
          ),
          MySpacing.height(12),
          _buildSelectedDateDisplay(theme, accent),
        ],
      ),
    );
  }

  Widget _buildPresetButton(ThemeData theme, Color accent) {
    final isCustomSelected = widget.selectedPreset == ReportRangePreset.custom;

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
            final now = DateTime.now();
            final firstDate = DateTime(now.year - 1);
            final lastDate = DateTime(now.year + 1);

            final picked = await showDateRangePicker(
              context: context,
              firstDate: firstDate,
              lastDate: lastDate,
              initialDateRange: widget.customDateRange ?? DateTimeRange(
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
              widget.onCustomDateRangeChanged(picked);
              widget.onPresetChanged(ReportRangePreset.custom);
            }
          } else {
            widget.onPresetChanged(value);
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
                ReportHelpers.presetLabel(widget.selectedPreset),
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
          widget.onReportTypeChanged(value);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: ReportType.dailySales, child: Text('Daily Sales Report')),
          PopupMenuItem(value: ReportType.sellerPurchase, child: Text('Seller Purchase Summary')),
          PopupMenuItem(value: ReportType.buyerSales, child: Text('Buyer Sales Summary')),
          PopupMenuItem(value: ReportType.mandiProfit, child: Text('Mandi Profit Report')),
          PopupMenuItem(value: ReportType.pendingPayment, child: Text('Pending Payment Report')),
          PopupMenuItem(value: ReportType.customerLedger, child: Text('Customer Ledger Report')),
          PopupMenuItem(value: ReportType.paymentMode, child: Text('Payment Mode Report')),
          PopupMenuItem(value: ReportType.topSellingProducts, child: Text('Top Selling Products Report')),
          PopupMenuItem(value: ReportType.chargesPerformance, child: Text('Charges Performance Report')),
        ],
        child: Padding(
          padding: MySpacing.xy(16, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.labelLarge(
                ReportHelpers.reportTypeLabel(widget.selectedReportType),
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

    switch (widget.selectedPreset) {
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
        if (widget.customDateRange != null) {
          startDate = DateTime(widget.customDateRange!.start.year, widget.customDateRange!.start.month, widget.customDateRange!.start.day);
          endDate = DateTime(widget.customDateRange!.end.year, widget.customDateRange!.end.month, widget.customDateRange!.end.day, 23, 59, 59);
        } else {
          final now = DateTime.now();
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }
        break;
    }

    final startDateStr = ReportHelpers.formatDate(startDate);
    final endDateStr = ReportHelpers.formatDate(endDate);

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
                final now = DateTime.now();
                final firstDate = DateTime(now.year - 1);
                final lastDate = DateTime(now.year + 1);

                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  initialDateRange: widget.customDateRange ?? DateTimeRange(
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
                  widget.onCustomDateRangeChanged(picked);
                }
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
}
