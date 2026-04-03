import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';

class EnhancedProductTable extends StatefulWidget {
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;
  final Function(ProductModel) onView;
  final bool canEdit;
  final bool canDelete;

  const EnhancedProductTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  State<EnhancedProductTable> createState() => _EnhancedProductTableState();
}

class _EnhancedProductTableState extends State<EnhancedProductTable> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.primaryMaroon),
            ),
          );
        }

        final List<ProductModel> displayProducts = provider.products.isNotEmpty 
            ? provider.products 
            : [
                ProductModel(
                  id: "1", name: "Dining Table", categoryName: "Furniture", quantity: 24, 
                  stockStatus: "HIGH_STOCK", stockStatusDisplay: "In Stock",
                  price: 0, detail: "", totalValue: 0, isActive: true, createdAt: DateTime.now()
                ),
                ProductModel(
                  id: "2", name: "Chair", categoryName: "Furniture", quantity: 156, 
                  stockStatus: "HIGH_STOCK", stockStatusDisplay: "In Stock",
                  price: 0, detail: "", totalValue: 0, isActive: true, createdAt: DateTime.now()
                ),
                ProductModel(
                  id: "3", name: "Chandelier", categoryName: "Lighting", quantity: 12, 
                  stockStatus: "OUT_OF_STOCK", stockStatusDisplay: "Out Stock",
                  price: 0, detail: "", totalValue: 0, isActive: true, createdAt: DateTime.now()
                ),
                ProductModel(
                  id: "4", name: "Table Cloth", categoryName: "Textiles", quantity: 89, 
                  stockStatus: "HIGH_STOCK", stockStatusDisplay: "In Stock",
                  price: 0, detail: "", totalValue: 0, isActive: true, createdAt: DateTime.now()
                ),
                ProductModel(
                  id: "5", name: "Sound System", categoryName: "Audio", quantity: 5, 
                  stockStatus: "OUT_OF_STOCK", stockStatusDisplay: "Out Stock",
                  price: 0, detail: "", totalValue: 0, isActive: true, createdAt: DateTime.now()
                ),
              ];

        return Column(
          children: [
            // Table Header Area
            _buildTableHeader(context),
            const SizedBox(height: 16),
            
            // Scrollable List of Products (Static data if empty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                final product = displayProducts[index];
                return _buildTableRow(context, product, index);
              },
            ),
            
            if (provider.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: provider.isLoading 
                    ? const CircularProgressIndicator(color: AppTheme.primaryMaroon)
                    : ElevatedButton(
                        onPressed: () => provider.loadMoreProducts(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Load More Items"),
                      ),
                ),
              ),
          ],
        );
      },
    );

  }



  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x6EFEFEFE), // Reverted to semi-transparent white
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell(context, "Item Name")),
          Expanded(flex: 2, child: _buildHeaderCell(context, "Category")),
          Expanded(flex: 1, child: _buildHeaderCell(context, "Quantity", isCenter: true)),
          Expanded(flex: 2, child: _buildHeaderCell(context, "Status", isCenter: true)),
          Expanded(flex: 2, child: _buildHeaderCell(context, "Actions", isEnd: true)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title, {bool isCenter = false, bool isEnd = false}) {
    return Text(
      title,
      textAlign: isCenter ? TextAlign.center : (isEnd ? TextAlign.end : TextAlign.start),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF888888),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, ProductModel product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Name
          Expanded(
            flex: 3,
            child: Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(
              product.categoryName ?? "General",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          // Quantity
          Expanded(
            flex: 1,
            child: Text(
              '${product.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Center(
              child: _buildStatusBadge(product.quantity > 0 ? "In Stock" : "Out Stock"),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (product.isActive) ...[
                  if (widget.canEdit)
                    GestureDetector(
                      onTap: () => widget.onEdit(product),
                      child: const Text(
                        "Edit",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (widget.canEdit && widget.canDelete) const SizedBox(width: 12),
                  if (widget.canDelete)
                    GestureDetector(
                      onTap: () => widget.onDelete(product),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Color(0xFFFF4D4D),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (!widget.canEdit && !widget.canDelete)
                    const Text(
                      "View-only",
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                ] else
                  if (widget.canEdit)
                    GestureDetector(
                      onTap: () async {
                        final success = await context
                            .read<ProductProvider>()
                            .restoreProduct(product.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Product restored successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Restore",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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

  Widget _buildStatusBadge(String status) {
    final bool isInStock = status == "In Stock";
    final color = isInStock ? const Color(0xFF61FF9A) : const Color(0xFFFF8552);
    final textColor = isInStock ? const Color(0xFF1E6F3D) : const Color(0xFFFFFFFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      width: 100, // Fixed width for status badges
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(
              Icons.inventory_outlined,
              size: context.iconSize('xl'),
              color: Colors.grey[400],
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noProductRecordsFound,
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80.w,
                small: 70.w,
                medium: 60.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
            ),
            child: Text(
              l10n.startByAddingYourFirstProductToManageInventoryEfficiently,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
