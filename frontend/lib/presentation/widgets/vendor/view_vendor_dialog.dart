import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';

class ViewVendorDetailsDialog extends StatefulWidget {
  final VendorModel vendor;

  const ViewVendorDetailsDialog({super.key, required this.vendor});

  @override
  State<ViewVendorDetailsDialog> createState() => _ViewVendorDetailsDialogState();
}

class _ViewVendorDetailsDialogState extends State<ViewVendorDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoadingDetails = false;

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

  void _handleStatusChange(String newStatus) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() {
        _isLoadingDetails = true;
      });

      final provider = context.read<VendorProvider>();
      final success = await provider.updateVendor(
        id: widget.vendor.id,
        name: widget.vendor.name,
        businessName: widget.vendor.businessName,
        cnic: widget.vendor.cnic,
        phone: widget.vendor.phone,
        city: widget.vendor.city,
        area: widget.vendor.area,
      );

      if (success) {
        _showSuccessSnackbar('${l10n.vendor} ${l10n.status} ${l10n.updatedSuccessfully}!');
        Navigator.of(context).pop(); // Close dialog to refresh data
      } else {
        _showErrorSnackbar('${l10n.failedToUpdate} ${l10n.vendor} ${l10n.status}');
      }
    } catch (e) {
      _showErrorSnackbar('${l10n.error} ${l10n.updating} ${l10n.vendor} ${l10n.status}: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
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
    final l10n = AppLocalizations.of(context)!;

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
            '${l10n.loading} ${l10n.vendor} ${l10n.details}...',
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
    final l10n = AppLocalizations.of(context)!;

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
              Icons.store_rounded,
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
                  '${l10n.vendor} ${l10n.details}',
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
                    '${l10n.complete} ${l10n.vendor} ${l10n.information}',
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
              widget.vendor.id.length > 10
                  ? '${widget.vendor.id.substring(0, 10)}...'
                  : widget.vendor.id,
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVendorProfileCard(),
            SizedBox(height: context.cardPadding),
            _buildContactInfoCard(),
            SizedBox(height: context.cardPadding),
            _buildLocationCard(),
            SizedBox(height: context.cardPadding),
            _buildStatusCard(),
            SizedBox(height: context.cardPadding),
            _buildActivityCard(),
            SizedBox(height: context.mainPadding),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorProfileCard() {
    final l10n = AppLocalizations.of(context)!;

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
                widget.vendor.initials,
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
                  widget.vendor.displayName,
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
                      '${l10n.vendor} ${l10n.since} ${widget.vendor.formattedCreatedAt}',
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
                      '${widget.vendor.vendorAgeDays} ${l10n.daysOld} (${widget.vendor.relativeCreatedAt})',
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
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: l10n.contactInformation,
      icon: Icons.contact_phone,
      color: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.phone, widget.vendor.formattedPhone, Icons.phone),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.cnic, widget.vendor.cnic ?? 'N/A', Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: l10n.location,
      icon: Icons.location_on,
      color: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.city, widget.vendor.city, Icons.location_city),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.area, widget.vendor.area, Icons.map),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.fullAddress, widget.vendor.fullAddress, Icons.home),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: '${l10n.status} ${l10n.information}',
      icon: Icons.info,
      color: _getStatusColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.status, widget.vendor.statusDisplayName, Icons.flag),
          SizedBox(height: context.smallPadding),
          _buildInfoRow('${l10n.active} ${l10n.since}', widget.vendor.formattedCreatedAt, Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final l10n = AppLocalizations.of(context)!;

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
                l10n.activitySummary,
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
                      l10n.totalOrders,
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      '${widget.vendor.paymentsCount}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
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
                      l10n.totalAmount,
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      'PKR ${widget.vendor.totalPaymentsAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
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

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: context.iconSize('small'), color: Colors.grey[600]),
        SizedBox(width: context.smallPadding),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: context.subtitleFontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: context.subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerRight,
      child: PremiumButton(
        text: l10n.close,
        onPressed: _handleClose,
        height: context.buttonHeight / 1.5,
        isOutlined: true,
        backgroundColor: Colors.grey[600],
        textColor: Colors.grey[600],
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.vendor.isActive) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}
