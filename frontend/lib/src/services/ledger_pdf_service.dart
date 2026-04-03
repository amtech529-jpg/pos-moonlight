import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class LedgerPdfService {
  static const String companyName = 'Moon Light Events';

  static String _mapStatus(String status) {
    status = status.trim().toUpperCase();
    if (status == 'PAID') return 'Paid';
    if (status == 'ISSUED' || status == 'PENDING') return 'Pending';
    if (status == 'UNPAID' || status == 'SEND' || status == 'SENT') return 'Unpaid';
    if (status == 'PARTIAL') return 'Partial';
    if (status == 'OVERDUE') return 'Overdue';
    return status.isEmpty ? 'N/A' : status;
  }

  /// Print a single ledger entry (Transaction Slip)
  static Future<void> printTransactionSlip(Map<String, dynamic> entry) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt style
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.Divider(),
              pw.Text('TRANSACTION SLIP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              _buildRow('Date:', entry['date']?.toString() ?? 'N/A'),
              _buildRow('Reference:', entry['category'] ?? entry['invoice_number'] ?? 'N/A'),
              _buildRow('Description:', entry['description'] ?? 'N/A'),
              pw.Divider(),
              _buildRow('Amount:', (entry['debit'] ?? '0').toString(), isBold: true),
              _buildRow('Status:', _mapStatus(entry['status']?.toString() ?? 'N/A')),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Transaction_${entry['id']}',
    );
  }

  /// Print the entire Ledger Statement
  static Future<void> printLedgerStatement({
    required List<dynamic> entries,
    required Map<String, dynamic> summary,
    String? title,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(title ?? 'General Ledger Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (subtitle != null) pw.Text(subtitle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.grey)),
        ),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Invoiced', 'Rs. ${NumberFormat("#,##0").format(summary['total_invoiced'] ?? summary['total_debit'] ?? 0)}'),
                _buildSummaryItem('Total Paid', 'Rs. ${NumberFormat("#,##0").format(summary['total_paid'] ?? summary['total_credit'] ?? 0)}'),
                _buildSummaryItem('Outstanding', 'Rs. ${NumberFormat("#,##0").format(summary['total_due'] ?? summary['outstanding_balance'] ?? 0)}', isLast: true),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Table
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Invoice/Ref', 'Description', 'Amount', 'Status'],
            data: entries.map((e) => [
              e['date']?.toString() ?? 'N/A',
              e['invoice_number'] ?? e['reference_number'] ?? 'N/A',
              e['description'] ?? e['customer_name'] ?? 'N/A',
              'Rs. ${NumberFormat("#,##0").format(e['total_amount'] ?? e['debit'] ?? 0)}',
              _mapStatus(e['status']?.toString() ?? (e['is_overdue'] == true ? 'Overdue' : 'N/A')),
            ]).toList(),
          ),
        ],
      ),
    );

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Ledger_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, {bool isLast = false}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
