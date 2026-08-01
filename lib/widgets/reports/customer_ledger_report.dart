import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/reports/report_data_table.dart';

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
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Customer Name', flex: 2),
            ReportTableHeader(label: 'Phone', flex: 2),
            ReportTableHeader(label: 'Paid'),
            ReportTableHeader(label: 'Received'),
            ReportTableHeader(label: 'Balance', textAlign: TextAlign.right),
          ],
          rows: state.data.map((item) {
            return Container(
              padding: MySpacing.xy(12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.customerName,
                      fontWeight: 600,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.customerPhone,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.totalPaid),
                      fontWeight: 600,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.totalReceived),
                      fontWeight: 600,
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.netBalance),
                      textAlign: TextAlign.right,
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
