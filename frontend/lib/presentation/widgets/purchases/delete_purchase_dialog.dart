import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/providers/vendor_provider.dart';
import '../globals/text_button.dart';

class DeletePurchaseDialog extends StatelessWidget {
  final PurchaseModel purchase;

  const DeletePurchaseDialog({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
      ),
      elevation: context.shadowBlur('heavy'),
      backgroundColor: AppTheme.creamWhite,
      child: Container(
        padding: EdgeInsets.zero,
        width: context.dialogWidth, // Using responsive dialog width instead of fixed 35.w
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: 85.w,
            small: 75.w,
            medium: 45.w,
            large: 35.w,
            ultrawide: 25.w,
          ),
          minWidth: 340, // Slightly wider for better text fit
          maxHeight: 85.h, // Prevent vertical overflow on short screens
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section (Fixed at top)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.cardPadding * 0.8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadius('large')),
                  topRight: Radius.circular(context.borderRadius('large')),
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(context.smallPadding),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 28),
                ),
              ),
            ),
            
            // Scrollable Content Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(context.mainPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      l10n.deletePurchase ?? "Delete Purchase",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                    ),
                    SizedBox(height: context.smallPadding),

                    // Message
                    Text(
                      "Are you sure you want to delete this purchase record? This action cannot be reversed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    ),
                    SizedBox(height: context.mainPadding),

                    // Details Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.cardPadding * 0.8),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _infoRow("Vendor", _getVendorName(context, l10n)),
                          const Divider(height: 16, thickness: 0.5),
                          _infoRow("Total Amount", "Rs. ${purchase.total.toStringAsFixed(2)}"),
                        ],
                      ),
                    ),

                    SizedBox(height: context.mainPadding),

                    // Action Buttons - Fully Responsive
                    Consumer<PurchaseProvider>(
                      builder: (context, provider, child) {
                        // Use Column for narrow widths, Row for wider
                        final bool isNarrow = MediaQuery.of(context).size.width < 420;
                        
                        final cancelBtn = PremiumButton(
                          text: l10n.cancel ?? "Cancel",
                          onPressed: () => Navigator.pop(context),
                          isOutlined: true,
                          backgroundColor: AppTheme.charcoalGray,
                          height: 42,
                        );

                        final deleteBtn = PremiumButton(
                          text: "Delete Purchase",
                          isLoading: provider.isLoading,
                          onPressed: provider.isLoading ? null : () => _handleDelete(context, provider),
                          backgroundColor: Colors.red.shade600,
                          height: 42,
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              deleteBtn,
                              SizedBox(height: context.smallPadding),
                              cancelBtn,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: cancelBtn),
                            SizedBox(width: context.smallPadding),
                            Expanded(child: deleteBtn),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete handler - FIXED ✅
  // Robustly get vendor name including provider lookup
  String _getVendorName(BuildContext context, AppLocalizations l10n) {
    if (purchase.vendorName != null && purchase.vendorName!.isNotEmpty) {
      return purchase.vendorName!;
    }
    if (purchase.vendorDetail?.name != null) {
      return purchase.vendorDetail!.name;
    }
    if (purchase.vendor != null) {
      try {
        final vendorProvider = context.read<VendorProvider>();
        final found = vendorProvider.vendors.firstWhere((v) => v.id == purchase.vendor);
        return found.name;
      } catch (e) {}
    }
    return "Unknown Vendor";
  }

  void _handleDelete(BuildContext context, PurchaseProvider provider) async {
    if (purchase.id == null || purchase.id!.isEmpty) {
      _showError(context, "Cannot delete: Invalid purchase ID");
      return;
    }

    final success = await provider.deletePurchase(purchase.id!);

    if (!context.mounted) return;

    Navigator.pop(context); // Close dialog first
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$label:",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $message"),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
}
