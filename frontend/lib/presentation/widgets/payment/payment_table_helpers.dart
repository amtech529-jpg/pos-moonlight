import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payment/payment_model.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PaymentTableHelpers {
  final Function(PaymentModel) onEdit;
  final Function(PaymentModel) onDelete;
  final Function(PaymentModel) onViewReceipt;

  PaymentTableHelpers({required this.onEdit, required this.onDelete, required this.onViewReceipt});

  /// Build the actions row for each payment record in the table
  Widget buildActionsRow(BuildContext context, PaymentModel payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Receipt Button
        if (payment.hasReceipt)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onViewReceipt(payment),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.5),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.receipt_long, color: Colors.purple, size: context.iconSize('small')),
              ),
            ),
          ),

        if (payment.hasReceipt) SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(payment),
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
            onTap: () => onDelete(payment),
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
  Widget buildErrorState(BuildContext context, PaymentProvider provider) {
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
            l10n.failedToLoadPayments,
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
                  provider.clearError();
                  provider.refreshData();
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
            child: Icon(Icons.payments_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noPaymentsFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startByAddingFirstPaymentToTrack,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),


        ],
      ),
    );
  }

  /// Get payment method color
  Color getPaymentMethodColor(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'bank_transfer':
        return Colors.blue;
      case 'mobile_payment':
        return Colors.purple;
      case 'check':
        return Colors.orange;
      case 'card':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Get payment method icon
  IconData getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank_transfer':
        return Icons.account_balance_rounded;
      case 'mobile_payment':
        return Icons.phone_android_rounded;
      case 'check':
        return Icons.receipt_long_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  /// Get status color based on payment status
  Color getStatusColor(PaymentModel payment) {
    if (payment.isFinalPayment) return Colors.green;
    if (payment.bonus > 0) return Colors.blue;
    if (payment.deduction > 0) return Colors.orange;
    return Colors.grey;
  }

  /// Get status text
  String getStatusText(PaymentModel payment, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (payment.isFinalPayment) return l10n.finalPayment;
    if (payment.bonus > 0) return l10n.withBonus;
    if (payment.deduction > 0) return l10n.withDeduction;
    return l10n.regularPayment;
  }

  /// Get labor initials for avatar
  String getLaborInitials(String? laborName) {
    if (laborName == null || laborName.isEmpty) return 'N/A';
    final words = laborName.trim().split(' ');
    if (words.isEmpty) return 'N/A';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'.toUpperCase();
  }

  /// Format currency for display
  String formatCurrency(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  /// Build status chip
  Widget buildStatusChip(BuildContext context, PaymentModel payment) {
    final color = getStatusColor(payment);
    final text = getStatusText(payment, context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// Build labor avatar
  Widget buildLaborAvatar(BuildContext context, PaymentModel payment) {
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
          getLaborInitials(payment.laborName),
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
        ),
      ),
    );
  }

  /// Build payment method badge
  Widget buildPaymentMethodBadge(BuildContext context, PaymentModel payment) {
    final color = getPaymentMethodColor(payment.paymentMethod);
    final icon = getPaymentMethodIcon(payment.paymentMethod);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            payment.paymentMethod,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
