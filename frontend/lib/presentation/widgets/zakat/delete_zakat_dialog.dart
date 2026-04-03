import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/zakat/zakat_model.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';

class DeleteZakatDialog extends StatefulWidget {
  final Zakat zakat;

  const DeleteZakatDialog({
    super.key,
    required this.zakat,
  });

  @override
  State<DeleteZakatDialog> createState() => _DeleteZakatDialogState();
}

class _DeleteZakatDialogState extends State<DeleteZakatDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ZakatProvider>(context, listen: false);

    final success = await provider.deleteZakat(widget.zakat.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      } else {
        _showErrorSnackbar(provider.errorMessage ?? l10n.failedToDeleteZakatRecord);
      }
    }
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.zakatRecordDeletedSuccessfully,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
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
                offset: Offset(
                  _shakeAnimation.value * 2 * (1 - _scaleAnimation.value),
                  0,
                ),
                child: Container(
                  width: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 85.w,
                    small: 75.w,
                    medium: 65.w,
                    large: 55.w,
                    ultrawide: 45.w,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: 550,
                    maxHeight: 85.h,
                  ),
                  margin: EdgeInsets.all(context.mainPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius('large')),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: context.shadowBlur('heavy'),
                        offset: Offset(0, context.cardPadding),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
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
              Icons.warning_rounded,
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
                  context.shouldShowCompactLayout ? l10n.deleteZakat : l10n.deleteZakatRecord,
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
                    l10n.thisActionCannotBeUndone,
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
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: ResponsiveBreakpoints.responsive(
                context,
                tablet: 15.w,
                small: 20.w,
                medium: 12.w,
                large: 10.w,
                ultrawide: 8.w,
              ),
              height: ResponsiveBreakpoints.responsive(
                context,
                tablet: 15.w,
                small: 20.w,
                medium: 12.w,
                large: 10.w,
                ultrawide: 8.w,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                size: context.iconSize('xl'),
                color: Colors.red,
              ),
            ),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            context.shouldShowCompactLayout
                ? l10n.areYouSureYouWantToDeleteThisZakatRecord
                : l10n.areYouAbsolutelySureYouWantToDeleteThisZakatRecord,
            style: TextStyle(
              fontSize: context.bodyFontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),

          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding,
                        vertical: context.smallPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        widget.zakat.id,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        widget.zakat.name,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.beneficiary}:',
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: context.smallPadding / 4),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    _getBeneficiaryInitials(widget.zakat.beneficiaryName),
                                    style: TextStyle(
                                      fontSize: context.captionFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.smallPadding / 2),
                              Expanded(
                                child: Text(
                                  widget.zakat.beneficiaryName,
                                  style: TextStyle(
                                    fontSize: context.subtitleFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.charcoalGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.cardPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${l10n.amount}:',
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: context.smallPadding / 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.smallPadding,
                              vertical: context.smallPadding / 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Text(
                              widget.zakat.formattedAmount,
                              style: TextStyle(
                                fontSize: context.bodyFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryMaroon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.description}:',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      widget.zakat.description,
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoalGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.dateAndTime}:',
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: context.smallPadding / 4),
                          Text(
                            widget.zakat.formattedDate,
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                          Text(
                            widget.zakat.formattedTime,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.cardPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${l10n.authorizedBy}:',
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: context.smallPadding / 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.smallPadding / 2,
                              vertical: context.smallPadding / 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Text(
                              widget.zakat.authorizedInitials,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          SizedBox(height: context.smallPadding / 4),
                          Text(
                            widget.zakat.authorizedBy,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: context.iconSize('small'),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    context.shouldShowCompactLayout
                        ? l10n.thisWillPermanentlyDeleteTheZakatRecord
                        : l10n.thisWillPermanentlyDeleteTheZakatRecordAndAllAssociatedData,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.orange[700],
                    ),
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
        Consumer<ZakatProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.deleteZakat,
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
          child: Consumer<ZakatProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.delete,
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

  String _getBeneficiaryInitials(String beneficiaryName) {
    final words = beneficiaryName.trim().split(' ');
    if (words.isEmpty) return 'B';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'.toUpperCase();
  }
}
