import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Focus Nodes
  final _businessNameFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  
  // Quick Select Focus Nodes
  final _cityChipsFirstFocusNode = FocusNode();
  final _countryChipsFirstFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();

  // Form state
  String _selectedCustomerType = 'INDIVIDUAL';
  bool _showBusinessFields = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Options
  final List<String> _customerTypes = ['INDIVIDUAL', 'BUSINESS'];
  final List<String> _commonCities = [
    'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad',
    'Multan', 'Peshawar', 'Quetta'
  ];
  final List<String> _commonCountries = [
    'Pakistan', 'UAE', 'Saudi Arabia', 'UK', 'USA', 'Canada', 'Australia'
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _businessNameController.dispose();
    _taxNumberController.dispose();
    _notesController.dispose();
    _businessNameFocusNode.dispose();
    _notesFocusNode.dispose();
    _cityChipsFirstFocusNode.dispose();
    _countryChipsFirstFocusNode.dispose();
    _cityFocusNode.dispose();
    _countryFocusNode.dispose();
    super.dispose();
  }

  void _handleCustomerTypeChange(String type) {
    if (_selectedCustomerType == type) return;

    setState(() {
      _selectedCustomerType = type;
      _showBusinessFields = type == 'BUSINESS';
      
      // Preserve data when switching, only clear business-specific fields if needed
      if (!_showBusinessFields) {
        _businessNameController.clear();
        _taxNumberController.clear();
      }
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      final success = await provider.addCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        customerType: _selectedCustomerType,
        businessName: _showBusinessFields && _businessNameController.text.trim().isNotEmpty
            ? _businessNameController.text.trim()
            : null,
        taxNumber: _showBusinessFields && _taxNumberController.text.trim().isNotEmpty
            ? _taxNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(provider.errorMessage ?? l10n.failedToAddCustomer);
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
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.customerAddedSuccessfully,
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
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
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
                    Flexible(
                      child: _buildFormContent(),
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
      padding: EdgeInsets.symmetric(
        horizontal: context.cardPadding,
        vertical: context.cardPadding * 0.4, // Reduced vertical padding
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryMaroon,
            AppTheme.primaryMaroon.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding * 0.6),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.15),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(
              Icons.person_add_outlined, // Sleeker icon
              color: AppTheme.pureWhite,
              size: 20, // Smaller icon size
            ),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.addCustomer,
                  style: const TextStyle(
                    fontSize: 16, // Smaller font
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  l10n.createNewCustomerProfile,
                  style: TextStyle(
                    fontSize: 11, // Smaller subtext
                    fontWeight: FontWeight.w400,
                    color: AppTheme.pureWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.pureWhite,
                  size: 20,
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
              // Customer Type Selection
              _buildCustomerTypeSection(),

              SizedBox(height: context.cardPadding),

              // Basic Information Section
              _buildBasicInfoSection(),

              SizedBox(height: context.cardPadding),

              // Contact Information Section
              _buildContactInfoSection(),

              // Business Information Section (conditionally shown)
              if (_showBusinessFields) ...[
                SizedBox(height: context.cardPadding),
                _buildBusinessInfoSection(),
              ],

              SizedBox(height: context.cardPadding),

              // Additional Information Section
              _buildAdditionalInfoSection(),

              SizedBox(height: context.mainPadding),

              // Action Buttons
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

  Widget _buildCustomerTypeSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding * 0.4), // Reduced from all(cardPadding)
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.02), // Subtler background
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('small'), // Smaller icon
              ),
              SizedBox(width: context.smallPadding / 2),
              Text(
                'Customer Type',
                style: TextStyle(
                  fontSize: context.subtitleFontSize, // Smaller title
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray.withOpacity(0.8),
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding), // Reduced gap
          Container(
            padding: const EdgeInsets.all(4), // Inner padding for the "track"
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Row(
              children: _customerTypes.map((type) {
                final bool isSelected = _selectedCustomerType == type;
                return Expanded(
                  child: InkWell(
                    onTap: () => _handleCustomerTypeChange(type),
                    borderRadius: BorderRadius.circular(context.borderRadius('small') - 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10), // Slimmer height
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.pureWhite : Colors.transparent,
                        borderRadius: BorderRadius.circular(context.borderRadius('small') - 2),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ] : [],
                        border: isSelected ? Border.all(
                          color: AppTheme.primaryMaroon.withOpacity(0.2),
                          width: 1,
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type == 'BUSINESS' ? Icons.business_outlined : Icons.person_outline,
                            color: isSelected ? AppTheme.primaryMaroon : Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type == 'BUSINESS' ? 'Business' : 'Individual',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryMaroon : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information', Icons.info_outline),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: 'Full Name *',
          hint: context.shouldShowCompactLayout
              ? 'Enter name'
              : 'Enter customer\'s full name',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter customer name';
            }
            if (value!.length < 2) {
              return 'Name must be at least 2 characters';
            }
            if (value.length > 100) {
              return 'Name must be less than 100 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contact Information', Icons.contact_phone_outlined),
        SizedBox(height: context.cardPadding),

        // Phone Number
        PremiumTextField(
          label: 'Phone Number *',
          hint: context.shouldShowCompactLayout
              ? 'Enter phone'
              : 'Enter phone number (e.g., +923001234567)',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter phone number';
            }
            if (value!.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),

        // Email
        PremiumTextField(
          label: 'Email Address',
          hint: context.shouldShowCompactLayout
              ? 'Enter email (optional)'
              : 'Enter email address (optional)',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),

        // Address
        PremiumTextField(
          label: 'Address',
          hint: context.shouldShowCompactLayout
              ? 'Enter address'
              : 'Enter complete address (optional)',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          maxLines: 2,
        ),
        SizedBox(height: context.cardPadding),

        // City and Country Row
        ResponsiveBreakpoints.responsive(
          context,
          tablet: _buildLocationFieldsColumn(),
          small: _buildLocationFieldsColumn(),
          medium: _buildLocationFieldsRow(),
          large: _buildLocationFieldsRow(),
          ultrawide: _buildLocationFieldsRow(),
        ),
      ],
    );
  }

  Widget _buildLocationFieldsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCityField(),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildCountryField(),
        ),
      ],
    );
  }

  Widget _buildLocationFieldsColumn() {
    return Column(
      children: [
        _buildCityField(),
        SizedBox(height: context.cardPadding),
        _buildCountryField(),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: 'City',
          hint: 'Enter city',
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          focusNode: _cityFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityChipsFirstFocusNode),
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonCities.take(4).toList().asMap().entries.map((entry) => _buildQuickSelectChip(
            label: entry.value,
            isSelected: _cityController.text == entry.value,
            onTap: () {
              setState(() => _cityController.text = entry.value);
              // Move focus to Country field after selecting city
              FocusScope.of(context).requestFocus(_countryFocusNode);
            },
            focusNode: entry.key == 0 ? _cityChipsFirstFocusNode : null,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: 'Country',
          hint: 'Enter country',
          controller: _countryController,
          prefixIcon: Icons.public_outlined,
          focusNode: _countryFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_countryChipsFirstFocusNode),
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonCountries.take(4).toList().asMap().entries.map((entry) => _buildQuickSelectChip(
            label: entry.value,
            isSelected: _countryController.text == entry.value,
            onTap: () {
              setState(() => _countryController.text = entry.value);
              // Move focus forward after selecting country
              if (_showBusinessFields) {
                FocusScope.of(context).requestFocus(_businessNameFocusNode);
              } else {
                FocusScope.of(context).requestFocus(_notesFocusNode);
              }
            },
            focusNode: entry.key == 0 ? _countryChipsFirstFocusNode : null,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Business Information', Icons.business_outlined),
          SizedBox(height: context.cardPadding),

          // Business Name
          PremiumTextField(
            label: 'Business Name *',
            hint: context.shouldShowCompactLayout
                ? 'Enter business name'
                : 'Enter registered business name',
            controller: _businessNameController,
            prefixIcon: Icons.business_center_outlined,
            focusNode: _businessNameFocusNode,
            textInputAction: TextInputAction.next,
            validator: _showBusinessFields ? (value) {
              if (value?.isEmpty ?? true) {
                return 'Business name is required for business customers';
              }
              if (value!.length > 200) {
                return 'Business name must be less than 200 characters';
              }
              return null;
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Information', Icons.note_outlined),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: 'Notes',
          hint: context.shouldShowCompactLayout
              ? 'Enter notes'
              : 'Enter any additional notes about the customer (optional)',
          controller: _notesController,
          prefixIcon: Icons.description_outlined,
          focusNode: _notesFocusNode,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length > 500) {
              return 'Notes must be less than 500 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryMaroon,
          size: context.iconSize('medium'),
        ),
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
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    // Special highlight for Islamabad and Pakistan as per user request
    final bool isSpecialLabel = label == 'Islamabad' || label == 'Pakistan';
    final Color activeColor = isSpecialLabel ? Colors.teal : AppTheme.accentGold;
    
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
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? activeColor.withOpacity(0.15) 
                    : (isFocused ? Colors.grey.withOpacity(0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(
                  color: isSelected 
                      ? activeColor 
                      : (isFocused ? Colors.grey.shade400 : Colors.grey.shade300),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: (isFocused && !isSelected) ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    spreadRadius: 0,
                  )
                ] : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey[700],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCompactButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<CustomerProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: 'Add Customer',
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
          text: 'Cancel',
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
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: 'Cancel',
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
          child: Consumer<CustomerProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Add Customer',
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