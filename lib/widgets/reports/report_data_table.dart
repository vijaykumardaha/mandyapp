import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class ReportTableHeader {
  final String label;
  final int flex;
  final TextAlign textAlign;

  const ReportTableHeader(
      {required this.label, this.flex = 1, this.textAlign = TextAlign.left});
}

class ReportDataTable extends StatelessWidget {
  final List<ReportTableHeader> headers;
  final List<Widget> rows;

  const ReportDataTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: MySpacing.xy(12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: headers
                    .map(
                      (h) => Expanded(
                        flex: h.flex,
                        child: MyText.bodySmall(h.label,
                            fontWeight: 600, textAlign: h.textAlign),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) => rows[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
