import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/sales/sale_model.dart';
import '../globals/text_button.dart';
import 'package:frontend/presentation/widgets/globals/keyboard_scrollable.dart';
import '../../../src/providers/auth_provider.dart';


class OrderSuccessDialog extends StatefulWidget {
  final SaleModel sale;

  const OrderSuccessDialog({
    super.key,
    required this.sale,
  });

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog> with SingleTickerProviderStateMixin {
  bool get canSeeFinancials => context.watch<AuthProvider>().currentUser?.canSeeFinancials ?? false;
  bool _isPrinting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePrintOrder(BuildContext context) async {
    debugPrint("🖨️ [OrderSuccessDialog] Print Receipt requested for ${widget.sale.invoiceNumber}");

    setState(() => _isPrinting = true);

    try {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final success = await salesProvider.generateReceiptPdf(widget.sale.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Receipt sent to printer/saved"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Failed to generate receipt"),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
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

  void _handleDone(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final canSeeFinancials = currentUser?.canSeeFinancials ?? false;

    final bool isUpdate = widget.sale.updatedAt.difference(widget.sale.createdAt).inSeconds > 5;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 85.w,
                small: 75.w,
                medium: 65.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
              maxHeight: 90.h,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('large')),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.borderRadius('large')),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuccessHeader(context, isUpdate),
                  Flexible(
                    child: KeyboardScrollable(
                      padding: EdgeInsets.all(context.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderSummaryCard(context),
                          SizedBox(height: context.cardPadding),
                          _buildItemsList(context, canSeeFinancials),
                          if (canSeeFinancials) ...[
                            SizedBox(height: context.cardPadding),
                            _buildPaymentInfo(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(context, isUpdate),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context, bool isUpdate) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUpdate 
            ? [const Color(0xFF2196F3), const Color(0xFF00BCD4)] // Blue theme for updates
            : [const Color(0xFF00B09B), const Color(0xFF96C93D)], // Green theme for new
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpdate ? Icons.sync_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpdate ? "Order Updated" : l10n.saleCompleted,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isUpdate 
                    ? "Changes have been synchronized with the backend"
                    : l10n.transactionProcessedSuccessfully,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "REAL-TIME",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sale = widget.sale;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, l10n.invoiceNumber, sale.formattedInvoiceNumber, isBold: true, color: Colors.blue.shade700),
          const Divider(height: 20),
          _buildInfoRow(context, l10n.customer, sale.customerName),
          _buildInfoRow(context, "Date", DateFormat('dd MMM yyyy, hh:mm a').format(sale.createdAt)),
          _buildInfoRow(context, "Status", sale.statusDisplay, color: sale.statusColor),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, bool canSeeFinancials) {
    final sale = widget.sale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              "Order Items (${sale.totalItems})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sale.saleItems.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = sale.saleItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (item.customizationNotes != null && item.customizationNotes!.isNotEmpty)
                            Text(
                              item.customizationNotes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "x${item.quantity}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (canSeeFinancials)
                      Expanded(
                        flex: 2,
                        child: Text(
                          "PKR ${item.lineTotal.toStringAsFixed(0)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sale = widget.sale;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.03),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildAmountRow(context, "Subtotal", sale.subtotal),
          if (sale.overallDiscount > 0)
            _buildAmountRow(context, "Discount", -sale.overallDiscount, color: Colors.orange.shade700),
          if (sale.taxAmount > 0)
            _buildAmountRow(context, "Tax", sale.taxAmount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1.5),
          ),
          _buildAmountRow(context, l10n.totalAmount, sale.grandTotal, isLarge: true, color: Colors.black),
          _buildAmountRow(context, "Amount Paid", sale.amountPaid, color: Colors.green.shade700),
          if (sale.remainingAmount > 0)
            _buildAmountRow(context, "Remaining", sale.remainingAmount, color: Colors.red.shade700, isBold: true),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isUpdate) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PremiumButton(
              text: _isPrinting ? "Printing..." : l10n.printReceipt,
              onPressed: _isPrinting ? null : () => _handlePrintOrder(context),
              icon: _isPrinting ? null : Icons.print_rounded,
              backgroundColor: Colors.blue.shade600,
              isLoading: _isPrinting,
              height: 55,
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: PremiumButton(
              text: isUpdate ? "Done" : l10n.newSale,
              onPressed: () => _handleDone(context),
              icon: isUpdate ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
              backgroundColor: isUpdate ? Colors.blueGrey.shade600 : Colors.green.shade600,
              height: 55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(BuildContext context, String label, double amount, {bool isLarge = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isLarge ? FontWeight.w800 : (isBold ? FontWeight.w700 : FontWeight.w500),
              color: isLarge ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            "PKR ${amount.abs().toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isLarge ? 20 : 15,
              fontWeight: isLarge ? FontWeight.w900 : FontWeight.w700,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final bool isLoading;
  final double height;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    required this.backgroundColor,
    this.isLoading = false,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}