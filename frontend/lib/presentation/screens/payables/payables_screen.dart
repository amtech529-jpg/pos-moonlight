import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/models/payable/payable_model.dart';

import '../../widgets/payables/add_payable_dialog.dart';
import '../../widgets/payables/edit_payable_dialog.dart';
import '../../../l10n/app_localizations.dart';

class PayablesPage extends StatefulWidget {
  const PayablesPage({super.key});

  @override
  State<PayablesPage> createState() => _PayablesPageState();
}

class _PayablesPageState extends State<PayablesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  void _showAddPayableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddPayableDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PayablesProvider>();
      provider.loadPayables();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit global pinkish/beige background
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: 24),

            // Stats row (5 cards for Payables as per screenshot)
            _buildStatsRow(),

            const SizedBox(height: 32),

            // Search Bar Section
            _buildSearchSection(),

            const SizedBox(height: 48),

            // Payables Table
            _buildPayablesTable(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Partner/payable Module",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage all your Payables",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _showAddPayableDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222222),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            "+ Add Partner",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Consumer<PayablesProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;
        
        String totalPartners = "0";
        String totalPayable = "0";
        String totalAmount = "Rs. 0";
        String paidThisMonth = "Rs. 0"; 
        String activePartner = "0";

        if (stats != null) {
          totalPartners = stats.totalPayables.toString(); 
          totalPayable = stats.pendingPayables.toString();
          totalAmount = "Rs. ${stats.totalOutstandingAmount.toStringAsFixed(0)}";
          paidThisMonth = "Rs. ${stats.totalPaidAmount.toStringAsFixed(0)}"; 
          activePartner = stats.overduePayables.toString();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummaryCard("Total Payables", totalPartners, Icons.person_outline),
                   const SizedBox(width: 12),
                   _buildSummaryCard("Pending Payables", totalPayable, Icons.trending_up_rounded, valueColor: Colors.black),
                   const SizedBox(width: 12),
                   _buildSummaryCard("Total Paid", paidThisMonth, Icons.description_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard("Total Outstanding", totalAmount, Icons.trending_down_rounded, iconColor: Colors.green),
                const SizedBox(width: 12),
                _buildSummaryCard("Overdue Amount", "Rs. ${stats?.overdueAmount.toStringAsFixed(0) ?? '0'}", Icons.warning_amber_rounded, iconColor: Colors.red),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, {Color? valueColor, Color? iconColor}) {
    return Container(
      width: 185,
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ),
              ),
              Icon(
                icon,
                size: 24,
                color: iconColor ?? Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              onChanged: (value) => context.read<PayablesProvider>().setSearchQuery(value),
              decoration: InputDecoration(
                filled: true,
                fillColor: _searchFocusNode.hasFocus 
                    ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                    : const Color(0xFFE8E8E8),
                hintText: "Search Partner or item...",
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFBBBBBB),
                  size: 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayablesTable() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<PayablesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (provider.payables.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("No payables found"),
          ));
        }

        return Column(
          children: [
            // Table Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(l10n.creditorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)))),
                  Expanded(flex: 2, child: Text(l10n.reasonItem, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)))),

                  Expanded(flex: 2, child: Text(l10n.amountBorrowed, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)))),
                  Expanded(flex: 2, child: Text(l10n.paid, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)))),
                  Expanded(flex: 2, child: Text(l10n.balanceRemaining.replaceAll(':', ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)))),
                  Expanded(flex: 2, child: Text(l10n.status, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text(l10n.actions, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Rows from provider
            ...provider.payables.map((payable) {
               return _buildPayableRow(payable);
            }),
            const SizedBox(height: 24),
            // Total Summary Container at the bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    "Total Outstanding Balance",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Rs. ${provider.statistics?.totalOutstandingAmount.toStringAsFixed(0) ?? '0'}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF40FF76),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPayableRow(Payable payable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(flex: 3, child: Text(payable.creditorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black))),
          Expanded(flex: 2, child: Text(payable.reasonOrItem, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF444444)))),

          Expanded(flex: 2, child: Text("Rs. ${payable.amountBorrowed.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)))),
          Expanded(flex: 2, child: Text("Rs. ${payable.amountPaid.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)))),
          Expanded(flex: 2, child: Text("Rs. ${payable.balanceRemaining.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)))),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 120,
                height: 32,
                decoration: BoxDecoration(
                  color: payable.statusColorValue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: payable.statusColorValue.withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    payable.statusText,
                    style: TextStyle(color: payable.statusColorValue.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF222222), size: 28),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => EditPayableDialog(payable: payable), // We will create this
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
