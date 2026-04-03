import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/confirmation_dialog.dart';
import 'package:frontend/presentation/widgets/payment/add_payment_dialog.dart';
import '../../../src/providers/product_provider.dart';
import 'order_items_management_dialog.dart';

class OrderTableHelpers {
  final Function(OrderModel) onEdit;
  final Function(OrderModel) onDelete;
  final Function(OrderModel) onView;

  OrderTableHelpers({required this.onEdit, required this.onDelete, required this.onView});

  Widget buildActionsRow(BuildContext context, OrderModel order) {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onView(order),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.4),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
              ),
            ),
          ),

          SizedBox(width: context.smallPadding / 3),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showOrderItemsManagementDialog(context, order),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
                ),
                child: Icon(Icons.shopping_cart_rounded, color: AppTheme.accentGold, size: context.iconSize('small')),
              ),
            ),
          ),

          SizedBox(width: context.smallPadding / 3),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onEdit(order),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
              ),
            ),
          ),

          SizedBox(width: context.smallPadding / 3),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDelete(order),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
              ),
            ),
          ),

          SizedBox(width: context.smallPadding / 3),

          PopupMenuButton<String>(
            onSelected: (value) => _handleQuickAction(context, order, value),
            itemBuilder: (context) => _buildQuickActionMenuItems(context, order),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.4),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.more_vert, color: Colors.grey[600], size: context.iconSize('small')),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildQuickActionMenuItems(BuildContext context, OrderModel order) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];

    switch (order.status) {
      case OrderStatus.PENDING:
        items.addAll([
          PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Text(l10n.confirmOrder, style: TextStyle(fontSize: context.captionFontSize)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Text(l10n.cancelOrder, style: TextStyle(fontSize: context.captionFontSize)),
              ],
            ),
          ),
        ]);
        break;
      case OrderStatus.CONFIRMED:
        items.add(
          PopupMenuItem(
            value: 'mark_ready',
            child: Row(
              children: [
                Icon(Icons.done_all, color: Colors.green, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Text(l10n.markAsReady, style: TextStyle(fontSize: context.captionFontSize)),
              ],
            ),
          ),
        );
        break;
      case OrderStatus.READY:
        items.add(
          PopupMenuItem(
            value: 'mark_delivered',
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.purple, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Text(l10n.markAsDelivered, style: TextStyle(fontSize: context.captionFontSize)),
              ],
            ),
          ),
        );
        break;
      case OrderStatus.DELIVERED:
      case OrderStatus.RETURNED:
      case OrderStatus.CANCELLED:
        break;
    }

    if (order.isActive) {
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
            ],
          ),
        ),
      );
    }
    
    // Add 'Add Payment' option if remaining amount > 0
    if (order.remainingAmount > 0) {
      items.add(
        PopupMenuItem(
          value: 'add_payment',
          child: Row(
            children: [
              Icon(Icons.payment_rounded, color: Colors.green, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.addPayment, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    }
    
    // Always add Invoice option
    items.add(
      PopupMenuItem(
        value: 'invoice',
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.indigo, size: context.iconSize('small')),
            SizedBox(width: context.smallPadding),
            Text(l10n.invoice, style: TextStyle(fontSize: context.captionFontSize)),
          ],
        ),
      ),
    );

    return items;
  }

  void _handleQuickAction(BuildContext context, OrderModel order, String action) async {
    final provider = context.read<OrderProvider>();

    switch (action) {
      case 'confirm':
        await _handleStatusChange(context, provider, order, 'confirmed');
        break;
      case 'mark_ready':
        await _handleStatusChange(context, provider, order, 'ready');
        break;
      case 'mark_delivered':
        await _handleStatusChange(context, provider, order, 'delivered');
        break;
      case 'cancel':
        await _handleStatusChange(context, provider, order, 'cancelled');
        break;
      case 'soft_delete':
        await _handleSoftDelete(context, provider, order);
        break;
      case 'restore':
        await _handleRestore(context, provider, order);
        break;
      case 'invoice':
        await _handleGenerateInvoice(context, provider, order);
        break;
      case 'add_payment':
        await _handleAddPayment(context, order);
        break;
    }
  }

  Future<void> _handleAddPayment(BuildContext context, OrderModel order) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(preSelectedOrderId: order.id),
    );
    
    // Refresh order if payment added
    if (result == true) {
      context.read<OrderProvider>().refreshOrders();
    }
  }

  Future<void> _handleGenerateInvoice(BuildContext context, OrderProvider provider, OrderModel order) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final invoiceData = await provider.generateInvoice(order.id);
      
      if (invoiceData != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${l10n.invoice} ${l10n.generated}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.invoice} #: ${invoiceData['invoice_number'] ?? 'N/A'}'),
                  SizedBox(height: 8),
                  Text('${l10n.date}: ${invoiceData['invoice_date'] ?? 'N/A'}'),
                  SizedBox(height: 16),
                  Text('${l10n.totalAmount}: ${invoiceData['total_amount'] ?? 0}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.print, size: 16),
                label: Text(l10n.printInvoice),
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessSnackbar(context, 'Printing not implemented yet');
                },
              ),
            ],
          ),
        );
      } else {
        if (provider.errorMessage != null) {
          _showErrorSnackbar(context, provider.errorMessage!);
        }
      }
    } catch (e) {
      _showErrorSnackbar(context, '${l10n.error}: $e');
    }
  }

  Future<void> _handleStatusChange(BuildContext context, OrderProvider provider, OrderModel order, String newStatus) async {
    final l10n = AppLocalizations.of(context)!;
    final statusText = _getStatusTextFromString(context, newStatus);
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: l10n.changeOrderStatus,
            message: '${l10n.areYouSureChangeStatusTo} #${order.id.substring(0, 8)} ${l10n.to} "$statusText"?',
            actionText: l10n.changeStatus,
            actionColor: Colors.blue,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.updateOrderStatus(order.id, newStatus);
      if (provider.errorMessage != null) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToUpdateOrderStatus);
      } else if (success) {
        _showSuccessSnackbar(context, '${l10n.orderStatusUpdatedTo} $statusText ${l10n.successfully}');
        // Refresh inventory so quantityAvailable reflects the new reservation
        try {
          if (context.mounted) {
            context.read<ProductProvider>().initialize();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _handleSoftDelete(BuildContext context, OrderProvider provider, OrderModel order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: l10n.deactivateOrder,
            message: '${l10n.areYouSureDeactivateOrder} #${order.id.substring(0, 8)}? ${l10n.thisActionCanBeReversed}',
            actionText: l10n.deactivate,
            actionColor: Colors.orange,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.softDeleteOrder(order.id);
      if (provider.errorMessage != null) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToDeactivateOrder);
      } else if (success) {
        _showSuccessSnackbar(context, l10n.orderDeactivatedSuccessfully);
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, OrderProvider provider, OrderModel order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: l10n.restoreOrder,
            message: '${l10n.areYouSureRestoreOrder} #${order.id.substring(0, 8)}?',
            actionText: l10n.restore,
            actionColor: Colors.green,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.restoreOrder(order.id);
      if (provider.errorMessage != null) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToRestoreOrder);
      } else if (success) {
        _showSuccessSnackbar(context, l10n.orderRestoredSuccessfully);
      }
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
                style: TextStyle(
                  fontSize: context.bodyFontSize, 
                  fontWeight: FontWeight.w500, 
                  color: AppTheme.pureWhite
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.pureWhite,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  Widget buildErrorState(BuildContext context, OrderProvider provider) {
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
            l10n.failedToLoadOrders,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              provider.errorMessage ?? l10n.unexpectedErrorOccurred,
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
                  provider.refreshOrders();
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
            child: Icon(Icons.shopping_bag_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noOrdersFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startManagingCustomerOrders,
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
                        l10n.createNewOrder,
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

  Widget buildNoSearchResultsState(BuildContext context, OrderProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.search_off_rounded, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noOrdersFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              '${l10n.noOrdersMatchSearch} "${provider.searchQuery}". ${l10n.tryAdjustingSearchTerms}',
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.mainPadding),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(context.borderRadius())),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      provider.clearFilters();
                    },
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.6, vertical: context.cardPadding / 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_rounded, color: Colors.grey[700], size: context.iconSize('medium')),
                          SizedBox(width: context.smallPadding),
                          Text(
                            l10n.clearSearch,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: context.mainPadding),

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
                            l10n.createNewOrder,
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
        ],
      ),
    );
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return AppTheme.accentGold;
      case OrderStatus.CONFIRMED:
        return AppTheme.primaryMaroon;
      case OrderStatus.READY:
        return Colors.green;
      case OrderStatus.DELIVERED:
        return Colors.purple;
      case OrderStatus.RETURNED:
        return Colors.teal;
      case OrderStatus.CANCELLED:
        return Colors.red;
    }
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Pending';
      case OrderStatus.CONFIRMED:
        return 'Confirmed';
      case OrderStatus.READY:
        return 'Ready';
      case OrderStatus.DELIVERED:
        return 'Delivered';
      case OrderStatus.RETURNED:
        return 'Returned';
      case OrderStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  String _getStatusTextFromString(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'confirmed':
        return l10n.confirmed;
      case 'ready':
        return l10n.ready;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showOrderItemsManagementDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) => OrderItemsManagementDialog(order: order),
    );
  }
}
