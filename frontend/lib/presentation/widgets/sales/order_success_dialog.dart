import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart'; // ✅ CHANGED: Use SalesProvider
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart'; // ✅ Using PremiumButton

class OrderSuccessDialog extends StatefulWidget {
  final String saleId; // ✅ Required for printing
  final String invoiceNumber; // ✅ Required for display
  final double totalPrice;
  final double advanceAmount;
  final DateTime deliveryDate;

  const OrderSuccessDialog({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.totalPrice,
    required this.advanceAmount,
    required this.deliveryDate,
  });

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog> {
  bool _isPrinting = false; // ✅ State for loading spinner

  // ✅ UPDATED PRINT FUNCTION
  Future<void> _handlePrintOrder(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    debugPrint("🖨️ [OrderSuccessDialog] Print Receipt requested for ${widget.invoiceNumber}");

    setState(() => _isPrinting = true);

    try {
      // Use SalesProvider instead of InvoiceProvider
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      debugPrint(" [OrderSuccessDialog] Calling SalesProvider.generateReceiptPdf with saleId: ${widget.saleId}");

      // Call the new function in SalesProvider
      final success = await salesProvider.generateReceiptPdf(widget.saleId);

      debugPrint(" [OrderSuccessDialog] generateReceiptPdf result: $success");

      if (mounted) {
        if (success) {
          debugPrint(" [OrderSuccessDialog] Print successful");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Receipt sent to printer/saved"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          debugPrint(" [OrderSuccessDialog] Print failed");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Failed to generate receipt"),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(" [OrderSuccessDialog] Print error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text("Error: $e"),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleDone(BuildContext context) {
    // Only pop once. The CheckoutDialog already closed itself before opening this dialog.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: 85.w,
            small: 75.w,
            medium: 65.w,
            large: 55.w,
            ultrawide: 45.w,
          ),
        ),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: context.shadowBlur('heavy'),
              offset: Offset(0, context.cardPadding),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSuccessHeader(context),
              _buildSuccessContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: 40, // ✅ Fixed Large Size
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.saleCompleted,
                  style: TextStyle(
                    fontSize: 24, // ✅ Fixed Large Size
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                  ),
                ),
                Text(
                  l10n.transactionProcessedSuccessfully,
                  style: TextStyle(
                    fontSize: 16, // ✅ Fixed Large Size
                    color: AppTheme.pureWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        children: [
          _buildOrderSummaryCard(context),
          SizedBox(height: context.cardPadding),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ✅ Invoice Number (Real)
          _buildSummaryRow(
            context,
            l10n.invoiceNumber,
            widget.invoiceNumber,
            valueColor: Colors.purple,
            fontSize: 18,
          ),
          SizedBox(height: 12),

          // ✅ Total Amount
          _buildSummaryRow(
            context,
            l10n.totalAmount,
            'PKR ${widget.totalPrice.toStringAsFixed(0)}',
            valueColor: Colors.green,
            isHighlight: true,
            fontSize: 26, // ✅ Extra Big for Visibility
          ),

          if (widget.advanceAmount > 0 && widget.advanceAmount < widget.totalPrice) ...[
            SizedBox(height: 12),
            _buildSummaryRow(
              context,
              l10n.amountPaid,
              'PKR ${widget.advanceAmount.toStringAsFixed(0)}',
              valueColor: Colors.blue,
              fontSize: 18,
            ),
            SizedBox(height: 12),
            _buildSummaryRow(
              context,
              l10n.remaining,
              'PKR ${(widget.totalPrice - widget.advanceAmount).toStringAsFixed(0)}',
              valueColor: Colors.orange,
              fontSize: 18,
            ),
          ],

          SizedBox(height: 12),
          _buildSummaryRow(
            context,
            '${l10n.date}:',
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context,
      String label,
      String value, {
        Color? valueColor,
        bool isHighlight = false,
        double fontSize = 16, // ✅ Default bigger font
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            color: AppTheme.charcoalGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600, // Thicker font
            color: valueColor ?? AppTheme.charcoalGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // ✅ Print Receipt Button using PremiumButton
        Expanded(
          child: PremiumButton(
            text: _isPrinting ? "Printing..." : l10n.printReceipt,
            onPressed: _isPrinting ? null : () => _handlePrintOrder(context),
            icon: _isPrinting ? null : Icons.print_rounded,
            backgroundColor: Colors.blue,
            isLoading: _isPrinting,
            height: 60, // ✅ Taller button for easier tapping
          ),
        ),
        SizedBox(width: context.cardPadding),

        // ✅ New Sale Button using PremiumButton
        Expanded(
          child: PremiumButton(
            text: l10n.newSale,
            onPressed: () => _handleDone(context),
            icon: Icons.add_shopping_cart_rounded,
            backgroundColor: Colors.green,
            height: 60, // ✅ Taller button
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// KEPT EXISTING CLASSES BELOW AS REQUESTED
// --------------------------------------------------------------------------

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
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
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: context.shadowBlur('heavy'),
              offset: Offset(0, context.cardPadding),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildContent(context),
            _buildActions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: (confirmColor ?? AppTheme.primaryMaroon).withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: (confirmColor ?? AppTheme.primaryMaroon).withOpacity(0.2),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Icon(
                icon,
                color: confirmColor ?? AppTheme.primaryMaroon,
                size: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 14.sp,
                  small: 13.sp,
                  medium: 12.sp,
                  large: 11.sp,
                  ultrawide: 10.sp,
                ),
              ),
            ),
            SizedBox(width: context.cardPadding),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 11.sp,
                  small: 10.sp,
                  medium: 9.sp,
                  large: 8.5.sp,
                  ultrawide: 8.sp,
                ),
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Text(
        message,
        style: TextStyle(
          fontSize: ResponsiveBreakpoints.responsive(
            context,
            tablet: 9.sp,
            small: 8.5.sp,
            medium: 8.sp,
            large: 7.5.sp,
            ultrawide: 7.sp,
          ),
          color: Colors.grey[700],
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCancel ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.cardPadding / 1.5,
                    ),
                    child: Text(
                      cancelText ?? l10n.cancel,
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.responsive(
                          context,
                          tablet: 9.sp,
                          small: 8.5.sp,
                          medium: 8.sp,
                          large: 7.5.sp,
                          ultrawide: 7.sp,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: confirmColor ?? AppTheme.primaryMaroon,
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onConfirm,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.cardPadding / 1.5,
                    ),
                    child: Text(
                      confirmText ?? l10n.confirm,
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.responsive(
                          context,
                          tablet: 9.sp,
                          small: 8.5.sp,
                          medium: 8.sp,
                          large: 7.5.sp,
                          ultrawide: 7.sp,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.pureWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(context.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryMaroon,
              strokeWidth: 3,
            ),
            SizedBox(height: context.cardPadding),
            Text(
              message ?? l10n.processing,
              style: TextStyle(
                fontSize: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 9.sp,
                  small: 8.5.sp,
                  medium: 8.sp,
                  large: 7.5.sp,
                  ultrawide: 7.sp,
                ),
                color: AppTheme.charcoalGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}