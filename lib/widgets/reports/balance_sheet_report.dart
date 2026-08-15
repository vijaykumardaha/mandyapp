import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/models/report_models.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class BalanceSheetReportWidget extends StatelessWidget {
  final BalanceSheetReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const BalanceSheetReportWidget({
    super.key,
    required this.state,
    required this.theme,
    required this.currencyFormat,
  });

  static const double _rowWidth = 540;

  List<(BalanceSheetReportData, double, double)> _runningRows() {
    final running = <(BalanceSheetReportData, double, double)>[];
    var balance = state.openingBalance;
    for (final item in state.data.reversed) {
      final opening = balance;
      balance += item.netBalance;
      running.add((item, opening, balance));
    }
    return running.reversed.toList();
  }

  Widget _cell(String text,
      {double width = 100,
      TextAlign align = TextAlign.right,
      Color? color,
      int? fontWeight}) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: MyText.bodySmall(
          text,
          color: color,
          fontWeight: fontWeight ?? 600,
        ),
      ),
    );
  }

  Widget _buildTable() {
    final rows = _runningRows();
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Container(
                width: _rowWidth,
                padding: MySpacing.xy(12, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    _cell('Date', width: 90, align: TextAlign.left),
                    _cell('Opening', width: 110),
                    _cell('Debit'),
                    _cell('Credit'),
                    _cell('Closing', width: 110),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: _rowWidth,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final (item, opening, closing) = rows[index];
                      return Container(
                        width: _rowWidth,
                        padding: MySpacing.xy(12, 8),
                        child: Row(
                          children: [
                            _cell(item.date, width: 90, align: TextAlign.left),
                            _cell(
                              currencyFormat.format(opening),
                              width: 110,
                              color: opening >= 0 ? Colors.green : Colors.red,
                            ),
                            _cell(
                              currencyFormat.format(item.totalDebit),
                              color: Colors.red,
                            ),
                            _cell(
                              currencyFormat.format(item.totalCredit),
                              color: Colors.green,
                            ),
                            _cell(
                              currencyFormat.format(closing),
                              width: 110,
                              color: closing >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MySpacing.height(16),
        _buildTable(),
      ],
    );
  }
}
