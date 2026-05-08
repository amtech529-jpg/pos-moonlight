import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dispatch/dispatch_form_model.dart';

class PdfGatePassService {
  static const String companyName = 'MOON LIGHT EVENTS';
  static const String officeAddress = 'Al-Hamra Town Phase 2, Raiwand Road, Lahore';
  static const String contactNo = '0324-4580401, 0324-4580402';

  static Future<Uint8List> generatePdfBytes(DispatchFormModel form) async {
    final pdf = pw.Document();
    final order = form.orderDetails;
    
    // Load Logo
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
                            pw.Image(logoImage, height: 60)
                          else
                            pw.Text("MOONLIGHT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 5),
                          pw.Text(companyName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      // Gate Pass Title
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            color: PdfColors.grey300,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                            child: pw.Text(
                              "GATE PASS",
                              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text("Gate Pass #: ${form.id.length > 8 ? form.id.substring(0, 8).toUpperCase() : 'NEW'}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (order != null)
                            pw.Text("Order #: ${order.orderNumber}", style: pw.TextStyle(fontSize: 10)),
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
                          pw.Expanded(child: _buildInfoRow("Customer:", order?.businessName != null ? "${order!.businessName} (${order.clientName ?? order.customerName})" : (order?.customerName ?? form.customerDetails?['name'] ?? 'N/A'))),
                          pw.Expanded(child: _buildInfoRow("Date:", DateFormat('dd-MM-yyyy   hh:mm a').format(form.createdAt.toLocal()))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoRow("Event Name:", form.eventName ?? order?.eventName ?? 'N/A')),
                          pw.Expanded(child: _buildInfoRow("Dispatch Date:", form.dispatchDate != null ? DateFormat('dd-MM-yyyy').format(form.dispatchDate!) : (order?.dispatchDate != null ? DateFormat('dd-MM-yyyy').format(order!.dispatchDate!) : 'N/A'))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoRow("Location:", form.eventLocation ?? order?.eventLocation ?? 'N/A')),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.black, height: 1),

                // Dispatch Logistics Section
                pw.Container(
                  color: PdfColors.grey100,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoRow("Driver:", form.driverName)),
                          pw.Expanded(child: _buildInfoRow("Vehicle #:", form.vehicleNumber)),
                          pw.Expanded(child: _buildInfoRow("Vehicle Type:", form.vehicleType ?? 'N/A')),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildInfoRow("Staff Accompanying:", form.staffName)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.black, height: 1),

                // Items Table
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      // Table Header
                      pw.Container(
                        color: PdfColors.grey200,
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(width: 40, child: pw.Text("Sr#", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(left: 10), child: pw.Text("Item Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))),
                            pw.SizedBox(width: 70, child: pw.Text("Quantity", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.SizedBox(width: 70, child: pw.Text("Status", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.SizedBox(width: 50, child: pw.Text("Check", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          ],
                        ),
                      ),
                      // Table Rows
                      ...form.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(width: 40, child: pw.Text("${i + 1}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                              pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(left: 10), child: pw.Text(item.productName + (item.isExtra ? " (Partner Stock)" : ""), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
                              pw.SizedBox(width: 70, child: pw.Text("${item.quantity}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                              pw.SizedBox(width: 70, child: pw.Text(item.isExtra ? "PARTNER" : "OK", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                              pw.SizedBox(width: 50, child: pw.Center(child: pw.Container(width: 12, height: 12, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1))))),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Signature Area
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSignatureLine("Receiver's Signature"),
                      _buildSignatureLine("Driver's Signature"),
                      _buildSignatureLine("Authorized Signature"),
                    ],
                  ),
                ),

                // Footer Box
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    children: [
                      pw.Text("Address: $officeAddress", style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 2),
                      pw.Text("Contact: $contactNo", style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(width: 5),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
      ],
    );
  }

  static pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)))),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static Future<void> printGatePass(DispatchFormModel form) async {
    try {
      final Uint8List pdfBytes = await generatePdfBytes(form);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'GatePass_${form.id.substring(0, min(8, form.id.length)).toUpperCase()}.pdf',
      );
    } catch (e) {
      debugPrint('Error printing Gate Pass: $e');
    }
  }
}
