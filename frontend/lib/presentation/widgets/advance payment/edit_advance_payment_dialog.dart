import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/advance_payment/advance_payment_model.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/custom_date_picker.dart';
import '../globals/image_upload_widget.dart';

class EditAdvancePaymentDialog extends StatefulWidget {
  final AdvancePayment payment;

  const EditAdvancePaymentDialog({super.key, required this.payment});

  @override
  State<EditAdvancePaymentDialog> createState() => _EditAdvancePaymentDialogState();
}

class _EditAdvancePaymentDialogState extends State<EditAdvancePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late LaborModel _selectedLabor;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _receiptImagePath;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(text: widget.payment.amount.toString());
    _descriptionController = TextEditingController(text: widget.payment.description);
    _selectedDate = widget.payment.date;
    _selectedTime = widget.payment.timeOfDay;
    _receiptImagePath = widget.payment.receiptImagePath;

    _selectedLabor = LaborModel(
      id: widget.payment.laborId,
      name: widget.payment.laborName,
      cnic: '',
      phoneNumber: widget.payment.laborPhone,
      caste: '',
      designation: widget.payment.laborRole,
      joiningDate: DateTime.now(),
      salary: 0.0,
      area: '',
      city: '',
      gender: '',
      age: 0,
      displayName: widget.payment.laborName,
      initials: widget.payment.laborName.isNotEmpty ? widget.payment.laborName[0].toUpperCase() : '',
      isNewLabor: false,
      isRecentLabor: false,
      workExperienceDays: 0,
      workExperienceYears: 0.0,
      phoneCountryCode: '',
      formattedPhone: widget.payment.laborPhone,
      fullAddress: '',
      genderDisplay: '',
      advancePaymentsCount: 0,
      totalAdvanceAmount: 0.0,
      paymentsCount: 0,
      totalPaymentsAmount: 0.0,
      remainingMonthlySalary: 0.0,
      remainingAdvanceAmount: 0.0,
      totalAdvancesAmount: 0.0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text.trim());

      final currentAdvanceAmount = widget.payment.amount;
      final newAdvanceAmount = amount;
      final salaryDifference = newAdvanceAmount - currentAdvanceAmount;
      if (salaryDifference > 0 && salaryDifference > _selectedLabor.remainingAdvanceAmount) {
        _showErrorSnackbar(
          '${l10n.amountIncreaseCannotExceedRemainingAdvanceAmount} PKR ${_selectedLabor.remainingAdvanceAmount.toStringAsFixed(0)}. ${l10n.totalAdvancesThisMonth}: PKR ${_selectedLabor.totalAdvancesAmount.toStringAsFixed(0)}',
        );
        return;
      }

      setState(() {
        _isUpdating = true;
      });

      try {
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('${l10n.anUnexpectedErrorOccurred}: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUpdating = false;
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
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.advancePaymentUpdatedSuccessfully,
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
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(context, tablet: double.infinity, small: 600, medium: 800, large: 1000, ultrawide: 1200),
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: SingleChildScrollView(child: _buildFormContent())),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(context.borderRadius()), topRight: Radius.circular(context.borderRadius())),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              l10n.editAdvancePayment,
              style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          IconButton(
            onPressed: _handleCancel,
            icon: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.laborInformation,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  ),
                  SizedBox(height: context.smallPadding),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: context.iconSize('medium') / 2,
                        backgroundColor: AppTheme.primaryMaroon,
                        child: Text(
                          _selectedLabor.initials,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                      SizedBox(width: context.smallPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLabor.name,
                              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _selectedLabor.designation,
                              style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
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

            PremiumTextField(
              label: l10n.amountPkr,
              hint: l10n.enterAmount,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return l10n.pleaseEnterValidAmount;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.description,
              hint: l10n.enterDescription,
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterDescription;
                }
                if (value!.length < 5) {
                  return l10n.descriptionMustBeAtLeast5Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await context.showSyncfusionDateTimePicker(
                          initialDate: _selectedDate,
                          initialTime: _selectedTime,
                          title: l10n.selectDate,
                          minDate: DateTime(2000),
                          maxDate: DateTime.now().add(const Duration(days: 365)),
                          onDateTimeSelected: (date, time) {
                            setState(() {
                              _selectedDate = date;
                              _selectedTime = time;
                            });
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                            SizedBox(height: context.smallPadding),
                            Text(
                              l10n.date,
                              style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                            ),
                            SizedBox(height: context.smallPadding / 2),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await context.showSyncfusionDateTimePicker(
                          initialDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
                          initialTime: _selectedTime,
                          title: l10n.selectTime,
                          minDate: DateTime(2000),
                          maxDate: DateTime.now().add(const Duration(days: 365)),
                          onDateTimeSelected: (date, time) {
                            setState(() {
                              _selectedTime = time;
                            });
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.access_time, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                            SizedBox(height: context.smallPadding),
                            Text(
                              l10n.time,
                              style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                            ),
                            SizedBox(height: context.smallPadding / 2),
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            ImageUploadWidget(
              initialImagePath: _receiptImagePath,
              onImageChanged: (file) {
                // setState(() {
                //   _selectedImageFile = file;
                // });
              },
              label: l10n.receiptImageOptional,
              isRequired: false,
              maxHeight: 200,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
              maxFileSizeMB: 5,
            ),
            SizedBox(height: context.mainPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: l10n.cancel,
                    onPressed: _handleCancel,
                    isOutlined: true,
                    height: context.buttonHeight,
                    backgroundColor: Colors.grey[600],
                    textColor: Colors.grey[600],
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumButton(
                    text: l10n.updatePayment,
                    onPressed: _isUpdating ? null : _handleUpdate,
                    isLoading: _isUpdating,
                    height: context.buttonHeight,
                    icon: Icons.save_rounded,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
