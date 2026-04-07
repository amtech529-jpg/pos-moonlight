import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/sales/sale_model.dart';
import '../models/order/order_model.dart';
import '../providers/customer_provider.dart';

class PdfInvoiceService {
  static const String companyName = 'MOON LIGHT EVENTS';
  static const String officeAddress = 'Al-Hamra Town Phase 2, Raiwand Road, Lahore';
  static const String contactNo = '0324-4580401, 0324-4580402';
  static const String whatsappNo = '0324-4580401, 0324-4580402';
  static const String emailAddress = 'moonlightevents707@gmail.com';

  static Future<Uint8List> generatePdfBytes(SaleModel sale, {OrderModel? associatedOrder, Customer? customer}) async {
    final pdf = pw.Document();
    
    // Load Logo if available
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/moon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load logo: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              children: [
                // Header Area
                pw.Padding(
                  padding: const pw.EdgeInsets.all(15),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo and Company Name
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null)
                            pw.Image(logoImage, height: 80)
                          else
                            pw.Text("MOONLIGHT", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 5),
                          pw.Text(companyName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      // Quotation Title and Number
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            color: PdfColors.blue300,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                            child: pw.Text(
                              "Invoice",
                              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Row(
                            children: [
                              pw.Text("No#", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(width: 15),
                              pw.Text(
                                sale.invoiceNumber.isNotEmpty 
                                  ? sale.invoiceNumber 
                                  : "INV-${sale.id.toUpperCase()}", 
                                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.black, height: 1),
                
                // Info Section
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildInfoRow("Date:", DateFormat('dd-MM-yyyy').format(sale.dateOfSale)),
                          ),
                          pw.Expanded(
                            child: _buildInfoRow("Event:", associatedOrder?.eventName ?? (sale.notes?.isNotEmpty == true ? (sale.notes!.contains('\n') ? sale.notes!.split('\n').first : sale.notes!) : "N/A")),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildInfoRow("Bill To:", customer?.businessName ?? customer?.name ?? sale.customerName),
                          ),
                          pw.Expanded(
                            child: _buildInfoRow("Location:", associatedOrder?.eventLocation ?? "N/A"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.black, height: 1),

                // Table Area
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      // Vertical grid lines
                      pw.Row(
                        children: [
                          pw.Container(width: 40, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))), // Qty
                          pw.Expanded(child: pw.Container(decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black))))), // Description
                          pw.Container(width: 40, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))), // Days
                          pw.Container(width: 50, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))), // Event
                          pw.Container(width: 70, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))), // Rate
                          pw.Container(width: 80), // Amount
                        ],
                      ),
                      pw.Column(
                        children: [
                          // Persistent Table Header
                          pw.Container(
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.grey100,
                              border: pw.Border(
                                top: pw.BorderSide(color: PdfColors.black, width: 1),
                                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                              ),
                            ),
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              children: [
                                _buildHeaderCell("Qty", width: 40),
                                _buildHeaderCell("Description", isFlex: true, align: pw.TextAlign.left),
                                _buildHeaderCell("Days", width: 40),
                                _buildHeaderCell("Event", width: 50),
                                _buildHeaderCell("Rate", width: 70),
                                _buildHeaderCell("Amount", width: 80),
                              ],
                            ),
                          ),
                          // Items
                          ...sale.saleItems.map((item) => pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                            ),
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Row(
                              children: [
                                // Qty
                                pw.Container(width: 40, child: pw.Text("${item.quantity}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                                
                                // Description (Product Name + Notes)
                                pw.Expanded(child: pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 8),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(item.productName.isNotEmpty ? item.productName : "Item Details", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                      if (item.customizationNotes != null && 
                                          item.customizationNotes!.isNotEmpty && 
                                          !item.customizationNotes!.contains('From Quote Item'))
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.only(top: 2),
                                          child: pw.Text(item.customizationNotes!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                                        )
                                    ]
                                  ),
                                )),
                                
                                // Days
                                pw.Container(width: 40, child: pw.Text("${item.days > 0 ? item.days : 1}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9))),
                                
                                // Event Pricing? (Converted from pricingType)
                                pw.Container(width: 50, child: pw.Text(
                                  (item.pricingType == 'PER_EVENT' || item.pricingType == 'FIXED') ? "Yes" : "No", 
                                  textAlign: pw.TextAlign.center, 
                                  style: pw.TextStyle(fontSize: 9)
                                )),
                                
                                // Rate
                                pw.Container(width: 70, child: pw.Text(NumberFormat("#,##0").format(item.unitPrice), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9))),
                                
                                // Amount
                                pw.Container(width: 80, padding: const pw.EdgeInsets.only(right: 8), child: pw.Text(NumberFormat("#,##0").format(item.lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                              ],
                            ),
                          )).toList(),
                          
                          // If no items, show a placeholder row to avoid empty table lookup
                          if (sale.saleItems.isEmpty)
                            pw.Container(
                              padding: const pw.EdgeInsets.all(20),
                              child: pw.Center(child: pw.Text("No item details available", style: pw.TextStyle(color: PdfColors.grey500, fontStyle: pw.FontStyle.italic))),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Summary Row (Grand Total)
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 2)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(width: 40, height: 28, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))),
                          pw.Expanded(
                            child: pw.Container(
                              height: 28,
                              alignment: pw.Alignment.center,
                              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black))),
                              child: pw.Text(
                                "Grand Total", 
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
                              ),
                            ),
                          ),
                          pw.Container(
                            width: 80, 
                            height: 28,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 8),
                            child: pw.Text(
                              NumberFormat("#,##0").format(sale.grandTotal),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
                            ),
                          ),
                        ],
                      ),
                      // Paid / Balance rows
                      pw.Row(
                        children: [
                          pw.Container(width: 40, height: 24, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))),
                          pw.Expanded(
                            child: pw.Container(
                              height: 24,
                              alignment: pw.Alignment.center,
                              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black))),
                              child: pw.Text("Amount Paid", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                          pw.Container(
                            width: 80, 
                            height: 24,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 8),
                            child: pw.Text(NumberFormat("#,##0").format(sale.amountPaid), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Container(width: 40, height: 24, decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black)))),
                          pw.Expanded(
                            child: pw.Container(
                              height: 24,
                              alignment: pw.Alignment.center,
                              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black))),
                              child: pw.Text("Balance Due", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                          pw.Container(
                            width: 80, 
                            height: 24,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 8),
                            child: pw.Text(NumberFormat("#,##0").format(sale.remainingAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ],
                  )
                ),

                // Footer Box
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 2)),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildFooterRow("Office:", officeAddress),
                      _buildFooterRow("Contact No:", contactNo),
                      _buildFooterRow("Whatsapp No:", whatsappNo),
                      _buildFooterRow("Email Adress:", emailAddress, color: PdfColors.blue700),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Generate PDF bytes
    return await pdf.save();
  }

  static Future<void> printInvoice(SaleModel sale, {OrderModel? associatedOrder, Customer? customer}) async {
    final Uint8List pdfBytes = await generatePdfBytes(sale, associatedOrder: associatedOrder, customer: customer);

    // Sanitize filename for Windows compatibility (X-STRICT: Only Letters and Underline)
    String safeName = 'Invoice_${sale.invoiceNumber.isEmpty ? "Order" : sale.invoiceNumber}';
    safeName = safeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').trim();
    if (safeName.length > 30) safeName = safeName.substring(0, 30);

    // Show print preview
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '$safeName.pdf', // Forces .pdf extension for Windows
      );
    } catch (e) {
      debugPrint('Error showing PDF: $e');
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 55,
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text, {double? width, bool isFlex = false, pw.TextAlign align = pw.TextAlign.center}) {
    final cell = pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
    );
    
    if (isFlex) {
      return pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: cell));
    }
    return pw.SizedBox(width: width, child: cell);
  }

  static pw.Widget _buildFooterRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }
}

