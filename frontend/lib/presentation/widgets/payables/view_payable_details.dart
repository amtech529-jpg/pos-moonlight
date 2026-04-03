import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../../../l10n/app_localizations.dart';

class ViewPayableDetailsDialog extends StatefulWidget {
  final Payable payable;

  const ViewPayableDetailsDialog({super.key, required this.payable});

  @override
  State<ViewPayableDetailsDialog> createState() => _ViewPayableDetailsDialogState();
}

class _ViewPayableDetailsDialogState extends State<ViewPayableDetailsDialog> with SingleTickerProviderStateMixin {
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
        gradient: LinearGradient(colors: [widget.payable.statusColorValue, widget.payable.statusColorValue.withOpacity(0.7)]),
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
            child: Icon(Icons.credit_card_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.payableDetails,
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
                    l10n.viewCompletePayableInformation,
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
              '#${widget.payable.id.length > 8 ? widget.payable.id.substring(0, 8).toUpperCase() : widget.payable.id.toUpperCase()}',
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
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Creditor Information Card
          _buildCreditorInfoCard(isCompact),
          SizedBox(height: context.cardPadding),

          // Amount Details Card
          _buildAmountDetailsCard(isCompact),
          SizedBox(height: context.cardPadding),

          // Status and Progress Card
          _buildStatusCard(isCompact),
          SizedBox(height: context.cardPadding),

          // Date Information Card
          _buildDateInfoCard(isCompact),
          SizedBox(height: context.cardPadding),

          // Reason and Notes Card
          _buildReasonNotesCard(isCompact),
          SizedBox(height: context.mainPadding),

          // Close Button
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton(
              text: AppLocalizations.of(context)!.close,
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

  Widget _buildCreditorInfoCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.creditorInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildCreditorInfoCompact(),
            small: _buildCreditorInfoCompact(),
            medium: _buildCreditorInfoExpanded(),
            large: _buildCreditorInfoExpanded(),
            ultrawide: _buildCreditorInfoExpanded(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditorInfoCompact() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.name,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          widget.payable.creditorName,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.cardPadding),
        Text(
          l10n.phoneNumber,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          widget.payable.creditorPhone ?? l10n.notAvailable,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
      ],
    );
  }

  Widget _buildCreditorInfoExpanded() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.name,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                widget.payable.creditorName,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.phoneNumber,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                widget.payable.creditorPhone ?? l10n.notAvailable,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDetailsCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: Colors.red, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.amountBreakdown,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.red[700]),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.amountBorrowed}:',
                style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
              ),
              Text(
                'PKR ${widget.payable.amountBorrowed.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.red),
              ),
            ],
          ),
          if (widget.payable.amountPaid > 0) ...[
            SizedBox(height: context.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.amountPaid}:',
                  style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
                ),
                Text(
                  'PKR ${widget.payable.amountPaid.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ],
            ),
          ],
          SizedBox(height: context.cardPadding),
          Container(width: double.infinity, height: 1, color: Colors.grey.shade300),
          SizedBox(height: context.cardPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.balanceRemaining}:',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Text(
                'PKR ${widget.payable.balanceRemaining.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: widget.payable.balanceRemaining > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: widget.payable.statusColorValue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: widget.payable.statusColorValue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  color: widget.payable.statusColorValue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Icon(
                  widget.payable.isFullyPaid
                      ? Icons.check_circle
                      : widget.payable.isOverdueComputed
                      ? Icons.warning
                      : Icons.schedule,
                  color: widget.payable.statusColorValue,
                  size: context.iconSize('medium'),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.status,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    Text(
                      widget.payable.statusText,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: widget.payable.statusColorValue),
                    ),
                  ],
                ),
              ),
              if (widget.payable.isOverdueComputed) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Text(
                    l10n.daysOverdueCount(widget.payable.daysOverdue),
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                  ),
                ),
              ],
            ],
          ),
          if (!widget.payable.isFullyPaid) ...[
            SizedBox(height: context.cardPadding),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.paymentProgress,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    Text(
                      '${widget.payable.paymentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w600,
                        color: widget.payable.statusColorValue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding),
                LinearProgressIndicator(
                  value: widget.payable.paymentPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(widget.payable.statusColorValue),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateInfoCard(bool isCompact) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildDateInfoCompact(),
      small: _buildDateInfoCompact(),
      medium: _buildDateInfoExpanded(),
      large: _buildDateInfoExpanded(),
      ultrawide: _buildDateInfoExpanded(),
    );
  }

  Widget _buildDateInfoCompact() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.dateBorrowed,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.payable.formattedDateBorrowed,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available, size: context.iconSize('small'), color: Colors.orange),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.expectedRepaymentDate,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.payable.formattedExpectedRepaymentDate,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: widget.payable.isOverdueComputed ? Colors.red : AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfoExpanded() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.dateBorrowed,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.payable.formattedDateBorrowed,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_available, size: context.iconSize('small'), color: Colors.orange),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.expectedRepayment,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.payable.formattedExpectedRepaymentDate,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: widget.payable.isOverdueComputed ? Colors.red : AppTheme.charcoalGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonNotesCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.grey[700], size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.transactionDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Text(
            '${l10n.reasonItem}:',
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            widget.payable.reasonOrItem,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
          ),
          if (widget.payable.notes != null && widget.payable.notes!.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            Text(
              '${l10n.notes}:',
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            SizedBox(height: context.smallPadding / 2),
            Text(
              widget.payable.notes!,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
            ),
          ],
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.created}:',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDateTime(widget.payable.createdAt),
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.lastUpdated}:',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    Text(
                      widget.payable.updatedAt != null ? _formatDateTime(widget.payable.updatedAt!) : l10n.notUpdated,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
