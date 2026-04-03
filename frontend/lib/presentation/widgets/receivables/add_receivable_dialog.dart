import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/receivables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class AddReceivableDialog extends StatefulWidget {
  const AddReceivableDialog({super.key});

  @override
  State<AddReceivableDialog> createState() => _AddReceivableDialogState();
}

class _AddReceivableDialogState extends State<AddReceivableDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _debtorNameController = TextEditingController();
  final _debtorPhoneController = TextEditingController();
  final _amountGivenController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountReturnedController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime _dateLent = DateTime.now();
  DateTime _expectedReturnDate = DateTime.now().add(const Duration(days: 30));

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
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
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
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

      await receivablesProvider.addReceivable(
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
              l10n.receivableAddedSuccessfully,
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
                    small: 90.w,
                    medium: 80.w,
                    large: 70.w,
                    ultrawide: 60.w,
                  ),
                  maxHeight: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 90.h,
                    small: 95.h,
                    medium: 85.h,
                    large: 80.h,
                    ultrawide: 75.h,
                  ),
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
                      child: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: _buildScrollableContent(),
                        small: _buildScrollableContent(),
                        medium: _buildDesktopLayout(),
                        large: _buildDesktopLayout(),
                        ultrawide: _buildDesktopLayout(),
                      ),
                    ),
                  ],
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
              Icons.account_balance_wallet_rounded,
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
                  context.shouldShowCompactLayout ? l10n.addReceivable : l10n.addNewReceivable,
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
                    l10n.recordAmountLentToCustomerOrSupplier,
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

  Widget _buildScrollableContent() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDebtorInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
              SizedBox(height: context.cardPadding),
              _buildDetailsCard(),
              SizedBox(height: context.cardPadding),
              _buildDatesCard(),
              SizedBox(height: context.mainPadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDebtorInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
              SizedBox(height: context.cardPadding),
              _buildDetailsCard(),
              SizedBox(height: context.cardPadding),
              _buildDatesCard(),
              SizedBox(height: context.mainPadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtorInfoCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: context.shadowBlur('light'),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.debtorInformation,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.debtorName,
            hint: context.shouldShowCompactLayout ? l10n.enterName : l10n.enterDebtorFullName,
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
            hint: context.shouldShowCompactLayout ? l10n.enterPhone : l10n.enterPhoneNumber,
            controller: _debtorPhoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterPhoneNumber;
              if (value!.length < 10) return l10n.pleaseEnterValidPhoneNumber;
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: context.shadowBlur('light'),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.amountDetails,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.amountGivenPkr,
            hint: context.shouldShowCompactLayout ? l10n.enterAmount : l10n.enterAmountGivenToDebtor,
            controller: _amountGivenController,
            prefixIcon: Icons.trending_up_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterAmountGiven;
              final amount = double.tryParse(value!);
              if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.amountReturnedPkr,
            hint: l10n.optionalIfAnyAmountAlreadyReturned,
            controller: _amountReturnedController,
            prefixIcon: Icons.trending_down_rounded,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amountReturned = double.tryParse(value);
                if (amountReturned == null || amountReturned < 0) return l10n.pleaseEnterValidAmount;
                final amountGiven = double.tryParse(_amountGivenController.text) ?? 0;
                if (amountReturned > amountGiven) return l10n.cannotExceedAmountGiven;
              }
              return null;
            },
          ),
          if (_amountGivenController.text.isNotEmpty || _amountReturnedController.text.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            _buildBalancePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: context.shadowBlur('light'),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.transactionDetails,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: '${l10n.reasonItem} (${l10n.optional})',
            hint: context.shouldShowCompactLayout ? l10n.reasonForLending : l10n.enterReasonForLendingOrItemDescription,
            controller: _reasonController,
            prefixIcon: Icons.assignment_outlined,
            maxLines: ResponsiveBreakpoints.responsive(
              context,
              tablet: 2,
              small: 2,
              medium: 3,
              large: 3,
              ultrawide: 3,
            ),
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.notesOptional,
            hint: context.shouldShowCompactLayout ? l10n.additionalNotes : l10n.enterAdditionalNotesOrTerms,
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
        ],
      ),
    );
  }

  Widget _buildDatesCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: context.shadowBlur('light'),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.dateInformation,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
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
                      text: '${_dateLent.day}/${_dateLent.month}/${_dateLent.year}',
                    ),
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
                      text: '${_expectedReturnDate.day}/${_expectedReturnDate.month}/${_expectedReturnDate.year}',
                    ),
                    prefixIcon: Icons.event_available,
                    enabled: false,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildDateInfoRow(),
        ],
      ),
    );
  }

  Widget _buildBalancePreview() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.balanceRemaining,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  'PKR ${balanceRemaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: balanceRemaining >= 0 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfoRow() {
    final l10n = AppLocalizations.of(context)!;
    final daysDifference = _expectedReturnDate.difference(_dateLent).inDays;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
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
              daysDifference > 0
                  ? '${l10n.lendingPeriod} $daysDifference ${l10n.days}'
                  : l10n.pleaseSelectValidReturnDate,
              style: TextStyle(
                fontSize: context.captionFontSize,
                color: daysDifference > 0 ? Colors.blue[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    if (context.shouldShowCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<ReceivablesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.addReceivable,
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight,
                icon: Icons.add_rounded,
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
    } else {
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
            flex: 2,
            child: Consumer<ReceivablesProvider>(
              builder: (context, provider, child) {
                return PremiumButton(
                  text: l10n.addReceivable,
                  onPressed: provider.isLoading ? null : _handleSubmit,
                  isLoading: provider.isLoading,
                  height: context.buttonHeight / 1.5,
                  icon: Icons.add_rounded,
                  backgroundColor: AppTheme.primaryMaroon,
                );
              },
            ),
          ),
        ],
      );
    }
  }
}
