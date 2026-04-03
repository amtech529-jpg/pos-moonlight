import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_field.dart';
import '../globals/text_button.dart';
import '../globals/custom_date_picker.dart';

class EditOrderDialog extends StatefulWidget {
  final OrderModel order;

  const EditOrderDialog({super.key, required this.order});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customerController;
  late TextEditingController _descriptionController;
  late TextEditingController _advancePaymentController;
  late TextEditingController _expectedDeliveryDateController;
  late TextEditingController _remainingAmountController;

  Customer? _selectedCustomer;
  OrderStatus _selectedStatus = OrderStatus.PENDING;
  DateTime? _selectedDeliveryDate;
  bool _isLoadingCustomerDetails = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _customerController = TextEditingController(text: widget.order.customerName);
    _descriptionController = TextEditingController(text: widget.order.description);
    _advancePaymentController = TextEditingController(text: widget.order.advancePayment.toString());
    _expectedDeliveryDateController = TextEditingController(
      text: widget.order.expectedDeliveryDate != null
          ? '${widget.order.expectedDeliveryDate!.day.toString().padLeft(2, '0')}/${widget.order.expectedDeliveryDate!.month.toString().padLeft(2, '0')}/${widget.order.expectedDeliveryDate!.year}'
          : '',
    );
    
    double remaining = widget.order.totalAmount - widget.order.advancePayment;
    _remainingAmountController = TextEditingController(text: 'PKR ${remaining.toStringAsFixed(2)}');

    _selectedStatus = widget.order.status;
    _selectedDeliveryDate = widget.order.expectedDeliveryDate;

    _advancePaymentController.addListener(_updateRemainingAmount);

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    _loadCustomerDetails();
  }

  Future<void> _loadCustomerDetails() async {
    setState(() {
      _isLoadingCustomerDetails = true;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final customer = customerProvider.customers.firstWhere(
            (c) => c.id == widget.order.customerId,
        orElse: () => Customer(
          id: widget.order.customerId,
          name: widget.order.customerName,
          phone: widget.order.customerPhone,
          email: widget.order.customerEmail,
          description: null,
          createdAt: DateTime.now(),
          lastPurchaseDate: null,
          lastPurchase: null,
          address: '',
          city: '',
          country: 'Pakistan',
          customerType: 'INDIVIDUAL',
          status: 'NEW',
          phoneVerified: false,
          emailVerified: false,
          businessName: null,
          taxNumber: null,
          isActive: true,
          displayName: widget.order.customerName,
          initials: widget.order.customerName.isNotEmpty ? widget.order.customerName[0].toUpperCase() : 'C',
          isNewCustomer: true,
          isRecentCustomer: false,
          totalSalesCount: 0,
          totalSalesAmount: 0.0,  // Add total sales amount
          hasRecentSales: false,
          customerTypeDisplay: 'Individual',
          statusDisplay: 'New Customer',
          createdByEmail: null,
          lastOrderDate: null,
        ),
      );
      setState(() {
        _selectedCustomer = customer;
        _isLoadingCustomerDetails = false;
      });
    } catch (e) {
      debugPrint('Error loading customer details: $e');
      setState(() {
        _isLoadingCustomerDetails = false;
      });
    }
  }

  void _updateRemainingAmount() {
    if (_advancePaymentController.text.isEmpty) {
      _remainingAmountController.text = 'PKR ${widget.order.totalAmount.toStringAsFixed(2)}';
      return;
    }

    final advance = double.tryParse(_advancePaymentController.text.trim()) ?? 0.0;
    final remaining = widget.order.totalAmount - advance;
    _remainingAmountController.text = 'PKR ${remaining.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerController.dispose();
    _descriptionController.dispose();
    _advancePaymentController.dispose();
    _expectedDeliveryDateController.dispose();
    _remainingAmountController.dispose();
    super.dispose();
  }

  void _handleStatusChange(OrderStatus? status) {
    if (status != null) {
      setState(() {
        _selectedStatus = status;
      });
    }
  }

  void _handleDeliveryDateChange(DateTime? date) {
    setState(() {
      _selectedDeliveryDate = date;
      if (date != null) {
        _expectedDeliveryDateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else {
        _expectedDeliveryDateController.text = '';
      }
    });
  }

  void _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isValidStatusTransition()) {
        _showStatusTransitionWarning();
        return;
      }

      final provider = Provider.of<OrderProvider>(context, listen: false);

      final success = await provider.updateOrder(
        id: widget.order.id,
        description: _descriptionController.text.trim(),
        advancePayment: double.tryParse(_advancePaymentController.text.trim()) ?? 0.0,
        expectedDeliveryDate: _selectedDeliveryDate,
        status: _selectedStatus.name.toUpperCase(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(_getUserFriendlyErrorMessage(provider.errorMessage ?? 'Failed to update order'));
        }
      }
    }
  }

  bool _isValidStatusTransition() {
    if (_selectedStatus == widget.order.status) return true;
    final validNextStatuses = _getValidNextStatuses(widget.order.status);
    return validNextStatuses.contains(_selectedStatus);
  }

  void _showStatusTransitionWarning() {
    final l10n = AppLocalizations.of(context)!;
    final validNextStatuses = _getValidNextStatuses(widget.order.status);
    final validStatusTexts = validNextStatuses.map((s) => _getStatusText(s)).join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(l10n.invalidStatusTransition),
          ],
        ),
        content: Text(
          '${l10n.cannotChangeStatusFrom} "${_getStatusText(widget.order.status)}" ${l10n.to} "${_getStatusText(_selectedStatus)}".\n\n'
              '${l10n.validNextStatusesAre}: $validStatusTexts',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String errorMessage) {
    final l10n = AppLocalizations.of(context)!;

    if (errorMessage.contains('Invalid status transition')) {
      return _getStatusTransitionErrorMessage();
    } else if (errorMessage.contains('maximum recursion depth exceeded')) {
      return l10n.serverErrorOccurred;
    } else if (errorMessage.contains('not a valid choice')) {
      return l10n.invalidStatusSelected;
    } else if (errorMessage.contains('Date has wrong format')) {
      return l10n.invalidDateFormat;
    } else if (errorMessage.contains('cannot be before order date')) {
      return l10n.deliveryDateCannotBeBeforeOrderDate;
    } else if (errorMessage.contains('cannot exceed total amount')) {
      return l10n.advancePaymentCannotExceedTotal;
    } else if (errorMessage.contains('cannot be negative')) {
      return l10n.advancePaymentCannotBeNegative;
    } else if (errorMessage.contains('cannot be modified')) {
      return l10n.orderCannotBeModified;
    }
    return errorMessage;
  }

  String _getStatusTransitionErrorMessage() {
    final l10n = AppLocalizations.of(context)!;
    final currentStatus = widget.order.status;
    final validNextStatuses = _getValidNextStatuses(currentStatus);

    if (validNextStatuses.isEmpty) {
      return l10n.orderCannotHaveStatusChanged;
    }

    final validStatusTexts = validNextStatuses.map((status) => _getStatusText(status)).join(', ');
    return '${l10n.invalidStatusTransitionFrom} ${_getStatusText(currentStatus)}, ${l10n.youCanOnlyChangeTo}: $validStatusTexts';
  }

  List<OrderStatus> _getValidNextStatuses(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.PENDING:
        return [OrderStatus.CONFIRMED, OrderStatus.CANCELLED];
      case OrderStatus.CONFIRMED:
        return [OrderStatus.READY, OrderStatus.CANCELLED];
      case OrderStatus.READY:
        return [OrderStatus.DELIVERED, OrderStatus.CANCELLED];
      case OrderStatus.DELIVERED:
        return []; // OrderStatus.RETURNED removed as per user request. Use Return & Tally module instead.
      case OrderStatus.RETURNED:
        return [];
      case OrderStatus.CANCELLED:
        return [];
    }
  }

  List<OrderStatus> _getValidStatusOptions() {
    final validOptions = <OrderStatus>[widget.order.status];
    validOptions.addAll(_getValidNextStatuses(widget.order.status));

    if (!validOptions.contains(_selectedStatus)) {
      validOptions.add(_selectedStatus);
    }

    validOptions.sort((a, b) {
      if (a == widget.order.status) return -1;
      if (b == widget.order.status) return 1;
      return _getStatusPriority(a).compareTo(_getStatusPriority(b));
    });

    return validOptions;
  }

  int _getStatusPriority(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return 1;
      case OrderStatus.CONFIRMED:
        return 2;
      case OrderStatus.READY:
        return 3;
      case OrderStatus.DELIVERED:
        return 4;
      case OrderStatus.RETURNED:
        return 5;
      case OrderStatus.CANCELLED:
        return 6;
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
              l10n.orderUpdatedSuccessfully,
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
            Icon(Icons.error_outline, color: Colors.white, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Update Failed',
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w400, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
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
                width: ResponsiveBreakpoints.responsive(context, tablet: 85.w, small: 75.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
                constraints: BoxConstraints(maxWidth: 600, maxHeight: 85.h),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildFormContent()),
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
                  l10n.editOrder,
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
                    l10n.updateOrderInformation,
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
                          widget.order.id,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.order.status).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(widget.order.status),
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                    ],
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
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomerInfoSection(),
                SizedBox(height: context.cardPadding),
                _buildOrderDetailsSection(),
                SizedBox(height: context.cardPadding),
                _buildFinancialInfoSection(),
                SizedBox(height: context.cardPadding),
                _buildDeliveryInfoSection(),
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
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    final l10n = AppLocalizations.of(context)!;

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
              Icon(Icons.person_outline, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.customerInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          if (_isLoadingCustomerDetails)
            const Center(child: CircularProgressIndicator())
          else if (_selectedCustomer != null) ...[
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      _selectedCustomer!.initials,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.blue[700]),
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
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius('small')),
                            ),
                            child: Text(
                              _selectedCustomer!.id,
                              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
                            ),
                          ),
                          SizedBox(width: context.smallPadding),
                          Expanded(
                            child: Text(
                              _selectedCustomer!.name,
                              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (!context.isTablet) ...[
                        SizedBox(height: context.smallPadding),
                        Text(
                          '${_selectedCustomer!.phone} • ${_selectedCustomer!.email}',
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Colors.green, size: context.iconSize('small')),
                  SizedBox(width: context.smallPadding),
                  Text(
                    '${l10n.customerSince}: ${_formatDate(_selectedCustomer!.createdAt)}',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

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
              Icon(Icons.shopping_bag_outlined, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.orderDescription,
            hint: context.shouldShowCompactLayout ? l10n.enterDescription : l10n.describeOrderDetails,
            controller: _descriptionController,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
            validator: (value) {
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.orderStatus,
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: _getStatusColor(widget.order.status)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: _getStatusColor(widget.order.status), size: 16),
                SizedBox(width: context.smallPadding / 2),
                Text(
                  '${l10n.currentStatus}: ${_getStatusText(widget.order.status)}',
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(widget.order.status),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding,
            runSpacing: context.smallPadding / 2,
            children: _getValidStatusOptions()
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
                    _getStatusText(status),
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
          if (_getValidNextStatuses(widget.order.status).isNotEmpty) ...[
            SizedBox(height: context.smallPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: context.smallPadding / 2),
                  Expanded(
                    child: Text(
                      '${l10n.validNextStatuses}: ${_getValidNextStatuses(widget.order.status).map((s) => _getStatusText(s)).join(', ')}',
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.blue[700]),
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

  Widget _buildFinancialInfoSection() {
    final l10n = AppLocalizations.of(context)!;

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
              Icon(Icons.account_balance_wallet_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.financialInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.totalAmountPKR,
            hint: l10n.totalOrderAmount,
            controller: TextEditingController(text: 'PKR ${widget.order.totalAmount.toStringAsFixed(2)}'),
            prefixIcon: Icons.attach_money_rounded,
            enabled: false,
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: '${l10n.advancePaymentPKR} *',
            hint: l10n.enterAdvancePaymentAmount,
            controller: _advancePaymentController,
            prefixIcon: Icons.payment_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return l10n.pleaseEnterAdvancePayment;
              }
              if (double.tryParse(value!) == null) {
                return l10n.pleaseEnterValidAmount;
              }
              final advance = double.parse(value);
              if (advance < 0) {
                return l10n.advancePaymentCannotBeNegative;
              }
              if (advance > widget.order.totalAmount) {
                return l10n.advancePaymentCannotExceedTotal;
              }
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.remainingAmountPKR,
            hint: l10n.remainingAmountToBePaid,
            controller: _remainingAmountController,
            prefixIcon: Icons.account_balance_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.deliveryInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.orderDate,
            hint: l10n.dateWhenOrderWasPlaced,
            controller: TextEditingController(
              text:
              '${widget.order.dateOrdered.day.toString().padLeft(2, '0')}/${widget.order.dateOrdered.month.toString().padLeft(2, '0')}/${widget.order.dateOrdered.year}',
            ),
            prefixIcon: Icons.calendar_today_outlined,
            enabled: false,
          ),
          SizedBox(height: context.cardPadding),
          InkWell(
            onTap: () async {
              await context.showSyncfusionDateTimePicker(
                initialDate: _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
                initialTime: TimeOfDay.now(),
                title: l10n.selectExpectedDeliveryDate,
                minDate: DateTime.now(),
                maxDate: DateTime.now().add(const Duration(days: 365)),
                showTimeInline: false,
                onDateTimeSelected: (date, time) {
                  _handleDeliveryDateChange(date);
                },
              );
            },
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.purple, size: context.iconSize('medium')),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Text(
                      _selectedDeliveryDate != null
                          ? '${l10n.expectedDelivery}: ${_selectedDeliveryDate!.day.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.month.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.year}'
                          : l10n.selectExpectedDeliveryDate,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        color: _selectedDeliveryDate != null ? AppTheme.charcoalGray : Colors.grey[500],
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<OrderProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateOrder,
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
          text: l10n.cancel,
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
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: AppTheme.pureWhite,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 1,
          child: Consumer<OrderProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.update,
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return Colors.orange;
      case OrderStatus.CONFIRMED:
        return Colors.blue;
      case OrderStatus.READY:
        return Colors.green;
      case OrderStatus.DELIVERED:
        return Colors.green;
      case OrderStatus.RETURNED:
        return Colors.teal;
      case OrderStatus.CANCELLED:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case OrderStatus.PENDING:
        return l10n.pending;
      case OrderStatus.CONFIRMED:
        return l10n.confirmed;
      case OrderStatus.READY:
        return l10n.ready;
      case OrderStatus.DELIVERED:
        return l10n.delivered;
      case OrderStatus.RETURNED:
        return 'Returned';
      case OrderStatus.CANCELLED:
        return l10n.cancelled;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return Icons.pending_rounded;
      case OrderStatus.CONFIRMED:
        return Icons.check_circle_outline;
      case OrderStatus.READY:
        return Icons.done_all_rounded;
      case OrderStatus.DELIVERED:
        return Icons.local_shipping_rounded;
      case OrderStatus.RETURNED:
        return Icons.assignment_return_rounded;
      case OrderStatus.CANCELLED:
        return Icons.cancel_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
