import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class DeleteSaleDialog extends StatefulWidget {
  final SaleModel sale;

  const DeleteSaleDialog({super.key, required this.sale});

  @override
  State<DeleteSaleDialog> createState() => _DeleteSaleDialogState();
}

class _DeleteSaleDialogState extends State<DeleteSaleDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final provider = Provider.of<SalesProvider>(context, listen: false);

    await provider.deleteSale(widget.sale.id);

    if (mounted) {
      _showSuccessSnackbar();
      Navigator.of(context).pop();
    }
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.saleDeletedSuccessfully,
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

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(_shakeAnimation.value * 2 * (1 - _scaleAnimation.value), 0),
                child: Container(
                  width: context.dialogWidth,
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 85.w, small: 75.w, medium: 65.w, large: 55.w, ultrawide: 45.w),
                    maxHeight: 85.h,
                  ),
                  margin: EdgeInsets.all(context.mainPadding),
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
                      _buildHeader(),
                      Flexible(
                        child: SingleChildScrollView(
                          child: ResponsiveBreakpoints.responsive(
                            context,
                            tablet: _buildCompactContent(),
                            small: _buildCompactContent(),
                            medium: _buildDesktopContent(),
                            large: _buildDesktopContent(),
                            ultrawide: _buildDesktopContent(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactContent() {
    return _buildContent(isCompact: true);
  }

  Widget _buildDesktopContent() {
    return _buildContent(isCompact: false);
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.warning_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.deleteSale : l10n.deleteSaleRecord,
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    l10n.actionCannotBeUndone,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
              height: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.delete_forever_rounded, size: context.iconSize('xl'), color: Colors.red),
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            isCompact ? l10n.areYouSureDeleteSale : l10n.areYouAbsolutelySure,
            style: TextStyle(fontSize: context.bodyFontSize * 1.1, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.cardPadding),

          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        widget.sale.id,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        widget.sale.formattedInvoiceNumber,
                        style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                      decoration: BoxDecoration(
                        color: widget.sale.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        widget.sale.status,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: widget.sale.statusColor),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),

                Row(
                  children: [
                    Icon(Icons.person_rounded, color: Colors.grey[600], size: context.iconSize('small')),
                    SizedBox(width: context.smallPadding / 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sale.customerName,
                            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                          ),
                          Text(
                            widget.sale.customerPhone,
                            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),

                if (isCompact)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.items}:',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          Text(
                            '${widget.sale.totalItems}',
                            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                          ),
                        ],
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.grandTotal}:',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          Text(
                            'PKR ${widget.sale.grandTotal.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
                          ),
                        ],
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.amountPaid}:',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          Text(
                            'PKR ${widget.sale.amountPaid.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green),
                          ),
                        ],
                      ),
                      if (widget.sale.remainingAmount > 0) ...[
                        SizedBox(height: context.smallPadding / 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.remaining}:',
                              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                            ),
                            Text(
                              'PKR ${widget.sale.remainingAmount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.items}: ${widget.sale.totalItems}',
                              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                            ),
                            Text(
                              '${l10n.total}: PKR ${widget.sale.grandTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: context.subtitleFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${l10n.paid}: PKR ${widget.sale.amountPaid.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green),
                            ),
                            if (widget.sale.remainingAmount > 0)
                              Text(
                                '${l10n.due}: PKR ${widget.sale.remainingAmount.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: context.smallPadding),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.date}:',
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        Text(
                          widget.sale.dateTimeText,
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${l10n.payment}:',
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPaymentMethodIcon(widget.sale.paymentMethod),
                              color: _getPaymentMethodColor(widget.sale.paymentMethod),
                              size: context.iconSize('small'),
                            ),
                            SizedBox(width: context.smallPadding / 2),
                            Text(
                              widget.sale.paymentMethod,
                              style: TextStyle(
                                fontSize: context.subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: _getPaymentMethodColor(widget.sale.paymentMethod),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                if (widget.sale.notes?.isNotEmpty == true) ...[
                  SizedBox(height: context.smallPadding),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.notes}:',
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        Text(
                          widget.sale.notes ?? '',
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    isCompact ? l10n.permanentDeleteWarningShort : l10n.permanentDeleteWarningLong,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.mainPadding),

          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildCompactButtons(),
            small: _buildCompactButtons(),
            medium: _buildDesktopButtons(),
            large: _buildDesktopButtons(),
            ultrawide: _buildDesktopButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleCancel,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: AppTheme.pureWhite,
        ),
        SizedBox(height: context.cardPadding),
        Consumer<SalesProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: provider.isLoading ? l10n.deleting : l10n.deleteSaleButton,
              onPressed: provider.isLoading ? null : _handleDelete,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.delete_forever_rounded,
              backgroundColor: Colors.red,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: AppTheme.pureWhite,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 1,
          child: Consumer<SalesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: provider.isLoading ? l10n.deleting : l10n.delete,
                onPressed: provider.isLoading ? null : _handleDelete,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.delete_forever_rounded,
                backgroundColor: Colors.red,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Cash':
        return Colors.green;
      case 'Card':
        return Colors.blue;
      case 'Bank Transfer':
        return Colors.purple;
      case 'Credit':
        return Colors.orange;
      case 'Split':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money_rounded;
      case 'Card':
        return Icons.credit_card_rounded;
      case 'Bank Transfer':
        return Icons.account_balance_rounded;
      case 'Credit':
        return Icons.account_balance_wallet_rounded;
      case 'Split':
        return Icons.call_split_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}
