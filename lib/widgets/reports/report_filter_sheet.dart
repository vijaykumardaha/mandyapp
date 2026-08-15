import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/reports/report_types.dart';

/// Modal bottom sheet that lets the user pick a report date range and type.
///
/// The sheet keeps its own selection state for live highlight feedback and
/// mirrors every change back to the caller via the callbacks, so the parent
/// stays the source of truth (matching how [ReportFilterBar] is wired).
class ReportFilterSheet extends StatefulWidget {
  final ReportRangePreset initialPreset;
  final ReportType initialReportType;
  final DateTimeRange? initialCustomDateRange;
  final ValueChanged<ReportRangePreset> onPresetChanged;
  final ValueChanged<ReportType> onReportTypeChanged;
  final ValueChanged<DateTimeRange> onCustomDateRangeChanged;
  final VoidCallback onApply;

  const ReportFilterSheet({
    super.key,
    required this.initialPreset,
    required this.initialReportType,
    required this.initialCustomDateRange,
    required this.onPresetChanged,
    required this.onReportTypeChanged,
    required this.onCustomDateRangeChanged,
    required this.onApply,
  });

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late ReportRangePreset _preset;
  late ReportType _reportType;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _reportType = widget.initialReportType;
    _customDateRange = widget.initialCustomDateRange;
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customDateRange ??
          DateTimeRange(
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
        _preset = ReportRangePreset.custom;
      });
      widget.onCustomDateRangeChanged(picked);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    final accent = theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 16, color: accent.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.filter_list_outlined, size: 20, color: accent),
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
                      final isSelected = _preset == preset;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _preset = preset;
                          });
                          widget.onPresetChanged(preset);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : accent.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.12),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            preset.name[0].toUpperCase() +
                                preset.name.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_preset == ReportRangePreset.custom) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: _pickCustomDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: accent),
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
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      'Report Type', Icons.assessment_outlined, theme),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: ReportType.values.length,
                    itemBuilder: (context, index) {
                      final reportType = ReportType.values[index];
                      final isSelected = _reportType == reportType;
                      final name = ReportHelpers.reportTypeLabel(reportType);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _reportType = reportType;
                          });
                          widget.onReportTypeChanged(reportType);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : accent.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.12),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
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
                        widget.onApply();
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
  }
}
