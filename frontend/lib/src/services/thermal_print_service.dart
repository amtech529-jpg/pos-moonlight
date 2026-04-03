import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart' as esc;
import 'package:flutter/services.dart';

class ThermalPrintService {
  static const PaperSize paperSize = PaperSize.mm58;
  static const CapabilityProfile profile = CapabilityProfile();

  /// Print thermal receipt using the printing package
  static Future<bool> printThermalReceipt(Map<String, dynamic> thermalData) async {
    try {
      // Generate ESC/POS bytes from thermal data
      final bytes = await _generateThermalReceiptBytes(thermalData);
      
      // Print using the printing package
      await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: 'Thermal Receipt',
        format: format,
      );
      
      return true;
    } catch (e) {
      print('Error printing thermal receipt: $e');
      return false;
    }
  }

  /// Generate ESC/POS bytes for thermal receipt
  static Future<Uint8List> _generateThermalReceiptBytes(Map<String, dynamic> thermalData) async {
    final generator = Generator(paperSize, profile);
    
    final receipt = thermalData['sale'];
    final items = thermalData['items'] as List;
    final company = thermalData['company'];
    
    List<int> bytes = [];
    
    // Reset printer
    bytes += generator.reset();
    
    // Company header
    bytes += generator.text(
      company['name'] ?? 'Moon Light Events',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        width: PosTextSize.size2,
        height: PosTextSize.size2,
      ),
    );
    
    bytes += generator.text(
      company['address'] ?? '',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      company['phone'] ?? '',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    bytes += generator.hr();
    
    // Receipt details
    bytes += generator.text(
      'Invoice: ${receipt['invoice_number']}',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text('Date: ${receipt['date_of_sale']}');
    bytes += generator.text('Customer: ${receipt['customer_name']}');
    if (receipt['customer_phone'] != null && receipt['customer_phone'].isNotEmpty) {
      bytes += generator.text('Phone: ${receipt['customer_phone']}');
    }
    
    bytes += generator.hr();
    
    // Table header
    bytes += generator.row([
      PosColumn(
        text: 'Item',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'Qty',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      PosColumn(
        text: 'Price',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: 'Total',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    // Items
    for (var item in items) {
      final itemName = item['name'] as String;
      final quantity = item['quantity'] as int;
      final unitPrice = item['unit_price'] as double;
      final total = item['total'] as double;
      
      // Split long item names if needed
      if (itemName.length > 8) {
        bytes += generator.row([
          PosColumn(text: itemName.substring(0, 8), width: 8),
          PosColumn(text: quantity.toString(), width: 3, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: unitPrice.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: total.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
        
        if (itemName.length > 8) {
          bytes += generator.row([
            PosColumn(text: itemName.substring(8), width: 8),
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 6),
            PosColumn(text: '', width: 6),
          ]);
        }
      } else {
        bytes += generator.row([
          PosColumn(text: itemName, width: 8),
          PosColumn(text: quantity.toString(), width: 3, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: unitPrice.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: total.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }
    
    bytes += generator.hr();
    
    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 17, styles: const PosStyles(align: PosAlign.right)),
      PosColumn(text: receipt['subtotal'].toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    if (receipt['overall_discount'] > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 17, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: '-${receipt['overall_discount'].toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    if (receipt['tax_amount'] > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax:', width: 17, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: receipt['tax_amount'].toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.hr(ch: '=', len: 23);
    
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 17,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: receipt['grand_total'].toStringAsFixed(0),
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);
    
    bytes += generator.hr(ch: '=', len: 23);
    
    // Payment info
    bytes += generator.text('Payment: ${receipt['payment_method']}');
    bytes += generator.row([
      PosColumn(text: 'Paid:', width: 17, styles: const PosStyles(align: PosAlign.right)),
      PosColumn(text: receipt['amount_paid'].toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    if (receipt['remaining_amount'] > 0) {
      bytes += generator.row([
        PosColumn(text: 'Due:', width: 17, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: receipt['remaining_amount'].toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.hr();
    
    // Footer
    bytes += generator.text(
      'Thank you for shopping!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'No Return / Exchange without receipt',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Visit us again!',
      styles: const PosStyles(align: PosAlign.center),
    );
    
    // Add some blank lines
    bytes += generator.feed(3);
    
    // Cut paper
    bytes += generator.cut();
    
    return Uint8List.fromList(bytes);
  }

  /// Print directly to available printer
  static Future<bool> printDirectly(Map<String, dynamic> thermalData) async {
    try {
      // Get available printers
      final printers = await Printing.listPrinters();
      
      if (printers.isEmpty) {
        print('No printers found');
        return false;
      }
      
      // Find thermal printer (usually contains "thermal" or "receipt" in name)
      var thermalPrinter = printers.firstWhere(
        (printer) => 
          printer.name.toLowerCase().contains('thermal') ||
          printer.name.toLowerCase().contains('receipt') ||
          printer.name.toLowerCase().contains('pos'),
        orElse: () => printers.first, // fallback to first available printer
      );
      
      // Generate ESC/POS bytes
      final bytes = await _generateThermalReceiptBytes(thermalData);
      
      // Print directly
      await Printing.directPrintPdf(
        printer: thermalPrinter,
        onLayout: (format) async => bytes,
        name: 'Thermal Receipt',
      );
      
      return true;
    } catch (e) {
      print('Error printing directly: $e');
      return false;
    }
  }

  /// Check if thermal printers are available
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      
      // Filter for thermal/POS printers
      final thermalPrinters = printers.where((printer) => 
        printer.name.toLowerCase().contains('thermal') ||
        printer.name.toLowerCase().contains('receipt') ||
        printer.name.toLowerCase().contains('pos')
      ).toList();
      
      return thermalPrinters;
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }
}
