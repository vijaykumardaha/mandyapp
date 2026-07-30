import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

class StockTransactionReportWidget extends StatelessWidget {
  final StockTransactionReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const StockTransactionReportWidget({
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
                title: 'Total Amount',
                value: currencyFormat.format(state.totalAmount),
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
            ReportTableHeader(label: 'Product', flex: 2),
            ReportTableHeader(label: 'Buyer', flex: 1),
            ReportTableHeader(label: 'Qty', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Amount', flex: 1, textAlign: TextAlign.center),
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
                        MyText.bodySmall(item.productName, fontWeight: 600),
                        if (item.variantName != null)
                          MyText.bodySmall(item.variantName!, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(item.buyerName),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      '${item.buyQuantity.toStringAsFixed(2)}',
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
