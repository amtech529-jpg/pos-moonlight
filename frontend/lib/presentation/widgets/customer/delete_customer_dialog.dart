import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class EnhancedDeleteCustomerDialog extends StatefulWidget {
  final Customer customer;

  const EnhancedDeleteCustomerDialog({
    super.key,
    required this.customer,
  });

  @override
  State<EnhancedDeleteCustomerDialog> createState() => _EnhancedDeleteCustomerDialogState();
}

class _EnhancedDeleteCustomerDialogState extends State<EnhancedDeleteCustomerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  bool _isPermanentDelete = true; // Toggle between permanent and soft delete
  bool _confirmationChecked = false; // Requires user to check confirmation
  String _confirmationText = ''; // User must type confirmation text
  bool _hasSalesRecords = false; // Track if customer has sales records

  final TextEditingController _confirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Check if customer has sales records
    _hasSalesRecords = widget.customer.totalSalesCount > 0;
    
    // If customer has sales records, default to soft delete
    if (_hasSalesRecords) {
      _isPermanentDelete = false;
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    if (!_validateDeletion()) {
      _showValidationError();
      return;
    }

    final provider = Provider.of<CustomerProvider>(context, listen: false);

    bool success;
    if (_isPermanentDelete) {
      success = await provider.deleteCustomer(widget.customer.id);
      
      // If permanent delete failed due to PROTECT constraint, suggest soft delete
      if (!success && provider.errorMessage?.contains('protected foreign keys') == true) {
        if (mounted) {
          _showProtectedKeysError();
        }
        return;
      }
    } else {
      success = await provider.softDeleteCustomer(widget.customer.id);
    }

    if (mounted) {
      if (success) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      } else {
        _showErrorSnackbar(provider.errorMessage ?? 'Failed to delete customer');
      }
    }
  }

  bool _validateDeletion() {
    return true;
  }

  void _showProtectedKeysError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Cannot Delete Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This customer has sales records and cannot be permanently deleted.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Would you like to soft delete this customer instead? (They will be marked as inactive but their data will be preserved)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14, color: AppTheme.charcoalGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isPermanentDelete = false;
              });
              _handleDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Soft Delete',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationError() {
    _showSnackbar('Please confirm that you understand this action', Colors.orange, Icons.warning_outlined);
  }

  void _showSuccessSnackbar() {
    _showSnackbar(
      _isPermanentDelete
          ? 'Customer deleted permanently!'
          : 'Customer deactivated successfully!',
      Colors.green,
      Icons.check_circle_rounded,
    );
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar(message, Colors.red, Icons.error_outline);
  }

  void _showSnackbar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
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
        backgroundColor: color,
        duration: Duration(seconds: color == Colors.red ? 4 : 3),
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
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(
                  _shakeAnimation.value * 2 * (1 - _scaleAnimation.value),
                  0,
                ),
                child: Container(
                  width: 360,
                  constraints: BoxConstraints(
                    maxWidth: 360,
                    maxHeight: 85.h,
                  ),
                  margin: EdgeInsets.all(context.mainPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius('large')),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: context.shadowBlur('heavy'),
                        offset: Offset(0, context.cardPadding),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildContent(),
                    ],
                  ),
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
        gradient: LinearGradient(
          colors: _isPermanentDelete
              ? [Colors.red, Colors.redAccent]
              : [Colors.orange, Colors.orangeAccent],
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
              _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
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
                  _isPermanentDelete ? 'Delete Permanently' : 'Deactivate Customer',
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
                    _isPermanentDelete
                        ? 'This action cannot be undone'
                        : 'Customer can be restored later',
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
              onTap: _handleCancel,
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
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.smallPadding),
          Text(
            _isPermanentDelete
                ? 'Are you sure you want to permanently delete "${widget.customer.name}"? This action cannot be undone.'
                : 'Are you sure you want to deactivate "${widget.customer.name}"? They will be hidden but can be restored later.',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: AppTheme.charcoalGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
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
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: _isPermanentDelete ? Colors.red : Colors.orange,
            size: context.iconSize('large'),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPermanentDelete ? 'Permanent Deletion Warning' : 'Deactivation Notice',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: _isPermanentDelete ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  _isPermanentDelete
                      ? 'This will permanently remove all customer data from the database. This action cannot be reversed.'
                      : 'This will deactivate the customer but preserve all data. The customer can be restored later.',
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    color: AppTheme.charcoalGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteTypeToggle() {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Choose deletion type:',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: _buildDeleteOption(
                  title: 'Permanent Delete',
                  subtitle: 'Removes from database permanently',
                  icon: Icons.delete_forever_rounded,
                  color: Colors.red,
                  isSelected: _isPermanentDelete,
                  onTap: () {
                    setState(() {
                      _isPermanentDelete = true;
                      _confirmationChecked = false;
                      _confirmationText = '';
                      _confirmationController.clear();
                    });
                  },
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildDeleteOption(
                  title: 'Deactivate',
                  subtitle: 'Hide but can be restored',
                  icon: Icons.visibility_off_rounded,
                  color: Colors.orange,
                  isSelected: !_isPermanentDelete,
                  onTap: () {
                    setState(() {
                      _isPermanentDelete = false;
                      _confirmationChecked = false;
                      _confirmationText = '';
                      _confirmationController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.cardPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: context.iconSize('medium'),
            ),
            SizedBox(height: context.smallPadding),
            Text(
              title,
              style: TextStyle(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.smallPadding / 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.captionFontSize * 0.9,
                color: isSelected ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getCustomerInitials(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _isPermanentDelete ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.smallPadding,
                              vertical: context.smallPadding / 2,
                            ),
                            decoration: BoxDecoration(
                              color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Text(
                              widget.customer.id,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w600,
                                color: _isPermanentDelete ? Colors.red : Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: context.smallPadding),
                        Expanded(
                          child: Text(
                            widget.customer.name,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!context.isTablet) ...[
                      SizedBox(height: context.smallPadding),
                      Text(
                        '${widget.customer.phone} • ${widget.customer.email}',
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.customer.lastPurchase != null) ...[
            SizedBox(height: context.cardPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: Colors.blue,
                    size: context.iconSize('small'),
                  ),
                  SizedBox(width: context.smallPadding),
                  Text(
                    'Customer since: ${_formatDate(widget.customer.createdAt)}',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactWarning() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: Colors.amber[700],
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Impact Assessment',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            _isPermanentDelete
                ? '• All customer data will be permanently removed\n• Order history will be anonymized\n• Contact information will be deleted\n• This action cannot be undone'
                : '• Customer will be hidden from active lists\n• All data will be preserved\n• Customer can be restored later\n• Order history remains intact',
            style: TextStyle(
              fontSize: context.subtitleFontSize,
              color: AppTheme.charcoalGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _confirmationChecked = !_confirmationChecked;
              });
            },
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.smallPadding),
              child: Row(
                children: [
                  Checkbox(
                    value: _confirmationChecked,
                    onChanged: (value) {
                      setState(() {
                        _confirmationChecked = value ?? false;
                      });
                    },
                    activeColor: _isPermanentDelete ? Colors.red : Colors.orange,
                  ),
                  Expanded(
                    child: Text(
                      _isPermanentDelete
                          ? 'I understand this will permanently delete the customer.'
                          : 'I understand this will deactivate the customer.',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: (_isPermanentDelete ? Colors.red : Colors.orange)[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cancel Button (safe action)
        PremiumButton(
          text: 'Cancel',
          onPressed: _handleCancel,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: AppTheme.pureWhite,
        ),

        SizedBox(height: context.cardPadding),

        // Delete Button (destructive action)
        Consumer<CustomerProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: _isPermanentDelete ? 'Delete Permanently' : 'Deactivate Customer',
              onPressed: provider.isLoading ? null : _handleDelete,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
              backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
              textColor: AppTheme.pureWhite,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    return Row(
      children: [
        // Cancel Button (safe action)
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: 'Cancel',
            onPressed: _handleCancel,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: AppTheme.pureWhite,
          ),
        ),

        SizedBox(width: context.cardPadding),

        // Delete Button (destructive action)
        Expanded(
          flex: 1,
          child: Consumer<CustomerProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: _isPermanentDelete ? 'Delete' : 'Deactivate',
                onPressed: provider.isLoading ? null : _handleDelete,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: _isPermanentDelete ? Icons.delete_forever_rounded : Icons.visibility_off_rounded,
                backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
                textColor: AppTheme.pureWhite,
              );
            },
          ),
        ),
      ],
    );
  }

  String _getCustomerInitials() {
    final words = widget.customer.name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.length == 1) {
      return words[0].substring(0, 2).toUpperCase();
    }
    return 'CU';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}