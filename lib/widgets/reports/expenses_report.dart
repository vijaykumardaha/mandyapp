import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/reports/report_data_table.dart';
import 'package:krishimandi/widgets/reports/report_summary_card.dart';

class ExpensesReportWidget extends StatelessWidget {
  final ExpensesReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const ExpensesReportWidget({
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
                title: 'Total Expenses',
                value: currencyFormat.format(state.totalAmount),
                color: theme.colorScheme.error,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Transactions',
                value: '${state.totalTransactions}',
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Date', flex: 2),
            ReportTableHeader(label: 'Bill #', flex: 2),
            ReportTableHeader(label: 'Expense', flex: 2),
            ReportTableHeader(label: 'Amount', textAlign: TextAlign.right),
          ],
          rows: state.data.map((item) {
            return Container(
              padding: MySpacing.xy(12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(item.date, fontWeight: 600),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.orderId != null ? '#${item.orderId}' : '-',
                      fontWeight: 600,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.expenseName,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.totalAmount),
                      textAlign: TextAlign.right,
                      fontWeight: 600,
                      color: theme.colorScheme.error,
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
