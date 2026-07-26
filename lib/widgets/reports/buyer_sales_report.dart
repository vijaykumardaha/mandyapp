import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_data_table.dart';
import 'package:mandyapp/widgets/reports/report_summary_card.dart';

class BuyerSalesReportWidget extends StatelessWidget {
  final BuyerSalesReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const BuyerSalesReportWidget({
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
                title: 'Total Revenue',
                value: currencyFormat.format(state.totalRevenue),
                color: theme.colorScheme.primary,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Quantity',
                value: '${state.totalQuantity.toStringAsFixed(2)} units',
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Buyer', flex: 2),
            ReportTableHeader(label: 'Bills', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Revenue', flex: 1, textAlign: TextAlign.center),
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
                        MyText.bodySmall(item.buyerName, fontWeight: 600),
                        MyText.bodySmall(item.buyerPhone, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      '${item.totalBills}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      currencyFormat.format(item.totalRevenue),
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
