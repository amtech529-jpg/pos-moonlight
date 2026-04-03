import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/labor/salary_slip_model.dart';
import '../../utils/debug_helper.dart';

class SalarySlipPdfService {
  static const String companyName = 'Moon Light Events';
  
  /// Preview and print PDF salary slip
  static Future<void> previewAndPrintSlip(SalarySlip slip) async {
    try {
      DebugHelper.printInfo('SalarySlipPdfService', 'Opening PDF preview for salary slip: ${slip.id}');

      final pdf = pw.Document();

      // Load fonts
      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      // Build PDF content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(regularFont, boldFont),
                pw.SizedBox(height: 30),
                _buildSlipInfo(slip, regularFont, boldFont),
                pw.SizedBox(height: 25),
                _buildEmployeeInfo(slip, regularFont, boldFont),
                pw.SizedBox(height: 30),
                pw.Text('SALARY BREAKDOWN', 
                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.blue900)),
                pw.SizedBox(height: 10),
                _buildSalaryBreakdown(slip, regularFont, boldFont),
                pw.SizedBox(height: 40),
                _buildTotalsSection(slip, regularFont, boldFont),
                pw.Spacer(),
                _buildSignatures(regularFont, boldFont),
                pw.SizedBox(height: 30),
                _buildFooter(regularFont, boldFont),
              ],
            );
          },
        ),
      );

      // Generate PDF bytes
      final Uint8List pdfBytes = await pdf.save();

      // Show print preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'SalarySlip_${slip.laborName}_${slip.month}_${slip.year}'.replaceAll(' ', '_'),
      );
    } catch (e) {
      DebugHelper.printError('SalarySlipPdfService', e);
      rethrow;
    }
  }

  static pw.Widget _buildHeader(pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          companyName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'OFFICIAL SALARY SLIP',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
              color: PdfColors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Divider(thickness: 1, color: PdfColors.blue900),
      ],
    );
  }

  static pw.Widget _buildSlipInfo(SalarySlip slip, pw.Font regularFont, pw.Font boldFont) {
    final monthName = DateFormat('MMMM').format(DateTime(slip.year, slip.month));
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('REFERENCE NUMBER', style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700)),
            pw.Text(slip.referenceNumber ?? slip.id.substring(0, 8).toUpperCase(), 
              style: pw.TextStyle(font: boldFont, fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Text('PAYMENT PERIOD', style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700)),
            pw.Text('$monthName ${slip.year}', 
              style: pw.TextStyle(font: boldFont, fontSize: 13)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ISSUE DATE', style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700)),
            pw.Text(DateFormat('dd MMMM yyyy').format(slip.salaryDate), 
              style: pw.TextStyle(font: boldFont, fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Text('PAYMENT STATUS', style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: slip.status == 'PAID' ? PdfColors.green100 : PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(slip.status, 
                style: pw.TextStyle(
                  font: boldFont, 
                  fontSize: 11,
                  color: slip.status == 'PAID' ? PdfColors.green900 : PdfColors.orange900,
                )),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEmployeeInfo(SalarySlip slip, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('EMPLOYEE DETAILS', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Full Name', style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(slip.laborName.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.black)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Designation', style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(slip.laborDesignation, style: pw.TextStyle(font: boldFont, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: slip.laborCnic != null ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CNIC Number', style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(slip.laborCnic!, style: pw.TextStyle(font: regularFont, fontSize: 12)),
                  ],
                ) : pw.SizedBox(),
              ),
              pw.Expanded(
                flex: 1,
                child: slip.laborPhone != null ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Phone Number', style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(slip.laborPhone!, style: pw.TextStyle(font: regularFont, fontSize: 12)),
                  ],
                ) : pw.SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSalaryBreakdown(SalarySlip slip, pw.Font regularFont, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildCell('DESCRIPTION', boldFont, textAlign: pw.TextAlign.left, fontSize: 10),
            _buildCell('EARNINGS', boldFont, fontSize: 10),
            _buildCell('DEDUCTIONS', boldFont, fontSize: 10),
          ],
        ),
        pw.TableRow(
          children: [
            _buildCell('Basic Salary', regularFont, textAlign: pw.TextAlign.left),
            _buildCell(NumberFormat('#,##0.00').format(slip.baseSalary), regularFont),
            _buildCell('-', regularFont),
          ],
        ),
        pw.TableRow(
          children: [
            _buildCell('Fixed Incentives / Bonuses', regularFont, textAlign: pw.TextAlign.left),
            _buildCell(NumberFormat('#,##0.00').format(slip.bonuses), regularFont),
            _buildCell('-', regularFont),
          ],
        ),
        pw.TableRow(
          children: [
            _buildCell('Salary Advances', regularFont, textAlign: pw.TextAlign.left),
            _buildCell('-', regularFont),
            _buildCell(NumberFormat('#,##0.00').format(slip.totalAdvances), regularFont),
          ],
        ),
        pw.TableRow(
          children: [
            _buildCell('Late / Absence Deductions', regularFont, textAlign: pw.TextAlign.left),
            _buildCell('-', regularFont),
            _buildCell(NumberFormat('#,##0.00').format(slip.deductions), regularFont),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalsSection(SalarySlip slip, pw.Font regularFont, pw.Font boldFont) {
    final totalEarnings = slip.baseSalary + slip.bonuses;
    final totalDeductions = slip.totalAdvances + slip.deductions;
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gross Earnings:', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  pw.Text(NumberFormat('#,##0.00').format(totalEarnings), style: pw.TextStyle(font: regularFont, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Deductions:', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  pw.Text('(${NumberFormat('#,##0.00').format(totalDeductions)})', style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.red900)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NET PAYABLE:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.black)),
                  pw.Text(
                    'PKR ${NumberFormat('#,##0.00').format(slip.netSalary)}',
                    style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue900)
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures(pw.Font regularFont, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 50),
            pw.Container(
              width: 180,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 1.0),
                ),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Text('Employee Signature', style: pw.TextStyle(font: regularFont, fontSize: 10)),
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 50),
            pw.Container(
              width: 180,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 1.0),
                ),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Text('Authorized Signature', style: pw.TextStyle(font: regularFont, fontSize: 10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'Thank you for your hard work and dedication to $companyName.',
            style: pw.TextStyle(fontSize: 9, font: regularFont, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated salary slip and does not require a physical stamp unless specified.',
            style: pw.TextStyle(fontSize: 8, font: regularFont, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCell(String text, pw.Font font, {pw.TextAlign textAlign = pw.TextAlign.center, double fontSize = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: fontSize), textAlign: textAlign),
    );
  }
}
