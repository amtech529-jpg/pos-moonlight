import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payment/payment_model.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../../../l10n/app_localizations.dart';

class EditPaymentDialog extends StatefulWidget {
  final PaymentModel payment;

  const EditPaymentDialog({super.key, required this.payment});

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _bonusController;
  late TextEditingController _deductionController;
  late TextEditingController _descriptionController;

  late String _selectedLaborId;
  late String _selectedPaymentMethod;
  late String _selectedPaymentMonth;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isFinalPayment;
  String? _receiptImagePath;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payment.amountPaid.toString());
    _bonusController = TextEditingController(text: widget.payment.bonus > 0 ? widget.payment.bonus.toString() : '');
    _deductionController = TextEditingController(text: widget.payment.deduction > 0 ? widget.payment.deduction.toString() : '');
    _descriptionController = TextEditingController(text: widget.payment.description);
    _selectedLaborId = widget.payment.laborId ?? '';
    _selectedPaymentMethod = widget.payment.paymentMethod;
    _selectedPaymentMonth = '${widget.payment.paymentMonth.day}/${widget.payment.paymentMonth.month}/${widget.payment.paymentMonth.year}';
    debugPrint('EditPaymentDialog: API month: ${widget.payment.paymentMonth}, converted to: $_selectedPaymentMonth');
    _selectedDate = widget.payment.date;
    _selectedTime = TimeOfDay(hour: widget.payment.time.hour, minute: widget.payment.time.minute);
    _isFinalPayment = widget.payment.isFinalPayment;
    _receiptImagePath = widget.payment.receiptImagePath;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _bonusController.dispose();
    _deductionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      final selectedLabor = provider.laborers.firstWhere((labor) => labor.id == _selectedLaborId, orElse: () => provider.laborers.first);

      final amount = double.parse(_amountController.text.trim());
      final bonus = double.tryParse(_bonusController.text.trim()) ?? 0.0;
      final deduction = double.tryParse(_deductionController.text.trim()) ?? 0.0;
      final netAmount = amount + bonus - deduction;

      final availableAmount = selectedLabor.remainingAmount + (selectedLabor.id == widget.payment.laborId ? widget.payment.netAmount : 0);

      if (netAmount > availableAmount && !_isFinalPayment) {
        _showErrorSnackbar(l10n.netAmountCannotExceedAvailable(availableAmount.toStringAsFixed(0)));
        return;
      }

      await provider.updatePayment(
        id: widget.payment.id,
        laborId: _selectedLaborId,
        vendorId: null,
        orderId: null,
        saleId: null,
        amountPaid: amount,
        bonus: bonus,
        deduction: deduction,
        paymentMonth: _parseDisplayMonthToDateTime(_selectedPaymentMonth),
        isFinalPayment: _isFinalPayment,
        paymentMethod: _selectedPaymentMethod,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute),
        receiptImagePath: _receiptImagePath,
        payerType: 'labor',
        payerId: _selectedLaborId,
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
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.paymentUpdatedSuccessfully,
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
            Text(
              message,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primaryMaroon)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primaryMaroon)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  List<String> _generatePaymentMonths() {
    final List<String> months = [];
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year - 1}');
    }

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year}');
    }

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year + 1}');
    }

    debugPrint('EditPaymentDialog: Generated months: ${months.take(5).toList()}... (total: ${months.length})');
    return months;
  }

  String _convertApiMonthToDisplay(String apiMonth) {
    try {
      final parts = apiMonth.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return '${monthNames[month - 1]} $year';
      }
    } catch (e) {
      debugPrint('Error converting API month format: $e');
    }
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${monthNames[now.month - 1]} ${now.year}';
  }

  String _convertDisplayMonthToApi(String displayMonth) {
    try {
      final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final parts = displayMonth.split(' ');
      if (parts.length == 2) {
        final monthName = parts[0];
        final year = int.parse(parts[1]);
        final monthIndex = monthNames.indexOf(monthName);
        if (monthIndex != -1) {
          final month = monthIndex + 1;
          return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
        }
      }
    } catch (e) {
      debugPrint('Error converting display month format: $e');
    }
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
  }

  void _selectReceiptImage() {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _receiptImagePath = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.receiptImageSelected),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeReceiptImage() {
    setState(() {
      _receiptImagePath = null;
    });
  }

  double get netAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final deduction = double.tryParse(_deductionController.text) ?? 0;
    return amount + bonus - deduction;
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
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
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: true))),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: true))),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: false))),
      ],
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
            child: Icon(Icons.edit_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.editPayment : l10n.editPaymentDetails,
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
                    l10n.updatePaymentInformation,
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
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
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

  Widget _buildFormContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<PaymentProvider>(
              builder: (context, provider, child) {
                return PremiumDropdownField<String>(
                  label: l10n.labor,
                  hint: l10n.selectLaborForPayment,
                  value: _selectedLaborId,
                  prefixIcon: Icons.person_outline,
                  items: provider.laborers
                      .map(
                        (labor) => DropdownItem<String>(
                      value: labor.id,
                      label:
                      '${labor.name} - ${labor.role} (${l10n.available}: PKR ${(labor.remainingAmount + (labor.id == widget.payment.laborId ? widget.payment.netAmount : 0)).toStringAsFixed(0)})',
                    ),
                  )
                      .toList(),
                  onChanged: (laborId) {
                    setState(() => _selectedLaborId = laborId!);
                  },
                  validator: (value) => value == null ? l10n.pleaseSelectLabor : null,
                );
              },
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final months = _generatePaymentMonths();
                      debugPrint('EditPaymentDialog: Dropdown value: $_selectedPaymentMonth, available months: ${months.take(5).toList()}...');
                      return PremiumDropdownField<String>(
                        label: l10n.paymentMonth,
                        hint: l10n.selectPaymentMonth,
                        value: _selectedPaymentMonth,
                        prefixIcon: Icons.calendar_month,
                        items: months.map((month) => DropdownItem<String>(value: month, label: month)).toList(),
                        onChanged: (month) {
                          setState(() {
                            _selectedPaymentMonth = month!;
                          });
                        },
                        validator: (value) => value == null ? l10n.pleaseSelectPaymentMonth : null,
                      );
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumDropdownField<String>(
                    label: l10n.paymentMethod,
                    hint: l10n.selectPaymentMethod,
                    value: _selectedPaymentMethod,
                    prefixIcon: Icons.payment,
                    items: PaymentProvider().paymentMethods.map((method) => DropdownItem<String>(value: method, label: method)).toList(),
                    onChanged: (method) {
                      setState(() {
                        _selectedPaymentMethod = method!;
                      });
                    },
                    validator: (value) => value == null ? l10n.pleaseSelectPaymentMethod : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.paymentAmount,
              hint: isCompact ? l10n.enterAmount : l10n.enterPaymentAmountPkr,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterAmount;
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.bonusPkr,
                    hint: l10n.optionalBonus,
                    controller: _bonusController,
                    prefixIcon: Icons.star_outline,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final bonus = double.tryParse(value);
                        if (bonus == null || bonus < 0) return l10n.enterValidBonus;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: l10n.deductionPkr,
                    hint: l10n.optionalDeduction,
                    controller: _deductionController,
                    prefixIcon: Icons.remove_circle_outline,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final deduction = double.tryParse(value);
                        if (deduction == null || deduction < 0) return l10n.enterValidDeduction;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_amountController.text.isNotEmpty || _bonusController.text.isNotEmpty || _deductionController.text.isNotEmpty) ...[
              SizedBox(height: context.cardPadding),
              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  color: netAmount >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(color: netAmount >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: netAmount >= 0 ? Colors.green : Colors.red, size: context.iconSize('medium')),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        '${l10n.netAmount}: PKR ${netAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: netAmount >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.description,
              hint: isCompact ? l10n.enterNotes : l10n.enterPaymentDescriptionOrNotes,
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              maxLines: ResponsiveBreakpoints.responsive(context, tablet: 2, small: 3, medium: 4, large: 5, ultrawide: 6),
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterDescription;
                if (value!.length < 5) return l10n.descriptionMustBeAtLeast5Characters;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: PremiumTextField(
                      label: l10n.date,
                      hint: l10n.selectDate,
                      controller: TextEditingController(text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      prefixIcon: Icons.calendar_today,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectTime,
                    child: PremiumTextField(
                      label: l10n.time,
                      hint: l10n.selectTime,
                      controller: TextEditingController(
                        text: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      prefixIcon: Icons.access_time,
                      enabled: false,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: _isFinalPayment ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: _isFinalPayment ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isFinalPayment ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _isFinalPayment ? Colors.green : Colors.grey,
                    size: context.iconSize('medium'),
                  ),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.finalPaymentForMonth,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: _isFinalPayment ? Colors.green : AppTheme.charcoalGray,
                          ),
                        ),
                        Text(
                          _isFinalPayment ? l10n.thisCompletesPaymentForSelectedMonth : l10n.markThisAsFinalPaymentForMonth,
                          style: TextStyle(fontSize: context.captionFontSize, color: _isFinalPayment ? Colors.green[700] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isFinalPayment,
                    onChanged: (value) {
                      setState(() {
                        _isFinalPayment = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: context.cardPadding),
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.receiptImageOptional,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  ),
                  SizedBox(height: context.smallPadding),
                  if (_receiptImagePath == null) ...[
                    GestureDetector(
                      onTap: _selectReceiptImage,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: context.iconSize('xl'), color: Colors.grey[600]),
                            SizedBox(height: context.smallPadding),
                            Text(
                              l10n.tapToSelectReceiptImage,
                              style: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_rounded, color: Colors.green, size: context.iconSize('medium')),
                          SizedBox(width: context.smallPadding),
                          Expanded(
                            child: Text(
                              l10n.receiptImageSelected,
                              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.green),
                            ),
                          ),
                          IconButton(
                            onPressed: _removeReceiptImage,
                            icon: Icon(Icons.close_rounded, color: Colors.red, size: context.iconSize('small')),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<PaymentProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updatePayment,
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
          child: Consumer<PaymentProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updatePayment,
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

  DateTime _parseDisplayMonthToDateTime(String displayMonth) {
    final parts = displayMonth.split('/');
    if (parts.length == 3) {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }
}
