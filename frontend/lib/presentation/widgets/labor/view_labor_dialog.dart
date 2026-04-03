import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';

class ViewLaborDetailsDialog extends StatefulWidget {
  final LaborModel labor;

  const ViewLaborDetailsDialog({super.key, required this.labor});

  @override
  State<ViewLaborDetailsDialog> createState() => _ViewLaborDetailsDialogState();
}

class _ViewLaborDetailsDialogState extends State<ViewLaborDetailsDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              message,
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

  void _handleStatusChange(bool newStatus) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() {
        _isLoadingDetails = true;
      });

      final provider = context.read<LaborProvider>();
      final success = newStatus ? await provider.restoreLabor(widget.labor.id) : await provider.softDeleteLabor(widget.labor.id);

      if (success) {
        _showSuccessSnackbar(l10n.laborStatusUpdatedSuccessfully);
        Navigator.of(context).pop();
      } else {
        _showErrorSnackbar(l10n.failedToUpdateLaborStatus);
      }
    } catch (e) {
      _showErrorSnackbar('${l10n.errorUpdatingLaborStatus} ${e.toString()}');
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 85.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: _isLoadingDetails
                    ? _buildLoadingState()
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildContent()),
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
          CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.loadingLaborDetails,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
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
        gradient: LinearGradient(colors: widget.labor.isActive ? [Colors.green, Colors.greenAccent] : [Colors.orange, Colors.orangeAccent]),
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
            child: Icon(Icons.engineering_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.laborDetails,
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
                    l10n.completeLaborInformation,
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
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.labor.id.length > 10 ? '${widget.labor.id.substring(0, 10)}...' : widget.labor.id,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
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
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
            _buildLaborProfileCard(),
            SizedBox(height: context.cardPadding),
            _buildContactInfoCard(),
            SizedBox(height: context.cardPadding),
            _buildWorkInfoCard(),
            SizedBox(height: context.cardPadding),
            _buildLocationCard(),
            SizedBox(height: context.cardPadding),
            _buildFinancialCard(),
            SizedBox(height: context.cardPadding),
            _buildStatusCard(),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborProfileCard() {
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
            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: Center(
              child: Text(
                widget.labor.initials,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.pureWhite),
              ),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.labor.displayName,
                  style: TextStyle(
                    fontSize: context.headerFontSize * 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.grey[600]),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      '${l10n.joined} ${_formatDate(widget.labor.joiningDate)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.grey[600]),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      '${widget.labor.workExperienceDays} ${l10n.daysExperience} (${widget.labor.workExperienceYears.toStringAsFixed(1)} ${l10n.years})',
                      style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
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
          _buildInfoRow(l10n.phone, widget.labor.formattedPhone, Icons.phone),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.cnic, widget.labor.cnic, Icons.credit_card),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.gender, widget.labor.genderDisplay, Icons.person),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.age, '${widget.labor.age} ${l10n.years}', Icons.cake),
        ],
      ),
    );
  }

  Widget _buildWorkInfoCard() {
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: l10n.workInformation,
      icon: Icons.work,
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.designation, widget.labor.designation, Icons.work_outline),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.salary, 'PKR ${widget.labor.salary.toStringAsFixed(0)}', Icons.attach_money),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.joiningDate, _formatDate(widget.labor.joiningDate), Icons.calendar_today),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.experience, '${widget.labor.workExperienceYears.toStringAsFixed(1)} ${l10n.years}', Icons.timeline),
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
          _buildInfoRow(l10n.city, widget.labor.city, Icons.location_city),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.area, widget.labor.area, Icons.map),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.fullAddress, widget.labor.fullAddress, Icons.home),
        ],
      ),
    );
  }

  Widget _buildFinancialCard() {
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: l10n.financialInformation,
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.monthlySalary, 'PKR ${widget.labor.salary.toStringAsFixed(0)}', Icons.attach_money),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.totalAdvances, 'PKR ${widget.labor.totalAdvanceAmount.toStringAsFixed(2)}', Icons.payment),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.totalPayments, 'PKR ${widget.labor.totalPaymentsAmount.toStringAsFixed(2)}', Icons.receipt),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.remainingMonthlySalary, 'PKR ${widget.labor.remainingMonthlySalary.toStringAsFixed(2)}', Icons.account_balance),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.remainingAdvanceAmount, 'PKR ${widget.labor.remainingAdvanceAmount.toStringAsFixed(2)}', Icons.account_balance_wallet),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.totalAdvancesThisMonth, 'PKR ${widget.labor.totalAdvancesAmount.toStringAsFixed(2)}', Icons.payment),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.paymentRecords, '${widget.labor.paymentsCount} ${l10n.payments}', Icons.history),
          if (widget.labor.lastPaymentDate != null) ...[
            SizedBox(height: context.smallPadding),
            _buildInfoRow(l10n.lastPayment, _formatDate(widget.labor.lastPaymentDate!), Icons.schedule),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final l10n = AppLocalizations.of(context)!;

    return _buildInfoCard(
      title: l10n.statusInformation,
      icon: Icons.info,
      color: _getStatusColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.status, widget.labor.isActive ? l10n.active : l10n.inactive, Icons.flag),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.created, _formatDate(widget.labor.createdAt), Icons.schedule),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.lastUpdated, _formatDate(widget.labor.updatedAt), Icons.update),
          if (widget.labor.createdBy != null) ...[
            SizedBox(height: context.smallPadding),
            _buildInfoRow(l10n.createdBy, widget.labor.createdBy!, Icons.person),
          ],
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              if (widget.labor.isNewLabor) _buildStatusBadge(l10n.newLabor, Colors.green),
              if (widget.labor.isRecentLabor) _buildStatusBadge(l10n.recent, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
      margin: EdgeInsets.only(right: context.smallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Color color, required Widget child}) {
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
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
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
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildCompactActionButtons(),
      small: _buildCompactActionButtons(),
      medium: _buildDesktopActionButtons(),
      large: _buildDesktopActionButtons(),
      ultrawide: _buildDesktopActionButtons(),
    );
  }

  Widget _buildCompactActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.labor.isActive)
          PremiumButton(
            text: l10n.restoreLabor,
            onPressed: () => _handleStatusChange(true),
            height: context.buttonHeight,
            icon: Icons.restore,
            backgroundColor: Colors.green,
          ),
        if (!widget.labor.isActive) SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.close,
          onPressed: _handleClose,
          height: context.buttonHeight,
          isOutlined: true,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.close,
            onPressed: _handleClose,
            height: context.buttonHeight / 1.5,
            isOutlined: true,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        if (!widget.labor.isActive) ...[
          SizedBox(width: context.cardPadding),
          Expanded(
            child: PremiumButton(
              text: l10n.restoreLabor,
              onPressed: () => _handleStatusChange(true),
              height: context.buttonHeight / 1.5,
              icon: Icons.restore,
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    if (widget.labor.isActive) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
