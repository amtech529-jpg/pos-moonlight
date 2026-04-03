import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/globals/custom_date_picker.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/zakat/zakat_model.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EditZakatDialog extends StatefulWidget {
  final Zakat zakat;

  const EditZakatDialog({super.key, required this.zakat});

  @override
  State<EditZakatDialog> createState() => _EditZakatDialogState();
}

class _EditZakatDialogState extends State<EditZakatDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _beneficiaryNameController;
  late TextEditingController _beneficiaryContactController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedAuthority;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.zakat.name);
    _descriptionController = TextEditingController(text: widget.zakat.description);
    _amountController = TextEditingController(text: widget.zakat.amount.toString());
    _beneficiaryNameController = TextEditingController(text: widget.zakat.beneficiaryName);
    _beneficiaryContactController = TextEditingController(text: widget.zakat.beneficiaryContact ?? '');
    _notesController = TextEditingController(text: widget.zakat.notes ?? '');

    _selectedDate = widget.zakat.date;
    _selectedTime = widget.zakat.time;
    _selectedAuthority = widget.zakat.authorizedBy;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _beneficiaryNameController.dispose();
    _beneficiaryContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final zakatProvider = Provider.of<ZakatProvider>(context, listen: false);

      final success = await zakatProvider.updateZakat(
        id: widget.zakat.id,
        name: _nameController.text.trim().isEmpty ? l10n.zakatContribution : _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: _selectedTime,
        amount: double.parse(_amountController.text.trim()),
        beneficiaryName: _beneficiaryNameController.text.trim(),
        beneficiaryContact: _beneficiaryContactController.text.trim().isEmpty ? null : _beneficiaryContactController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        authorizedBy: _selectedAuthority,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(zakatProvider.errorMessage ?? l10n.failedToUpdateZakatRecord);
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
              l10n.zakatRecordUpdatedSuccessfully,
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

  Future<void> _selectDateTime() async {
    await context.showSyncfusionDateTimePicker(
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      minDate: DateTime(2000),
      maxDate: DateTime.now(),
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      },
    );
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
                  maxHeight: 90.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent()]),
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
        gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
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
                  context.shouldShowCompactLayout ? l10n.editZakat : l10n.editZakatRecord,
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
                    l10n.updateZakatInformation,
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
              widget.zakat.id,
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

  Widget _buildFormContent() {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = context.shouldShowCompactLayout;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: l10n.title,
              hint: isCompact ? l10n.enterTitle : l10n.enterZakatContributionTitle,
              controller: _nameController,
              prefixIcon: Icons.title_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterTitle;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.description,
              hint: isCompact ? l10n.enterDescription : l10n.enterDescriptionPurposeOfZakat,
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

            PremiumTextField(
              label: l10n.amountPkr,
              hint: isCompact ? l10n.enterAmount : l10n.enterZakatAmountInPkr,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return l10n.pleaseEnterValidAmountGreaterThanZero;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.beneficiaryName,
              hint: isCompact ? l10n.enterBeneficiaryName : l10n.enterNameOfRecipientBeneficiary,
              controller: _beneficiaryNameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterBeneficiaryName;
                }
                if (value!.length < 2) {
                  return l10n.beneficiaryNameMustBeAtLeast2Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.beneficiaryContactOptional,
              hint: isCompact ? l10n.enterContact : l10n.enterBeneficiaryContactNumber,
              controller: _beneficiaryContactController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: context.cardPadding),

            Container(
              padding: EdgeInsets.symmetric(horizontal: context.cardPadding),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.smallPadding),
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.blue, size: context.iconSize('medium')),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.authorizedBy,
                        style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: context.smallPadding),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAuthority,
                      isExpanded: true,
                      items: ZakatAuthorities.authorities.map((String authority) {
                        return DropdownMenuItem<String>(
                          value: authority,
                          child: Text(
                            authority,
                            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAuthority = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(height: context.smallPadding),
                ],
              ),
            ),
            SizedBox(height: context.cardPadding),

            InkWell(
              onTap: _selectDateTime,
              child: Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded, color: Colors.blue, size: context.iconSize('medium')),
                        SizedBox(width: context.smallPadding),
                        Text(
                          l10n.dateAndTime,
                          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                        ),
                      ],
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${l10n.at} ${_selectedTime.format(context)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.additionalNotesOptional,
              hint: isCompact ? l10n.enterNotes : l10n.enterAdditionalNotesOrReligiousConsiderations,
              controller: _notesController,
              prefixIcon: Icons.notes_outlined,
              maxLines: 2,
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
        Consumer<ZakatProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateZakat,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: Colors.blue,
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
          child: Consumer<ZakatProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updateZakat,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }
}
