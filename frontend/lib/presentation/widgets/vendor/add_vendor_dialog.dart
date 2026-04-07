import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EnhancedAddVendorDialog extends StatefulWidget {
  const EnhancedAddVendorDialog({super.key});

  @override
  State<EnhancedAddVendorDialog> createState() => _EnhancedAddVendorDialogState();
}

class _EnhancedAddVendorDialogState extends State<EnhancedAddVendorDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _businessNameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  
  // Date
  DateTime _selectedDate = DateTime.now();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Validation errors
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
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
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _businessNameFocusNode.dispose();
    _addressFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    final provider = Provider.of<VendorProvider>(context, listen: false);

    _validationErrors = provider.validateVendorData(
      name: _nameController.text,
      phone: _phoneController.text,
      businessName: null,
      cnic: null,
      city: null,
      area: null,
    );

    setState(() {});
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _validateForm();

      if (_validationErrors.isNotEmpty) {
        _showValidationErrors();
        return;
      }

      final provider = Provider.of<VendorProvider>(context, listen: false);

      final success = await provider.addVendor(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
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
          _showErrorSnackbar(provider.errorMessage ?? 'Failed to add vendor');
        }
      }
    }
  }

  void _showValidationErrors() {
    final l10n = AppLocalizations.of(context)!;
    final errorMessages = _validationErrors.values.join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.pleaseFixErrors}:\n$errorMessages', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.vendor} ${l10n.success}!'),
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

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
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
              onPrimary: Colors.white, // Selected day text
              onSurface: Colors.black, // Day numbers and months
              secondary: AppTheme.primaryMaroon,
            ),
            dialogBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              bodyLarge: TextStyle(color: Colors.black),
              labelSmall: TextStyle(color: Colors.black),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryMaroon,
              ),
            ),
          ),
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
                width: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 85.w,
                  small: 95.w,
                  medium: 60.w,
                  large: 45.w,
                  ultrawide: 35.w,
                ),
                constraints: BoxConstraints(
                  maxHeight: 92.h,
                ),
                margin: EdgeInsets.all(!context.isMinimumSupported ? 12 : 24),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded, color: AppTheme.pureWhite, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${l10n.add} ${l10n.vendor}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.pureWhite),
            ),
          ),
          IconButton(
            onPressed: _handleCancel,
            icon: const Icon(Icons.close_rounded, color: AppTheme.pureWhite),
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
              const SizedBox(height: 24),
              _buildActionButtons(),
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
        PremiumTextField(
          label: '${l10n.vendor} ${l10n.name} *',
          labelFontSize: 12.sp,
          hint: l10n.enterVendorName,
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          focusNode: _nameFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          label: '${l10n.phone} *',
          labelFontSize: 12.sp,
          hint: 'Enter Phone Number',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_businessNameFocusNode),
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          label: '${l10n.businessName} *',
          labelFontSize: 12.sp,
          hint: 'Enter Business/Company Name',
          controller: _businessNameController,
          prefixIcon: Icons.business_outlined,
          focusNode: _businessNameFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_addressFocusNode),
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          label: 'Address *',
          labelFontSize: 12.sp,
          hint: 'Enter Full Address',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          focusNode: _addressFocusNode,
          maxLines: 2,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_noteFocusNode),
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          label: 'Notes (Optional)',
          labelFontSize: 12.sp,
          hint: 'Add notes here',
          controller: _noteController,
          prefixIcon: Icons.note_outlined,
          focusNode: _noteFocusNode,
          maxLines: 2,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: 16),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: "Cancel",
            onPressed: _handleCancel,
            isOutlined: true,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumButton(
            text: "Add Vendor",
            onPressed: _handleSubmit,
            height: 48,
            backgroundColor: AppTheme.primaryMaroon,
          ),
        ),
      ],
    );
  }
}
