import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

enum ReportRangePreset { today, yesterday, week, month, custom }

enum ReportType { summary, sales, payments, customers }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  ReportRangePreset _selectedPreset = ReportRangePreset.today;
  ReportType _selectedReportType = ReportType.summary;
  final DateFormat _dateFormat = DateFormat('dd/MM/yy');

  @override
  void initState() {
    super.initState();
    _applyPreset(ReportRangePreset.today, initialize: true);
  }

  void _applyPreset(ReportRangePreset preset, {bool initialize = false}) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day);
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case ReportRangePreset.today:
        break;
      case ReportRangePreset.yesterday:
        final yesterday = start.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case ReportRangePreset.week:
        final weekStart = start.subtract(const Duration(days: 6));
        start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportRangePreset.month:
        start = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        end = nextMonth.subtract(const Duration(seconds: 1));
        break;
      case ReportRangePreset.custom:
        if (!initialize) {
          _selectCustomRange();
          return;
        }
        break;
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(useMaterial3: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedPreset = ReportRangePreset.custom;
      _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
    });
  }

  String _formatDate(DateTime date) => _dateFormat.format(date);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('Reports', fontWeight: 600),
      ),
      body: Padding(
        padding: MySpacing.xy(16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDatePickerCard(theme),
            MySpacing.height(24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
                ),
                child: Center(
                  child: MyText.bodyMedium(
                    'Report metrics will appear here.',
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerCard(ThemeData theme) {
    final bgColor = theme.colorScheme.surface;
    final accent = theme.colorScheme.primary;

    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: bgColor,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 360;
          final bool isMedium = constraints.maxWidth < 520;

          final Widget presetButton = _buildPresetButton(theme, accent);
          final Widget reportButton = _buildReportTypeButton(theme, accent);
          final Widget fromTile = _buildDateTile(theme, label: 'From', date: _startDate);
          final Widget toTile = _buildDateTile(theme, label: 'To', date: _endDate);

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: presetButton),
                    MySpacing.width(12),
                    Expanded(child: reportButton),
                  ],
                ),
                MySpacing.height(12),
                fromTile,
                MySpacing.height(12),
                toTile,
              ],
            );
          }

          if (isMedium) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: presetButton),
                    MySpacing.width(12),
                    Expanded(child: reportButton),
                  ],
                ),
                MySpacing.height(12),
                Row(
                  children: [
                    Expanded(child: fromTile),
                    MySpacing.width(12),
                    Expanded(child: toTile),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              presetButton,
              MySpacing.width(16),
              reportButton,
              MySpacing.width(16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: fromTile),
                    MySpacing.width(12),
                    Expanded(child: toTile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetButton(ThemeData theme, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<ReportRangePreset>(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        position: PopupMenuPosition.under,
        onSelected: (value) => _applyPreset(value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: ReportRangePreset.today, child: Text('Today')),
          const PopupMenuItem(value: ReportRangePreset.yesterday, child: Text('Yesterday')),
          const PopupMenuItem(value: ReportRangePreset.week, child: Text('Week')),
          const PopupMenuItem(value: ReportRangePreset.month, child: Text('Month')),
          const PopupMenuItem(value: ReportRangePreset.custom, child: Text('Custom')),
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
              Icon(Icons.keyboard_arrow_down, color: accent),
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
          setState(() {
            _selectedReportType = value;
          });
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: ReportType.summary, child: Text('Summary')),
          PopupMenuItem(value: ReportType.sales, child: Text('Sales')),
          PopupMenuItem(value: ReportType.payments, child: Text('Payments')),
          PopupMenuItem(value: ReportType.customers, child: Text('Customers')),
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

  Widget _buildDateTile(ThemeData theme, {required String label, required DateTime date}) {
    final accent = theme.colorScheme.primary;
    return Container(
      padding: MySpacing.xy(16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodySmall(label, fontWeight: 500, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          MySpacing.height(6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: accent),
              MySpacing.width(8),
              Expanded(
                child: MyText.bodyMedium(
                  _formatDate(date),
                  fontWeight: 600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
      case ReportType.summary:
        return 'Summary';
      case ReportType.sales:
        return 'Sales';
      case ReportType.payments:
        return 'Payments';
      case ReportType.customers:
        return 'Customers';
    }
  }
}
