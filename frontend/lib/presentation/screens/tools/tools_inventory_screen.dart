import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../src/models/product/product_model.dart';
import '../../../src/services/product_service.dart';
import '../../../src/utils/debug_helper.dart';
import '../../../src/providers/report_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../widgets/product/add_product_dialog.dart';

class ToolsInventoryScreen extends StatefulWidget {
  const ToolsInventoryScreen({super.key});

  @override
  State<ToolsInventoryScreen> createState() => _ToolsInventoryScreenState();
}

class _ToolsInventoryScreenState extends State<ToolsInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ProductService _productService = ProductService();

  List<ProductModel> _tools = [];
  bool _isLoading = true;
  String? _error;

  // ✅ Category Filter State
  String? _selectedCategory;
  List<String> _categories = [];

  // Summary Data
  double _totalInventoryValue = 0;
  int _lowStockCount = 0;
  double _monthlyUsage = 0;
  String _historyMode = 'Usage'; // 'Usage' or 'Re-orders'
  int _analysisMonths = 6;

  @override
  void initState() {
    super.initState();
    _fetchTools();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchAllReports();
    });
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchTools() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch products that are consumables
      final response = await _productService.getProducts(
        filters: const ProductFilters(
          isConsumable: true,
          // We can also include 'isRental: false' if tools are strictly non-rental
          // For now let's just use isConsumable as per backend logic
        ),
        pageSize: 100, // Fetch more items
      );

      if (response.success && response.data != null) {
        final tools = response.data!.products;
        
        // Calculate summary statistics
        double totalValue = 0;
        int lowStock = 0;
        double monthlyUsage = 0;
        
        for (var tool in tools) {
          totalValue += (tool.price * tool.quantity);
          if (tool.isLowStock || tool.isOutOfStock) {
            lowStock++;
          }
          monthlyUsage += tool.monthlyRevenue;
        }

        // ✅ Extract unique categories from tools list
        final cats = tools
            .map((t) => t.categoryName ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        if (mounted) {
          setState(() {
            _tools = tools;
            _categories = cats;
            _totalInventoryValue = totalValue;
            _lowStockCount = lowStock;
            _monthlyUsage = monthlyUsage;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      DebugHelper.printError('Fetch tools error', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load tools';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3E9E7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3E9E7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error: $_error", style: const TextStyle(color: Colors.red, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTools,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Tools & Consumables', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Tools & Consumables', 'edit') ?? true;

    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9E7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
              "Tool & Consumes Inventory",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your Tools here's",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),

            // Summary Cards Row
            Consumer<ReportProvider>(
              builder: (context, reportProvider, _) {
                // Sum up real monthly usage if available, otherwise fallback to calculated _monthlyUsage
                double realUsage = _monthlyUsage;
                if (reportProvider.toolUsageTrends.isNotEmpty) {
                  realUsage = (reportProvider.toolUsageTrends.last['revenue'] as num).toDouble();
                }

                return Row(
                  children: [
                    _buildSummaryCard("Total Inventory Value", currencyFormat.format(_totalInventoryValue)),
                    const SizedBox(width: 20),
                    _buildSummaryCard("Low Stock Alerts", "$_lowStockCount Items", hasAlert: _lowStockCount > 0),
                    const SizedBox(width: 20),
                    _buildSummaryCard("Monthly Usage", currencyFormat.format(realUsage)),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),

            // Action Row
            Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 64,
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
                              hintText: "Search by item name...",
                              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (value) {
                              // Use backend search if needed, currently just local filtering logic can be added or simple re-fetch
                              setState(() {}); 
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // ✅ Category Filter Button with Dropdown
                _buildCategoryFilterButton(height: 64),
                const SizedBox(width: 20),
                // Usage Filter
                _buildFilterButton(
                  "Last $_analysisMonths months Usage", 
                  width: 220, 
                  isOutline: true, 
                  height: 64,
                  onTap: () {
                    final nextMonths = _analysisMonths == 6 ? 12 : (_analysisMonths == 12 ? 3 : 6);
                    setState(() => _analysisMonths = nextMonths);
                    Provider.of<ReportProvider>(context, listen: false).fetchToolUsageReport(months: nextMonths);
                  }
                ),
                const SizedBox(width: 20),
                // Add Button
                if (canAdd)
                  _buildAddButton(height: 64),
              ],
            ),
            const SizedBox(height: 48),

            // Tools Table
            _buildToolsTable(canEdit),

            const SizedBox(height: 48),

            // Usage Analysis Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Usage Analysis",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton("Usage", _historyMode == 'Usage'),
                      _buildToggleButton("Re-orders", _historyMode == 'Re-orders'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ReportProvider>(
              builder: (context, reportProvider, _) {
                if (reportProvider.isLoading) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                return _buildAnalysisSection(reportProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, {bool hasAlert = false}) {
    return Expanded(
      child: Container(
        height: 120, // Increased slightly to accommodate larger font
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  fontWeight: FontWeight.w500, // Reduced from w600
                  color: Color(0xFF888888),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26, // Reduced from 30
                      fontWeight: FontWeight.w600, 
                      height: 1.0, 
                      letterSpacing: 0,
                      color: Colors.black,
                    ),
                  ),
                  if (hasAlert) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, {double width = 150, bool isOutline = false, double height = 87, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12),
            border: isOutline ? Border.all(color: const Color(0xFFE0E0E0), width: 2) : null,
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddToolDialog({ProductModel? product}) async {
    final result = await showDialog<ProductModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddProductDialog(
        initialIsConsumable: true,
        initialIsRental: false,
        product: product,
      ),
    );

    if (result != null) {
      _fetchTools();
      // Also refresh reports as quantity might have changed
      Provider.of<ReportProvider>(context, listen: false).fetchAllReports();
    }
  }

  Widget _buildAddButton({double height = 87}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddToolDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF679DAA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              "+ Add New Item",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Category Filter Dropdown Button
  Widget _buildCategoryFilterButton({double height = 64}) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 60),
      onSelected: (value) {
        setState(() {
          _selectedCategory = value == 'All' ? null : value;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'All',
          child: Row(
            children: [
              if (_selectedCategory == null)
                const Icon(Icons.check, size: 16, color: Color(0xFF679DAA)),
              if (_selectedCategory == null) const SizedBox(width: 6),
              const Text(
                'All Categories',
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: Colors.black, // ✅ Forced Black
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ..._categories.map(
          (cat) => PopupMenuItem<String>(
            value: cat,
            child: Row(
              children: [
                if (_selectedCategory == cat)
                  const Icon(Icons.check, size: 16, color: Color(0xFF679DAA)),
                if (_selectedCategory == cat) const SizedBox(width: 6),
                Text(
                  cat,
                  style: const TextStyle(
                    color: Colors.black, // ✅ Forced Black
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        height: height,
        width: 180,
        decoration: BoxDecoration(
          color: _selectedCategory != null
              ? const Color(0xFF679DAA).withOpacity(0.15)
              : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
          border: _selectedCategory != null
              ? Border.all(color: const Color(0xFF679DAA), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: _selectedCategory != null
                  ? const Color(0xFF679DAA)
                  : const Color(0xFF666666),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _selectedCategory ?? 'Category Filter',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _selectedCategory != null
                      ? const Color(0xFF679DAA)
                      : const Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_selectedCategory != null) ...
              [
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF679DAA)),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTable(bool canEdit) {
    final filteredTools = _tools.where((tool) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = tool.name.toLowerCase().contains(query);
      // ✅ Apply category filter
      final matchesCategory = _selectedCategory == null ||
          (tool.categoryName ?? '').toLowerCase() == _selectedCategory!.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)))),
              Expanded(flex: 2, child: Text("Current QTY", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Units", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Min", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Stock level", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Rows
        if (filteredTools.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text("No tools found", style: TextStyle(fontSize: 18, color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTools.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filteredTools[index];
              return _buildToolRow(item, canEdit);
            },
          ),
      ],
    );
  }

  Widget _buildToolRow(ProductModel item, bool canEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black))),
          Expanded(flex: 2, child: Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text("-", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black), textAlign: TextAlign.center)), // Units not available
          Expanded(flex: 2, child: Text(item.minStockThreshold.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black), textAlign: TextAlign.center)),
          Expanded(
            flex: 2, 
            child: Text(
              item.stockStatusDisplay, 
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: item.stockStatusColor), 
              textAlign: TextAlign.center
            )
          ),
          if (canEdit)
            Expanded(
              flex: 2,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAddToolDialog(product: item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888888), fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(ReportProvider provider) {
    final trends = provider.toolUsageTrends;
    final history = _historyMode == 'Usage' ? provider.toolUsageHistory : provider.reorderHistory;

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Chart from real data
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 180,
              child: trends.isEmpty 
                ? const Center(child: Text("No usage data available", style: TextStyle(color: Colors.grey)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trends.map((t) {
                      // Normalize height (max 150)
                      double maxVal = trends.map((e) => (e['quantity'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
                      if (maxVal == 0) maxVal = 1;
                      double h = (t['quantity'] as num).toDouble() / maxVal * 150;
                      return _buildAnalysisBar(t['month'] ?? '?', h.clamp(10, 150));
                    }).toList(),
                  ),
            ),
          ),
          const SizedBox(width: 48),
          // Mini Table from real data
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildMiniHeader(),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No recent history"),
                  )
                else
                  ...history.map((h) => _buildMiniRow(
                    h['date'] ?? '', 
                    "${h['quantity']} units", 
                    item: h['item'] ?? '',
                    status: _historyMode == 'Usage' ? (h['status'] ?? '') : (h['vendor'] ?? '')
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisBar(String month, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 50,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF679DAA),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888888)),
        ),
      ],
    );
  }

  Widget _buildMiniHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
          Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
          Expanded(flex: 2, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String date, String qty, {required String item, required String status}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black))),
          Expanded(flex: 3, child: Text(item, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(qty, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black), textAlign: TextAlign.center)),
          Expanded(
            flex: 2, 
            child: Text(
              status, 
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                fontSize: 12, 
                color: _historyMode == 'Usage' ? Colors.black : const Color(0xFF679DAA)
              ), 
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _historyMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF679DAA) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF888888),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
