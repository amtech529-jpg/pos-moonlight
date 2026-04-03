import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';
import '../../../l10n/app_localizations.dart';

class AddPayableDialog extends StatefulWidget {
  const AddPayableDialog({super.key});

  @override
  State<AddPayableDialog> createState() => _AddPayableDialogState();
}

class _AddPayableDialogState extends State<AddPayableDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _creditorNameController = TextEditingController();
  final _creditorPhoneController = TextEditingController();
  final _creditorEmailController = TextEditingController();
  final _amountBorrowedController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _reasonOrItemController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Focus Nodes
  final _creditorNameFocusNode = FocusNode();
  final _creditorPhoneFocusNode = FocusNode();
  final _creditorEmailFocusNode = FocusNode();
  final _amountBorrowedFocusNode = FocusNode();
  final _amountPaidFocusNode = FocusNode();
  final _reasonFocusNode = FocusNode();

  DateTime _dateBorrowed = DateTime.now();
  DateTime _expectedRepaymentDate = DateTime.now().add(const Duration(days: 30));
  String _selectedPriority = 'MEDIUM';
  String? _selectedVendorId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _priorityOptions = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorProvider = context.read<VendorProvider>();
      vendorProvider.loadVendors();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _creditorNameController.dispose();
    _creditorPhoneController.dispose();
    _creditorEmailController.dispose();
    _amountBorrowedController.dispose();
    _amountPaidController.dispose();
    _reasonOrItemController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _creditorNameFocusNode.dispose();
    _creditorPhoneFocusNode.dispose();
    _creditorEmailFocusNode.dispose();
    _amountBorrowedFocusNode.dispose();
    _amountPaidFocusNode.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final amountBorrowed = double.parse(_amountBorrowedController.text.trim());

      if (_expectedRepaymentDate.isBefore(_dateBorrowed)) {
        _showErrorSnackbar(l10n.expectedRepaymentDateCannotBeBeforeDateBorrowed);
        return;
      }

      final payablesProvider = Provider.of<PayablesProvider>(context, listen: false);
      final amountPaid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;

      final success = await payablesProvider.addPayable(
        creditorName: _creditorNameController.text.trim(),
        creditorPhone: _creditorPhoneController.text.trim(),
        creditorEmail: _creditorEmailController.text.trim(),
        vendorId: _selectedVendorId,
        amountBorrowed: amountBorrowed,
        amountPaid: amountPaid,
        reasonOrItem: _reasonOrItemController.text.trim(),
        dateBorrowed: _dateBorrowed,
        expectedRepaymentDate: _expectedRepaymentDate,
        priority: _selectedPriority,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          // Refresh vendors in case a new one was auto-created for this partner
          context.read<VendorProvider>().loadVendors(showLoadingIndicator: false);
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(payablesProvider.errorMessage ?? l10n.failedToAddPayablePleaseTryAgain);
        }
      }
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
              l10n.payableAddedSuccessfully,
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
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

  Future<void> _selectDateBorrowed() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _dateBorrowed,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      onDateTimeSelected: (date, time) {
        if (date != _dateBorrowed) {
          setState(() {
            _dateBorrowed = date;
            if (_expectedRepaymentDate.isBefore(_dateBorrowed.add(const Duration(days: 1)))) {
              _expectedRepaymentDate = _dateBorrowed.add(const Duration(days: 30));
            }
          });
        }
      },
      title: l10n.selectBorrowedDate,
      minDate: DateTime.now().subtract(const Duration(days: 365)),
      maxDate: DateTime.now(),
      showTimeInline: false,
    );
  }

  Future<void> _selectExpectedRepaymentDate() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _expectedRepaymentDate,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      onDateTimeSelected: (date, time) {
        if (date != _expectedRepaymentDate) {
          setState(() {
            _expectedRepaymentDate = date;
          });
        }
      },
      title: l10n.selectExpectedRepaymentDate,
      minDate: _dateBorrowed.add(const Duration(days: 1)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
      showTimeInline: false,
    );
  }

  double get balanceRemaining {
    final amountBorrowed = double.tryParse(_amountBorrowedController.text) ?? 0;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    return amountBorrowed - amountPaid;
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 80.w, large: 70.w, ultrawide: 60.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context, tablet: 90.h, small: 95.h, medium: 85.h, large: 80.h, ultrawide: 75.h),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
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
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
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
                  context.shouldShowCompactLayout ? l10n.addPayable : l10n.addNewPayable,
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
                    l10n.recordAmountOwedToCreditor,
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
              _buildCreditorInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
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
              _buildCreditorInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
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

  Widget _buildCreditorInfoCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.creditorInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.creditorName,
            hint: context.shouldShowCompactLayout ? l10n.enterName : l10n.enterCreditorFullName,
            controller: _creditorNameController,
            prefixIcon: Icons.person_outline,
            focusNode: _creditorNameFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_creditorPhoneFocusNode),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterCreditorName;
              if (value!.length < 2) return l10n.nameMustBeAtLeast2Characters;
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.phone,
            hint: context.shouldShowCompactLayout ? l10n.enterPhone : l10n.enterPhoneNumberWithFormat,
            controller: _creditorPhoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _creditorPhoneFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_creditorEmailFocusNode),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterPhoneNumber;
              if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value!)) return l10n.pleaseEnterAValidPhoneNumber;
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.emailOptional,
            hint: l10n.enterCreditorEmailAddress,
            controller: _creditorEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            focusNode: _creditorEmailFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_amountBorrowedFocusNode),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.amountDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.amountBorrowedPKR,
            hint: context.shouldShowCompactLayout ? l10n.enterAmount : l10n.enterAmountBorrowedFromCreditor,
            controller: _amountBorrowedController,
            prefixIcon: Icons.trending_up_rounded,
            keyboardType: TextInputType.number,
            focusNode: _amountBorrowedFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_amountPaidFocusNode),
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterAmountBorrowed;
              final amount = double.tryParse(value!);
              if (amount == null || amount <= 0) return l10n.pleaseEnterAValidAmount;
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.amountPaidPKR,
            hint: l10n.optionalIfAnyAmountAlreadyPaid,
            controller: _amountPaidController,
            prefixIcon: Icons.trending_down_rounded,
            keyboardType: TextInputType.number,
            focusNode: _amountPaidFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_reasonFocusNode),
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amountPaid = double.tryParse(value);
                if (amountPaid == null || amountPaid < 0) return l10n.pleaseEnterAValidAmount;
                final amountBorrowed = double.tryParse(_amountBorrowedController.text) ?? 0;
                if (amountPaid > amountBorrowed) return l10n.cannotExceedAmountBorrowed;
              }
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: '${l10n.reasonItem} (${l10n.optional})',
            hint: context.shouldShowCompactLayout ? l10n.enterReason : l10n.enterReasonForBorrowingOrItemDescription,
            controller: _reasonOrItemController,
            prefixIcon: Icons.receipt_long_outlined,
            focusNode: _reasonFocusNode,
            textInputAction: TextInputAction.done,
            maxLines: 2,
          ),
          if (_amountBorrowedController.text.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            _buildBalancePreview(),
          ],
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.dateInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDateBorrowed,
                  child: PremiumTextField(
                    label: l10n.dateBorrowed,
                    hint: l10n.selectDate,
                    controller: TextEditingController(text: '${_dateBorrowed.day.toString().padLeft(2, '0')}/${_dateBorrowed.month.toString().padLeft(2, '0')}/${_dateBorrowed.year}'),
                    prefixIcon: Icons.calendar_today,
                    enabled: false,
                  ),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: GestureDetector(
                  onTap: _selectExpectedRepaymentDate,
                  child: PremiumTextField(
                    label: l10n.expectedRepaymentDate,
                    hint: l10n.selectDate,
                    controller: TextEditingController(
                      text: '${_expectedRepaymentDate.day.toString().padLeft(2, '0')}/${_expectedRepaymentDate.month.toString().padLeft(2, '0')}/${_expectedRepaymentDate.year}',
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
        border: Border.all(color: balanceRemaining >= 0 ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, color: balanceRemaining >= 0 ? Colors.orange : Colors.red, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.balanceRemaining,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
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
    final daysDifference = _expectedRepaymentDate.difference(_dateBorrowed).inDays;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: context.iconSize('small')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              daysDifference > 0 ? l10n.borrowingPeriodDays(daysDifference) : l10n.pleaseSelectAValidRepaymentDate,
              style: TextStyle(fontSize: context.captionFontSize, color: daysDifference > 0 ? Colors.blue[700] : Colors.red[700]),
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
          Consumer<PayablesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.addPayable,
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
            child: Consumer<PayablesProvider>(
              builder: (context, provider, child) {
                return PremiumButton(
                  text: l10n.addPayable,
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
