import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/widgets/reports/report_data_table.dart';
import 'package:mandyapp/widgets/reports/report_summary_card.dart';

class TopSellingProductsReportWidget extends StatelessWidget {
  final TopSellingProductsReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const TopSellingProductsReportWidget({
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
          title: 'Total Revenue',
          value: currencyFormat.format(state.totalRevenue),
          color: theme.colorScheme.primary,
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Product', flex: 2),
            ReportTableHeader(label: 'Qty Sold', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Revenue', flex: 1, textAlign: TextAlign.center),
            ReportTableHeader(label: 'Rank', flex: 1, textAlign: TextAlign.center),
          ],
          rows: List.generate(state.data.length, (index) {
            final item = state.data[index];
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
                        MyText.bodySmall(item.unit, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: MyText.bodySmall(
                      '${item.totalQuantitySold.toStringAsFixed(2)}',
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
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: MySpacing.xy(8, 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MyText.bodySmall(
                        '#${index + 1}',
                        textAlign: TextAlign.center,
                        fontWeight: 600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
