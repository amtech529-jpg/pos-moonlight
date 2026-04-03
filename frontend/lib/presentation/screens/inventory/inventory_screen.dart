import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/inventory/real_time_inventory_widget.dart';
import '../../widgets/product/add_product_dialog.dart';
import '../../widgets/product/edit_product_dialog.dart';
import '../../widgets/product/delete_product_dialog.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategory = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Reduced range for faster browsing
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      initialEntryMode: DatePickerEntryMode.calendar, // Start with calendar view directly
      helpText: 'Select Reservation Dates',
      saveText: 'CHECK AVAILABILITY',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBD0D1D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyDates();
    }
  }

  void _applyDates() {
    final provider = context.read<ProductProvider>();
    final newFilters = provider.currentFilters.copyWith(
      startDate: _startDate,
      endDate: _endDate,
    );
    provider.applyFilters(newFilters);
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyDates();
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Fetch products to show in inventory and CLEAR SEARCH
    Future.microtask(() {
      final provider = context.read<ProductProvider>();
      provider.clearFilters(); // Reset search/filters when opening inventory
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProductDialog(),
    );
  }

  void _showEditProductDialog(dynamic product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProductDialog(product: product),
    );
  }

  void _showDeleteProductDialog(dynamic product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteProductDialog(product: product),
    );
    
    if (confirmed == true && mounted) {
      // Refresh the product list after deletion
      context.read<ProductProvider>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Inventory', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Inventory', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('Inventory', 'delete') ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9E7), // Matches the pinkish background in screenshot
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductProvider>().initialize(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(canAdd),
              const SizedBox(height: 32),
              // Responsive Search and Filter Section
              if (MediaQuery.of(context).size.width > 900)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSearchSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildDateFilterSection()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSearchSection(),
                    const SizedBox(height: 20),
                    _buildDateFilterSection(),
                  ],
                ),
              const SizedBox(height: 32),
              _buildInventoryTable(context, canEdit, canDelete),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool canAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventory Management",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            Text(
              "Manage your rental equipment and items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
            ),
          ],
        ),
        // if (canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddProductDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Black button as in screenshot
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "+Add Item",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: TextField(
            focusNode: _searchFocusNode,
            controller: _searchController,
            cursorColor: Colors.black,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
            onChanged: (val) {
              setState(() {});
              context.read<ProductProvider>().searchProducts(val);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: _searchFocusNode.hasFocus ? const Color(0xFFD9D9D9).withOpacity(0.7) : const Color(0xFFE8E8E8),
              hintText: "Search Inventory...",
              hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E8E), size: 22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterSection() {
    final bool hasDates = _startDate != null && _endDate != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RENTAL AVAILABILITY",
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 12, 
              letterSpacing: 1.2,
              color: hasDates ? const Color(0xFFBD0D1D) : const Color(0xFF666666)
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: hasDates ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasDates ? Colors.black : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded, 
                          color: hasDates ? Colors.white : const Color(0xFF8E8E8E), 
                          size: 18
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasDates 
                              ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                              : "Select Event Dates",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasDates ? Colors.white : const Color(0xFF666666),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasDates) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDates,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFBD0D1D)),
                  tooltip: "Reset",
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(BuildContext context, bool canEdit, bool canDelete) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.products;
        
        if (provider.isLoading && products.isEmpty) {
           return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        
        if (products.isEmpty) return _buildEmptyState();

        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)))),
                  Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Serial/Tag", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Location", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(_startDate != null ? "Date Avail" : "Available", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && products.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else ...[
              // Table Rows as Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildTableRow(product, canEdit, canDelete);
                },
              ),
              if (provider.hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: provider.isLoading 
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => provider.loadMoreProducts(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Load More Items"),
                        ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTableRow(dynamic product, bool canEdit, bool canDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Item Name
          Expanded(
            flex: 3,
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(
              product.categoryName ?? "General",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF444444)),
            ),
          ),
          // Serial Number
          Expanded(
            flex: 2,
            child: Text(
              product.serialNumber ?? "N/A",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF444444), fontWeight: FontWeight.w500),
            ),
          ),
          // Location
          Expanded(
            flex: 2,
            child: Text(
              product.warehouseLocation ?? "Warehouse",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF444444)),
            ),
          ),
          // Quantity (Available / Total)
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // Show dateAvailableQuantity if present (defaults to today in backend)
                  // otherwise fallback to quantityAvailable
                  "${product.dateAvailableQuantity ?? product.quantityAvailable}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 20, 
                    color: (product.dateAvailableQuantity != null && product.dateAvailableQuantity! < product.quantity) 
                        ? const Color(0xFFBD0D1D) // Red if some are booked 
                        : const Color(0xFF006400) // Green if all available
                  ),
                ),
                Text(
                  "of ${product.quantity}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: _buildStatusBadge(product),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canEdit)
                  GestureDetector(
                    onTap: () => _showEditProductDialog(product),
                    child: const Text(
                      "Edit",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
                    ),
                  ),
                if (canEdit && canDelete) const SizedBox(width: 8),
                if (canDelete)
                  GestureDetector(
                    onTap: () => _showDeleteProductDialog(product),
                    child: const Text(
                      "Delete",
                      style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18, color: Color(0xFFBD0D1D)),
                    ),
                  ),
                if (!canEdit && !canDelete)
                   const Text(
                    "View-only",
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic product) {
    final displayedQty = product.dateAvailableQuantity ?? product.quantityAvailable;
        
    bool isInStock = displayedQty > 0;
    Color bgColor = isInStock ? const Color(0xFF69FF95) : const Color(0xFFFF8542);
    String label = isInStock ? "In Stock" : "Out Stock";

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: Text(
          "No inventory items found",
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      ),
    );
  }
}
