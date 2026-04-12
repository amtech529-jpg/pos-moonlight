import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_button.dart';
import 'purchase_table_helpers.dart';

class ViewPurchaseDetailsDialog extends StatelessWidget {
  final PurchaseModel purchase;

  const ViewPurchaseDetailsDialog({super.key, required this.purchase});

  /// Helper to robustly get the Vendor Name with Localization
  String _getVendorName(BuildContext context, AppLocalizations l10n) {
    // 1. First priority: Provider lookup (most accurate if ID exists)
    if (purchase.vendor != null) {
      try {
        final vendorProvider = context.read<VendorProvider>();
        final foundVendor = vendorProvider.vendors.firstWhere(
          (v) => v.id == purchase.vendor,
        );
        if (foundVendor.businessName.isNotEmpty) return foundVendor.businessName;
        return foundVendor.name;
      } catch (_) {}
    }

    // 2. Second priority: Business name from nested detail object
    if (purchase.vendorDetail?.businessName != null && purchase.vendorDetail!.businessName.isNotEmpty) {
      return purchase.vendorDetail!.businessName;
    }

    // 3. Third priority: Direct name field or Detail name
    if (purchase.vendorName != null && purchase.vendorName!.isNotEmpty) {
      return purchase.vendorName!;
    }

    if (purchase.vendorDetail?.name != null) {
      return purchase.vendorDetail!.name;
    }

    return l10n.unknownVendor ?? "Unknown Company";
  }

  /// Helper to get Product Name robustly with Localization
  String _getProductName(BuildContext context, PurchaseItemModel item, AppLocalizations l10n) {
    // 1. Try nested detail
    if (item.productDetail?.name != null) {
      return item.productDetail!.name;
    }

    // 2. Try Lookup in Provider
    if (item.product != null) {
      try {
        final productProvider = context.read<ProductProvider>();
        final foundProduct = productProvider.products.firstWhere(
              (p) => p.id == item.product,
        );
        return foundProduct.name;
      } catch (e) {
        // Not found
      }
    }

    // 3. Fallback to ID or generic text
    return item.product ?? (l10n.unknownProduct ?? "Unknown Product");
  }

  @override
  Widget build(BuildContext context) {
    // Ensure l10n is not null
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
      ),
      backgroundColor: AppTheme.creamWhite,
      child: Container(
        width: context.dialogWidth,
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: 90.w,
            small: 85.w,
            medium: 70.w,
            large: 60.w,
            ultrawide: 50.w,
          ),
          maxHeight: 90.h,
        ),
        padding: EdgeInsets.all(context.mainPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section (Fixed)
            _buildHeader(context, l10n),
            const Divider(height: 24),

            // Content Section (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaInfo(context, l10n),
                    SizedBox(height: context.mainPadding),
                    _buildItemsTable(context, l10n),
                    const Divider(height: 32),
                    _buildTotalsSection(context, l10n),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),
            // Footer Section
            _buildActionButtons(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.primaryMaroon,
            size: 24,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.purchaseDetails ?? "Purchase Details",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoalGray,
                ),
              ),
              if (purchase.invoiceNumber.isNotEmpty)
                 Text(
                   "Invoice #${purchase.invoiceNumber}",
                   style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                 ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Vendor Name (Safe Lookup)
          _infoColumn(l10n.vendor ?? "Vendor", _getVendorName(context, l10n)),

          // Date
          _infoColumn(l10n.date ?? "Date", PurchaseTableHelpers.formatDate(purchase.purchaseDate)),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.charcoalGray)),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.smallPadding),
          child: Text(
            l10n.purchasedItems ?? "Purchased Items",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
             children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                       Expanded(flex: 3, child: _tableHeaderText(l10n.product)),
                       Expanded(flex: 1, child: _tableHeaderText(l10n.quantity, align: TextAlign.center)),
                       Expanded(flex: 2, child: _tableHeaderText(l10n.unitCost, align: TextAlign.right)),
                       Expanded(flex: 2, child: _tableHeaderText(l10n.total, align: TextAlign.right)),
                    ],
                  ),
                ),
                // Items
                ...purchase.items.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _tableCellText(_getProductName(context, item, l10n))),
                      Expanded(flex: 1, child: _tableCellText(item.quantity.toStringAsFixed(0), align: TextAlign.center)),
                      Expanded(flex: 2, child: _tableCellText(item.unitCost.toStringAsFixed(2), align: TextAlign.right)),
                      Expanded(flex: 2, child: _tableCellText(item.totalPrice.toStringAsFixed(2), isBold: true, align: TextAlign.right)),
                    ],
                  ),
                )),
             ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeaderText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
      textAlign: align,
    );
  }

  Widget _tableCellText(String text, {bool isBold = false, TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: isBold ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
      ),
    );
  }

  Widget _buildTotalsSection(BuildContext context, AppLocalizations l10n) {
    return _totalRow(l10n.grandTotal ?? "Grand Total", purchase.total, isMain: true);
  }

  Widget _totalRow(String label, double amount, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            fontSize: isMain ? 16 : 14,
            color: isMain ? AppTheme.charcoalGray : Colors.grey[600],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2).format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMain ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
            fontSize: isMain ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        /*  // Commented out Print Invoice button as requested
        PremiumButton(
          text: l10n.printInvoice ?? "Print Invoice",
          onPressed: () {
            // Print logic implementation
          },
          icon: Icons.print_rounded,
          isOutlined: true,
          width: 160,
          height: 45,
        ),
        SizedBox(width: context.mainPadding),
        */
        PremiumButton(
          text: l10n.close ?? "Close",
          onPressed: () => Navigator.pop(context),
          width: 140,
          height: 45,
          backgroundColor: AppTheme.primaryMaroon,
        ),
      ],
    );
  }
}