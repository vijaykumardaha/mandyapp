import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

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
                title: 'Profit',
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
            ReportTableHeader(label: 'Product', flex: 2),
            ReportTableHeader(label: 'Initial', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Sold', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Remaining', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Profit', textAlign: TextAlign.center),
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
                          MyText.bodySmall(item.variantName!,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.initialQuantity.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.soldQuantity.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.quantity.toStringAsFixed(2),
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
