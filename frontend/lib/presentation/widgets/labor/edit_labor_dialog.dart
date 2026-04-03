import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';

class EnhancedEditLaborDialog extends StatefulWidget {
  final LaborModel labor;

  const EnhancedEditLaborDialog({super.key, required this.labor});

  @override
  State<EnhancedEditLaborDialog> createState() => _EnhancedEditLaborDialogState();
}

class _EnhancedEditLaborDialogState extends State<EnhancedEditLaborDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cnicController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  late TextEditingController _salaryController;
  late TextEditingController _incentiveController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _ageController;
  late String _selectedGender;
  late DateTime _selectedJoiningDate;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isUpdating = false;

  final List<String> _commonCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
  ];
  final List<String> _commonAreas = [
    'Gulshan',
    'Clifton',
    'DHA',
    'Johar Town',
    'Model Town',
    'F-7',
    'Blue Area',
    'Saddar',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.labor.name);
    _cnicController = TextEditingController(text: widget.labor.cnic);
    _phoneController = TextEditingController(text: widget.labor.phoneNumber);
    _designationController = TextEditingController(text: widget.labor.designation);
    _salaryController = TextEditingController(text: widget.labor.salary.toString());
    _incentiveController = TextEditingController(text: widget.labor.fixedIncentive.toString());
    _areaController = TextEditingController(text: widget.labor.area);
    _cityController = TextEditingController(text: widget.labor.city);
    _ageController = TextEditingController(text: widget.labor.age.toString());
    _selectedGender = widget.labor.gender;
    _selectedJoiningDate = widget.labor.joiningDate;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    _incentiveController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_isUpdating) return;

      setState(() {
        _isUpdating = true;
      });

      try {
        final provider = Provider.of<LaborProvider>(context, listen: false);

        final success = await provider.updateLabor(
          id: widget.labor.id,
          name: _nameController.text.trim(),
          cnic: _cnicController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          designation: _designationController.text.trim(),
          joiningDate: _selectedJoiningDate,
          salary: double.parse(_salaryController.text.trim()),
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          gender: _selectedGender,
          age: int.parse(_ageController.text.trim()),
          fixedIncentive: double.tryParse(_incentiveController.text.trim()) ?? 0.0,
        );

        if (mounted) {
          if (success) {
            _showSuccessSnackbar(l10n.laborUpdatedSuccessfully);
            Navigator.of(context).pop();
          } else {
            _showErrorSnackbar(provider.errorMessage ?? l10n.failedToUpdateLabor);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('${l10n.errorUpdatingLabor}: ${e.toString()}');
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleCancel() {
    if (_isUpdating) return;

    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (_isUpdating) return;

    await context.showSyncfusionDateTimePicker(
      initialDate: _selectedJoiningDate,
      initialTime: TimeOfDay.fromDateTime(_selectedJoiningDate),
      title: l10n.selectJoiningDate,
      minDate: DateTime(2000),
      maxDate: DateTime.now(),
      showTimeInline: false,
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedJoiningDate = date;
        });
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
        SizedBox(width: context.smallPadding),
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoalGray,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.accentGold,
          ),
        ),
      ),
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
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 95.w,
                    small: 90.w,
                    medium: 80.w,
                    large: 70.w,
                    ultrawide: 60.w,
                  ),
                  maxHeight: 90.h,
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
                    Flexible(child: _buildFormContent()),
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
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(Icons.edit_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.editLabor : l10n.editLaborDetails,
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
                    l10n.updateWorkerInformation,
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
              widget.labor.id,
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
              onTap: _isUpdating ? null : _handleCancel,
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: context.cardPadding),
              _buildContactInfoSection(),
              SizedBox(height: context.cardPadding),
              _buildLocationInfoSection(),
              SizedBox(height: context.cardPadding),
              _buildEmploymentInfoSection(),
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

  Widget _buildBasicInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.basicInformation, Icons.info_outline),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.fullName} *',
          hint: context.shouldShowCompactLayout ? l10n.enterName : l10n.enterWorkerFullName,
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterName;
            }
            if (value!.length < 2) {
              return l10n.nameMustBeAtLeast2Characters;
            }
            if (value.length > 50) {
              return l10n.nameMustBeLessThan50Characters;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.cnic} *',
          hint: context.shouldShowCompactLayout ? l10n.enterCNIC : l10n.enterCNICFormat,
          controller: _cnicController,
          prefixIcon: Icons.credit_card,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterCNIC;
            }
            if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value!)) {
              return l10n.pleaseEnterValidCNIC;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.contactInformation, Icons.contact_phone_outlined),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.phoneNumber} *',
          hint: context.shouldShowCompactLayout ? l10n.enterPhone : l10n.enterPhoneNumberFormat,
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterPhoneNumber;
            }
            if (!RegExp(r'^\+92\d{10}$').hasMatch(value!)) {
              return l10n.pleaseEnterValidPhoneNumber;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.locationInformation, Icons.location_on_outlined),
        SizedBox(height: context.cardPadding),
        ResponsiveBreakpoints.responsive(
          context,
          tablet: _buildCityAreaColumn(),
          small: _buildCityAreaColumn(),
          medium: _buildCityAreaRow(),
          large: _buildCityAreaRow(),
          ultrawide: _buildCityAreaRow(),
        ),
      ],
    );
  }

  Widget _buildEmploymentInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.employmentInformation, Icons.work_outline),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.designation} *',
          hint: context.shouldShowCompactLayout
              ? l10n.enterDesignation
              : l10n.enterJobDesignation,
          controller: _designationController,
          prefixIcon: Icons.work_outline,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterDesignation;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        GestureDetector(
          onTap: _isUpdating ? null : () => _selectDate(context),
          child: AbsorbPointer(
            child: PremiumTextField(
              label: '${l10n.joiningDate} *',
              hint: l10n.selectJoiningDate,
              controller: TextEditingController(
                text:
                '${_selectedJoiningDate.day}/${_selectedJoiningDate.month}/${_selectedJoiningDate.year}',
              ),
              prefixIcon: Icons.calendar_today,
              enabled: !_isUpdating,
            ),
          ),
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.monthlySalary} *',
          hint: context.shouldShowCompactLayout ? l10n.enterSalary : l10n.enterMonthlySalaryInPKR,
          controller: _salaryController,
          prefixIcon: Icons.account_balance_wallet_outlined,
          keyboardType: TextInputType.number,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterSalary;
            }
            if (double.tryParse(value!) == null || double.parse(value) <= 0) {
              return l10n.pleaseEnterValidSalary;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: 'Fixed Monthly Incentive',
          hint: 'Enter fixed incentive amount',
          controller: _incentiveController,
          prefixIcon: Icons.card_giftcard_outlined,
          keyboardType: TextInputType.number,
          enabled: !_isUpdating,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumDropdownField<String>(
          label: '${l10n.gender} *',
          hint: context.shouldShowCompactLayout ? l10n.selectGender : l10n.selectGender,
          prefixIcon: Icons.person_pin_rounded,
          items: [
            DropdownItem<String>(value: 'M', label: l10n.male),
            DropdownItem<String>(value: 'F', label: l10n.female),
            DropdownItem<String>(value: 'O', label: l10n.other),
          ],
          value: _selectedGender,
          onChanged: _isUpdating
              ? null
              : (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseSelectGender;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: '${l10n.age} *',
          hint: context.shouldShowCompactLayout ? l10n.enterAge : l10n.enterAgeMinimum18Years,
          controller: _ageController,
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterAge;
            }
            if (int.tryParse(value!) == null || int.parse(value) < 18) {
              return l10n.ageMustBeAtLeast18;
            }
            if (int.parse(value) > 65) {
              return l10n.ageMustBeLessThan65;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCityAreaRow() {
    return Row(
      children: [
        Expanded(child: _buildCityField()),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildAreaField()),
      ],
    );
  }

  Widget _buildCityAreaColumn() {
    return Column(
      children: [
        _buildCityField(),
        SizedBox(height: context.cardPadding),
        _buildAreaField(),
      ],
    );
  }

  Widget _buildCityField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: '${l10n.city} *',
          hint: l10n.enterCity,
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterCity;
            }
            return null;
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonCities
              .take(4)
              .map(
                (city) => _buildQuickSelectChip(
              label: city,
              onTap: () => setState(() => _cityController.text = city),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: '${l10n.area} *',
          hint: l10n.enterArea,
          controller: _areaController,
          prefixIcon: Icons.map_outlined,
          enabled: !_isUpdating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterArea;
            }
            return null;
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonAreas
              .take(4)
              .map(
                (area) => _buildQuickSelectChip(
              label: area,
              onTap: () => setState(() => _areaController.text = area),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<LaborProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateLabor,
              onPressed: (_isUpdating || provider.isLoading) ? null : _handleUpdate,
              isLoading: _isUpdating || provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: AppTheme.primaryMaroon,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _isUpdating ? null : _handleCancel,
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
            onPressed: _isUpdating ? null : _handleCancel,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 2,
          child: Consumer<LaborProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updateLabor,
                onPressed: (_isUpdating || provider.isLoading) ? null : _handleUpdate,
                isLoading: _isUpdating || provider.isLoading,
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
