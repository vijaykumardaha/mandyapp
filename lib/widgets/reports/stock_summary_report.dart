import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/helpers/extensions/string.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/reports/report_data_table.dart';
import 'package:krishimandi/widgets/reports/report_summary_card.dart';

class StockSummaryReportWidget extends StatelessWidget {
  final StockSummaryReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const StockSummaryReportWidget({
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
                title: 'Total Purchased',
                value: currencyFormat.format(state.totalPurchaseAmount),
                color: theme.colorScheme.primary,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Sold',
                value: currencyFormat.format(state.totalSoldAmount),
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(12),
        Row(
          children: [
            Expanded(
              child: ReportSummaryCard(
                title: 'Total Profit',
                value: currencyFormat.format(state.totalProfit),
                color: state.totalProfit >= 0 ? Colors.green : Colors.red,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Remaining Qty',
                value: '${state.totalStockQuantity.toStringAsFixed(2)} units',
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Product'),
            ReportTableHeader(
                label: 'Initial Stock', flex: 2, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Sold Qty', textAlign: TextAlign.center),
            ReportTableHeader(
                label: 'Remaining Qty', flex: 2, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Profit', textAlign: TextAlign.center),
          ],
          rows: state.data.map((item) {
            return Container(
              padding: MySpacing.xy(12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: MyText.bodySmall(
                      item.variantName ?? '',
                      fontWeight: 600,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      '${item.initialQuantity.toStringAsFixed(2)} ${item.unit?.unitAbbreviation ?? ''}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      '${item.soldQuantity.toStringAsFixed(2)} ${item.unit?.unitAbbreviation ?? ''}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      '${item.quantity.toStringAsFixed(2)} ${item.unit?.unitAbbreviation ?? ''}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.profit),
                      textAlign: TextAlign.center,
                      fontWeight: 600,
                      color: item.profit >= 0 ? Colors.green : Colors.red,
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
