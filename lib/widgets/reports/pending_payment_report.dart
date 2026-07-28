import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

class PendingPaymentReportWidget extends StatelessWidget {
  final PendingPaymentReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const PendingPaymentReportWidget({
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
          title: 'Total Pending',
          value: currencyFormat.format(state.totalPendingAmount),
          color: theme.colorScheme.error,
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Customer', flex: 2),
            ReportTableHeader(label: 'Amount', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Days', flex: 1, textAlign: TextAlign.center),
          ],
          rows: state.data.map((item) {
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
          }).toList(),
        ),
      ],
    );
  }
}
