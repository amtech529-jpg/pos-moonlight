import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/models/payment/payment_model.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/models/order/order_model.dart';

import '../../../src/providers/payment_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/providers/order_provider.dart';

import '../../../src/theme/app_theme.dart';
import '../globals/image_upload.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../../../l10n/app_localizations.dart';

class AddPaymentDialog extends StatefulWidget {
  final String? preSelectedOrderId;
  final String? preSelectedSaleId;
  final String? preSelectedVendorId;
  final String? preSelectedLaborId;

  const AddPaymentDialog({
    super.key, 
    this.preSelectedOrderId,
    this.preSelectedSaleId,
    this.preSelectedVendorId,
    this.preSelectedLaborId,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _deductionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();

  // Selected Entities
  PaymentLabor? _selectedLabor;
  String? _selectedVendorId;
  String? _selectedOrderId;
  String? _selectedSaleId;

  String? _selectedPaymentMethod;
  String? _selectedPaymentMonth;
  String? _selectedPayerType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isFinalPayment = false;
  String? _receiptImagePath;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    _selectedPaymentMonth = '${months[now.month - 1]} ${now.year}';

    if (widget.preSelectedOrderId != null) {
      _selectedPayerType = 'CUSTOMER';
      _selectedOrderId = widget.preSelectedOrderId;
    } else if (widget.preSelectedSaleId != null) {
      _selectedPayerType = 'CUSTOMER';
      _selectedSaleId = widget.preSelectedSaleId;
    } else if (widget.preSelectedVendorId != null) {
      _selectedPayerType = 'VENDOR';
      _selectedVendorId = widget.preSelectedVendorId;
    } else {
      _selectedPayerType = 'LABOR';
    }

    // Load ALL required data for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final context = this.context;
    // Load Labors
    await Provider.of<PaymentProvider>(context, listen: false).loadLaborers();
    // Load Vendors
    await Provider.of<VendorProvider>(context, listen: false).loadVendors();
    // Load Sales (for Invoice selection)
    await Provider.of<SalesProvider>(context, listen: false).loadSales();
    // Load Orders
    await Provider.of<OrderProvider>(context, listen: false).loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _bonusController.dispose();
    _deductionController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLabor == null &&
          _selectedVendorId == null &&
          _selectedOrderId == null &&
          _selectedSaleId == null) {
        _showErrorSnackbar(l10n.pleaseSelectAtLeastOneEntity);
        return;
      }

      if (_selectedPaymentMethod == null) {
        _showErrorSnackbar(l10n.pleaseSelectPaymentMethod);
        return;
      }

      if (_selectedPaymentMonth == null) {
        _showErrorSnackbar(l10n.pleaseSelectPaymentMonth);
        return;
      }

      final amount = double.parse(_amountController.text.trim());
      final bonus = double.tryParse(_bonusController.text.trim()) ?? 0.0;
      final deduction = double.tryParse(_deductionController.text.trim()) ?? 0.0;
      final netAmount = amount + bonus - deduction;

      // TODO: Fix remaining amount validation when backend properly tracks remaining_monthly_salary
      // For now, skip this validation to allow payments
      /*
      if (_selectedLabor != null &&
          netAmount > _selectedLabor!.remainingAmount &&
          !_isFinalPayment) {
        _showErrorSnackbar(l10n.netAmountCannotExceedRemaining(
            _selectedLabor!.remainingAmount.toStringAsFixed(0)));
        return;
      }
      */

      String payerType;
      String? payerId;

      if (_selectedLabor != null) {
        payerType = 'LABOR';
        payerId = _selectedLabor!.id;
      } else if (_selectedVendorId != null) {
        payerType = 'VENDOR';
        payerId = _selectedVendorId;
      } else if (_selectedOrderId != null) {
        payerType = 'CUSTOMER';
        payerId = _selectedOrderId;
      } else if (_selectedSaleId != null) {
        payerType = 'CUSTOMER';
        payerId = _selectedSaleId;
      } else {
        payerType = 'OTHER';
        payerId = null;
      }

      final paymentProvider =
      Provider.of<PaymentProvider>(context, listen: false);

      final success = await paymentProvider.addPayment(
        laborId: _selectedLabor?.id,
        vendorId: _selectedVendorId,
        orderId: _selectedOrderId,
        saleId: _selectedSaleId,
        amountPaid: amount,
        bonus: bonus,
        deduction: deduction,
        paymentMonth: _convertDisplayMonthToApi(_selectedPaymentMonth!),
        isFinalPayment: _isFinalPayment,
        paymentMethod: _selectedPaymentMethod!,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: _selectedTime,
        receiptImagePath: _receiptImagePath,
        payerType: payerType,
        payerId: payerId,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackbar(
            paymentProvider.errorMessage ?? l10n.serverErrorTryAgainLater,
          );
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
            Icon(Icons.check_circle_rounded,
                color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.paymentAddedSuccessfully,
              style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded,
                color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context)
                  .colorScheme
                  .copyWith(primary: AppTheme.primaryMaroon)),
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context)
                  .colorScheme
                  .copyWith(primary: AppTheme.primaryMaroon)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  List<String> _generatePaymentMonths() {
    final List<String> months = [];
    final now = DateTime.now();
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year - 1}');
    }

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year}');
    }

    for (int i = 0; i < 12; i++) {
      months.add('${monthNames[i]} ${now.year + 1}');
    }

    return months;
  }

  String _convertDisplayMonthToApi(String displayMonth) {
    try {
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final parts = displayMonth.split(' ');
      if (parts.length == 2) {
        final monthName = parts[0];
        final year = int.parse(parts[1]);
        final monthIndex = monthNames.indexOf(monthName);
        if (monthIndex != -1) {
          final month = monthIndex + 1;
          return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
        }
      }
    } catch (e) {
      debugPrint('Error converting display month format: $e');
    }
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
  }

  double get netAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final deduction = double.tryParse(_deductionController.text) ?? 0;
    return amount + bonus - deduction;
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
                  maxWidth: ResponsiveBreakpoints.responsive(context,
                      tablet: 95.w,
                      small: 90.w,
                      medium: 80.w,
                      large: 70.w,
                      ultrawide: 60.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context,
                      tablet: 90.h,
                      small: 95.h,
                      medium: 85.h,
                      large: 80.h,
                      ultrawide: 75.h),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius:
                  BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: context.shadowBlur('heavy'),
                        offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: _buildScrollableContent(),
                        small: _buildScrollableContent(),
                        medium: _buildDesktopLayout(),
                        large: _buildDesktopLayout(),
                        ultrawide: _buildDesktopLayout(),
                      ),
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
        gradient: const LinearGradient(
            colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
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
                borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.payments_rounded,
                color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout
                      ? l10n.addPayment
                      : l10n.addLaborPayment, // Could rename this key to generic "Add Payment"
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
                    l10n.recordNewPaymentWithReceipt,
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
                child: Icon(Icons.close_rounded,
                    color: AppTheme.pureWhite,
                    size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
              SizedBox(height: context.cardPadding),
              _buildPaymentDetailsCard(),
              SizedBox(height: context.cardPadding),
              _buildReceiptCard(),
              SizedBox(height: context.mainPadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildBasicInfoCard(),
              SizedBox(height: context.cardPadding),
              _buildAmountCard(),
              SizedBox(height: context.cardPadding),
              _buildPaymentDetailsCard(),
              SizedBox(height: context.cardPadding),
              _buildReceiptCard(),
              SizedBox(height: context.mainPadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: context.shadowBlur('light'),
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  color: AppTheme.primaryMaroon,
                  size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.basicInformation,
                style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildPayerSelection(), // Renamed and logic updated
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(child: _buildPaymentMonthSelection()),
              SizedBox(width: context.cardPadding),
              Expanded(child: _buildPaymentMethodSelection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: context.shadowBlur('light'),
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  color: AppTheme.primaryMaroon,
                  size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentAmount,
                style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildAmountField(),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(child: _buildBonusField()),
              SizedBox(width: context.cardPadding),
              Expanded(child: _buildDeductionField()),
            ],
          ),
          if (_amountController.text.isNotEmpty ||
              _bonusController.text.isNotEmpty ||
              _deductionController.text.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            _buildNetAmountPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: context.shadowBlur('light'),
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: AppTheme.primaryMaroon,
                  size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentDetails,
                style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildDescriptionField(),
          SizedBox(height: context.cardPadding),
          _buildDateTimeFields(),
          SizedBox(height: context.cardPadding),
          _buildFinalPaymentToggle(),
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: context.shadowBlur('light'),
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_rounded,
                  color: AppTheme.primaryMaroon,
                  size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.receiptImageOptional,
                      style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray),
                    ),
                    Text(
                      l10n.uploadReceiptForBetterRecordKeeping,
                      style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildResponsiveImageUpload(),
        ],
      ),
    );
  }

  // Updated Payer Selection Widget with Real Data
  Widget _buildPayerSelection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumDropdownField<String>(
          label: l10n.entityType,
          hint: l10n.selectEntityType,
          value: _selectedPayerType,
          prefixIcon: Icons.category,
          items: ['LABOR', 'VENDOR', 'CUSTOMER', 'OTHER'].map((type) {
            return DropdownItem<String>(value: type, label: type);
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedPayerType = value;
              // Clear previous selections
              _selectedLabor = null;
              _selectedVendorId = null;
              _selectedOrderId = null;
              _selectedSaleId = null;
            });
          },
          validator: (value) =>
          value == null ? l10n.pleaseSelectEntityType : null,
        ),
        if (_selectedPayerType != null) ...[
          SizedBox(height: context.smallPadding),

          // LABOR SELECTION
          if (_selectedPayerType == 'LABOR')
            Consumer<PaymentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildLoadingIndicator(l10n.loadingLabors);
                }
                if (provider.laborers.isEmpty) {
                  return _buildEmptyState(l10n.noLaborsFound);
                }
                return PremiumDropdownField<PaymentLabor>(
                  label: l10n.selectLabor,
                  hint: l10n.chooseLaborForPayment,
                  value: _selectedLabor,
                  prefixIcon: Icons.person_outline,
                  items: provider.laborers
                      .map((labor) => DropdownItem<PaymentLabor>(
                    value: labor,
                    label:
                    '${labor.name} - ${labor.role} (${l10n.remaining}: PKR ${labor.remainingAmount.toStringAsFixed(0)})',
                  ))
                      .toList(),
                  onChanged: (labor) {
                    setState(() {
                      _selectedLabor = labor;
                    });
                  },
                  validator: (value) => _selectedPayerType == 'LABOR' && value == null
                      ? l10n.pleaseSelectLabor
                      : null,
                );
              },
            ),

          // VENDOR SELECTION (Updated)
          if (_selectedPayerType == 'VENDOR')
            Consumer<VendorProvider>(
              builder: (context, vendorProvider, child) {
                if (vendorProvider.isLoading) {
                  return _buildLoadingIndicator("Loading Vendors...");
                }
                if (vendorProvider.vendors.isEmpty) {
                  return _buildEmptyState("No Vendors Found");
                }
                return PremiumDropdownField<String>(
                  label: l10n.selectVendor,
                  hint: l10n.selectVendor,
                  value: _selectedVendorId,
                  prefixIcon: Icons.business,
                  items: vendorProvider.vendors
                      .map((vendor) => DropdownItem<String>(
                    value: vendor.id,
                    label: vendor.name,
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVendorId = val;
                    });
                  },
                  validator: (value) => _selectedPayerType == 'VENDOR' && value == null
                      ? l10n.pleaseSelectVendor
                      : null,
                );
              },
            ),

          // CUSTOMER / ORDER / SALE SELECTION (Updated)
          if (_selectedPayerType == 'CUSTOMER')
            Column(
              children: [
                PremiumDropdownField<String>(
                  label: l10n.customerType,
                  hint: l10n.selectCustomerType,
                  value: _selectedOrderId != null
                      ? 'ORDER'
                      : _selectedSaleId != null
                      ? 'SALE'
                      : null,
                  prefixIcon: Icons.shopping_cart,
                  items: ['ORDER', 'SALE'].map((type) {
                    return DropdownItem<String>(value: type, label: type);
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      if (value == 'ORDER') {
                        _selectedOrderId = null;
                        _selectedSaleId = null;
                      } else if (value == 'SALE') {
                        _selectedOrderId = null;
                        _selectedSaleId = null;
                      }
                    });
                  },
                ),
                SizedBox(height: context.smallPadding),

                // ORDER DROPDOWN
                if (_selectedOrderId == null && _selectedSaleId == null) ...[
                  // Wait for user to pick type
                ] else if (_selectedSaleId == null) ...[
                  Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                      if (orderProvider.isLoading) {
                        return _buildLoadingIndicator("Loading Orders...");
                      }
                      if (orderProvider.orders.isEmpty) {
                        return _buildEmptyState("No Orders Found");
                      }
                      return PremiumDropdownField<String>(
                        label: l10n.selectOrder,
                        hint: "Select an Order",
                        value: _selectedOrderId,
                        prefixIcon: Icons.receipt_long,
                        items: orderProvider.orders.map((order) {
                          return DropdownItem<String>(
                            value: order.id,
                            label: "${order.orderNumber} - ${order.customerName}",
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOrderId = val;
                            _selectedSaleId = null; // Ensure mutual exclusivity
                          });
                        },
                      );
                    },
                  ),
                ] else ...[
                  // SALE DROPDOWN
                  Consumer<SalesProvider>(
                      builder: (context, salesProvider, child) {
                        if (salesProvider.isLoading) {
                          return _buildLoadingIndicator("Loading Sales...");
                        }
                        if (salesProvider.sales.isEmpty) {
                          return _buildEmptyState("No Sales Found");
                        }
                        return PremiumDropdownField<String>(
                          label: l10n.selectSale,
                          hint: "Select a Sale Invoice",
                          value: _selectedSaleId,
                          prefixIcon: Icons.receipt,
                          items: salesProvider.sales.map((sale) {
                            return DropdownItem<String>(
                              value: sale.id,
                              label: "${sale.invoiceNumber} - ${sale.customerName} (PKR ${sale.grandTotal.toStringAsFixed(0)})",
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSaleId = val;
                              _selectedOrderId = null; // Ensure mutual exclusivity
                            });
                          },
                        );
                      }
                  )
                ],
              ],
            ),
        ],
      ],
    );
  }

  // Helper widgets for loading and empty states
  Widget _buildLoadingIndicator(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding),
      child: Row(
        children: [
          SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primaryMaroon)),
          SizedBox(width: context.smallPadding),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: context.smallPadding, horizontal: context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: context.iconSize('small'), color: Colors.orange[700]),
          SizedBox(width: context.smallPadding),
          Text(text, style: TextStyle(color: Colors.orange[700])),
        ],
      ),
    );
  }

  Widget _buildPaymentMonthSelection() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumDropdownField<String>(
      label: l10n.paymentMonth,
      hint: l10n.selectPaymentMonth,
      value: _selectedPaymentMonth,
      prefixIcon: Icons.calendar_month,
      items: _generatePaymentMonths()
          .map((month) => DropdownItem<String>(value: month, label: month))
          .toList(),
      onChanged: (month) {
        setState(() {
          _selectedPaymentMonth = month;
        });
      },
      validator: (value) =>
      value == null ? l10n.pleaseSelectPaymentMonth : null,
    );
  }

  Widget _buildPaymentMethodSelection() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        return PremiumDropdownField<String>(
          label: l10n.paymentMethod,
          hint: l10n.selectPaymentMethod,
          value: _selectedPaymentMethod,
          prefixIcon: Icons.payment,
          items: PaymentProvider.staticPaymentMethods
              .map((method) =>
              DropdownItem<String>(value: method, label: method))
              .toList(),
          onChanged: (method) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
          validator: (value) =>
          value == null ? l10n.pleaseSelectPaymentMethod : null,
        );
      },
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank transfer':
        return Icons.account_balance_rounded;
      case 'jazzcash':
      case 'easypaisa':
      case 'sadapay':
        return Icons.phone_android_rounded;
      case 'check':
        return Icons.receipt_long_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'bank transfer':
        return Colors.blue;
      case 'jazzcash':
      case 'easypaisa':
        return Colors.purple;
      case 'sadapay':
        return Colors.orange;
      case 'check':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.paymentAmountPkr,
      hint: context.shouldShowCompactLayout
          ? l10n.enterAmount
          : l10n.enterPaymentAmountPkr,
      controller: _amountController,
      prefixIcon: Icons.attach_money_rounded,
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {}),
      validator: (value) {
        if (value?.isEmpty ?? true) return l10n.pleaseEnterPaymentAmount;
        final amount = double.tryParse(value!);
        if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
        return null;
      },
    );
  }

  Widget _buildBonusField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.bonusPkr,
      hint: l10n.optionalBonus,
      controller: _bonusController,
      prefixIcon: Icons.star_outline,
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {}),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final bonus = double.tryParse(value);
          if (bonus == null || bonus < 0)
            return l10n.pleaseEnterValidBonusAmount;
        }
        return null;
      },
    );
  }

  Widget _buildDeductionField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.deductionPkr,
      hint: l10n.optionalDeduction,
      controller: _deductionController,
      prefixIcon: Icons.remove_circle_outline,
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {}),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final deduction = double.tryParse(value);
          if (deduction == null || deduction < 0)
            return l10n.pleaseEnterValidDeductionAmount;
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: l10n.description,
      hint: context.shouldShowCompactLayout
          ? l10n.enterNotes
          : l10n.enterPaymentDescriptionOrNotes,
      controller: _descriptionController,
      prefixIcon: Icons.description_outlined,
      maxLines: ResponsiveBreakpoints.responsive(
          context, tablet: 2, small: 3, medium: 3, large: 4, ultrawide: 4),
      validator: (value) {
        if (value?.isEmpty ?? true) return l10n.pleaseEnterDescription;
        if (value!.length < 5)
          return l10n.descriptionMustBeAtLeast5Characters;
        return null;
      },
    );
  }

  Widget _buildDateTimeFields() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: PremiumTextField(
              label: l10n.date,
              hint: l10n.selectDate,
              controller: TextEditingController(
                  text:
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              prefixIcon: Icons.calendar_today,
              enabled: false,
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: PremiumTextField(
              label: l10n.time,
              hint: l10n.selectTime,
              controller: TextEditingController(
                text:
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              prefixIcon: Icons.access_time,
              enabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalPaymentToggle() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: _isFinalPayment
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
            color: _isFinalPayment
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _isFinalPayment
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: _isFinalPayment ? Colors.green : Colors.grey,
            size: context.iconSize('medium'),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.finalPaymentForMonth,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: _isFinalPayment
                        ? Colors.green
                        : AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  _isFinalPayment
                      ? l10n.thisCompletesPaymentForSelectedMonth
                      : l10n.markThisAsFinalPaymentForMonth,
                  style: TextStyle(
                      fontSize: context.captionFontSize,
                      color: _isFinalPayment
                          ? Colors.green[700]
                          : Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isFinalPayment,
            onChanged: (value) {
              setState(() {
                _isFinalPayment = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNetAmountPreview() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: netAmount >= 0
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
            color: netAmount >= 0
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded,
              color: netAmount >= 0 ? Colors.green : Colors.red,
              size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.netPaymentAmount,
                  style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.charcoalGray),
                ),
                Text(
                  'PKR ${netAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: netAmount >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                if (_selectedLabor != null) ...[
                  Text(
                    l10n.remainingAfterPayment(
                        (_selectedLabor!.remainingAmount - netAmount)
                            .toStringAsFixed(0)),
                    style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveImageUpload() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: ResponsiveBreakpoints.responsive(context,
          tablet: 35.h, small: 40.h, medium: 45.h, large: 50.h, ultrawide: 55.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ResponsiveImageUploadWidget(
        initialImagePath: _receiptImagePath,
        onImageChanged: (imagePath) {
          setState(() {
            _receiptImagePath = imagePath;
          });
        },
        label: l10n.paymentReceiptOptional,
        context: context,
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    if (context.shouldShowCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<PaymentProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.addPayment,
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
            text: l10n.cancel,
            onPressed: _handleCancel,
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
            child: Consumer<PaymentProvider>(
              builder: (context, provider, child) {
                return PremiumButton(
                  text: l10n.addPayment,
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
}