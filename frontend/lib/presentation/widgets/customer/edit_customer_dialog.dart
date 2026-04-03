import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EditCustomerDialog extends StatefulWidget {
  final Customer customer;

  const EditCustomerDialog({super.key, required this.customer});

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _businessNameController;
  late TextEditingController _taxNumberController;
  late TextEditingController _notesController;

  // Form state
  String _selectedCustomerType = 'INDIVIDUAL';
  String _selectedStatus = 'NEW';
  bool _showBusinessFields = false;
  bool _phoneVerified = false;
  bool _emailVerified = false;
  bool _isActive = true;

  // Loading state for fetching full customer details
  bool _isLoadingFullDetails = false;
  Customer? _fullCustomerDetails;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Options
  final List<String> _customerTypes = ['INDIVIDUAL', 'BUSINESS'];
  final List<String> _statusOptions = ['NEW', 'REGULAR', 'VIP', 'INACTIVE'];
  final List<String> _commonCountries = ['Pakistan', 'UAE', 'Saudi Arabia', 'UK', 'USA', 'Canada', 'Australia', 'India'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing customer data
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _emailController = TextEditingController(text: widget.customer.email);
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _cityController = TextEditingController(text: widget.customer.city ?? '');
    _countryController = TextEditingController(text: widget.customer.country);
    _businessNameController = TextEditingController(text: widget.customer.businessName ?? '');
    _taxNumberController = TextEditingController(text: widget.customer.taxNumber ?? '');
    _notesController = TextEditingController(text: widget.customer.description ?? '');

    // Initialize form state with existing customer data
    _selectedCustomerType = widget.customer.customerType;
    _selectedStatus = widget.customer.status;

    // Show business fields if customer type is BUSINESS or if there's business data
    final hasBusinessData = (widget.customer.businessName?.isNotEmpty ?? false) || (widget.customer.taxNumber?.isNotEmpty ?? false);
    _showBusinessFields = _selectedCustomerType.toUpperCase() == 'BUSINESS' || hasBusinessData;

    // If we have business data but customer type is not BUSINESS, update it
    if (hasBusinessData && _selectedCustomerType.toUpperCase() != 'BUSINESS') {
      _selectedCustomerType = 'BUSINESS';
    }

    _phoneVerified = widget.customer.phoneVerified;
    _emailVerified = widget.customer.emailVerified;
    _isActive = widget.customer.isActive;

    // Initialize animations
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    // Fetch full customer details
    _fetchFullCustomerDetails();
  }

  Future<void> _fetchFullCustomerDetails() async {
    setState(() {
      _isLoadingFullDetails = true;
    });

    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      final success = await provider.fetchCustomerById(widget.customer.id);

      if (success && provider.selectedCustomer != null) {
        setState(() {
          _fullCustomerDetails = provider.selectedCustomer;
          _updateFormWithFullDetails();
        });
      }
    } catch (e) {
      print('Error fetching full customer details: $e');
    } finally {
      setState(() {
        _isLoadingFullDetails = false;
      });
    }
  }

  void _updateFormWithFullDetails() {
    if (_fullCustomerDetails == null) return;

    final customer = _fullCustomerDetails!;

    // Update controllers with full details
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _businessNameController.text = customer.businessName ?? '';
    _taxNumberController.text = customer.taxNumber ?? '';
    _notesController.text = customer.description ?? '';

    // Update form state
    _selectedCustomerType = customer.customerType;
    _selectedStatus = customer.status;

    // Show business fields if customer type is BUSINESS or if there's business data
    final hasBusinessData = (customer.businessName?.isNotEmpty ?? false) || (customer.taxNumber?.isNotEmpty ?? false);
    _showBusinessFields = _selectedCustomerType.toUpperCase() == 'BUSINESS' || hasBusinessData;

    // If we have business data but customer type is not BUSINESS, update it
    if (hasBusinessData && _selectedCustomerType.toUpperCase() != 'BUSINESS') {
      _selectedCustomerType = 'BUSINESS';
    }

    _phoneVerified = customer.phoneVerified;
    _emailVerified = customer.emailVerified;
    _isActive = customer.isActive;
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

    // Clear selected customer from provider
    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      // Note: We can't call a method here, but the provider will handle cleanup
    } catch (e) {
      // Provider might not be available during dispose
    }

    super.dispose();
  }

  void _handleCustomerTypeChange(String? newType) {
    if (newType != null && newType != _selectedCustomerType) {
      setState(() {
        _selectedCustomerType = newType;

        // Show business fields if customer type is BUSINESS or if there's existing business data
        final hasBusinessData = (widget.customer.businessName?.isNotEmpty ?? false) || (widget.customer.taxNumber?.isNotEmpty ?? false);
        _showBusinessFields = newType.toUpperCase() == 'BUSINESS' || hasBusinessData;
      });
    }
  }

  void _handleStatusChange(String? newStatus) {
    if (newStatus != null && newStatus != _selectedStatus) {
      setState(() {
        _selectedStatus = newStatus;
      });
    }
  }

  void _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);

      final success = await provider.updateCustomer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        customerType: _selectedCustomerType,
        status: _selectedStatus,
        businessName: _showBusinessFields && _businessNameController.text.trim().isNotEmpty ? _businessNameController.text.trim() : null,
        taxNumber: _showBusinessFields && _taxNumberController.text.trim().isNotEmpty ? _taxNumberController.text.trim() : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        phoneVerified: _phoneVerified,
        emailVerified: _emailVerified,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(provider.errorMessage ?? 'Failed to update customer');
        }
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              'Customer updated successfully!',
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
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
                  context.shouldShowCompactLayout ? 'Edit Customer' : 'Edit Customer Details',
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
                    'Update customer information',
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          widget.customer.customerTypeDisplay,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.customer.status).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.customer.statusDisplay,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.customer.id,
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Type and Status Section
              _buildTypeAndStatusSection(),

              SizedBox(height: context.cardPadding),

              // Customer Statistics Section
              _buildCustomerStatsSection(),

              SizedBox(height: context.cardPadding),

              // Basic Information Section
              _buildBasicInfoSection(),

              SizedBox(height: context.cardPadding),

              // Contact Information Section
              _buildContactInfoSection(),

              SizedBox(height: context.cardPadding),

              // Verification Section
              _buildVerificationSection(),

              SizedBox(height: context.cardPadding),

              // Business Information Section (conditionally shown)
              if (_showBusinessFields) ...[_buildBusinessInfoSection(), SizedBox(height: context.cardPadding)],

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

  Widget _buildTypeAndStatusSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                'Customer Type & Status',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          // Customer Type Selection
          Text(
            'Customer Type',
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: _customerTypes
                .map(
                  (type) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: type == _customerTypes.last ? 0 : context.smallPadding),
                      child: InkWell(
                        onTap: () => _handleCustomerTypeChange(type),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                        child: Container(
                          padding: EdgeInsets.all(context.cardPadding / 1.5),
                          decoration: BoxDecoration(
                            color: _selectedCustomerType == type ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(context.borderRadius()),
                            border: Border.all(
                              color: _selectedCustomerType == type ? Colors.blue : Colors.grey.shade300,
                              width: _selectedCustomerType == type ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == 'BUSINESS' ? Icons.business : Icons.person,
                                color: _selectedCustomerType == type ? Colors.blue : Colors.grey[600],
                                size: context.iconSize('small'),
                              ),
                              SizedBox(width: context.smallPadding / 2),
                              Text(
                                type == 'BUSINESS' ? 'Business' : 'Individual',
                                style: TextStyle(
                                  fontSize: context.captionFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedCustomerType == type ? Colors.blue : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          SizedBox(height: context.cardPadding),

          // Status Selection
          Text(
            'Customer Status',
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding,
            runSpacing: context.smallPadding / 2,
            children: _statusOptions
                .map(
                  (status) => InkWell(
                    onTap: () => _handleStatusChange(status),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.smallPadding),
                      decoration: BoxDecoration(
                        color: _selectedStatus == status ? _getStatusColor(status).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        border: Border.all(
                          color: _selectedStatus == status ? _getStatusColor(status) : Colors.grey.shade300,
                          width: _selectedStatus == status ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        _getStatusDisplayName(status),
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: _selectedStatus == status ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedStatus == status ? _getStatusColor(status) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatsSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                'Customer Statistics',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(child: _buildStatItem('Total Sales', '${widget.customer.totalSalesCount}', Icons.shopping_cart_outlined, Colors.green)),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildStatItem(
                  'Last Order Date',
                  widget.customer.lastOrderDate != null ? DateFormat('MMM dd, yyyy').format(widget.customer.lastOrderDate!) : 'N/A',
                  Icons.calendar_today_outlined,
                  Colors.blue,
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildStatItem(
                  'Customer Since',
                  DateFormat('MMM dd, yyyy').format(widget.customer.createdAt),
                  Icons.cake_outlined,
                  Colors.purple,
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildStatItem(
                  'Recent Sales',
                  widget.customer.hasRecentSales ? 'Yes' : 'No',
                  Icons.trending_up_outlined,
                  widget.customer.hasRecentSales ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: context.iconSize('medium')),
        SizedBox(height: context.smallPadding),
        Text(
          title,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding),
        Text(
          value,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: color),
        ),
      ],
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
          hint: context.shouldShowCompactLayout ? 'Enter full name' : 'Enter customer\'s full name',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
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
          hint: context.shouldShowCompactLayout ? 'Enter phone' : 'Enter phone number',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
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
          hint: context.shouldShowCompactLayout ? 'Enter email (optional)' : 'Enter email address (optional)',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
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
          hint: context.shouldShowCompactLayout ? 'Enter address' : 'Enter complete address (optional)',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length > 300) {
                return 'Address must be less than 300 characters';
              }
            }
            return null;
          },
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

  Widget _buildVerificationSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                'Verification Status',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _phoneVerified,
                  onChanged: (value) => setState(() => _phoneVerified = value ?? false),
                  title: Text(
                    'Phone Verified',
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                  ),
                  activeColor: Colors.green,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: _emailVerified,
                  onChanged: (value) => setState(() => _emailVerified = value ?? false),
                  title: Text(
                    'Email Verified',
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                  ),
                  activeColor: Colors.green,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          // Active Status (Display Only)
          Container(
            padding: EdgeInsets.all(context.cardPadding / 2),
            decoration: BoxDecoration(
              color: widget.customer.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: widget.customer.isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  widget.customer.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: widget.customer.isActive ? Colors.green : Colors.red,
                  size: context.iconSize('medium'),
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  'Account Status: ${widget.customer.isActive ? 'Active' : 'Inactive'}',
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: widget.customer.isActive ? Colors.green : Colors.red,
                  ),
                ),
                if (widget.customer.isActive) ...[
                  SizedBox(width: context.smallPadding),
                  Icon(Icons.info_outline, color: Colors.green, size: context.iconSize('small')),
                  SizedBox(width: context.smallPadding / 2),
                  Text(
                    'Account is currently active',
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.green[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFieldsRow() {
    return Row(
      children: [
        Expanded(
          child: PremiumTextField(label: 'City', hint: 'Enter city', controller: _cityController, prefixIcon: Icons.location_city_outlined),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildCountryField()),
      ],
    );
  }

  Widget _buildLocationFieldsColumn() {
    return Column(
      children: [
        PremiumTextField(
          label: 'City',
          hint: 'Enter city',
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length > 100) {
                return 'City name must be less than 100 characters';
              }
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),
        _buildCountryField(),
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
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length > 100) {
                return 'Country name must be less than 100 characters';
              }
            }
            return null;
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonCountries
              .take(4)
              .map(
                (country) => InkWell(
                  onTap: () => setState(() => _countryController.text = country),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      country,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.accentGold),
                    ),
                  ),
                ),
              )
              .toList(),
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
            hint: context.shouldShowCompactLayout ? 'Enter business name' : 'Enter registered business name',
            controller: _businessNameController,
            prefixIcon: Icons.business_center_outlined,
            validator: _showBusinessFields
                ? (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Business name is required for business customers';
                    }
                    if (value!.length < 2) {
                      return 'Business name must be at least 2 characters';
                    }
                    if (value.length > 200) {
                      return 'Business name must be less than 200 characters';
                    }
                    return null;
                  }
                : null,
          ),
          SizedBox(height: context.cardPadding),

          // Tax Number
          PremiumTextField(
            label: 'Tax/NTN Number',
            hint: context.shouldShowCompactLayout ? 'Enter tax number' : 'Enter tax or NTN number (optional)',
            controller: _taxNumberController,
            prefixIcon: Icons.receipt_outlined,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 3) {
                  return 'Tax number must be at least 3 characters';
                }
                if (value.length > 50) {
                  return 'Tax number must be less than 50 characters';
                }
                // Basic format validation for Pakistani NTN
                if (value.isNotEmpty && !RegExp(r'^[0-9-]+$').hasMatch(value)) {
                  return 'Tax number should contain only numbers and hyphens';
                }
              }
              return null;
            },
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
          hint: context.shouldShowCompactLayout ? 'Enter notes' : 'Enter any additional notes about the customer (optional)',
          controller: _notesController,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
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
        Icon(icon, color: Colors.blue, size: context.iconSize('medium')),
        SizedBox(width: context.smallPadding),
        Text(
          title,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
      ],
    );
  }

  Widget _buildCompactButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<CustomerProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: 'Update Customer',
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
                text: 'Update Customer',
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'REGULAR':
        return Colors.green;
      case 'VIP':
        return Colors.purple;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'New Customer';
      case 'REGULAR':
        return 'Regular Customer';
      case 'VIP':
        return 'VIP Customer';
      case 'INACTIVE':
        return 'Inactive Customer';
      default:
        return status;
    }
  }
}
