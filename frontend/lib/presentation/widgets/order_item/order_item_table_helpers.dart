import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/confirmation_dialog.dart';

class OrderItemTableHelpers {
  final Function(OrderItemModel) onEdit;
  final Function(OrderItemModel) onDelete;
  final Function(OrderItemModel) onView;

  OrderItemTableHelpers({required this.onEdit, required this.onDelete, required this.onView});

  Widget buildActionsRow(BuildContext context, OrderItemModel orderItem) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onView(orderItem),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(orderItem),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(orderItem),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        PopupMenuButton<String>(
          onSelected: (value) => _handleQuickAction(context, orderItem, value),
          itemBuilder: (context) => _buildQuickActionMenuItems(context, orderItem),
          child: Container(
            padding: EdgeInsets.all(context.smallPadding * 0.5),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Icon(Icons.more_vert, color: Colors.grey[600], size: context.iconSize('small')),
          ),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildQuickActionMenuItems(BuildContext context, OrderItemModel orderItem) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];

    if (orderItem.isActive) {
      items.add(
        PopupMenuItem(
          value: 'deactivate',
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
          value: 'activate',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.green, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.activate, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleQuickAction(BuildContext context, OrderItemModel orderItem, String action) async {
    final provider = context.read<OrderItemProvider>();

    switch (action) {
      case 'activate':
        await _handleStatusChange(context, provider, orderItem, true);
        break;
      case 'deactivate':
        await _handleStatusChange(context, provider, orderItem, false);
        break;
    }
  }

  Future<void> _handleStatusChange(BuildContext context, OrderItemProvider provider, OrderItemModel orderItem, bool isActive) async {
    final l10n = AppLocalizations.of(context)!;
    final statusText = isActive ? l10n.activate.toLowerCase() : l10n.deactivate.toLowerCase();
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: '${isActive ? l10n.activate : l10n.deactivate} ${l10n.orderItem}',
            message: '${l10n.areYouSureYouWantTo} $statusText "${orderItem.productName}"?',
            actionText: isActive ? l10n.activate : l10n.deactivate,
            actionColor: isActive ? Colors.green : Colors.orange,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.updateOrderItemStatus(orderItem.id, isActive);
      if (provider.errorMessage != null) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToUpdateItemStatus);
      } else if (success) {
        _showSuccessSnackbar(context, '${l10n.orderItem} ${isActive ? l10n.activatedSuccessfully : l10n.deactivatedSuccessfully}');
      }
    }
  }

  Future<void> _handleDuplicate(BuildContext context, OrderItemProvider provider, OrderItemModel orderItem) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: '${l10n.duplicate} ${l10n.orderItem}',
            message: '${l10n.areYouSureYouWantToCreateACopyOf} "${orderItem.productName}"?',
            actionText: l10n.duplicate,
            actionColor: Colors.blue,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.duplicateOrderItem(orderItem.id);
      if (provider.errorMessage != null) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToDuplicateItem);
      } else if (success) {
        _showSuccessSnackbar(context, l10n.orderItemDuplicatedSuccessfully);
      }
    }
  }

  Future<void> _handleExport(BuildContext context, OrderItemModel orderItem) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _showSuccessSnackbar(context, l10n.orderItemDetailsExportedSuccessfully);
    } catch (e) {
      _showErrorSnackbar(context, '${l10n.failedToExport}: ${e.toString()}');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  Widget buildErrorState(BuildContext context, OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.error_outline, size: context.iconSize('xl'), color: Colors.red[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.failedToLoadOrderItems,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              provider.errorMessage ?? l10n.anUnexpectedErrorOccurred,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.mainPadding),

          Container(
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  provider.loadOrderItems();
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.6, vertical: context.cardPadding / 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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

  Widget buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.inventory_2_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noOrderItemsFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startManagingYourOrderItems,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.mainPadding),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.6, vertical: context.cardPadding / 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.addOrderItem,
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

  Color getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.orange;
  }

  String getStatusText(bool isActive) {
    return isActive ? 'Active' : 'Inactive';
  }
}
