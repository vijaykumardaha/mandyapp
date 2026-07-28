import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/widgets/reports/report_types.dart';

class ReportPdfService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

  static Future<File> generatePdf({
    required ReportsState state,
    required ReportType reportType,
    required String dateRange,
  }) async {
    final pdf = pw.Document();
    final title = ReportHelpers.reportTypeLabel(reportType);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(title, dateRange),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildContent(state, reportType),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${reportType.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(String title, String dateRange) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Mandi App',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1565C0'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Report Period',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    dateRange,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Mandi App - Report',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildContent(ReportsState state, ReportType reportType) {
    switch (reportType) {
      case ReportType.dailySales:
        return _buildDailySalesContent(state as DailySalesReportLoaded);
      case ReportType.dailyPurchase:
        return _buildDailyPurchaseContent(state as DailyPurchaseReportLoaded);
      case ReportType.mandiProfit:
        return _buildMandiProfitContent(state as MandiProfitReportLoaded);
      case ReportType.pendingPayment:
        return _buildPendingPaymentContent(state as PendingPaymentReportLoaded);
      case ReportType.customerLedger:
        return _buildCustomerLedgerContent(state as CustomerLedgerReportLoaded);
    }
  }

  static pw.Widget _buildSummaryRow(List<pw.Widget> cards) {
    return pw.Row(
      children: cards.map((card) => pw.Expanded(child: card)).toList(),
    );
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8, right: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1565C0'),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
      ),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellHeight: 30,
      cellDecoration: (index, row, cell) {
        return pw.BoxDecoration(
          color: index.isEven ? PdfColors.grey50 : PdfColors.white,
          border: const pw.Border(
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey200),
          ),
        );
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        for (int i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
      },
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        for (int i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
      },
      headers: headers,
      data: rows,
    );
  }

  // ── Daily Sales ──────────────────────────────────────────────
  static List<pw.Widget> _buildDailySalesContent(DailySalesReportLoaded state) {
    return [
      _buildSummaryRow([
        _summaryCard('Total Revenue', currencyFormat.format(state.totalRevenue), PdfColor.fromHex('#1565C0')),
        _summaryCard('Total Quantity', '${state.totalQuantity.toStringAsFixed(2)} units', PdfColor.fromHex('#2E7D32')),
        _summaryCard('Transactions', '${state.totalTransactions}', PdfColor.fromHex('#E65100')),
      ]),
      pw.SizedBox(height: 16),
      pw.Text('Sales Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildTable(
        ['Product', 'Unit', 'Quantity', 'Revenue'],
        state.data.map((item) => [
          item.productName,
          item.unit,
          item.totalQuantity.toStringAsFixed(2),
          currencyFormat.format(item.totalRevenue),
        ]).toList(),
      ),
    ];
  }

  // ── Daily Purchase ───────────────────────────────────────────
  static List<pw.Widget> _buildDailyPurchaseContent(DailyPurchaseReportLoaded state) {
    return [
      _buildSummaryRow([
        _summaryCard('Total Cost', currencyFormat.format(state.totalCost), PdfColor.fromHex('#1565C0')),
        _summaryCard('Total Quantity', '${state.totalQuantity.toStringAsFixed(2)} units', PdfColor.fromHex('#2E7D32')),
        _summaryCard('Transactions', '${state.totalTransactions}', PdfColor.fromHex('#E65100')),
      ]),
      pw.SizedBox(height: 16),
      pw.Text('Purchase Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildTable(
        ['Product', 'Unit', 'Quantity', 'Cost'],
        state.data.map((item) => [
          item.productName,
          item.unit,
          item.totalQuantity.toStringAsFixed(2),
          currencyFormat.format(item.totalCost),
        ]).toList(),
      ),
    ];
  }

  // ── Mandi Profit ─────────────────────────────────────────────
  static List<pw.Widget> _buildMandiProfitContent(MandiProfitReportLoaded state) {
    return [
      _buildSummaryRow([
        _summaryCard('Total Profit', currencyFormat.format(state.totalProfit), PdfColor.fromHex('#2E7D32')),
        _summaryCard('Total Revenue', currencyFormat.format(state.totalRevenue), PdfColor.fromHex('#1565C0')),
        _summaryCard('Total Cost', currencyFormat.format(state.totalCost), PdfColor.fromHex('#C62828')),
      ]),
      pw.SizedBox(height: 16),
      pw.Text('Daily Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildTable(
        ['Date', 'Revenue', 'Cost', 'Profit'],
        state.data.map((item) => [
          item.date,
          currencyFormat.format(item.dailyRevenue),
          currencyFormat.format(item.dailyCost),
          currencyFormat.format(item.dailyProfit),
        ]).toList(),
      ),
    ];
  }

  // ── Pending Payment ──────────────────────────────────────────
  static List<pw.Widget> _buildPendingPaymentContent(PendingPaymentReportLoaded state) {
    return [
      _summaryCard('Total Pending', currencyFormat.format(state.totalPendingAmount), PdfColor.fromHex('#C62828')),
      pw.SizedBox(height: 16),
      pw.Text('Pending Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildTable(
        ['Customer', 'Phone', 'Bills', 'Pending Amount', 'Days'],
        state.data.map((item) => [
          item.customerName,
          item.customerPhone,
          '${item.totalBills}',
          currencyFormat.format(item.pendingAmount),
          '${item.daysPending}',
        ]).toList(),
      ),
    ];
  }

  // ── Customer Ledger ──────────────────────────────────────────
  static List<pw.Widget> _buildCustomerLedgerContent(CustomerLedgerReportLoaded state) {
    return [
      _summaryCard('Net Balance', currencyFormat.format(state.totalNetBalance),
          state.totalNetBalance >= 0 ? PdfColor.fromHex('#2E7D32') : PdfColor.fromHex('#C62828')),
      pw.SizedBox(height: 16),
      pw.Text('Customer Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildTable(
        ['Customer', 'Phone', 'Purchases', 'Sales', 'Net Balance'],
        state.data.map((item) => [
          item.customerName,
          item.customerPhone,
          currencyFormat.format(item.totalPurchases),
          currencyFormat.format(item.totalSales),
          currencyFormat.format(item.netBalance),
        ]).toList(),
      ),
    ];
  }
}
