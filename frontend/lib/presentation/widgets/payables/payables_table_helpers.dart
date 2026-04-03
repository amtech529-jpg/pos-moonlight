import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PayablesTableHelpers {
  final Function(Payable) onEdit;
  final Function(Payable) onDelete;
  final Function(Payable) onView;

  PayablesTableHelpers({required this.onEdit, required this.onDelete, required this.onView});

  /// Build the actions row for each payable record in the table
  Widget buildActionsRow(BuildContext context, Payable payable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onView(payable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(payable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(payable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),
      ],
    );
  }

  /// Build error state widget
  Widget buildErrorState(BuildContext context, PayablesProvider provider) {
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
            l10n.failedToLoadPayables,
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
                  provider.loadPayables();
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

  /// Build empty state widget
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
            child: Icon(Icons.account_balance_wallet_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noPayablesFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startByAddingYourFirstPayableRecordToTrackYourBorrowingsEffectively,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  Color getStatusColor(Payable payable) {
    if (payable.isFullyPaid) return Colors.green;
    if (payable.amountPaid > 0 && payable.balanceRemaining > 0) return Colors.orange;
    if (payable.isOverdueComputed) return Colors.red;
    return Colors.blue; // Pending
  }

  String getStatusText(BuildContext context, Payable payable) {
    final l10n = AppLocalizations.of(context)!;

    if (payable.isFullyPaid) return l10n.fullyPaid;
    if (payable.amountPaid > 0 && payable.balanceRemaining > 0) return l10n.partiallyPaid;
    if (payable.isOverdueComputed) return l10n.overdue;
    return l10n.pending;
  }

  /// Get priority color
  Color getPriorityColor(Payable payable) {
    switch (payable.priority.toUpperCase()) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.yellow;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get creditor initials for avatar
  String getCreditorInitials(String creditorName) {
    final words = creditorName.trim().split(' ');
    if (words.isEmpty) return 'C';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'.toUpperCase();
  }

  /// Format currency for display
  String formatCurrency(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  /// Build status chip
  Widget buildStatusChip(BuildContext context, Payable payable) {
    final color = getStatusColor(payable);
    final text = getStatusText(context, payable);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding * 0.6, vertical: context.smallPadding / 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: context.captionFontSize * 0.75, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// Build priority chip
  Widget buildPriorityChip(BuildContext context, Payable payable) {
    final color = getPriorityColor(payable);
    final text = payable.priorityDisplay;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding * 0.6, vertical: context.smallPadding / 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: context.captionFontSize * 0.75, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// Build creditor avatar
  Widget buildCreditorAvatar(BuildContext context, Payable payable) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          getCreditorInitials(payable.creditorName),
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
      ),
    );
  }

  /// Build vendor badge
  Widget buildVendorBadge(BuildContext context, Payable payable) {
    final l10n = AppLocalizations.of(context)!;

    if (payable.vendorId == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
        child: Text(
          l10n.noVendor,
          style: TextStyle(fontSize: context.captionFontSize * 0.8, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
      decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
      child: Text(
        payable.vendorDisplayName,
        style: TextStyle(fontSize: context.captionFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
      ),
    );
  }
}
