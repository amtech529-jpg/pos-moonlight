import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/advance_payment/advance_payment_model.dart';

import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class ViewReceiptDialog extends StatefulWidget {
  final AdvancePayment payment;

  const ViewReceiptDialog({super.key, required this.payment});

  @override
  State<ViewReceiptDialog> createState() => _ViewReceiptDialogState();
}

class _ViewReceiptDialogState extends State<ViewReceiptDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 85.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildTabletLayout(),
                  small: _buildMobileLayout(),
                  medium: _buildDesktopLayout(),
                  large: _buildDesktopLayout(),
                  ultrawide: _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: true))),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: true))),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: false))),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.payment.hasReceipt ? [Colors.green, Colors.greenAccent] : [Colors.orange, Colors.orangeAccent]),
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
            child: Icon(
              widget.payment.hasReceipt ? Icons.receipt_rounded : Icons.receipt_long_outlined,
              color: AppTheme.pureWhite,
              size: context.iconSize('large'),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.payment.hasReceipt ? l10n.paymentReceipt : l10n.noReceiptAvailable,
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
                    widget.payment.hasReceipt ? l10n.viewReceiptDetailsAndImage : l10n.addReceiptForThisPayment,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.payment.id,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          SizedBox(width: context.smallPadding),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClose,
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
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentDetails,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                SizedBox(height: context.cardPadding),
                ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildPaymentDetailsCompact(),
                  small: _buildPaymentDetailsCompact(),
                  medium: _buildPaymentDetailsExpanded(),
                  large: _buildPaymentDetailsExpanded(),
                  ultrawide: _buildPaymentDetailsExpanded(),
                ),
              ],
            ),
          ),
          SizedBox(height: context.cardPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildDateTimeCompact(),
            small: _buildDateTimeCompact(),
            medium: _buildDateTime(),
            large: _buildDateTime(),
            ultrawide: _buildDateTime(),
          ),
          SizedBox(height: context.cardPadding),
          _buildDescriptionSection(),
          SizedBox(height: context.cardPadding),
          _buildSalaryProgressSection(),
          SizedBox(height: context.cardPadding),
          if (widget.payment.hasReceipt) ...[_buildReceiptImageSection(isCompact: isCompact)] else ...[_buildNoReceiptSection(isCompact: isCompact)],
          SizedBox(height: context.mainPadding),
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton(
              text: l10n.close,
              onPressed: _handleClose,
              height: context.buttonHeight / (isCompact ? 1 : 1.5),
              isOutlined: true,
              backgroundColor: Colors.grey[600],
              textColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCompact() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.labor,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          widget.payment.laborName,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        Text(
          '${widget.payment.laborRole} • ${widget.payment.laborPhone}',
          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
        Text(
          l10n.amount,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          'PKR ${widget.payment.amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w700, color: Colors.green),
        ),
        Text(
          '${widget.payment.advancePercentage.toStringAsFixed(1)}% ${l10n.ofSalary}',
          style: TextStyle(fontSize: context.captionFontSize, color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsExpanded() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labor,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                widget.payment.laborName,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Text(
                '${widget.payment.laborRole} • ${widget.payment.laborPhone}',
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.amount,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                'PKR ${widget.payment.amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w700, color: Colors.green),
              ),
              Text(
                '${widget.payment.advancePercentage.toStringAsFixed(1)}% ${l10n.ofSalary}',
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.green[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCompact() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
              SizedBox(width: context.smallPadding),
              Text(
                _formatDate(widget.payment.date),
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Row(
            children: [
              Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
              SizedBox(width: context.smallPadding),
              Text(
                widget.payment.timeText,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
                SizedBox(width: context.smallPadding),
                Text(
                  _formatDate(widget.payment.date),
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              children: [
                Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
                SizedBox(width: context.smallPadding),
                Text(
                  widget.payment.timeText,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.description,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            widget.payment.description,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryProgressSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: widget.payment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: widget.payment.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l10n.totalSalary}: PKR ${widget.payment.totalSalary.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                decoration: BoxDecoration(color: widget.payment.statusColor, borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Text(
                  widget.payment.statusText,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.remaining}: PKR ${widget.payment.remainingSalary.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: widget.payment.remainingSalary <= 0 ? Colors.red : AppTheme.charcoalGray,
                ),
              ),
              Text(
                '${((widget.payment.totalSalary - widget.payment.remainingSalary) / widget.payment.totalSalary * 100).toStringAsFixed(1)}% ${l10n.used}',
                style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Container(
            height: ResponsiveBreakpoints.responsive(context, tablet: 6, small: 7, medium: 8, large: 9, ultrawide: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.grey.shade300),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (widget.payment.totalSalary - widget.payment.remainingSalary) / widget.payment.totalSalary,
              child: Container(
                decoration: BoxDecoration(color: widget.payment.statusColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImageSection({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_rounded, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.receiptImage,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            height: ResponsiveBreakpoints.responsive(context, tablet: 25.h, small: 30.h, medium: 35.h, large: 40.h, ultrawide: 45.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: context.iconSize('xl') * 2, color: Colors.grey[500]),
                SizedBox(height: context.smallPadding),
                Text(
                  l10n.receiptImagePreview,
                  style: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[600]),
                ),
                if (widget.payment.receiptImagePath != null) ...[
                  Text(
                    widget.payment.receiptImagePath!,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoReceiptSection({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.orange, size: context.iconSize('xl')),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.noReceiptAvailable,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.smallPadding),
          Text(
            isCompact ? l10n.noReceiptAvailableShort : l10n.noReceiptAvailableLong,
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.orange[400]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),
          PremiumButton(
            text: l10n.addReceipt,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.receiptUploadFunctionalityToBeImplemented,
                    style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.pureWhite),
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                ),
              );
            },
            height: context.buttonHeight,
            icon: Icons.add_photo_alternate_outlined,
            backgroundColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}
