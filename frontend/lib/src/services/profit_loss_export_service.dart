import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/profit_loss/profit_loss_models.dart';
import '../theme/app_theme.dart';

class ProfitLossExportService {
  static const String _companyName = 'Moon Light Events';
  static const String _companyAddress = '';
  static const String _companyPhone = '';
  static const String _companyEmail = '';

  /// Export Profit & Loss report to PDF
  static Future<String?> exportToPDF({
    required ProfitLossRecord profitLoss,
    required List<ProductProfitability> productProfitability,
    required ProfitLossDashboard? dashboardData,
    String? customPeriod,
  }) async {
    try {
      final pdf = pw.Document();

      // Add pages
      pdf.addPage(_buildSummaryPage(profitLoss, customPeriod));

      if (productProfitability.isNotEmpty) {
        pdf.addPage(_buildProductAnalysisPage(productProfitability));
      }

      if (dashboardData != null) {
        pdf.addPage(_buildDashboardPage(dashboardData));
      }

      pdf.addPage(_buildDetailedBreakdownPage(profitLoss));

      // Save PDF
      final output = await getTemporaryDirectory();
      final fileName = 'profit_loss_report_${_getFormattedDate(DateTime.now())}.pdf';
      final file = File(path.join(output.path, fileName));
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error exporting to PDF: $e');
      return null;
    }
  }

  /// Export Profit & Loss report to Excel
  static Future<String?> exportToExcel({
    required ProfitLossRecord profitLoss,
    required List<ProductProfitability> productProfitability,
    required ProfitLossDashboard? dashboardData,
    String? customPeriod,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Summary Sheet
      _addSummarySheet(excel, profitLoss, customPeriod);

      // Product Analysis Sheet
      if (productProfitability.isNotEmpty) {
        _addProductAnalysisSheet(excel, productProfitability);
      }

      // Dashboard Sheet
      if (dashboardData != null) {
        _addDashboardSheet(excel, dashboardData);
      }

      // Detailed Breakdown Sheet
      _addDetailedBreakdownSheet(excel, profitLoss);

      // Save Excel file
      final output = await getTemporaryDirectory();
      final fileName = 'profit_loss_report_${_getFormattedDate(DateTime.now())}.xlsx';
      final file = File(path.join(output.path, fileName));
      await file.writeAsBytes(excel.encode()!);

      return file.path;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  /// Build PDF Summary Page
  static pw.Page _buildSummaryPage(ProfitLossRecord profitLoss, String? customPeriod) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildSummarySection(profitLoss, customPeriod),
            pw.SizedBox(height: 20),
            _buildKeyMetrics(profitLoss),
            pw.SizedBox(height: 20),
            _buildProfitabilityIndicators(profitLoss),
          ],
        );
      },
    );
  }

  /// Build PDF Product Analysis Page
  static pw.Page _buildProductAnalysisPage(List<ProductProfitability> products) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Product Profitability Analysis',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 15),
            _buildProductTable(products),
          ],
        );
      },
    );
  }

  /// Build PDF Dashboard Page
  static pw.Page _buildDashboardPage(ProfitLossDashboard dashboard) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Business Dashboard',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 15),
            _buildDashboardMetrics(dashboard),
          ],
        );
      },
    );
  }

  /// Build PDF Detailed Breakdown Page
  static pw.Page _buildDetailedBreakdownPage(ProfitLossRecord profitLoss) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Detailed Breakdown',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 15),
            _buildDetailedBreakdown(profitLoss),
          ],
        );
      },
    );
  }

  /// Build PDF Header
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Profit & Loss Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
              ),
              pw.Text('Generated: ${_getFormattedDateTime(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Summary Section
  static pw.Widget _buildSummarySection(ProfitLossRecord profitLoss, String? customPeriod) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Period Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Period Type: ${customPeriod ?? profitLoss.periodTypeDisplay}')),
              pw.Expanded(child: pw.Text('From: ${_formatDate(profitLoss.startDate)}')),
              pw.Expanded(child: pw.Text('To: ${_formatDate(profitLoss.endDate)}')),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Key Metrics
  static pw.Widget _buildKeyMetrics(ProfitLossRecord profitLoss) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Key Financial Metrics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              _buildMetricCard('Total Income', profitLoss.formattedTotalIncome, PdfColors.green),
              pw.SizedBox(width: 10),
              _buildMetricCard('Total Expenses', profitLoss.formattedTotalExpenses, PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildMetricCard('Gross Profit', profitLoss.formattedGrossProfit, PdfColors.blue),
              pw.SizedBox(width: 10),
              _buildMetricCard('Net Profit', profitLoss.formattedNetProfit, profitLoss.isProfitable ? PdfColors.green : PdfColors.red),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Metric Card
  static pw.Widget _buildMetricCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          border: pw.Border.all(color: color),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Profitability Indicators
  static pw.Widget _buildProfitabilityIndicators(ProfitLossRecord profitLoss) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Profitability Indicators',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Gross Profit Margin: ${profitLoss.formattedGrossProfitMargin}')),
              pw.Expanded(child: pw.Text('Net Profit Margin: ${profitLoss.formattedProfitMargin}')),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Expense Ratio: ${(profitLoss.totalExpensesCalculated / profitLoss.totalSalesIncome * 100).toStringAsFixed(1)}%'),
              ),
              pw.Expanded(child: pw.Text('Status: ${profitLoss.isProfitable ? "Profitable" : "Loss"}')),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Product Table
  static pw.Widget _buildProductTable(List<ProductProfitability> products) {
    final headers = ['Rank', 'Product', 'Category', 'Units Sold', 'Revenue', 'Cost', 'Profit', 'Margin %'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(80),
        2: pw.FixedColumnWidth(60),
        3: pw.FixedColumnWidth(50),
        4: pw.FixedColumnWidth(60),
        5: pw.FixedColumnWidth(60),
        6: pw.FixedColumnWidth(60),
        7: pw.FixedColumnWidth(50),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map(
                (header) => pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...products
            .take(20)
            .map(
              (product) => pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('#${product.profitabilityRank}')),
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(product.productName, maxLines: 2)),
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(product.productCategory)),
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(product.unitsSold.toString())),
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(product.formattedTotalRevenue)),
                  pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('PKR ${product.totalCost.toStringAsFixed(0)}')),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(5),
                    child: pw.Text(product.formattedGrossProfit, style: pw.TextStyle(color: product.isProfitable ? PdfColors.green : PdfColors.red)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(5),
                    child: pw.Text(product.formattedProfitMargin, style: pw.TextStyle(color: product.isProfitable ? PdfColors.green : PdfColors.red)),
                  ),
                ],
              ),
            )
            .toList(),
      ],
    );
  }

  /// Build Dashboard Metrics
  static pw.Widget _buildDashboardMetrics(ProfitLossDashboard dashboard) {
    return pw.Column(
      children: [
        _buildDashboardCard('Growth Metrics', [
          'Sales Growth: ${dashboard.growthMetrics.salesGrowth.toStringAsFixed(1)}%',
          'Expense Growth: ${dashboard.growthMetrics.expenseGrowth.toStringAsFixed(1)}%',
          'Profit Growth: ${dashboard.growthMetrics.profitGrowth.toStringAsFixed(1)}%',
        ]),
        pw.SizedBox(height: 15),
        _buildDashboardCard('Business Trends', ['Sales Trend: ${dashboard.trends.salesTrend}', 'Profit Trend: ${dashboard.trends.profitTrend}']),
        pw.SizedBox(height: 15),
        _buildDashboardCard('Expense Breakdown', [
          'Labor: PKR ${dashboard.expenseBreakdown.laborPayments.toStringAsFixed(0)}',
          'Vendors: PKR ${dashboard.expenseBreakdown.vendorPayments.toStringAsFixed(0)}',
          'Other: PKR ${dashboard.expenseBreakdown.otherExpenses.toStringAsFixed(0)}',
          'Zakat: PKR ${dashboard.expenseBreakdown.zakat.toStringAsFixed(0)}',
        ]),
      ],
    );
  }

  /// Build Dashboard Card
  static pw.Widget _buildDashboardCard(String title, List<String> items) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 10),
          ...items
              .map(
                (item) => pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(item, style: pw.TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  /// Build Detailed Breakdown
  static pw.Widget _buildDetailedBreakdown(ProfitLossRecord profitLoss) {
    return pw.Column(
      children: [
        _buildBreakdownCard('Income Sources', ['Sales Income: ${profitLoss.formattedTotalIncome}', 'Products Sold: ${profitLoss.totalProductsSold}']),
        pw.SizedBox(height: 15),
        _buildBreakdownCard('Expense Categories', [
          'Labor Payments: PKR ${profitLoss.totalLaborPayments.toStringAsFixed(0)}',
          'Vendor Payments: PKR ${profitLoss.totalVendorPayments.toStringAsFixed(0)}',
          'Other Expenses: PKR ${profitLoss.totalExpensesCalculated.toStringAsFixed(0)}',
          'Zakat: PKR ${profitLoss.totalZakat.toStringAsFixed(0)}',
        ]),
        pw.SizedBox(height: 15),
        _buildBreakdownCard('Calculation Details', [
          'Gross Profit = Income - COGS',
          'Net Profit = Gross Profit - Total Expenses',
          'Profit Margin = (Net Profit / Income) × 100',
        ]),
      ],
    );
  }

  /// Build Breakdown Card
  static pw.Widget _buildBreakdownCard(String title, List<String> items) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 10),
          ...items
              .map(
                (item) => pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(item, style: pw.TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  /// Add Summary Sheet to Excel
  static void _addSummarySheet(Excel excel, ProfitLossRecord profitLoss, String? customPeriod) {
    final sheet = excel['Summary'];

    // Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Profit & Loss Summary';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Generated: ${_getFormattedDateTime(DateTime.now())}';

    // Period Information
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Period Information';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Period Type';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = customPeriod ?? profitLoss.periodTypeDisplay;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Start Date';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = _formatDate(profitLoss.startDate);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'End Date';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = _formatDate(profitLoss.endDate);

    // Financial Summary
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8)).value = 'Financial Summary';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = 'Total Income';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9)).value = profitLoss.totalSalesIncome;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = 'Total Expenses';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value = profitLoss.totalExpenses;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).value = 'Gross Profit';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11)).value = profitLoss.grossProfit;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).value = 'Net Profit';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).value = profitLoss.netProfit;

    // Profitability Metrics
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14)).value = 'Profitability Metrics';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 15)).value = 'Gross Profit Margin';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 15)).value = '${profitLoss.grossProfitMarginPercentage.toStringAsFixed(2)}%';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 16)).value = 'Net Profit Margin';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 16)).value = '${profitLoss.profitMarginPercentage.toStringAsFixed(2)}%';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 17)).value = 'Expense Ratio';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 17)).value =
        '${(profitLoss.totalExpensesCalculated / profitLoss.totalSalesIncome * 100).toStringAsFixed(2)}%';
  }

  /// Add Product Analysis Sheet to Excel
  static void _addProductAnalysisSheet(Excel excel, List<ProductProfitability> products) {
    final sheet = excel['Product Analysis'];

    // Headers
    final headers = ['Rank', 'Product Name', 'Category', 'Units Sold', 'Revenue', 'Cost', 'Profit', 'Margin %', 'Status'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
    }

    // Data
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = product.profitabilityRank;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = product.productName;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = product.productCategory;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = product.unitsSold;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = product.totalRevenue;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = product.totalCost;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = product.grossProfit;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = product.profitMargin;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = product.isProfitable ? 'Profitable' : 'Loss';
    }
  }

  /// Add Dashboard Sheet to Excel
  static void _addDashboardSheet(Excel excel, ProfitLossDashboard dashboard) {
    final sheet = excel['Dashboard'];

    // Growth Metrics
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Growth Metrics';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Sales Growth';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = '${dashboard.growthMetrics.salesGrowth.toStringAsFixed(1)}%';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Expense Growth';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = '${dashboard.growthMetrics.expenseGrowth.toStringAsFixed(1)}%';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Profit Growth';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = '${dashboard.growthMetrics.profitGrowth.toStringAsFixed(1)}%';

    // Trends
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Business Trends';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Sales Trend';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = dashboard.trends.salesTrend;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = 'Profit Trend';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = dashboard.trends.profitTrend;

    // Expense Breakdown
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = 'Expense Breakdown';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = 'Labor Payments';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value = dashboard.expenseBreakdown.laborPayments;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).value = 'Vendor Payments';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11)).value = dashboard.expenseBreakdown.vendorPayments;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).value = 'Other Expenses';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).value = dashboard.expenseBreakdown.otherExpenses;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13)).value = 'Zakat';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 13)).value = dashboard.expenseBreakdown.zakat;
  }

  /// Add Detailed Breakdown Sheet to Excel
  static void _addDetailedBreakdownSheet(Excel excel, ProfitLossRecord profitLoss) {
    final sheet = excel['Detailed Breakdown'];

    // Source Records
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Source Records';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Sales Records';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = profitLoss.totalProductsSold;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = profitLoss.totalSalesIncome;

    // Expense Details
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Expense Details';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Labor Payments';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = profitLoss.totalLaborPayments;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Vendor Payments';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = profitLoss.totalVendorPayments;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = 'Other Expenses';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = profitLoss.totalExpenses;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = 'Zakat';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = profitLoss.totalZakat;

    // Calculation Formula
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = 'Calculation Formula';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = 'Gross Profit = Income - COGS';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value =
        '${profitLoss.totalSalesIncome} - ${profitLoss.totalCostOfGoodsSold} = ${profitLoss.grossProfit}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11)).value = 'Net Profit = Gross Profit - Total Expenses';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11)).value =
        '${profitLoss.grossProfit} - ${profitLoss.totalExpenses} = ${profitLoss.netProfit}';
  }

  /// Show export format selection dialog
  static Future<String?> showExportFormatDialog() async {
    // This method will be called from the provider, but the actual dialog
    // will be shown by the UI layer using ProfitLossExportDialog
    // For now, return null to indicate no format selected
    return null;
  }

  /// Open exported file
  static Future<void> openExportedFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  /// Utility methods
  static String _getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String _getFormattedDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
