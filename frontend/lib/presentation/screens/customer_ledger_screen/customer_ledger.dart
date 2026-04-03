import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/providers/customer_ledger_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';

import '../../../src/models/customer_ledger/customer_ledger_model.dart';
import '../../../src/services/ledger_pdf_service.dart';
import '../../../src/services/ledger_export_service.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMonth;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLedger();
    });
  }

  Future<void> _loadLedger() async {
    final provider = context.read<CustomerLedgerProvider>();
    await provider.loadCustomerLedger(
      customerId: widget.customerId,
      customerName: widget.customerName,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECE9),
      body: Consumer<CustomerLedgerProvider>(
        builder: (context, provider, child) {
          // Filter entries by search
          final filteredEntries = _searchQuery.isEmpty
              ? provider.ledgerEntries
              : provider.ledgerEntries.where((e) {
                  final q = _searchQuery.toLowerCase();
                  return e.description.toLowerCase().contains(q) ||
                      (e.referenceNumber?.toLowerCase().contains(q) ?? false);
                }).toList();

          return Column(
            children: [
              // ─── Header ─────────────────────────────────────────────────
              _buildHeader(context),

              // ─── Summary Cards ───────────────────────────────────────────
              _buildSummaryCards(context, provider),

              // ─── How it works legend ─────────────────────────────────────
              _buildLegend(context),

              // ─── Search + Month Filter Bar ───────────────────────────────
              _buildFilterBar(context, provider),

              // ─── Table Header ────────────────────────────────────────────
              _buildTableHeader(context),

              // ─── Table Rows ──────────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon))
                    : filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No transactions found' : 'No results for "$_searchQuery"',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredEntries.length,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemBuilder: (context, index) {
                              return _buildLedgerRow(filteredEntries[index], context, index);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customerName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                'Customer Ledger',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 24),
            onPressed: () => _exportToExcel(context),
            tooltip: 'Export to Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final provider = context.read<CustomerLedgerProvider>();
    if (provider.ledgerEntries.isEmpty || provider.summary == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ledger data to export')),
        );
      }
      return;
    }

    try {
      final filePath = await LedgerExportService.exportCustomerLedgerToExcel(
        customerName: widget.customerName,
        entries: provider.ledgerEntries,
        summary: provider.summary!,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ledger exported: ${filePath.split('\\').last}'),
            backgroundColor: Colors.green.shade700,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => LedgerExportService.openExportedFile(filePath),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate Excel file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY CARDS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCards(BuildContext context, CustomerLedgerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          _summaryCard(
            'Total Billed',
            provider.summary?.formattedTotalReceivables ?? 'Rs. 0',
            Icons.receipt_long,
            Colors.red.shade600,
            'Total amount of sales/invoices',
          ),
          const SizedBox(width: 8),
          _summaryCard(
            'Total Collected',
            provider.summary?.formattedTotalPayments ?? 'Rs. 0',
            Icons.payments,
            Colors.green.shade600,
            'Total payment received',
          ),
          const SizedBox(width: 8),
          _summaryCard(
            'Balance Due',
            provider.summary?.formattedOutstandingBalance ?? 'Rs. 0',
            Icons.account_balance_wallet,
            AppTheme.primaryMaroon,
            'Remaining unpaid amount',
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, String tooltip) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HOW IT WORKS LEGEND
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLegend(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Amount = sale/invoice billed  •  Paid = payment received  •  Dues = remaining balance',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILTER BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterBar(BuildContext context, CustomerLedgerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search description or ref...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: Colors.grey[500]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Month Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                hint: const Text('Month', style: TextStyle(fontSize: 13)),
                icon: const Icon(Icons.calendar_month, size: 16),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedMonth = newValue);
                    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final monthIndex = monthNames.indexOf(newValue) + 1;
                    final now = DateTime.now();
                    final startOfMonth = DateTime(now.year, monthIndex, 1);
                    final endOfMonth = DateTime(now.year, monthIndex + 1, 0);
                    context.read<CustomerLedgerProvider>().filterLedger(
                          startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
                          endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
                        );
                  }
                },
                items: <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 13)));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reset button (if month is selected)
          if (_selectedMonth != null)
            GestureDetector(
              onTap: () {
                setState(() => _selectedMonth = null);
                _loadLedger();
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(Icons.clear, size: 18, color: Colors.red.shade400),
              ),
            ),

          const SizedBox(width: 8),

          // Refresh
          GestureDetector(
            onTap: _loadLedger,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
              ),
              child: Icon(Icons.refresh, size: 18, color: AppTheme.primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TABLE HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTableHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.15)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 3, child: Text('Ref #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 3, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 3, child: Text('Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 3, child: Text('Dues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          Expanded(flex: 3, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryMaroon))),
          SizedBox(width: 36),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TABLE ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLedgerRow(CustomerLedgerEntry entry, BuildContext context, int index) {
    final isDebit = entry.debit > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isDebit ? Colors.red.shade300 : Colors.green.shade400,
            width: 3,
          ),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 3,
            child: Text(
              DateFormat('dd/MM/yy').format(entry.date),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          // Ref #
          Expanded(
            flex: 3,
            child: Text(
              entry.referenceNumber ?? '-',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Description
          Expanded(
            flex: 4,
            child: Text(
              entry.description,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Amount (debit = what customer owes — red)
          Expanded(
            flex: 3,
            child: Text(
              entry.debit > 0 ? NumberFormat('#,##0').format(entry.debit) : '-',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade700),
            ),
          ),

          // Paid (credit = what customer paid — green)
          Expanded(
            flex: 3,
            child: Text(
              entry.credit > 0 ? NumberFormat('#,##0').format(entry.credit) : '-',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
            ),
          ),

          // Dues (running balance)
          Expanded(
            flex: 3,
            child: Text(
              NumberFormat('#,##0').format(entry.balance),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: entry.balance > 0 ? AppTheme.primaryMaroon : Colors.green.shade700,
              ),
            ),
          ),

          // Status badge
          Expanded(flex: 3, child: _buildStatusBadge(entry.status ?? '')),

          // Print
          SizedBox(
            width: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.print_outlined, size: 18, color: Colors.blueGrey),
              onPressed: () {
                LedgerPdfService.printTransactionSlip({
                  'date': DateFormat('yyyy-MM-dd').format(entry.date),
                  'invoice_number': entry.referenceNumber,
                  'description': entry.description,
                  'debit': entry.debit,
                  'credit': entry.credit,
                  'status': entry.status,
                });
              },
              tooltip: 'Print slip',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS BADGE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.trim().toUpperCase()) {
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
        color = Colors.blue;
        text = 'Partial';
        break;
      case 'PAID':
        color = const Color(0xFF26A69A);
        text = 'Paid';
        break;
      case 'OVERDUE':
        color = Colors.red.shade800;
        text = 'Overdue';
        break;
      case 'PENDING':
      case 'ISSUED':
        color = const Color(0xFFFE813E);
        text = 'Pending';
        break;
      case 'UNPAID':
      case 'SENT':
      case 'SEND':
        color = const Color(0xFFD32F2F);
        text = 'Unpaid';
        break;
      case 'CLOSED':
        color = Colors.blueGrey;
        text = 'Closed';
        break;
      case 'WRITTEN_OFF':
        color = Colors.indigo;
        text = 'Written Off';
        break;
      default:
        color = Colors.grey;
        text = status.isEmpty ? '-' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11, // Fixed - was 7.sp (too small)
        ),
      ),
    );
  }
}
