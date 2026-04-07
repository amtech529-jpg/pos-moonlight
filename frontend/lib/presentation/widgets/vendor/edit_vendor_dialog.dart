import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EnhancedEditVendorDialog extends StatefulWidget {
  final VendorModel vendor;

  const EnhancedEditVendorDialog({super.key, required this.vendor});

  @override
  State<EnhancedEditVendorDialog> createState() => _EnhancedEditVendorDialogState();
}

class _EnhancedEditVendorDialogState extends State<EnhancedEditVendorDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;
  
  // Date
  late DateTime _selectedDate;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Track changes
  bool _hasChanges = false;
  Map<String, dynamic> _originalData = {};

  // Options
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

    // Initialize controllers with existing vendor data
    _nameController = TextEditingController(text: widget.vendor.name);
    _businessNameController = TextEditingController(text: widget.vendor.businessName);
    _phoneController = TextEditingController(text: widget.vendor.phone);
    _addressController = TextEditingController(text: widget.vendor.fullAddress);
    _noteController = TextEditingController(text: ''); 
    _selectedDate = widget.vendor.createdAt;

    // Store original data for change tracking
    _originalData = {
      'name': widget.vendor.name,
      'businessName': widget.vendor.businessName,
      'phone': widget.vendor.phone,
      'fullAddress': widget.vendor.fullAddress,
      'note': '', 
      'createdAt': widget.vendor.createdAt.toIso8601String(),
    };

    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _businessNameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _noteController.addListener(_checkForChanges);

    // Initialize animations
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
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final currentData = {
      'name': _nameController.text,
      'businessName': _businessNameController.text,
      'phone': _phoneController.text,
      'fullAddress': _addressController.text,
      'note': _noteController.text,
      'createdAt': _selectedDate.toIso8601String(),
    };

    bool hasChanges = false;
    for (String key in _originalData.keys) {
      if (_originalData[key] != currentData[key]) {
        hasChanges = true;
        break;
      }
    }

    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (!_hasChanges) {
        _showInfoSnackbar(l10n.noChangesDetected);
        return;
      }

      final provider = Provider.of<VendorProvider>(context, listen: false);

      final success = await provider.updateVendor(
        id: widget.vendor.id,
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        cnic: null,
        phone: _phoneController.text.trim(),
        city: null,
        area: null,
        fullAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: _selectedDate,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(provider.errorMessage ?? '${l10n.failedToUpdate} ${l10n.vendor}');
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
              '${l10n.vendor} ${l10n.updatedSuccessfully}!',
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

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleCancel() {
    final l10n = AppLocalizations.of(context)!;

    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (dialogContext) => Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Unsaved Changes?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Do you want to discard your changes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.black),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Cancel', 
                            style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _animationController.reverse().then((_) {
                              Navigator.of(context).pop();
                            });
                          },
                          child: const Text(
                            'Discard', 
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      _animationController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 90.w,
                  small: 95.w,
                  medium: 75.w,
                  large: 60.w,
                  ultrawide: 50.w,
                ),
                constraints: BoxConstraints(
                  maxHeight: 92.h,
                ),
                margin: EdgeInsets.all(!context.isMinimumSupported ? 8 : 16),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                    // Keep buttons always visible at bottom, out of scroll
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: _buildActionButtons(),
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
        gradient: LinearGradient(
          colors: _hasChanges ? [Colors.orange[700]!, Colors.orange[400]!] : [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
              _hasChanges ? Icons.edit : Icons.edit_outlined,
              color: Colors.white,
              size: context.iconSize('large'),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout
                      ? '${l10n.edit} ${l10n.vendor}'
                      : '${l10n.edit} ${l10n.vendor} ${l10n.details}',
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    _hasChanges ? l10n.unsavedChanges : '${l10n.update} ${l10n.vendor} ${l10n.information}',
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
          if (_hasChanges)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.orange, size: 8),
                  SizedBox(width: context.smallPadding / 2),
                  Text(
                    l10n.modified,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.pureWhite,
                    ),
                  ),
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
              widget.vendor.id.length > 8 ? '${widget.vendor.id.substring(0, 8)}...' : widget.vendor.id,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFormFields() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: '${l10n.vendor} ${l10n.name} *',
          labelFontSize: 12.sp,
          hint: l10n.enterVendorName,
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        PremiumTextField(
          label: '${l10n.phone} *',
          labelFontSize: 12.sp,
          hint: 'Enter Phone Number',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        PremiumTextField(
          label: '${l10n.businessName} *',
          labelFontSize: 12.sp,
          hint: 'Enter Business/Company Name',
          controller: _businessNameController,
          prefixIcon: Icons.business_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        PremiumTextField(
          label: 'Address *',
          labelFontSize: 12.sp,
          hint: 'Enter Full Address',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.next,
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        PremiumTextField(
          label: 'Notes (Optional)',
          labelFontSize: 12.sp,
          hint: 'Add notes here',
          controller: _noteController,
          prefixIcon: Icons.note_outlined,
          maxLines: 2,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleUpdate(),
        ),
        const SizedBox(height: 12),
        _buildDatePicker(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryMaroon),
            const SizedBox(width: 12),
            Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryMaroon,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: AppTheme.primaryMaroon,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _checkForChanges();
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: "Cancel",
            onPressed: _handleCancel,
            isOutlined: true,
            backgroundColor: AppTheme.primaryMaroon,
            textColor: AppTheme.primaryMaroon,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<VendorProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: "Update Vendor",
                onPressed: (!_hasChanges || provider.isLoading) ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: 48,
                backgroundColor: _hasChanges ? AppTheme.primaryMaroon : Colors.grey[400],
                textColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
}
