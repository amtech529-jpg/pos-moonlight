import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/services/customer_service.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';

class ViewCustomerDetailsDialog extends StatefulWidget {
  final Customer customer;

  const ViewCustomerDetailsDialog({super.key, required this.customer});

  @override
  State<ViewCustomerDetailsDialog> createState() => _ViewCustomerDetailsDialogState();
}

class _ViewCustomerDetailsDialogState extends State<ViewCustomerDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final CustomerService _customerService = CustomerService();
  CustomerModel? _fullCustomerDetails;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    _loadFullCustomerDetails();
  }

  Future<void> _loadFullCustomerDetails() async {
    try {
      setState(() {
        _isLoadingDetails = true;
      });

      final response = await _customerService.getCustomerById(widget.customer.id);

      if (response.success && response.data != null) {
        setState(() {
          _fullCustomerDetails = response.data!;
          _isLoadingDetails = false;
        });
      } else {
        setState(() {
          _isLoadingDetails = false;
        });
        _showErrorSnackbar(response.message ?? 'Failed to load customer details');
      }
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
      _showErrorSnackbar('Error loading customer details: ${e.toString()}');
    }
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

  void _showSuccessSnackbar(String message) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _handleVerifyContact(String type) async {
    try {
      final response = await _customerService.verifyCustomerContact(
        id: widget.customer.id,
        verificationType: type,
        verified: true,
      );

      if (response.success) {
        _showSuccessSnackbar('${type.capitalize()} verified successfully!');
        _loadFullCustomerDetails();
        if (mounted) {
          context.read<CustomerProvider>().loadCustomers(showLoadingIndicator: false);
        }
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to verify $type');
      }
    } catch (e) {
      _showErrorSnackbar('Error verifying $type: ${e.toString()}');
    }
  }

  void _handleUpdateActivity(String activityType) async {
    try {
      final response = await _customerService.updateCustomerActivity(
        id: widget.customer.id,
        activityType: activityType,
        activityDate: DateTime.now().toIso8601String(),
      );

      if (response.success) {
        _showSuccessSnackbar('Customer ${activityType} updated successfully!');
        _loadFullCustomerDetails();
        if (mounted) {
          context.read<CustomerProvider>().loadCustomers(showLoadingIndicator: false);
        }
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to update customer $activityType');
      }
    } catch (e) {
      _showErrorSnackbar('Error updating customer $activityType: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
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
                  maxHeight: 85.h,
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
                child: _isLoadingDetails
                    ? _buildLoadingState()
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: _buildContent(),
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

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryMaroon,
            strokeWidth: 3,
          ),
          SizedBox(height: context.cardPadding),
          Text(
            'Loading customer details...',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
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
              Icons.person_rounded,
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
                  'Customer Details',
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
                    'Complete customer information',
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
              horizontal: context.cardPadding,
              vertical: context.cardPadding / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Text(
              widget.customer.id.length > 10
                  ? '${widget.customer.id.substring(0, 10)}...'
                  : widget.customer.id,
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
              onTap: _handleClose,
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

  Widget _buildContent() {
    if (_fullCustomerDetails == null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: context.iconSize('xl'),
                color: Colors.grey[400],
              ),
              SizedBox(height: context.cardPadding),
              Text(
                'Failed to load customer details',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: context.smallPadding),
              TextButton(
                onPressed: _loadFullCustomerDetails,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerProfileCard(),
            SizedBox(height: context.cardPadding),
            _buildContactInfoCard(),
            SizedBox(height: context.cardPadding),
            _buildLocationCard(),
            SizedBox(height: context.cardPadding),
            _buildStatusAndTypeCard(),
            SizedBox(height: context.cardPadding),
            _buildVerificationCard(),
            if (_fullCustomerDetails!.businessName != null || _fullCustomerDetails!.taxNumber != null) ...[
              SizedBox(height: context.cardPadding),
              _buildBusinessInfoCard(),
            ],
            if (_fullCustomerDetails!.notes != null && _fullCustomerDetails!.notes!.isNotEmpty) ...[
              SizedBox(height: context.cardPadding),
              _buildNotesCard(),
            ],
            SizedBox(height: context.cardPadding),
            _buildActivityCard(),
            SizedBox(height: context.cardPadding),
            _buildQuickActionsCard(),
            SizedBox(height: context.mainPadding),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerProfileCard() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _fullCustomerDetails!.initials,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullCustomerDetails!.displayName,
                  style: TextStyle(
                    fontSize: context.headerFontSize * 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: context.iconSize('small'),
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      'Customer since ${_fullCustomerDetails!.formattedCreatedAt}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: context.iconSize('small'),
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      '${_fullCustomerDetails!.customerAgeDays} days old (${_fullCustomerDetails!.relativeCreatedAt})',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildContactInfoCompact(),
      small: _buildContactInfoCompact(),
      medium: _buildContactInfoExpanded(),
      large: _buildContactInfoExpanded(),
      ultrawide: _buildContactInfoExpanded(),
    );
  }

  Widget _buildContactInfoCompact() {
    return Column(
      children: [
        _buildInfoCard(
          title: 'Phone Number',
          value: _fullCustomerDetails!.phone,
          icon: Icons.phone,
          color: Colors.orange,
          trailing: _fullCustomerDetails!.phoneVerified
              ? Icon(Icons.verified, color: Colors.green, size: context.iconSize('small'))
              : Icon(Icons.error, color: Colors.red, size: context.iconSize('small')),
        ),
        SizedBox(height: context.cardPadding),
        _buildInfoCard(
          title: 'Email Address',
          value: _fullCustomerDetails!.email,
          icon: Icons.email,
          color: Colors.purple,
          trailing: _fullCustomerDetails!.emailVerified
              ? Icon(Icons.verified, color: Colors.green, size: context.iconSize('small'))
              : Icon(Icons.error, color: Colors.red, size: context.iconSize('small')),
        ),
      ],
    );
  }

  Widget _buildContactInfoExpanded() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'Phone Number',
            value: _fullCustomerDetails!.phone,
            icon: Icons.phone,
            color: Colors.orange,
            trailing: _fullCustomerDetails!.phoneVerified
                ? Icon(Icons.verified, color: Colors.green, size: context.iconSize('small'))
                : Icon(Icons.error, color: Colors.red, size: context.iconSize('small')),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildInfoCard(
            title: 'Email Address',
            value: _fullCustomerDetails!.email,
            icon: Icons.email,
            color: Colors.purple,
            trailing: _fullCustomerDetails!.emailVerified
                ? Icon(Icons.verified, color: Colors.green, size: context.iconSize('small'))
                : Icon(Icons.error, color: Colors.red, size: context.iconSize('small')),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final locationText = [
      _fullCustomerDetails!.address,
      _fullCustomerDetails!.city,
      _fullCustomerDetails!.country,
    ].where((item) => item != null && item.isNotEmpty).join(', ');

    return _buildInfoCard(
      title: 'Location',
      value: locationText.isNotEmpty ? locationText : 'Not provided',
      icon: Icons.location_on,
      color: Colors.teal,
    );
  }

  Widget _buildStatusAndTypeCard() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'Status',
            value: _fullCustomerDetails!.statusDisplayName,
            icon: Icons.flag,
            color: _getStatusColor(_fullCustomerDetails!.status),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildInfoCard(
            title: 'Type',
            value: _fullCustomerDetails!.customerTypeDisplayName,
            icon: _fullCustomerDetails!.customerType == 'BUSINESS' ? Icons.business : Icons.person,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
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
              Icon(
                Icons.verified_user,
                color: Colors.green,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _fullCustomerDetails!.phoneVerified ? Icons.check_circle : Icons.cancel,
                      color: _fullCustomerDetails!.phoneVerified ? Colors.green : Colors.red,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      'Phone ${_fullCustomerDetails!.phoneVerified ? 'Verified' : 'Unverified'}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: _fullCustomerDetails!.phoneVerified ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _fullCustomerDetails!.emailVerified ? Icons.check_circle : Icons.cancel,
                      color: _fullCustomerDetails!.emailVerified ? Colors.green : Colors.red,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      'Email ${_fullCustomerDetails!.emailVerified ? 'Verified' : 'Unverified'}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: _fullCustomerDetails!.emailVerified ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return _buildInfoCard(
      title: 'Business Information',
      value: [
        if (_fullCustomerDetails!.businessName != null) 'Name: ${_fullCustomerDetails!.businessName}',
        if (_fullCustomerDetails!.taxNumber != null) 'Tax Number: ${_fullCustomerDetails!.taxNumber}',
      ].join('\n'),
      icon: Icons.business,
      color: Colors.indigo,
    );
  }

  Widget _buildNotesCard() {
    return _buildInfoCard(
      title: 'Notes',
      value: _fullCustomerDetails!.notes!,
      icon: Icons.note,
      color: Colors.amber,
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Activity Timeline',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Order',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      _fullCustomerDetails!.lastOrderDate != null
                          ? _fullCustomerDetails!.formattedLastOrderDate
                          : 'No orders yet',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: _fullCustomerDetails!.lastOrderDate != null
                            ? AppTheme.charcoalGray
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Contact',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      _fullCustomerDetails!.lastContactDate != null
                          ? _fullCustomerDetails!.formattedLastContactDate
                          : 'No contact yet',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: _fullCustomerDetails!.lastContactDate != null
                            ? AppTheme.charcoalGray
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.orange,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Wrap(
            spacing: context.smallPadding,
            runSpacing: context.smallPadding / 2,
            children: [
              if (!_fullCustomerDetails!.phoneVerified)
                _buildActionChip(
                  label: 'Verify Phone',
                  icon: Icons.phone_android,
                  color: Colors.green,
                  onTap: () => _handleVerifyContact('phone'),
                ),
              if (!_fullCustomerDetails!.emailVerified)
                _buildActionChip(
                  label: 'Verify Email',
                  icon: Icons.email,
                  color: Colors.blue,
                  onTap: () => _handleVerifyContact('email'),
                ),
              _buildActionChip(
                label: 'Update Order',
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => _handleUpdateActivity('order'),
              ),
              _buildActionChip(
                label: 'Update Contact',
                icon: Icons.contact_phone,
                color: Colors.teal,
                onTap: () => _handleUpdateActivity('contact'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            value,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.cardPadding / 2,
          vertical: context.smallPadding,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: context.iconSize('small')),
            SizedBox(width: context.smallPadding / 2),
            Text(
              label,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: PremiumButton(
        text: 'Close',
        onPressed: _handleClose,
        height: context.buttonHeight / 1.5,
        isOutlined: true,
        backgroundColor: Colors.grey[600],
        textColor: Colors.grey[600],
      ),
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
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}