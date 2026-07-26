import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_data_table.dart';
import 'package:mandyapp/widgets/reports/report_summary_card.dart';

class PaymentModeReportWidget extends StatelessWidget {
  final PaymentModeReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const PaymentModeReportWidget({
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
        ReportSummaryCard(
          title: 'Total Amount',
          value: currencyFormat.format(state.totalAmount),
          color: theme.colorScheme.primary,
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Payment Mode', flex: 2),
            ReportTableHeader(label: 'Transactions', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Amount', flex: 1, textAlign: TextAlign.center),
          ],
          rows: state.data.map((item) {
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
          }).toList(),
        ),
      ],
    );
  }
}
