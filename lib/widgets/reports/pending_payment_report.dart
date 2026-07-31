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
        Row(
          children: [
            Expanded(
              child: ReportSummaryCard(
                title: 'Buyer Total Pending',
                value: currencyFormat.format(state.totalBuyerPending),
                color: theme.colorScheme.error,
              ),
            ),
            MySpacing.width(12),
            Expanded(
              child: ReportSummaryCard(
                title: 'Seller Total Pending',
                value: currencyFormat.format(state.totalSellerPending),
                color: Colors.green,
              ),
            ),
          ],
        ),
        MySpacing.height(16),
        ReportDataTable(
          headers: const [
            ReportTableHeader(label: 'Customer', flex: 2),
            ReportTableHeader(
                label: 'Billing ID', flex: 2, textAlign: TextAlign.center),
            ReportTableHeader(
                label: 'Type', flex: 2, textAlign: TextAlign.center),
            ReportTableHeader(
                label: 'Total Amount', flex: 2, textAlign: TextAlign.right),
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
                        MyText.bodySmall(
                          item.customerName,
                          fontWeight: 600,
                          overflow: TextOverflow.ellipsis,
                        ),
                        MyText.bodySmall(
                          item.customerPhone,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.billingId != null ? '#${item.billingId}' : '-',
                      textAlign: TextAlign.center,
                      fontWeight: 600,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      item.billingType ?? 'Buyer',
                      textAlign: TextAlign.center,
                      fontWeight: 600,
                      color: item.billingType == 'Seller'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                      currencyFormat.format(item.pendingAmount),
                      textAlign: TextAlign.right,
                      fontWeight: 600,
                      color: item.billingType == 'Seller'
                          ? Colors.green
                          : theme.colorScheme.error,
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
