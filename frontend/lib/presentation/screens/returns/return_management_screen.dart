import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/providers/rental_return_provider.dart';
import '../../../src/models/rental_return_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/returns/add_return_dialog.dart';
import '../../widgets/returns/tally_return_dialog.dart';
import '../../widgets/returns/recovery_dialog.dart';

class ReturnManagementScreen extends StatefulWidget {
  const ReturnManagementScreen({super.key});

  @override
  State<ReturnManagementScreen> createState() => _ReturnManagementScreenState();
}

class _ReturnManagementScreenState extends State<ReturnManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedMonths = 6; // Default to 6 months as per requirements
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _debounce;

  void _showAddReturnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddReturnDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = context.read<RentalReturnProvider>();
    
    // Calculate date range based on _selectedMonths
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month - _selectedMonths, now.day);
    _endDate = now;

    await provider.loadReturns(
      startDate: _startDate,
      endDate: _endDate,
      search: _searchController.text,
    );
    await provider.loadStatistics();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData();
    });
  }

  void _onMonthFilterChanged(int months) {
    setState(() {
      _selectedMonths = months;
    });
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            // Stats row (5 cards for Return & Tally as per screenshot)
            _buildStatsRow(),

            const SizedBox(height: 32),

            // Search Bar Section
            _buildSearchSection(),

            const SizedBox(height: 48),

            // Returns Table
            _buildReturnsTable(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummaryGrid(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Returns & Damages Summary",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem("Partner Returns", stats['partner_returns'] ?? "0", const Color(0xFF40C4FF)),
              _buildDivider(),
              _buildSummaryItem("Damage Items", stats['damage_items'] ?? "0", const Color(0xFFFF5252)),
              _buildDivider(),
              _buildSummaryItem("Damage Cost", stats['damage_cost'] ?? "Rs. 0", const Color(0xFFFFAB40)),
              _buildDivider(),
              _buildSummaryItem("Successful Recovery", stats['successful_recoveries'] ?? "Rs. 0", const Color(0xFF40FF76)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withOpacity(0.1),
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
              "Return & Tally",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage and track equipment returns",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildPeriodFilter(),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _showAddReturnDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "+ Add Return",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [3, 6, 12].map((m) {
          final isSelected = _selectedMonths == m;
          return GestureDetector(
            onTap: () => _onMonthFilterChanged(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryMaroon : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$m M",
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<RentalReturnProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        return GridView.count(
          crossAxisCount: context.shouldShowCompactLayout ? 2 : 5,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _buildSummaryCard("Partner Returns", stats['partner_returns'] ?? "0", Icons.people_alt_outlined, iconColor: Colors.blue),
            _buildSummaryCard("Damage Items", stats['damage_items'] ?? "0", Icons.report_problem_outlined, iconColor: Colors.red),
            _buildSummaryCard("Overall Loss", stats['damage_cost'] ?? "Rs. 0", Icons.account_balance_wallet_outlined, iconColor: Colors.orange),
            _buildSummaryCard("Total Recovered", stats['successful_recoveries'] ?? "Rs. 0", Icons.check_circle_outline, iconColor: Colors.green),
            _buildSummaryCard("Pending Claims", stats['pending_claims'] ?? "0", Icons.hourglass_empty_rounded, iconColor: Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, {Color? valueColor, Color? iconColor}) {
    return Container(
      width: 200, // Increased width to match others
      height: 120, // Increased height
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
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
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ),
              ),
              Icon(
                icon,
                size: 28,
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
              onChanged: _onSearchChanged,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: _searchFocusNode.hasFocus 
                    ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                    : const Color(0xFFE8E8E8),
                hintText: "Search Damaged item or Partner...",
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFBBBBBB),
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFFBBBBBB)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
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

  Widget _buildReturnsTable() {
    return Consumer<RentalReturnProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (provider.error != null && provider.returns.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
          ));
        }

        return Column(
          children: [
            // Table Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2), // Reverted to light grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 4, child: Text("Customer / Order", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)))),
                  Expanded(flex: 4, child: Text("Items Details", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)))),
                  Expanded(flex: 2, child: Text("Sent/Ret", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Dmg / Mis", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Dmg Charge", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Status", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: Text("Actions", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (provider.returns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_return_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No returns found for the selected period",
                        style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...provider.returns.map((r) => _buildReturnRow(r)),

            const SizedBox(height: 24),
            _buildBottomSummaryGrid(provider.stats),
          ],
        );
      },
    );
  }

  Widget _buildReturnRow(RentalReturnModel r) {
    String formattedDate = "${r.returnDate.day}/${r.returnDate.month}/${r.returnDate.year}";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Customer & Order Info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    r.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "#${r.orderNumber.split('-').last}", 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items Summary
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.itemsSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF444444)),
                ),
                if (r.isStockRestored)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text("Stock Restored", style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Sent vs Returned Ratio
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${r.totalItemsReturned} / ${r.totalItemsSent}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const Text("Items", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          
          // Damages & Missing
          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _buildCountBadge(r.totalDamaged, Colors.red, Icons.report_problem)),
                  const SizedBox(width: 4),
                  Flexible(child: _buildCountBadge(r.totalMissing, Colors.orange, Icons.help_outline)),
                ],
              ),
            ),
          ),
          
          // Damage Charges
          Expanded(
            flex: 2,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rs. ${r.damageCharges.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 17, 
                    color: r.damageCharges > 0 ? Colors.red[700] : Colors.grey[400]
                  ),
                ),
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: r.statusColor.withOpacity(0.3)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    r.status,
                    style: TextStyle(color: r.statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    color: Colors.blue,
                    tooltip: "Tally Items",
                    onPressed: () => _showTallyDialog(r),
                  ),
                  if (!r.isStockRestored)
                    _buildActionButton(
                      icon: Icons.inventory_2_rounded,
                      color: Colors.green,
                      tooltip: "Restore Stock",
                      onPressed: () => _handleRestoreStock(r),
                    ),
                  _buildActionButton(
                    icon: Icons.payments_rounded,
                    color: Colors.orange,
                    tooltip: "Add Recovery",
                    onPressed: () => _showRecoveryDialog(r),
                  ),
                  // Delete button removed as per request
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, IconData icon) {
    if (count == 0) return const SizedBox.shrink();
    return Tooltip(
      message: "${icon == Icons.report_problem ? 'Damaged' : 'Missing'}: $count",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showTallyDialog(RentalReturnModel r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TallyReturnDialog(rentalReturn: r),
    );
  }

  void _showRecoveryDialog(RentalReturnModel r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryDialog(rentalReturn: r),
    );
  }

  void _handleRestoreStock(RentalReturnModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFBD0D1D)),
              const SizedBox(height: 16),
              const Text(
                "Restore Stock?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                "This will add returned items back to your inventory. This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("CONFIRM RESTORE", style: TextStyle(color: Color(0xFFBD0D1D), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<RentalReturnProvider>();
      final success = await provider.restoreStock(returnId: r.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Stock restored successfully", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        final errorMessage = (provider.error != null && provider.error!.isNotEmpty) 
            ? provider.error! 
            : "Failed to restore stock";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        provider.clearMessages();
      }
    }
  }

  void _handleDeleteReturn(RentalReturnModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "Delete Return?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to delete this return record? This cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("DELETE RECORD", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<RentalReturnProvider>();
      final success = await provider.deleteReturn(returnId: r.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Return deleted successfully", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        final errorMessage = (provider.error != null && provider.error!.isNotEmpty) 
            ? provider.error! 
            : "Failed to delete return record";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        provider.clearMessages();
      }
    }
  }
}
