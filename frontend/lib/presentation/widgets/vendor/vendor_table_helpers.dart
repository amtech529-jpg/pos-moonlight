import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/confirmation_dialog.dart';

class VendorTableHelpers {
  final Function(VendorModel) onEdit;
  final Function(VendorModel) onDelete;
  final Function(VendorModel) onView;

  VendorTableHelpers({
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  /// Build the actions row for each vendor in the table
  Widget buildActionsRow(BuildContext context, VendorModel vendor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onView(vendor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.visibility_outlined,
                color: Colors.purple,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(vendor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(vendor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Quick Actions Dropdown
        PopupMenuButton<String>(
          onSelected: (value) => _handleQuickAction(context, vendor, value),
          itemBuilder: (context) => _buildQuickActionMenuItems(context, vendor),
          child: Container(
            padding: EdgeInsets.all(context.smallPadding * 0.5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
              size: context.iconSize('small'),
            ),
          ),
        ),
      ],
    );
  }

  /// Build quick action menu items based on vendor state
  List<PopupMenuEntry<String>> _buildQuickActionMenuItems(BuildContext context, VendorModel vendor) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];

    // Status change actions
    if (vendor.isActive) {
      items.add(
        PopupMenuItem(
          value: 'soft_delete',
          child: Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.orange, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.deactivate, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    } else {
      items.add(
        PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.restore, color: Colors.green, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.restore, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  /// Handle quick action selection
  void _handleQuickAction(BuildContext context, VendorModel vendor, String action) async {
    final provider = context.read<VendorProvider>();

    switch (action) {
      case 'soft_delete':
        await _handleSoftDelete(context, provider, vendor);
        break;
      case 'restore':
        await _handleRestore(context, provider, vendor);
        break;
    }
  }

  /// Handle soft delete (deactivate)
  Future<void> _handleSoftDelete(
      BuildContext context,
      VendorProvider provider,
      VendorModel vendor,
      ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: '${l10n.deactivate} ${l10n.vendor}',
        message: '${l10n.areYouSureDeactivate} ${vendor.name}? ${l10n.actionCanBeReversed}',
        actionText: l10n.deactivate,
        actionColor: Colors.orange,
      ),
    ) ?? false;

    if (confirmed) {
      final success = await provider.softDeleteVendor(vendor.id);
      if (provider.hasError) {
        _showErrorSnackbar(context, provider.errorMessage ?? '${l10n.failedToDeactivate} ${l10n.vendor}');
      } else if (success) {
        _showSuccessSnackbar(context, '${l10n.vendor} ${l10n.deactivatedSuccessfully}');
      }
    }
  }

  /// Handle restore vendor
  Future<void> _handleRestore(
      BuildContext context,
      VendorProvider provider,
      VendorModel vendor,
      ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: '${l10n.restore} ${l10n.vendor}',
        message: '${l10n.areYouSureRestore} ${vendor.name}?',
        actionText: l10n.restore,
        actionColor: Colors.green,
      ),
    ) ?? false;

    if (confirmed) {
      final success = await provider.restoreVendor(vendor.id);
      if (provider.hasError) {
        _showErrorSnackbar(context, provider.errorMessage ?? '${l10n.failedToRestore} ${l10n.vendor}');
      } else if (success) {
        _showSuccessSnackbar(context, '${l10n.vendor} ${l10n.restoredSuccessfully}');
      }
    }
  }

  /// Show success snackbar
  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  /// Build error state widget
  Widget buildErrorState(BuildContext context, VendorProvider provider) {
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
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(
              Icons.error_outline,
              size: context.iconSize('xl'),
              color: Colors.red[400],
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            '${l10n.failedToLoad} ${l10n.vendor}',
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
              provider.errorMessage ?? l10n.unexpectedError,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.mainPadding),

          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  provider.clearError();
                  provider.refreshVendors();
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.cardPadding * 0.6,
                    vertical: context.cardPadding / 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.pureWhite,
                        size: context.iconSize('medium'),
                      ),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.retry,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget buildEmptyState(BuildContext context) {
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
              Icons.store_outlined,
              size: context.iconSize('xl'),
              color: Colors.grey[400],
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            '${l10n.noVendorsFound}',
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
              l10n.startByAddingFirstVendor,
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

  /// Get status color based on status string
  Color getStatusColor(String status) {
    if (status.toLowerCase() == 'active') {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  /// Get vendor type icon - simplified for basic model
  IconData getVendorTypeIcon(String vendorType) {
    return Icons.business; // Default icon since vendorType might not be in basic model
  }
}
