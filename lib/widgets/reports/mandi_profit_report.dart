import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_data_table.dart';
import 'package:mandyapp/widgets/reports/report_summary_card.dart';

class MandiProfitReportWidget extends StatelessWidget {
  final MandiProfitReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const MandiProfitReportWidget({
    super.key,
    required this.state,
    required this.theme,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Profit',
                value: currencyFormat.format(state.totalProfit),
                color: theme.colorScheme.primary,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Revenue',
                value: currencyFormat.format(state.totalRevenue),
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Date', flex: 1),
            ReportTableHeader(label: 'Revenue', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Cost', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Profit', flex: 1, textAlign: TextAlign.center),
          ],
          rows: state.data.map((item) {
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
          }).toList(),
        ),
      ],
    );
  }
}
