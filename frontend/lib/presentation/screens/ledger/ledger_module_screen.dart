import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/ledger_provider.dart';
import '../../../src/services/ledger_export_service.dart';
import '../../../src/services/pdf_invoice_service.dart';
import '../../../src/services/sales_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../src/models/api_response.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/ledger_pdf_service.dart';
import '../../../src/utils/debug_helper.dart';

class LedgerModuleScreen extends StatefulWidget {
  const LedgerModuleScreen({super.key});

  @override
  State<LedgerModuleScreen> createState() => _LedgerModuleScreenState();
}

class _LedgerModuleScreenState extends State<LedgerModuleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  final SalesService _salesService = SalesService();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    
    // Fetch ledger data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    context.read<LedgerProvider>().loadLedger(
      startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
      endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF679DAA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _exportToExcel() async {
    bool loaderPopped = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final provider = context.read<LedgerProvider>();
      final path = await LedgerExportService.exportToExcel(
        provider.ledgerEntries,
        provider.totals,
      );
      
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loaderPopped = true;
      }

      if (path != null) {
        debugPrint('✅ Excel exported to: $path');
        await LedgerExportService.openExportedFile(path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Ledger exported successfully"),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: "Re-open",
                textColor: Colors.white,
                onPressed: () => LedgerExportService.openExportedFile(path),
              ),
            ),
          );
        }
      } else {
        throw Exception("Export service returned null path");
      }
    } catch (e) {
      if (mounted) {
        if (!loaderPopped) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Export failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice(Map<String, dynamic> item) async {
    final String? invoiceId = item['sale_id'] ?? item['id'];
    
    bool loaderPopped = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _salesService.generateInvoicePdf(invoiceId!);
      
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loaderPopped = true;
      }

      if (response.success && response.data != null) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => response.data!,
          name: 'Invoice_$invoiceId',
        );
      } else {
        // Fallback to local Print if server fails
        await LedgerPdfService.printTransactionSlip(item);
      }
    } catch (e) {
      if (mounted) {
        if (!loaderPopped) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        // Fallback to local Print if error occurs
        await LedgerPdfService.printTransactionSlip(item);
      }
    }
  }

  Color _getStatusColor(String status) {
    status = status.toUpperCase();
    if (status == 'PAID') return const Color(0xFF26A69A);
    if (status == 'ISSUED' || status == 'PENDING') return const Color(0xFFFE813E);
    if (status == 'PARTIAL') return Colors.blue;
    if (status == 'OVERDUE') return Colors.red;
    if (status == 'UNPAID' || status == 'SEND') return const Color(0xFFD32F2F);
    return Colors.grey;
  }

  String _getStatusText(String status) {
    status = status.trim().toUpperCase();
    if (status == 'PAID') return 'Paid';
    if (status == 'ISSUED' || status == 'PENDING') return 'Pending';
    if (status == 'UNPAID' || status == 'SEND' || status == 'SENT') return 'Unpaid';
    if (status == 'PARTIAL') return 'Partial';
    if (status == 'OVERDUE') return 'Overdue';
    return status.isEmpty ? 'N/A' : status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E9E7),
      body: Consumer<LedgerProvider>(
        builder: (context, provider, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          final currentUser = authProvider.currentUser;
          final bool canExport = currentUser?.canPerform('Ledger', 'view') ?? true;

          if (provider.isLoading && provider.ledgerEntries.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF679DAA)));
          }

          if (provider.errorMessage != null && provider.ledgerEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${provider.errorMessage}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(),
                    child: const Text("Retry"),
                  )
                ],
              ),
            );
          }

          final totals = provider.totals;
          final totalOutstanding = totals['total_due'] ?? 0.0;
          final totalCollected = totals['total_paid'] ?? 0.0;
          final totalOverdue = provider.totalOverdue;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Subtitle
                const Text(
                  "Ledger Module",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Manage your Financial Record",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),

                // Summary Cards Row
                Row(
                  children: [
                    _buildSummaryCard('Total Outstanding Balance', 'Rs. ${NumberFormat("#,##0").format(totalOutstanding)}'),
                    const SizedBox(width: 20),
                    _buildSummaryCard('Total Collected', 'Rs. ${NumberFormat("#,##0").format(totalCollected)}'),
                    const SizedBox(width: 20),
                    _buildSummaryCard('Total Overdues', 'Rs. ${NumberFormat("#,##0").format(totalOverdue)}'),
                  ],
                ),
                const SizedBox(height: 48),

                // Search and Controls Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 87,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                focusNode: _searchFocusNode,
                                controller: _searchController,
                                cursorColor: Colors.black,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(fontSize: 15, color: Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _searchFocusNode.hasFocus 
                                      ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                                      : const Color(0xFFE8E8E8),
                                  hintText: "Search by Invoice or Customer...",
                                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 24),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                                onChanged: (value) => provider.updateSearchQuery(value),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Month Selector
                    Expanded(
                      flex: 1,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectMonth(context),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: 87,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Month-wise Selection',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMMM yyyy').format(_selectedDate),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                  const Divider(height: 8, thickness: 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Export Button
                    if (canExport)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _exportToExcel(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 87,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF679DAA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '+ Export to Excel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 48),

                // Table Content
                _buildTableHeader(),
                const SizedBox(height: 12),
                provider.ledgerEntries.isEmpty 
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No ledger records found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ))
                  : _buildTableRows(provider.ledgerEntries),
                
                if (provider.isLoading && provider.ledgerEntries.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 3, child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 4, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 3, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 2, child: Text('Paid', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 2, child: Text('Write-Off', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 3, child: Text('Dues', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 3, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
          Expanded(flex: 2, child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF888888)))),
        ],
      ),
    );
  }

  Widget _buildTableRows(List<dynamic> entries) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final mappedItem = {
          'id': entry['id'],
          'date': entry['date'] ?? 'N/A',
          'category': entry['invoice_number'] ?? 'N/A',
          'description': entry['customer_name'] ?? 'N/A',
          'debit': 'Rs. ${NumberFormat("#,##0").format(entry['total_amount'] ?? 0)}',
          'paid': 'Rs. ${NumberFormat("#,##0").format(entry['amount_paid'] ?? 0)}',
          'writeoff': 'Rs. ${NumberFormat("#,##0").format(entry['write_off_amount'] ?? 0)}',
          'dues': 'Rs. ${NumberFormat("#,##0").format(entry['amount_due'] ?? 0)}',
          'status': entry['is_overdue'] == true ? 'Overdue' : _getStatusText(entry['status'] ?? 'N/A'),
          'statusColor': _getStatusColor(entry['is_overdue'] == true ? 'OVERDUE' : (entry['status'] ?? '')),
          'sale_id': entry['sale_id'],
          'order_id': entry['order_id'],
        };
        return _buildLedgerRow(mappedItem);
      },
    );
  }

  Widget _buildSummaryCard(String title, String amount) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black))),
          Expanded(flex: 3, child: Text(item['category'], style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11, color: Color(0xFF444444)))),
          Expanded(flex: 4, child: Text(item['description'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black))),
          Expanded(flex: 3, child: Text(item['debit'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black))),
          Expanded(flex: 2, child: Text(item['paid'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.green))),
          Expanded(flex: 2, child: Text(item['writeoff'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.orange))),
          Expanded(flex: 3, child: Text(item['dues'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black))),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: item['statusColor'].withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(item['status'], style: TextStyle(color: item['statusColor'], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.print, size: 18, color: Colors.blue),
                onPressed: () => _printInvoice(item),
                tooltip: 'Print Invoice',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
