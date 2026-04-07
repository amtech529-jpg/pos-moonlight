import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_button.dart'; // PremiumButton
import '../../widgets/purchases/purchase_table.dart';
import '../../widgets/purchases/add_purchase_dialog.dart';
import '../../widgets/purchases/purchase_filter_dialog.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // Local state for the current filter
  PurchaseFilter _activeFilter = PurchaseFilter();
  final FocusNode _searchFocusNode = FocusNode(); 
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Use post-frame callback for safer initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PurchaseProvider>().initialize();
      }
    });
  }

  /// Opens the filter dialog and updates the local filter state
  void _showFilterDialog() async {
    final result = await showDialog<PurchaseFilter>(
      context: context,
      builder: (context) => PurchaseFilterDialog(initialFilter: _activeFilter),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _activeFilter.searchQuery = value;
      });
    });
  }

  /// Opens the dialog to record a new inventory purchase
  void _showAddPurchaseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddPurchaseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Purchase', 'add') ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _refreshPurchases,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24), // Using standard padding
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context, l10n, canAdd),
  
              const SizedBox(height: 32),
  
              // Statistics Summary Cards
              _buildSummaryRow(context, l10n),
  
              const SizedBox(height: 32),
  
              // Search and Filter Row
              _buildSearchAndFilterRow(context, l10n),
  
              if (_activeFilter.vendorId != null || _activeFilter.status != null || _activeFilter.startDate != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_activeFilter.vendorId != null)
                      Chip(
                        label: const Text("Vendor Filter active"),
                        onDeleted: () => setState(() => _activeFilter.vendorId = null),
                      ),
                    if (_activeFilter.status != null)
                      Chip(
                        label: Text("Status: ${_activeFilter.status}"),
                        onDeleted: () => setState(() => _activeFilter.status = null),
                      ),
                    ActionChip(
                      label: const Text("Reset All Filters"),
                      avatar: const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: () => setState(() => _activeFilter = PurchaseFilter()),
                    ),
                  ],
                ),
              ],
  
              const SizedBox(height: 32),
  
              // Main Data Section: Purchase List Table
              PurchaseTable(filter: _activeFilter),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshPurchases() async {
    await context.read<PurchaseProvider>().initialize();
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool canAdd) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    
    final headerContent = [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Purchase",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your all Purchase record",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        if (!isWide) const SizedBox(height: 16),
        // Primary Action: New Purchase
        if (canAdd)
          ElevatedButton.icon(
            onPressed: _showAddPurchaseDialog,
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text(
              "Add Purchase",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(160, 50),
            ),
          ),
    ];

    return isWide 
        ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: headerContent)
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: headerContent);
  }

  Widget _buildSummaryRow(BuildContext context, AppLocalizations l10n) {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, child) {
        final totalInvoices = provider.purchases.length;
        final totalInvestment = provider.purchases.fold(0.0, (sum, p) => sum + p.total);
        
        int totalItemsCount = 0;
        for (var p in provider.purchases) {
          totalItemsCount += p.items.length;
        }

        bool isNarrow = MediaQuery.of(context).size.width < 1100;
        
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                   Expanded(child: _buildStatCard(title: "Total Records", value: totalItemsCount.toString(), icon: Icons.menu_book_outlined)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildStatCard(title: "Total Investment", value: "Rs. ${totalInvestment.toStringAsFixed(0)}", icon: Icons.analytics_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildStatCard(title: "Total Invoices", value: totalInvoices.toString(), icon: Icons.receipt_outlined)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildStatCard(title: "Total Records", value: totalItemsCount.toString(), icon: Icons.menu_book_outlined)),
            const SizedBox(width: 20),
            Expanded(child: _buildStatCard(title: "Total Investment", value: "Rs. ${totalInvestment.toStringAsFixed(0)}", icon: Icons.analytics_outlined)),
            const SizedBox(width: 20),
            Expanded(child: _buildStatCard(title: "Total Invoices", value: totalInvoices.toString(), icon: Icons.receipt_outlined)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool hasBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasBorder ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: const Color(0xFFEEEEEE),
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow(BuildContext context, AppLocalizations l10n) {
    bool isWide = MediaQuery.of(context).size.width > 700;
    
    final searchBar = Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            cursorColor: Colors.black,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 15, color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: _searchFocusNode.hasFocus 
                  ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                  : const Color(0xFFE8E8E8),
              hintText: l10n.search,
              hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF8E8E8E)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged("");
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );

    final filterButton = GestureDetector(
      onTap: _showFilterDialog,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              offset: Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Text(
              l10n.filter,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );

    return isWide 
        ? Row(
            children: [
              Expanded(child: searchBar),
              const SizedBox(width: 16),
              filterButton,
            ],
          )
        : Column(
            children: [
              searchBar,
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: filterButton),
            ],
          );
  }
}