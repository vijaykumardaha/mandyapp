import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/reports/report_data_table.dart';
import 'package:mandiapp/widgets/reports/report_summary_card.dart';

class DailySalesReportWidget extends StatelessWidget {
  final DailySalesReportLoaded state;
  final ThemeData theme;
  final NumberFormat currencyFormat;

  const DailySalesReportWidget({
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
                title: 'Total Sales',
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
            ReportTableHeader(label: 'Product', flex: 2),
            ReportTableHeader(label: 'Qty', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Sales', textAlign: TextAlign.center),
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
                        MyText.bodySmall(item.unit,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.totalQuantity.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
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
