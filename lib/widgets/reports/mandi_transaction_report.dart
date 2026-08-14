import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/reports/report_data_table.dart';
import 'package:krishimandi/widgets/reports/report_summary_card.dart';

class MandiTransactionReportWidget extends StatelessWidget {
  final MandiTransactionReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const MandiTransactionReportWidget({
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
                title: 'Total Paid',
                value: currencyFormat.format(state.totalPaid),
                color: Colors.red,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Receive',
                value: currencyFormat.format(state.totalReceive),
                color: Colors.green,
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
            ReportTableHeader(label: 'Type'),
            ReportTableHeader(label: 'Note', flex: 3),
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
                    child: MyText.bodySmall(
                      item.isDebit ? 'Paid' : 'Receive',
                      fontWeight: 600,
                      color: item.isDebit ? Colors.red : Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: MyText.bodySmall(
                      item.transactionNote,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.amount),
                      textAlign: TextAlign.right,
                      fontWeight: 600,
                      color: item.isDebit ? Colors.red : Colors.green,
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
