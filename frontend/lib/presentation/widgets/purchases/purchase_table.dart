import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import 'purchase_table_helpers.dart';
import 'view_purchase_details_dialog.dart';
import 'edit_purchase_dialog.dart';
import 'delete_purchase_dialog.dart';
import 'purchase_filter_dialog.dart';

class PurchaseTable extends StatefulWidget {
  final PurchaseFilter? filter;

  const PurchaseTable({super.key, this.filter});

  @override
  State<PurchaseTable> createState() => _PurchaseTableState();
}

class _PurchaseTableState extends State<PurchaseTable> {
  // 1. Define separate controllers for robust scrolling
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Simplified: Removing scroll sync logic that was causing layout issues
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  /// Get filtered purchases based on the applied filter
  List<PurchaseModel> _getFilteredPurchases(List<PurchaseModel> allPurchases) {
    if (widget.filter == null) {
      return allPurchases;
    }

    List<PurchaseModel> filtered = List.from(allPurchases);

    // Filter by vendor
    if (widget.filter!.vendorId != null && widget.filter!.vendorId!.isNotEmpty) {
      filtered = filtered.where((p) => p.vendor == widget.filter!.vendorId).toList();
    }

    // Filter by status
    if (widget.filter!.status != null && widget.filter!.status!.isNotEmpty) {
      filtered = filtered.where((p) => p.status.toLowerCase() == widget.filter!.status!.toLowerCase()).toList();
    }

    // Filter by date range
    if (widget.filter!.startDate != null) {
      filtered = filtered.where((p) {
        return p.purchaseDate.isAfter(widget.filter!.startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (widget.filter!.endDate != null) {
      filtered = filtered.where((p) {
        return p.purchaseDate.isBefore(widget.filter!.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const double minWidth = 1100;
    final screenWidth = MediaQuery.of(context).size.width;
    // 48 for padding (24 on each side)
    bool needsScrolling = screenWidth < (minWidth + 48); 

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final bool canEdit = currentUser?.canPerform('Purchase', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('Purchase', 'delete') ?? true;

    return Consumer<PurchaseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.purchases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredPurchases = _getFilteredPurchases(provider.purchases);
        final List<Map<String, dynamic>> allItems = [];
        final String search = (widget.filter?.searchQuery ?? "").trim().toLowerCase();

        for (var purchase in filteredPurchases) {
          for (var item in purchase.items) {
             final name = (item.productDetail?.name ?? item.productName ?? "").toLowerCase();
             final category = (item.productDetail?.categoryName ?? item.categoryName ?? "").toLowerCase();
             final vendorName = (purchase.vendorName ?? purchase.vendorDetail?.name ?? "").toLowerCase();
             final vendorBusiness = (purchase.vendorDetail?.businessName ?? "").toLowerCase();
             final invoiceNum = (purchase.invoiceNumber ?? "").toLowerCase();
             final description = (item.description ?? "").toLowerCase();

             bool matchesSearch = search.isEmpty || 
                 name.contains(search) || 
                 category.contains(search) ||
                 vendorName.contains(search) ||
                 vendorBusiness.contains(search) ||
                 invoiceNum.contains(search) ||
                 description.contains(search);

             if (matchesSearch) {
                allItems.add({
                  'name': item.productDetail?.name ?? item.productName ?? "Unknown Product",
                  'category': item.productDetail?.categoryName ?? item.categoryName ?? "General",
                  'quantity': item.quantity,
                  'description': item.description ?? "-", 
                  'price': item.unitCost,
                  'purchaseId': purchase.id,
                  'item': item,
                  'purchase': purchase,
                });
             }
          }
        }

        if (allItems.isEmpty) {
          return _buildEmptyState(search);
        }

        // Build the table header
        final tableHeader = Container(
          width: needsScrolling ? minWidth : double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              _buildResponsiveCell(flex: 3, width: minWidth * 0.25, isScrolling: needsScrolling, child: _buildHeaderCell("Item Name")),
              _buildResponsiveCell(flex: 2, width: minWidth * 0.15, isScrolling: needsScrolling, child: _buildHeaderCell("Category")),
              _buildResponsiveCell(flex: 1, width: minWidth * 0.1, isScrolling: needsScrolling, child: _buildHeaderCell("Quantity", isCenter: true)),
              _buildResponsiveCell(flex: 2, width: minWidth * 0.2, isScrolling: needsScrolling, child: _buildHeaderCell("Notes", isCenter: true)),
              _buildResponsiveCell(flex: 2, width: minWidth * 0.15, isScrolling: needsScrolling, child: _buildHeaderCell("Purchase Price", isEnd: true)),
              _buildResponsiveCell(flex: 1, width: minWidth * 0.15, isScrolling: needsScrolling, child: _buildHeaderCell("Actions", isCenter: true)),
            ],
          ),
        );

        // Build the table body using a simple Column instead of ListView to avoid layout loops
        final tableBody = Column(
          children: allItems.map((data) {
            return InkWell(
              onTap: () => _showViewDetails(data['purchase']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: needsScrolling ? minWidth : double.infinity,
                child: _buildItemRecordRow(context, data, needsScrolling, minWidth, canEdit, canDelete),
              ),
            );
          }).toList(),
        );

        final tableContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            tableHeader,
            tableBody,
          ],
        );

        if (needsScrolling) {
          return Scrollbar(
            controller: _contentHorizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _contentHorizontalController,
              scrollDirection: Axis.horizontal,
              child: tableContent,
            ),
          );
        }
        
        return tableContent;
      },
    );
  }

  Widget _buildEmptyState(String search) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              search.isNotEmpty ? "No products match '$search'" : "No items found in purchase history.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeaderCell(String title, {bool isCenter = false, bool isEnd = false}) {
    return Text(
      title,
      textAlign: isCenter ? TextAlign.center : (isEnd ? TextAlign.end : TextAlign.start),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF999999),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildResponsiveCell({
    required int flex,
    required double width,
    required bool isScrolling,
    required Widget child,
  }) {
    if (isScrolling) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }

  Widget _buildItemRecordRow(BuildContext context, Map<String, dynamic> data, bool isScrolling, double minWidth, bool canEdit, bool canDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Item Name
          _buildResponsiveCell(
            flex: 3,
            width: minWidth * 0.25,
            isScrolling: isScrolling,
            child: Text(
              data['name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
            ),
          ),
          // Category
          _buildResponsiveCell(
            flex: 2,
            width: minWidth * 0.15,
            isScrolling: isScrolling,
            child: Text(
              data['category'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF777777)),
            ),
          ),
          // Quantity
          _buildResponsiveCell(
            flex: 1,
            width: minWidth * 0.1,
            isScrolling: isScrolling,
            child: Text(
              data['quantity'].toString(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
            ),
          ),
          // Notes/Description
          _buildResponsiveCell(
            flex: 2,
            width: minWidth * 0.2,
            isScrolling: isScrolling,
            child: Center(
              child: Text(
                data['description'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w400),
              ),
            ),
          ),
          // Purchase Price
          _buildResponsiveCell(
            flex: 2,
            width: minWidth * 0.15,
            isScrolling: isScrolling,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "Rs. ${data['price'].toStringAsFixed(2)}",
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
            ),
          ),
          // Actions
          _buildResponsiveCell(
            flex: 1,
            width: minWidth * 0.15,
            isScrolling: isScrolling,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  InkWell(
                    onTap: () => _showEditDialog(data['purchase']),
                    borderRadius: BorderRadius.circular(6),
                    child: Tooltip(
                      message: "Edit purchase",
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 18),
                      ),
                    ),
                  ),
                if (canEdit && canDelete) const SizedBox(width: 4),
                if (canDelete)
                  InkWell(
                    onTap: () => _showDeleteDialog(data['purchase']),
                    borderRadius: BorderRadius.circular(6),
                    child: Tooltip(
                      message: "Delete purchase",
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade500, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showViewDetails(PurchaseModel purchase) {
     showDialog(
      context: context,
      builder: (context) => ViewPurchaseDetailsDialog(purchase: purchase),
    );
  }

  void _showEditDialog(PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (context) => EditPurchaseDialog(purchase: purchase),
    );
  }

  void _showDeleteDialog(PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (context) => DeletePurchaseDialog(purchase: purchase),
    );
  }
}