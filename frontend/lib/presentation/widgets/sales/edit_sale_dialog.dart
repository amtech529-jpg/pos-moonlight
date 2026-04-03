import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/models/sales/request_models.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EditSaleDialog extends StatefulWidget {
  final SaleModel sale;

  const EditSaleDialog({super.key, required this.sale});

  @override
  State<EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<EditSaleDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedPaymentMethod = 'Cash';
  String _selectedStatus = 'Paid';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    _amountPaidController.text = widget.sale.amountPaid.toStringAsFixed(0);
    _notesController.text = widget.sale.notes ?? '';
    _selectedPaymentMethod = widget.sale.paymentMethod ?? 'CASH';
    _selectedStatus = widget.sale.status ?? 'DRAFT';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

      await provider.updateSale(
        widget.sale.id,
        UpdateSaleRequest(paymentMethod: _selectedPaymentMethod, status: _selectedStatus, notes: _notesController.text),
      );

      if (mounted) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
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
              l10n.saleUpdatedSuccessfully,
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

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  double get _remainingAmount {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    return widget.sale.grandTotal - amountPaid;
  }

  String _calculatedStatus(AppLocalizations l10n) {
    final remaining = _remainingAmount;
    if (remaining <= 0) return l10n.paidStatus;
    if (remaining < widget.sale.grandTotal) return l10n.partialStatus;
    return l10n.unpaidStatus;
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context, tablet: 90.h, small: 85.h, medium: 80.h, large: 75.h, ultrawide: 70.h),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildCompactLayout(),
                  small: _buildCompactLayout(),
                  medium: _buildDesktopLayout(),
                  large: _buildDesktopLayout(),
                  ultrawide: _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(controller: _scrollController, child: _buildFormContent(isCompact: true)),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(controller: _scrollController, child: _buildFormContent(isCompact: false)),
        ),
      ],
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
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.edit_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.editSale : l10n.editSaleDetails,
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
                    widget.sale.formattedInvoiceNumber,
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
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.sale.id,
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

  Widget _buildFormContent({required bool isCompact}) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSaleSummaryCard(),
            SizedBox(height: context.cardPadding),
            _buildEditableFieldsCard(isCompact),
            SizedBox(height: context.cardPadding),
            _buildPaymentSummaryCard(),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSummaryCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.saleSummaryReadOnly,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
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
                      l10n.customer,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      widget.sale.customerName,
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.items,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      l10n.itemsCount(widget.sale.totalItems),
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subtotal,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      'PKR ${widget.sale.subtotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.grandTotal,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      'PKR ${widget.sale.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.sale.overallDiscount > 0 || widget.sale.gstPercentage > 0) ...[
            SizedBox(height: context.smallPadding),
            Row(
              children: [
                if (widget.sale.overallDiscount > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.discount,
                          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                        ),
                        Text(
                          'PKR ${widget.sale.overallDiscount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                if (widget.sale.gstPercentage > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gst,
                          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                        ),
                        Text(
                          '${widget.sale.gstPercentage}%',
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableFieldsCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.editableFields,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.paymentMethod,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentMethod,
                isExpanded: true,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value ?? 'Cash'),
                items: ['Cash', 'Card', 'Bank Transfer', 'Credit', 'Split'].map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
                      child: Row(
                        children: [
                          Icon(_getPaymentMethodIcon(method), color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                          SizedBox(width: context.smallPadding),
                          Text(
                            method,
                            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.amountPaidPkr,
            controller: _amountPaidController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money_rounded,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.enterAmountPaid;
              final amount = double.tryParse(value!);
              if (amount == null || amount < 0) return l10n.enterValidAmount;
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.status,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                onChanged: (value) => setState(() => _selectedStatus = value ?? 'Paid'),
                items: [
                  DropdownMenuItem(value: 'Paid', child: _buildStatusItem(l10n.paidStatus, _getStatusColor('Paid'), context)),
                  DropdownMenuItem(value: 'Partial', child: _buildStatusItem(l10n.partialStatus, _getStatusColor('Partial'), context)),
                  DropdownMenuItem(value: 'Unpaid', child: _buildStatusItem(l10n.unpaidStatus, _getStatusColor('Unpaid'), context)),
                ],
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.notesOptional,
            controller: _notesController,
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            hint: l10n.specialInstructionsOrRemarks,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status, Color color, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: context.smallPadding),
          Text(
            status,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _remainingAmount;
    final calculatedStatus = _calculatedStatus(l10n);

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: remaining <= 0 ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: remaining <= 0 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: remaining <= 0 ? Colors.green : Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentSummary,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: _getStatusColor(_selectedStatus), shape: BoxShape.circle),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      calculatedStatus,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ),
                  ],
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
                      l10n.grandTotal,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      'PKR ${widget.sale.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.amountPaying,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      'PKR ${(double.tryParse(_amountPaidController.text) ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: Colors.green),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining > 0 ? l10n.remaining : l10n.change,
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                    Text(
                      'PKR ${remaining.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: remaining > 0 ? Colors.red : Colors.blue,
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

  Widget _buildActionButtons(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SalesProvider>(
      builder: (context, provider, child) {
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumButton(
                text: provider.isLoading ? l10n.updating : l10n.updateSale,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight,
                icon: Icons.save_rounded,
                backgroundColor: AppTheme.primaryMaroon,
              ),
              SizedBox(height: context.cardPadding),
              PremiumButton(
                text: l10n.cancel,
                onPressed: provider.isLoading ? null : _handleCancel,
                isOutlined: true,
                height: context.buttonHeight,
                backgroundColor: Colors.grey[600],
                textColor: Colors.grey[600],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: l10n.cancel,
                  onPressed: provider.isLoading ? null : _handleCancel,
                  isOutlined: true,
                  height: context.buttonHeight / 1.5,
                  backgroundColor: Colors.grey[600],
                  textColor: Colors.grey[600],
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumButton(
                  text: provider.isLoading ? l10n.updating : l10n.updateSale,
                  onPressed: provider.isLoading ? null : _handleUpdate,
                  isLoading: provider.isLoading,
                  height: context.buttonHeight / 1.5,
                  icon: Icons.save_rounded,
                  backgroundColor: AppTheme.primaryMaroon,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money_rounded;
      case 'Card':
        return Icons.credit_card_rounded;
      case 'Bank Transfer':
        return Icons.account_balance_rounded;
      case 'Credit':
        return Icons.account_balance_wallet_rounded;
      case 'Split':
        return Icons.call_split_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
