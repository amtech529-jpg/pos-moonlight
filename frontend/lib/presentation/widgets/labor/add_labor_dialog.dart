import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';

class AddLaborDialog extends StatefulWidget {
  const AddLaborDialog({super.key});

  @override
  State<AddLaborDialog> createState() => _AddLaborDialogState();
}

class _AddLaborDialogState extends State<AddLaborDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _incentiveController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _cnicFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _designationFocusNode = FocusNode();
  final _salaryFocusNode = FocusNode();
  final _incentiveFocusNode = FocusNode();
  final _areaFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _cityChipsFirstFocusNode = FocusNode();
  final _areaChipsFirstFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();

  String _selectedGender = 'M';
  DateTime _selectedJoiningDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Map<String, String> _validationErrors = {};

  bool _isCreating = false;

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
    _ageController.dispose();
    _nameFocusNode.dispose();
    _cnicFocusNode.dispose();
    _phoneFocusNode.dispose();
    _designationFocusNode.dispose();
    _salaryFocusNode.dispose();
    _incentiveFocusNode.dispose();
    _cityFocusNode.dispose();
    _areaFocusNode.dispose();
    _cityChipsFirstFocusNode.dispose();
    _areaChipsFirstFocusNode.dispose();
    _ageFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<LaborProvider>(context, listen: false);
    _validationErrors = {};

    if (_nameController.text.trim().isEmpty) {
      _validationErrors['name'] = l10n.nameIsRequired;
    }
    // CNIC is now optional, so validation removed here.
    if (_phoneController.text.trim().isEmpty) {
      _validationErrors['phoneNumber'] = l10n.phoneNumberIsRequired;
    }
    if (_designationController.text.trim().isEmpty) {
      _validationErrors['designation'] = l10n.designationIsRequired;
    }
    if (_areaController.text.trim().isEmpty) {
      _validationErrors['area'] = l10n.areaIsRequired;
    }
    if (_cityController.text.trim().isEmpty) {
      _validationErrors['city'] = l10n.cityIsRequired;
    }
    if (_selectedGender.isEmpty) {
      _validationErrors['gender'] = l10n.genderIsRequired;
    }
    if (_selectedJoiningDate.isAfter(DateTime.now())) {
      _validationErrors['joiningDate'] = l10n.joiningDateCannotBeInFuture;
    }

    double? salary;
    if (_salaryController.text.trim().isEmpty) {
      _validationErrors['salary'] = l10n.salaryIsRequired;
    } else {
      salary = double.tryParse(_salaryController.text.trim());
      if (salary == null) {
        _validationErrors['salary'] = l10n.pleaseEnterValidSalaryAmount;
      }
    }

    double incentive = 0.0;
    if (_incentiveController.text.trim().isNotEmpty) {
      incentive = double.tryParse(_incentiveController.text.trim()) ?? 0.0;
    }

    int? age;
    if (_ageController.text.trim().isEmpty) {
      _validationErrors['age'] = l10n.ageIsRequired;
    } else {
      age = int.tryParse(_ageController.text.trim());
      if (age == null) {
        _validationErrors['age'] = l10n.pleaseEnterValidAge;
      }
    }

    if (_validationErrors.isNotEmpty) {
      setState(() {});
      return;
    }

    _validationErrors = provider.validateLaborData(
      name: _nameController.text.trim(),
      cnic: _cnicController.text.trim().isEmpty ? "" : _cnicController.text.trim(), // Handle optional CNIC
      phoneNumber: _phoneController.text.trim(),
      designation: _designationController.text.trim(),
      salary: salary!,
      area: _areaController.text.trim(),
      city: _cityController.text.trim(),
      age: age!,
      gender: _selectedGender,
      joiningDate: _selectedJoiningDate,
      fixedIncentive: incentive,
    );

    setState(() {});
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_isCreating) return;

      setState(() {
        _isCreating = true;
      });

      _validateForm();

      if (_validationErrors.isNotEmpty) {
        _showValidationErrors();
        setState(() {
          _isCreating = false;
        });
        return;
      }

      try {
        final provider = Provider.of<LaborProvider>(context, listen: false);

        double salary = double.parse(_salaryController.text.trim());
        double incentive = double.tryParse(_incentiveController.text.trim()) ?? 0.0;
        int age = int.parse(_ageController.text.trim());

        final success = await provider.createLabor(
          name: _nameController.text.trim(),
          cnic: _cnicController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          designation: _designationController.text.trim(),
          joiningDate: _selectedJoiningDate,
          salary: salary,
          area: _areaController.text.trim(),
          city: _cityController.text.trim(),
          gender: _selectedGender,
          age: age,
          fixedIncentive: incentive,
        );

        if (mounted) {
          if (success) {
            _showSuccessSnackbar();
            _clearForm();
            Navigator.of(context).pop();
          } else {
            _showErrorSnackbar(provider.errorMessage ?? l10n.failedToCreateLabor);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('${l10n.errorCreatingLabor} ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }

  void _showValidationErrors() {
    final l10n = AppLocalizations.of(context)!;
    final errorMessages = _validationErrors.values.join('\n');

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
                '${l10n.pleaseFixFollowingErrors}\n$errorMessages',
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
        duration: const Duration(seconds: 5),
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
              l10n.laborCreatedSuccessfully,
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
    if (_isCreating) return;

    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _clearForm() {
    _nameController.clear();
    _cnicController.clear();
    _phoneController.clear();
    _designationController.clear();
    _salaryController.clear();
    _areaController.clear();
    _cityController.clear();
    _ageController.clear();
    _incentiveController.clear();
    setState(() {
      _selectedGender = 'M';
      _selectedJoiningDate = DateTime.now();
      _validationErrors = {};
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (_isCreating) return;

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

  Widget _buildQuickSelectChip({
    required String label, 
    required String currentValue, 
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    final isSelected = label.toLowerCase() == currentValue.toLowerCase();
    
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter || 
              event.logicalKey == LogicalKeyboardKey.space) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final bool isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryMaroon 
                    : (isFocused ? AppTheme.primaryMaroon.withOpacity(0.2) : AppTheme.accentGold.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(
                  color: (isSelected || isFocused) ? AppTheme.primaryMaroon : AppTheme.accentGold.withOpacity(0.3), 
                  width: (isSelected || isFocused) ? 1.5 : 1,
                ),
                boxShadow: isFocused ? [
                  BoxShadow(
                    color: AppTheme.primaryMaroon.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ] : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: (isSelected || isFocused) ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isFocused ? AppTheme.primaryMaroon : AppTheme.accentGold),
                ),
              ),
            ),
          );
        }
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
                    tablet: 90.w,
                    small: 85.w,
                    medium: 75.w,
                    large: 65.w,
                    ultrawide: 55.w,
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
              Icons.person_add_alt_1_rounded,
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
                  context.shouldShowCompactLayout ? l10n.addLabor : l10n.addNewLabor,
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
                    l10n.createNewLaborRecord,
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
              onTap: _isCreating ? null : _handleCancel,
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
          label: l10n.fullNameRequired,
          hint: context.shouldShowCompactLayout ? l10n.enterName : l10n.enterWorkersFullName,
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          focusNode: _nameFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_cnicFocusNode),
          enabled: !_isCreating,
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
          label: "${l10n.cnic} (Optional)",
          hint: context.shouldShowCompactLayout
              ? l10n.enterCnic
              : l10n.enterCnicFormat,
          controller: _cnicController,
          prefixIcon: Icons.credit_card,
          focusNode: _cnicFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
          enabled: !_isCreating,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value)) {
                return l10n.pleaseEnterValidCnicFormat;
              }
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
          label: l10n.phoneNumberRequired,
          hint: context.shouldShowCompactLayout ? l10n.enterPhone : l10n.enterPhoneNumberFormat,
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityFocusNode),
          enabled: !_isCreating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterPhoneNumber;
            }
            // Allow any digits, potentially with leading + or spaces/dashes
            if (!RegExp(r'^[+]*[0-9\s-]+$').hasMatch(value!)) {
              return l10n.pleaseEnterValidPhoneNumberFormat;
            }
            if (value.length < 7) {
              return "Phone number too short";
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
          label: l10n.designationRequired,
          hint: context.shouldShowCompactLayout
              ? l10n.enterDesignation
              : l10n.enterJobDesignation,
          controller: _designationController,
          prefixIcon: Icons.work_outline,
          focusNode: _designationFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_salaryFocusNode),
          enabled: !_isCreating,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterDesignation;
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        GestureDetector(
          onTap: _isCreating ? null : () => _selectDate(context),
          child: AbsorbPointer(
            child: PremiumTextField(
              label: l10n.joiningDateRequired,
              hint: l10n.selectJoiningDate,
              controller: TextEditingController(
                  text:
                  '${_selectedJoiningDate.day.toString().padLeft(2, '0')}/${_selectedJoiningDate.month.toString().padLeft(2, '0')}/${_selectedJoiningDate.year}'),
              prefixIcon: Icons.calendar_today,
              enabled: !_isCreating,
            ),
          ),
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: l10n.monthlySalaryRequired,
          hint: context.shouldShowCompactLayout
              ? l10n.enterSalary
              : l10n.enterMonthlySalaryInPkr,
          controller: _salaryController,
          prefixIcon: Icons.account_balance_wallet_outlined,
          keyboardType: TextInputType.number,
          focusNode: _salaryFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_incentiveFocusNode),
          enabled: !_isCreating,
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
          hint: 'Enter fixed incentive amount (e.g. 1000)',
          controller: _incentiveController,
          prefixIcon: Icons.card_giftcard_outlined,
          keyboardType: TextInputType.number,
          focusNode: _incentiveFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_ageFocusNode),
          enabled: !_isCreating,
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
          label: l10n.genderRequired,
          hint: context.shouldShowCompactLayout ? l10n.selectGender : l10n.selectGender,
          prefixIcon: Icons.person_pin_rounded,
          items: [
            DropdownItem<String>(value: 'M', label: l10n.male),
            DropdownItem<String>(value: 'F', label: l10n.female),
            DropdownItem<String>(value: 'O', label: l10n.other),
          ],
          value: _selectedGender,
          onChanged: _isCreating
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
          label: l10n.ageRequired,
          hint: context.shouldShowCompactLayout ? l10n.enterAge : l10n.enterAgeMinimum18Years,
          controller: _ageController,
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          focusNode: _ageFocusNode,
          textInputAction: TextInputAction.done,
          enabled: !_isCreating,
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
          label: l10n.cityRequired,
          hint: l10n.enterCity,
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          focusNode: _cityFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityChipsFirstFocusNode),
          enabled: !_isCreating,
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
          children: _commonCities.take(4).toList().asMap().entries.map((entry) => _buildQuickSelectChip(
              label: entry.value,
              currentValue: _cityController.text,
              onTap: () {
                setState(() => _cityController.text = entry.value);
                FocusScope.of(context).requestFocus(_areaFocusNode);
              },
              focusNode: entry.key == 0 ? _cityChipsFirstFocusNode : null,
            ),
          ).toList(),
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
          label: l10n.areaRequired,
          hint: l10n.enterArea,
          controller: _areaController,
          prefixIcon: Icons.map_outlined,
          focusNode: _areaFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_areaChipsFirstFocusNode),
          enabled: !_isCreating,
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
          children: _commonAreas.take(4).toList().asMap().entries.map((entry) => _buildQuickSelectChip(
              label: entry.value,
              currentValue: _areaController.text,
              onTap: () {
                setState(() => _areaController.text = entry.value);
                FocusScope.of(context).requestFocus(_designationFocusNode);
              },
              focusNode: entry.key == 0 ? _areaChipsFirstFocusNode : null,
            ),
          ).toList(),
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
              text: l10n.addLabor,
              onPressed: (_isCreating || provider.isLoading) ? null : _handleSubmit,
              isLoading: _isCreating || provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.person_add_alt_1_rounded,
              backgroundColor: AppTheme.primaryMaroon,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _isCreating ? null : _handleCancel,
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
            onPressed: _isCreating ? null : _handleCancel,
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
                text: l10n.addLabor,
                onPressed: (_isCreating || provider.isLoading) ? null : _handleSubmit,
                isLoading: _isCreating || provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.person_add_alt_1_rounded,
                backgroundColor: AppTheme.primaryMaroon,
              );
            },
          ),
        ),
      ],
    );
  }
}
