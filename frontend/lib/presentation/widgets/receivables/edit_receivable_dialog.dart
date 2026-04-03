import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/receivables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EditReceivableDialog extends StatefulWidget {
  final Receivable receivable;

  const EditReceivableDialog({
    super.key,
    required this.receivable,
  });

  @override
  State<EditReceivableDialog> createState() => _EditReceivableDialogState();
}

class _EditReceivableDialogState extends State<EditReceivableDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _debtorNameController;
  late TextEditingController _debtorPhoneController;
  late TextEditingController _amountGivenController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late TextEditingController _amountReturnedController;

  late DateTime _dateLent;
  late DateTime _expectedReturnDate;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _debtorNameController = TextEditingController(text: widget.receivable.debtorName);
    _debtorPhoneController = TextEditingController(text: widget.receivable.debtorPhone);
    _amountGivenController = TextEditingController(text: widget.receivable.amountGiven.toString());
    _reasonController = TextEditingController(text: widget.receivable.reasonOrItem);
    _notesController = TextEditingController(text: widget.receivable.notes ?? '');
    _amountReturnedController = TextEditingController(text: widget.receivable.amountReturned.toString());
    _dateLent = widget.receivable.dateLent;
    _expectedReturnDate = widget.receivable.expectedReturnDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debtorNameController.dispose();
    _debtorPhoneController.dispose();
    _amountGivenController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _amountReturnedController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final amountGiven = double.parse(_amountGivenController.text.trim());
      final amountReturned = double.tryParse(_amountReturnedController.text.trim()) ?? 0.0;

      if (amountReturned > amountGiven) {
        _showErrorSnackbar(l10n.amountReturnedCannotExceedAmountGiven);
        return;
      }

      if (_expectedReturnDate.isBefore(_dateLent)) {
        _showErrorSnackbar(l10n.expectedReturnDateCannotBeBeforeDateLent);
        return;
      }

      final receivablesProvider = Provider.of<ReceivablesProvider>(context, listen: false);

      await receivablesProvider.updateReceivable(
        id: widget.receivable.id,
        debtorName: _debtorNameController.text.trim(),
        debtorPhone: _debtorPhoneController.text.trim(),
        amountGiven: amountGiven,
        reasonOrItem: _reasonController.text.trim(),
        dateLent: _dateLent,
        expectedReturnDate: _expectedReturnDate,
        amountReturned: amountReturned,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
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
              l10n.receivableUpdatedSuccessfully,
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
            Text(
              message,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
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

  Future<void> _selectDateLent() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateLent,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryMaroon,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateLent) {
      setState(() {
        _dateLent = picked;
        if (_expectedReturnDate.isBefore(_dateLent.add(const Duration(days: 1)))) {
          _expectedReturnDate = _dateLent.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectExpectedReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate,
      firstDate: _dateLent.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryMaroon,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expectedReturnDate) {
      setState(() {
        _expectedReturnDate = picked;
      });
    }
  }

  double get balanceRemaining {
    final amountGiven = double.tryParse(_amountGivenController.text) ?? 0;
    final amountReturned = double.tryParse(_amountReturnedController.text) ?? 0;
    return amountGiven - amountReturned;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 95.w,
                    small: 85.w,
                    medium: 75.w,
                    large: 65.w,
                    ultrawide: 55.w,
                  ),
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
        Flexible(
          child: SingleChildScrollView(
            child: _buildFormContent(isCompact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            child: _buildFormContent(isCompact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            child: _buildFormContent(isCompact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
              Icons.edit_outlined,
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
                  context.shouldShowCompactLayout ? l10n.editReceivable : l10n.editReceivableDetails,
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
                    l10n.updateReceivableInformation,
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
            padding: EdgeInsets.symmetric(
              horizontal: context.smallPadding,
              vertical: context.smallPadding / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Text(
              widget.receivable.id,
              style: TextStyle(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),
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

  Widget _buildFormContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: l10n.debtorName,
              hint: isCompact ? l10n.enterName : l10n.enterDebtorFullName,
              controller: _debtorNameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterDebtorName;
                if (value!.length < 2) return l10n.nameMustBeAtLeast2Characters;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.phone,
              hint: isCompact ? l10n.enterPhone : l10n.enterPhoneNumber,
              controller: _debtorPhoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterPhoneNumber;
                if (value!.length < 10) return l10n.pleaseEnterValidPhoneNumber;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.amountGivenPkr,
                    hint: l10n.enterAmount,
                    controller: _amountGivenController,
                    prefixIcon: Icons.trending_up_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.pleaseEnterAmount;
                      final amount = double.tryParse(value!);
                      if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: l10n.amountReturnedPkr,
                    hint: l10n.enterReturned,
                    controller: _amountReturnedController,
                    prefixIcon: Icons.trending_down_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final amountReturned = double.tryParse(value);
                        if (amountReturned == null || amountReturned < 0) return l10n.enterValidAmount;
                        final amountGiven = double.tryParse(_amountGivenController.text) ?? 0;
                        if (amountReturned > amountGiven) return l10n.cannotExceedAmountGiven;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_amountGivenController.text.isNotEmpty || _amountReturnedController.text.isNotEmpty) ...[
              SizedBox(height: context.cardPadding),
              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  color: balanceRemaining >= 0 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(
                    color: balanceRemaining >= 0 ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: balanceRemaining >= 0 ? Colors.orange : Colors.red,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        '${l10n.balanceRemaining} PKR ${balanceRemaining.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: balanceRemaining >= 0 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: '${l10n.reasonItem} (${l10n.optional})',
              hint: isCompact ? l10n.reasonForLending : l10n.enterReasonForLendingOrItemDescription,
              controller: _reasonController,
              prefixIcon: Icons.assignment_outlined,
              maxLines: ResponsiveBreakpoints.responsive(
                context,
                tablet: 2,
                small: 3,
                medium: 4,
                large: 5,
                ultrawide: 6,
              ),
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.notesOptional,
              hint: isCompact ? l10n.additionalNotes : l10n.enterAdditionalNotesOrTerms,
              controller: _notesController,
              prefixIcon: Icons.note_outlined,
              maxLines: ResponsiveBreakpoints.responsive(
                context,
                tablet: 3,
                small: 3,
                medium: 4,
                large: 4,
                ultrawide: 4,
              ),
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDateLent,
                    child: PremiumTextField(
                      label: l10n.dateLent,
                      hint: l10n.selectDate,
                      controller: TextEditingController(
                          text: '${_dateLent.day}/${_dateLent.month}/${_dateLent.year}'),
                      prefixIcon: Icons.calendar_today,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectExpectedReturnDate,
                    child: PremiumTextField(
                      label: l10n.expectedReturnDate,
                      hint: l10n.selectDate,
                      controller: TextEditingController(
                          text: '${_expectedReturnDate.day}/${_expectedReturnDate.month}/${_expectedReturnDate.year}'),
                      prefixIcon: Icons.event_available,
                      enabled: false,
                    ),
                  ),
                ),
              ],
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
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<ReceivablesProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateReceivable,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: AppTheme.primaryMaroon,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleCancel,
          isOutlined: true,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Consumer<ReceivablesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updateReceivable,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: AppTheme.primaryMaroon,
              );
            },
          ),
        ),
      ],
    );
  }
}
