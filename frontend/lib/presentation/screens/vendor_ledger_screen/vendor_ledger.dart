import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/providers/vendor_ledger_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';

import '../../../src/models/vendor_ledger/vendor_ledger_model.dart';
import '../../../src/services/ledger_pdf_service.dart';

class VendorLedgerScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorLedgerScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorLedgerScreen> createState() => _VendorLedgerScreenState();
}

class _VendorLedgerScreenState extends State<VendorLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLedger();
    });
  }

  Future<void> _loadLedger() async {
    final provider = context.read<VendorLedgerProvider>();
    await provider.loadVendorLedger(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECE9), // Matches screenshot background
      body: Consumer<VendorLedgerProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(2.w, 4.h, 2.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryMaroon),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Ledger Module',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10.w), // Align with title
                        child: Text(
                          'Manage your Financial Record',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Cards Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Total Outstanding Balance',
                        provider.summary?.formattedClosingBalance ?? 'Rs. 0',
                        context,
                      ),
                      SizedBox(width: 2.w),
                      _buildSummaryCard(
                        'Total Collected',
                        provider.summary?.formattedTotalCredits ?? 'Rs. 0',
                        context,
                      ),
                      SizedBox(width: 2.w),
                      _buildSummaryCard(
                        'Total OVERDUE',
                        provider.summary?.formattedTotalDebits ?? 'Rs. 0',
                        context,
                      ),
                    ],
                  ),
                ),
              ),

              // Search and Filters Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 8.h,
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
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 1.w),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Month Selection
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Month-wise Selection',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              height: 6.h,
                              padding: EdgeInsets.symmetric(horizontal: 1.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMonth,
                                  isExpanded: true,
                                  icon: const Icon(Icons.calendar_today, size: 18),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedMonth = newValue;
                                      });
                                      
                                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                      final monthIndex = monthNames.indexOf(newValue) + 1;
                                      final now = DateTime.now();
                                      final startOfMonth = DateTime(now.year, monthIndex, 1);
                                      final endOfMonth = DateTime(now.year, monthIndex + 1, 0);
                                      
                                      context.read<VendorLedgerProvider>().loadVendorLedger(
                                        vendorId: widget.vendorId,
                                        vendorName: widget.vendorName,
                                        startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
                                        endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
                                      );
                                    }
                                  },
                                  items: <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Export Button
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Export to Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF679DAA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Table Headers
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('Ref #', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('Paid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('Dues', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      ],
                    ),
                  ),
                ),
              ),

              // Ledger List
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon)),
                )
              else if (provider.ledgerEntries.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No entries found')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = provider.ledgerEntries[index];
                      return _buildLedgerRow(entry, context);
                    },
                    childCount: provider.ledgerEntries.length,
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(VendorLedgerEntry entry, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('yyyy-MM-dd').format(entry.date),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.sp),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                entry.referenceNumber ?? 'General',
                style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                entry.description,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                entry.debit > 0 ? NumberFormat('#,##0').format(entry.debit) : '-',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                entry.credit > 0 ? NumberFormat('#,##0').format(entry.credit) : '-',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp, color: Colors.green),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                NumberFormat('#,##0').format(entry.balance),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildStatusBadge('Paid'), // Vendor ledger entry model might not have status, default to Paid
            ),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () {
                  LedgerPdfService.printTransactionSlip({
                    'date': DateFormat('yyyy-MM-dd').format(entry.date),
                    'invoice_number': entry.referenceNumber,
                    'description': entry.description,
                    'debit': entry.debit,
                    'status': 'Paid',
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Print',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 10.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text = status;
    
    switch (status.trim().toUpperCase()) {
      case 'PARTIAL':
        color = const Color(0xFFE57373);
        text = 'Partial';
        break;
      case 'PAID':
        color = const Color(0xFF26A69A);
        text = 'Paid';
        break;
      case 'OVERDUE':
        color = const Color(0xFF00796B);
        text = 'Overdue';
        break;
      case 'PENDING':
      case 'ISSUED':
        color = const Color(0xFFFE813E);
        text = 'Pending';
        break;
      case 'UNPAID':
      case 'SEND':
        color = const Color(0xFFD32F2F);
        text = 'Unpaid';
        break;
      default:
        color = Colors.grey;
        text = status.isEmpty ? 'N/A' : status;
    }

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
