import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';

import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../../../src/models/principal_account/principal_account_model.dart';
import '../../../l10n/app_localizations.dart';

class ViewPrincipalAccountDetailsDialog extends StatefulWidget {
  final PrincipalAccount account;

  const ViewPrincipalAccountDetailsDialog({super.key, required this.account});

  @override
  State<ViewPrincipalAccountDetailsDialog> createState() => _ViewPrincipalAccountDetailsDialogState();
}

class _ViewPrincipalAccountDetailsDialogState extends State<ViewPrincipalAccountDetailsDialog> with SingleTickerProviderStateMixin {
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
        return Material(
          color: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
          child: Center(
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
        gradient: LinearGradient(colors: [widget.account.typeColor, widget.account.typeColor.withOpacity(0.8)]),
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
            child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.principalAccountDetails,
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
                    l10n.viewCompleteTransactionInformation,
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
              widget.account.id,
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
          _buildTransactionTypeCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildSourceModuleCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildBalanceInfoCard(isCompact),
          SizedBox(height: context.cardPadding),
          if (widget.account.handledBy != null) ...[_buildHandlerInfoCard(isCompact), SizedBox(height: context.cardPadding)],
          _buildDateTimeInfoCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildDescriptionCard(isCompact),
          if (widget.account.notes != null && widget.account.notes!.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            _buildNotesCard(isCompact),
          ],
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

  Widget _buildTransactionTypeCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: widget.account.typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: widget.account.typeColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.account.typeIcon, color: widget.account.typeColor, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.transactionDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    color: widget.account.typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.type,
                        style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.account.typeIcon, color: widget.account.typeColor, size: context.iconSize('small')),
                          SizedBox(width: context.smallPadding / 2),
                          Text(
                            widget.account.type.toUpperCase(),
                            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: widget.account.typeColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    color: widget.account.typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.amount,
                        style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        'PKR ${widget.account.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.headerFontSize * 0.8,
                          fontWeight: FontWeight.w800,
                          color: widget.account.typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceModuleCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: widget.account.sourceModuleColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: widget.account.sourceModuleColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getSourceModuleIcon(widget.account.sourceModule), color: widget.account.sourceModuleColor, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.sourceModuleInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    color: widget.account.sourceModuleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.module,
                        style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Row(
                        children: [
                          Icon(
                            _getSourceModuleIcon(widget.account.sourceModule),
                            color: widget.account.sourceModuleColor,
                            size: context.iconSize('small'),
                          ),
                          SizedBox(width: context.smallPadding / 2),
                          Text(
                            widget.account.sourceModule.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: widget.account.sourceModuleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.account.sourceId != null) ...[
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(context.cardPadding),
                    decoration: BoxDecoration(
                      color: widget.account.sourceModuleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sourceID,
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                        ),
                        SizedBox(height: context.smallPadding / 2),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(context.borderRadius('small')),
                          ),
                          child: Text(
                            widget.account.sourceId!,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: widget.account.sourceModuleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfoCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.balanceInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.blue[700]),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.mainPadding),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              children: [
                Text(
                  l10n.balanceAfterTransaction,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                ),
                SizedBox(height: context.smallPadding),
                Text(
                  'PKR ${widget.account.balanceAfter.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w800, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandlerInfoCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: _getPersonColor(widget.account.handledBy!).withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: _getPersonColor(widget.account.handledBy!).withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: _getPersonColor(widget.account.handledBy!), size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.handlerInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: _getPersonColor(widget.account.handledBy!).withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _getPersonColor(widget.account.handledBy!), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: AppTheme.pureWhite, size: context.iconSize('small')),
                ),
                SizedBox(width: context.cardPadding),
                Text(
                  widget.account.handledBy!,
                  style: TextStyle(
                    fontSize: context.bodyFontSize * 1.1,
                    fontWeight: FontWeight.w700,
                    color: _getPersonColor(widget.account.handledBy!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfoCard(bool isCompact) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildDateTimeInfoCompact(),
      small: _buildDateTimeInfoCompact(),
      medium: _buildDateTimeInfoExpanded(),
      large: _buildDateTimeInfoExpanded(),
      ultrawide: _buildDateTimeInfoExpanded(),
    );
  }

  Widget _buildDateTimeInfoCompact() {
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
                    l10n.date,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.account.formattedDate,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.account.relativeDate,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
                  Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.time,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.account.formattedTime,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeInfoExpanded() {
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
                      l10n.date,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.account.formattedDate,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.account.relativeDate,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
                    Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.time,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.account.formattedTime,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.grey[700], size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.transactionDescription,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              widget.account.description,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray, height: 1.5),
            ),
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.recordCreated}:',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDateTime(widget.account.dateTime),
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Text(
                  l10n.ledgerEntry,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_outlined, color: Colors.amber[700], size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.additionalNotes,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              widget.account.notes!,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getSourceModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'sales':
        return Icons.point_of_sale_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'advance_payment':
        return Icons.schedule_send_rounded;
      case 'expenses':
        return Icons.receipt_long_rounded;
      case 'receivables':
        return Icons.account_balance_outlined;
      case 'payables':
        return Icons.money_off_outlined;
      case 'zakat':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getPersonColor(String person) {
    switch (person) {
      case 'Shahzain Baloch':
        return Colors.blue;
      case 'Huzaifa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
