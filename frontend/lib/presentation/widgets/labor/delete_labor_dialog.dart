import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'delete_labor_widgets.dart';

class EnhancedDeleteLaborDialog extends StatefulWidget {
  final LaborModel labor;

  const EnhancedDeleteLaborDialog({
    super.key,
    required this.labor,
  });

  @override
  State<EnhancedDeleteLaborDialog> createState() => _EnhancedDeleteLaborDialogState();
}

class _EnhancedDeleteLaborDialogState extends State<EnhancedDeleteLaborDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  bool _isPermanentDelete = true;
  bool _confirmationChecked = false;
  bool _understandConsequences = false;
  String _confirmationText = '';

  final TextEditingController _confirmationController = TextEditingController();

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

    _confirmationController.addListener(() {
      setState(() {
        _confirmationText = _confirmationController.text;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_validateDeletion()) {
      _showValidationError();
      return;
    }

    final provider = Provider.of<LaborProvider>(context, listen: false);

    bool success;
    String successMessage;

    try {
      if (_isPermanentDelete) {
        success = await provider.deleteLabor(widget.labor.id);
        successMessage = l10n.laborDeletedPermanently;
      } else {
        success = await provider.softDeleteLabor(widget.labor.id);
        successMessage = l10n.laborDeactivatedSuccessfully;
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackbar(successMessage);
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackbar(provider.errorMessage ?? l10n.failedToDeleteLabor);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('${l10n.unexpectedErrorOccurred}: ${e.toString()}');
      }
    }
  }

  bool _validateDeletion() {
    if (!_confirmationChecked) {
      return false;
    }

    if (_isPermanentDelete) {
      if (!_understandConsequences) {
        return false;
      }
      return _confirmationText.toLowerCase().trim() == widget.labor.name.toLowerCase().trim();
    } else {
      return true;
    }
  }

  void _showValidationError() {
    final l10n = AppLocalizations.of(context)!;
    String message;

    if (!_confirmationChecked) {
      message = l10n.pleaseConfirmYouUnderstandThisAction;
    } else if (_isPermanentDelete && !_understandConsequences) {
      message = l10n.pleaseConfirmYouUnderstandConsequences;
    } else if (_isPermanentDelete && _confirmationText.toLowerCase().trim() != widget.labor.name.toLowerCase().trim()) {
      message = l10n.pleaseTypeLaborNameExactly;
    } else {
      message = l10n.pleaseCompleteAllConfirmationSteps;
    }

    _showSnackbar(message, Colors.orange, Icons.warning_outlined);
  }

  void _showSuccessSnackbar(String message) {
    _showSnackbar(message, Colors.green, Icons.check_circle_rounded);
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar(message, Colors.red, Icons.error_outline);
  }

  void _showSnackbar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
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
        backgroundColor: color,
        duration: Duration(seconds: color == Colors.red ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop(false);
    });
  }

  void _handleDeleteTypeChange(bool isPermanent) {
    setState(() {
      _isPermanentDelete = isPermanent;
      _confirmationChecked = false;
      _understandConsequences = false;
      _confirmationText = '';
      _confirmationController.clear();
    });
  }

  void _updateConfirmationChecked(bool value) {
    setState(() {
      _confirmationChecked = value;
    });
  }

  void _updateUnderstandConsequences(bool value) {
    setState(() {
      _understandConsequences = value;
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
                    small: 90.w,
                    medium: 70.w,
                    large: 60.w,
                    ultrawide: 50.w,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: 90.h,
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
                      DeleteLaborHeader(
                        labor: widget.labor,
                        isPermanentDelete: _isPermanentDelete,
                        onCancel: _handleCancel,
                      ),
                      Flexible(
                        child: DeleteLaborContent(
                          labor: widget.labor,
                          isPermanentDelete: _isPermanentDelete,
                          confirmationChecked: _confirmationChecked,
                          understandConsequences: _understandConsequences,
                          confirmationController: _confirmationController,
                          onDeleteTypeChange: _handleDeleteTypeChange,
                          onConfirmationCheckedChange: _updateConfirmationChecked,
                          onUnderstandConsequencesChange: _updateUnderstandConsequences,
                          onDelete: _handleDelete,
                          onCancel: _handleCancel,
                          validateDeletion: _validateDeletion,
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
}
