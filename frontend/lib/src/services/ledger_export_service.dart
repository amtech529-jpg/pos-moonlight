import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class LedgerExportService {
  static Future<String?> exportToExcel(List<dynamic> entries, Map<String, dynamic> totals) async {
    try {
      final excel = Excel.createExcel();
      
      // Use the default sheet to ensure it's the first one the user sees
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      var sheet = excel[defaultSheet];
      
      // Clean previous data if any (though it's a new instance)
      // Just start writing
      
      // Add Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'General Ledger Report';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

      // Summary
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Summary';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Invoiced';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = (totals['total_invoiced'] ?? 0.0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Paid';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = (totals['total_paid'] ?? 0.0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Total Due';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = (totals['total_due'] ?? 0.0);

      // Table Headers
      final headers = ['Date', 'Invoice Number', 'Customer Name', 'Total Amount', 'Amount Paid', 'Write-Off Amount', 'Amount Due', 'Due Date', 'Status'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8)).value = headers[i];
      }

      // Data
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final row = i + 9;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = entry['date']?.toString() ?? 'N/A';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = entry['invoice_number']?.toString() ?? 'N/A';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = entry['customer_name']?.toString() ?? 'N/A';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = (entry['total_amount'] ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = (entry['amount_paid'] ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = (entry['write_off_amount'] ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = (entry['amount_due'] ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = entry['due_date']?.toString().split('T')[0] ?? 'N/A';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = entry['status']?.toString() ?? 'N/A';
      }

      // Save file to Temporary directory for immediate opening
      final output = await getTemporaryDirectory();
      final fileName = 'ledger_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final filePath = path.join(output.path, fileName);
      final file = File(filePath);
      
      final bytes = excel.encode();
      if (bytes == null) throw Exception("Failed to encode Excel file");
      
      await file.writeAsBytes(bytes);
      
      // Small delay to ensure OS file system has finalized the write
      await Future.delayed(const Duration(milliseconds: 500));

      return filePath;
    } catch (e) {
      print('Error exporting ledger to Excel: $e');
      return null;
    }
  }

  static Future<String?> exportCustomerLedgerToExcel({
    required String customerName,
    required List<dynamic> entries, // Using dynamic to avoid hard dependency on models here
    required dynamic summary,
  }) async {
    try {
      final excel = Excel.createExcel();
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      var sheet = excel[defaultSheet];
      
      // Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Customer Ledger Report: $customerName';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

      // Summary Section
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Summary Statistics';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Billed (Sales/Invoices)';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = summary.totalReceivables;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Collected (Payments)';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = summary.totalPayments;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Outstanding Balance';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = summary.outstandingBalance;

      // Table Headers
      final headers = ['Date', 'Reference #', 'Description', 'Debit (Billed)', 'Credit (Paid)', 'Balance', 'Status'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8)).value = headers[i];
      }

      // Data Rows
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final row = i + 9;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = DateFormat('yyyy-MM-dd').format(entry.date);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = entry.referenceNumber ?? '-';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = entry.description;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = entry.debit;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = entry.credit;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = entry.balance;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = entry.status ?? '-';
      }

      // File Saving
      final output = await getTemporaryDirectory();
      final fileName = 'customer_ledger_${customerName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final filePath = path.join(output.path, fileName);
      final file = File(filePath);
      
      final bytes = excel.encode();
      if (bytes == null) throw Exception("Failed to encode Excel file");
      
      await file.writeAsBytes(bytes);
      await Future.delayed(const Duration(milliseconds: 500));

      return filePath;
    } catch (e) {
      print('Error exporting customer ledger to Excel: $e');
      return null;
    }
  }

  static Future<void> openExportedFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      debugPrint('📂 OpenFile result for $filePath: ${result.type} - ${result.message}');
      
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      print('Error opening exported ledger file: $e');
      rethrow;
    }
  }
}
