import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

class CustomerLedgerReportWidget extends StatelessWidget {
  final CustomerLedgerReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const CustomerLedgerReportWidget({
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
          title: 'Net Balance',
          value: currencyFormat.format(state.totalNetBalance),
          color: state.totalNetBalance >= 0 ? Colors.green : Colors.red,
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Customer', flex: 2),
            ReportTableHeader(label: 'Purchases', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Sales', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Balance', flex: 1, textAlign: TextAlign.center),
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
                      currencyFormat.format(item.totalPurchases),
                      textAlign: TextAlign.center,
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      currencyFormat.format(item.totalSales),
                      textAlign: TextAlign.center,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      currencyFormat.format(item.netBalance),
                      textAlign: TextAlign.center,
                      fontWeight: 600,
                      color: item.netBalance >= 0 ? Colors.green : Colors.red,
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
