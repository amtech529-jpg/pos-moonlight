import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/providers/advance_payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/image_upload_widget.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';

class AddAdvancePaymentDialog extends StatefulWidget {
  const AddAdvancePaymentDialog({super.key});

  @override
  State<AddAdvancePaymentDialog> createState() => _AddAdvancePaymentDialogState();
}

class _AddAdvancePaymentDialogState extends State<AddAdvancePaymentDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();

  LaborModel? _selectedLabor;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _receiptImageFile;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final laborProvider = Provider.of<LaborProvider>(context, listen: false);
      laborProvider.loadLabors();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLabor == null) {
        _showErrorSnackbar(l10n.pleaseSelectALabor);
        return;
      }

      final amount = double.parse(_amountController.text.trim());
      // TODO: Fix remaining advance amount validation when backend properly tracks remaining_advance_amount
      // For now, skip this validation to allow advance payments
      /*
      if (amount > _selectedLabor!.remainingAdvanceAmount) {
        _showErrorSnackbar(
          '${l10n.amountCannotExceedRemainingAdvanceAmount} PKR ${_selectedLabor!.remainingAdvanceAmount.toStringAsFixed(0)}. ${l10n.totalAdvancesThisMonth}: PKR ${_selectedLabor!.totalAdvancesAmount.toStringAsFixed(0)}',
        );
        return;
      }
      */

      final advancePaymentProvider = Provider.of<AdvancePaymentProvider>(context, listen: false);

      setState(() {
        _isSubmitting = true;
      });

      try {
        final success = await advancePaymentProvider.addAdvancePayment(
          laborId: _selectedLabor!.id,
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          time: _selectedTime,
          receiptImageFile: _receiptImageFile,
        );

        if (mounted) {
          if (success) {
            _showSuccessSnackbar();
            Navigator.of(context).pop();
          } else {
            _showErrorSnackbar(advancePaymentProvider.errorMessage ?? l10n.failedToAddAdvancePayment);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('${l10n.anUnexpectedErrorOccurred}: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.advancePaymentAddedSuccessfully),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onImageChanged(File? imageFile) {
    setState(() {
      _receiptImageFile = imageFile;
    });
  }

  void _selectDateTime() {
    final l10n = AppLocalizations.of(context)!;

    context.showSyncfusionDateTimePicker(
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      },
      title: l10n.selectDateAndTime,
      showTimeInline: true,
    );
  }

  double get remainingAfterAdvance {
    if (_selectedLabor == null) return 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    // TODO: Fix remaining advance amount calculation when backend properly tracks remaining_advance_amount
    // For now, use salary as fallback
    final remainingAdvance = _selectedLabor!.remainingAdvanceAmount > 0 
        ? _selectedLabor!.remainingAdvanceAmount 
        : _selectedLabor!.salary;
    return remainingAdvance - amount;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
          body: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: context.shadowBlur('heavy'),
                    offset: Offset(0, context.cardPadding),
                  ),
                ],
              ),
              transform: Matrix4.identity()
                ..scale(_scaleAnimation.value)
                ..translate(0.0, 0.0),
              transformAlignment: Alignment.center,
              child: ResponsiveBreakpoints.responsive(
                context,
                tablet: _buildDesktopLayout(),
                small: _buildDesktopLayout(),
                medium: _buildDesktopLayout(),
                large: _buildDesktopLayout(),
                ultrawide: _buildDesktopLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormFieldsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_document, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildLaborSelection(),
          SizedBox(height: context.cardPadding),
          _buildAmountField(),
          SizedBox(height: context.cardPadding),
          _buildDescriptionField(),
          SizedBox(height: context.cardPadding),
          _buildDateTimeFields(),
          if (_selectedLabor != null && _amountController.text.isNotEmpty) ...[SizedBox(height: context.cardPadding), _buildCalculationPreview()],
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.receiptImageOptional,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                    Text(
                      l10n.uploadReceiptImageForBetterRecordKeeping,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ImageUploadWidget(
            initialImagePath: null,
            onImageChanged: _onImageChanged,
            label: l10n.receiptImageOptional,
            isRequired: false,
            maxHeight: 200,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
            maxFileSizeMB: 5,
          ),
        ],
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
              _buildFormFieldsCard(),
              SizedBox(height: context.cardPadding),
              _buildReceiptCard(),
              SizedBox(height: context.mainPadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaborSelection() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<LaborProvider>(
      builder: (context, provider, child) {
        return PremiumDropdownField<LaborModel>(
          label: l10n.selectLabor,
          hint: l10n.selectALabor,
          prefixIcon: Icons.person_outline,
          items: provider.labors.map((labor) => DropdownItem<LaborModel>(value: labor, label: '${labor.name} (${labor.designation})')).toList(),
          value: _selectedLabor,
          onChanged: (labor) {
            setState(() {
              _selectedLabor = labor;
            });
          },
          validator: (value) => value == null ? l10n.pleaseSelectALabor : null,
        );
      },
    );
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.advanceAmountPkr,
      hint: context.shouldShowCompactLayout ? l10n.enterAmount : l10n.enterAdvanceAmountPkr,
      controller: _amountController,
      prefixIcon: Icons.attach_money_rounded,
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {}),
      validator: (value) {
        if (value?.isEmpty ?? true) return l10n.pleaseEnterAdvanceAmount;
        final amount = double.tryParse(value!);
        if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
        // TODO: Fix remaining salary validation when backend properly tracks remaining_monthly_salary
        // For now, skip this validation to allow advance payments
        /*
        if (_selectedLabor != null && amount > _selectedLabor!.remainingMonthlySalary) {
          return l10n.amountExceedsRemainingSalary;
        }
        */
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.description,
      hint: context.shouldShowCompactLayout ? l10n.enterReason : l10n.enterReasonForAdvancePayment,
      controller: _descriptionController,
      prefixIcon: Icons.description_outlined,
      maxLines: ResponsiveBreakpoints.responsive(context, tablet: 2, small: 3, medium: 3, large: 4, ultrawide: 4),
      validator: (value) {
        if (value?.isEmpty ?? true) return l10n.pleaseEnterDescription;
        if (value!.length < 5) return l10n.descriptionMustBeAtLeast5Characters;
        return null;
      },
    );
  }

  Widget _buildDateTimeFields() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDateTime,
            child: PremiumTextField(
              label: l10n.dateAndTime,
              hint: l10n.selectDateAndTime,
              controller: TextEditingController(
                text:
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              prefixIcon: Icons.calendar_today,
              enabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationPreview() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: remainingAfterAdvance < 0 ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: remainingAfterAdvance < 0 ? Colors.red.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                remainingAfterAdvance < 0 ? Icons.warning_rounded : Icons.calculate_rounded,
                color: remainingAfterAdvance < 0 ? Colors.red : Colors.blue,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Text(
                  l10n.salaryCalculation,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          _buildSalaryInfoRow(l10n.originalSalary, 'PKR ${_selectedLabor!.salary.toStringAsFixed(0)}', Colors.green),
          _buildSalaryInfoRow(
            l10n.currentMonthAdvances,
            // TODO: Fix calculation when backend properly tracks remaining_monthly_salary
            'PKR ${(_selectedLabor!.totalAdvancesAmount > 0 ? _selectedLabor!.totalAdvancesAmount : 0.0).toStringAsFixed(0)}',
            Colors.orange,
          ),
          _buildSalaryInfoRow(l10n.remainingForMonth, 'PKR ${(_selectedLabor!.remainingMonthlySalary > 0 ? _selectedLabor!.remainingMonthlySalary : _selectedLabor!.salary).toStringAsFixed(0)}', Colors.blue),
          Divider(color: Colors.grey.shade300, height: context.cardPadding),
          _buildSalaryInfoRow(l10n.newAdvance, 'PKR ${double.tryParse(_amountController.text)?.toStringAsFixed(0) ?? '0.00'}', AppTheme.primaryMaroon),
          _buildSalaryInfoRow(
            l10n.afterAdvance,
            'PKR ${remainingAfterAdvance.toStringAsFixed(0)}',
            remainingAfterAdvance < 0 ? Colors.red : Colors.green,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfoRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding / 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: color),
              textAlign: TextAlign.end,
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
          PremiumButton(
            text: l10n.addPayment,
            onPressed: _isSubmitting ? null : _handleSubmit,
            isLoading: _isSubmitting,
            height: context.buttonHeight,
            icon: Icons.add_rounded,
            backgroundColor: AppTheme.primaryMaroon,
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
            child: PremiumButton(
              text: l10n.addPayment,
              onPressed: _isSubmitting ? null : _handleSubmit,
              isLoading: _isSubmitting,
              height: context.buttonHeight / 1.5,
              icon: Icons.add_rounded,
              backgroundColor: AppTheme.primaryMaroon,
            ),
          ),
        ],
      );
    }
  }
}
