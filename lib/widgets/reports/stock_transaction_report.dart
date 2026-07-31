import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/helpers/extensions/string.dart';
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
                value: state.totalQuantityLabel,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Product'),
            ReportTableHeader(label: 'Buyer Name'),
            ReportTableHeader(label: 'Rate', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Quantity', textAlign: TextAlign.center),
            ReportTableHeader(label: 'Amount', textAlign: TextAlign.center),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.buyerName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      currencyFormat.format(item.avgPrice),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: MyText.bodySmall(
                      item.buyQuantity.toStringAsFixed(2) +
                          (item.unit != null && item.unit!.trim().isNotEmpty
                              ? '\u00A0${item.unit!.unitAbbreviation}'
                              : ''),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
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
