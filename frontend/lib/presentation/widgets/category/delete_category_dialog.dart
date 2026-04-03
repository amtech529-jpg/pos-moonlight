import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';

class DeleteCategoryDialog extends StatefulWidget {
  final Category category;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  bool _isPermanentDelete = true;
  bool _confirmationChecked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_confirmationChecked) {
      _showValidationSnackbar();
      return;
    }

    final provider = Provider.of<CategoryProvider>(context, listen: false);

    bool success;
    if (_isPermanentDelete) {
      success = await provider.deleteCategory(widget.category.id);
    } else {
      success = await provider.softDeleteCategory(widget.category.id);
    }

    if (mounted) {
      if (success) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      } else {
        _showErrorSnackbar(provider.errorMessage ?? l10n.failedToDeleteCategory);
      }
    }
  }

  void _showValidationSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.pleaseConfirmYouUnderstandThisAction,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
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
              _isPermanentDelete
                  ? l10n.categoryDeletedPermanently
                  : l10n.categoryDeactivatedSuccessfully,
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
              Icons.error_outline,
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
        duration: const Duration(seconds: 4),
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
                    medium: 60.w,
                    large: 50.w,
                    ultrawide: 40.w,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: 500,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildContent(),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPermanentDelete
              ? [Colors.red, Colors.redAccent]
              : [Colors.orange, Colors.orangeAccent],
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
              _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
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
                  _isPermanentDelete ? l10n.deletePermanently : l10n.deactivateCategory,
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
                    _isPermanentDelete
                        ? l10n.thisActionCannotBeUndone
                        : l10n.categoryCanBeRestoredLater,
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

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        l10n.chooseDeletionType,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.cardPadding),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPermanentDelete = true;
                          _confirmationChecked = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          color: _isPermanentDelete
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          border: Border.all(
                            color: _isPermanentDelete ? Colors.red : Colors.grey.shade300,
                            width: _isPermanentDelete ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              color: _isPermanentDelete ? Colors.red : Colors.grey,
                              size: context.iconSize('medium'),
                            ),
                            SizedBox(height: context.smallPadding),
                            Text(
                              l10n.permanentDelete,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w600,
                                color: _isPermanentDelete ? Colors.red : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.smallPadding / 2),
                            Text(
                              l10n.completelyRemovesFromDatabase,
                              style: TextStyle(
                                fontSize: context.captionFontSize * 0.9,
                                color: _isPermanentDelete ? Colors.red[600] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: context.cardPadding),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPermanentDelete = false;
                          _confirmationChecked = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          color: !_isPermanentDelete
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          border: Border.all(
                            color: !_isPermanentDelete ? Colors.orange : Colors.grey.shade300,
                            width: !_isPermanentDelete ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.visibility_off_rounded,
                              color: !_isPermanentDelete ? Colors.orange : Colors.grey,
                              size: context.iconSize('medium'),
                            ),
                            SizedBox(height: context.smallPadding),
                            Text(
                              l10n.deactivate,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w600,
                                color: !_isPermanentDelete ? Colors.orange : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.smallPadding / 2),
                            Text(
                              l10n.hidesButCanBeRestored,
                              style: TextStyle(
                                fontSize: context.captionFontSize * 0.9,
                                color: !_isPermanentDelete ? Colors.orange[600] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.mainPadding),

              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(
                    color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.2),
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
                            color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(context.borderRadius('small')),
                          ),
                          child: Text(
                            widget.category.id,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w600,
                              color: _isPermanentDelete ? Colors.red : Colors.orange,
                            ),
                          ),
                        ),

                        SizedBox(width: context.smallPadding),

                        Expanded(
                          child: Text(
                            widget.category.name,
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

                    if (widget.category.description.isNotEmpty && !context.isTablet) ...[
                      SizedBox(height: context.smallPadding),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.category.description,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: context.cardPadding),

              Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: CheckboxListTile(
                  value: _confirmationChecked,
                  onChanged: (value) {
                    setState(() {
                      _confirmationChecked = value ?? false;
                    });
                  },
                  title: Text(
                    _isPermanentDelete
                        ? l10n.iUnderstandPermanentDeleteCategory
                        : l10n.iUnderstandDeactivateCategory,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: (_isPermanentDelete ? Colors.red : Colors.orange)[700],
                    ),
                  ),
                  activeColor: _isPermanentDelete ? Colors.red : Colors.orange,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
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
        ),
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

        Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: _isPermanentDelete ? l10n.deletePermanently : l10n.deactivateCategory,
              onPressed: provider.isLoading ? null : _handleDelete,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
              backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
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
          child: Consumer<CategoryProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: _isPermanentDelete ? l10n.delete : l10n.deactivate,
                onPressed: provider.isLoading ? null : _handleDelete,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
                backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
              );
            },
          ),
        ),
      ],
    );
  }
}
