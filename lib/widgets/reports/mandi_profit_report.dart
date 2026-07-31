import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

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
                title: 'Total Sales',
                value: currencyFormat.format(state.totalRevenue),
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Date'),
            ReportTableHeader(
                label: 'Total Sales', textAlign: TextAlign.center),
            ReportTableHeader(
                label: 'Total Profit', textAlign: TextAlign.right),
          ],
          rows: state.data.map((item) {
            return Container(
              padding: MySpacing.xy(12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: MyText.bodySmall(item.date, fontWeight: 600),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.dailyRevenue),
                      textAlign: TextAlign.center,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.dailyProfit),
                      textAlign: TextAlign.right,
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
