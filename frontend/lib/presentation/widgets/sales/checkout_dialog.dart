import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import 'order_success_dialog.dart'; // ✅ Import Success Dialog

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountPaidController = TextEditingController();
  final _overallDiscountController = TextEditingController();
  final _gstController = TextEditingController();
  final _taxController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();

  final _cashAmountController = TextEditingController();
  final _cardAmountController = TextEditingController();
  final _bankTransferAmountController = TextEditingController();

  String _selectedPaymentMethod = 'Cash';
  bool _isSplitPayment = false;
  bool _showAdvancedOptions = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      _amountPaidController.text = provider.cartGrandTotal.toStringAsFixed(0);
      _overallDiscountController.text =
          provider.overallDiscount.toStringAsFixed(0);
      _gstController.text = provider.gstPercentage.toStringAsFixed(0);
      _taxController.text = provider.taxPercentage.toStringAsFixed(0);
      _notesController.text = '';
      _selectedPaymentMethod = 'Cash';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountPaidController.dispose();
    _overallDiscountController.dispose();
    _gstController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    _cashAmountController.dispose();
    _cardAmountController.dispose();
    _bankTransferAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<SalesProvider>(context, listen: false);

    // Validate cart is not empty
    if (provider.currentCart.isEmpty) {
      _showErrorDialog('Empty Cart', 'Please add items before checkout.');
      return;
    }

    // ✅ CAPTURE VALUES BEFORE CLEARING CART
    final double capturedTotalAmount = provider.cartGrandTotal;
    final double amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    final String paymentMethod = _translatePaymentMethod(_selectedPaymentMethod);

    if (amountPaid < 0) {
      _showErrorDialog('Invalid Amount', 'Amount paid cannot be negative.');
      return;
    }

    // Prepare split payment details if applicable
    Map<String, dynamic>? splitPaymentDetails;
    if (_isSplitPayment) {
      final cashAmount = double.tryParse(_cashAmountController.text) ?? 0.0;
      final cardAmount = double.tryParse(_cardAmountController.text) ?? 0.0;
      final bankAmount = double.tryParse(_bankTransferAmountController.text) ?? 0.0;

      splitPaymentDetails = {
        'cash': cashAmount,
        'card': cardAmount,
        'bank_transfer': bankAmount,
      };
    }

    // Prepare notes (null if empty)
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      // Call provider method to create sale from cart
      final bool success = await provider.createSaleFromCart(
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        notes: notes,
      );

      if (!mounted) return;

      if (success) {
        // ✅ Close Checkout Dialog FIRST
        Navigator.of(context).pop();

        // ✅ GET THE NEW SALE (It is inserted at index 0 in the provider)
        final newSale = provider.sales.first;

        // ✅ Show Success Dialog with Required Params
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OrderSuccessDialog(
            saleId: newSale.id,                   // ✅ Fix: Pass Sale ID
            invoiceNumber: newSale.invoiceNumber, // ✅ Fix: Pass Invoice Number
            totalPrice: capturedTotalAmount,
            advanceAmount: amountPaid,
            deliveryDate: DateTime.now(),
          ),
        );
      } else {
        // Show error from provider
        _showErrorDialog(
          'Sale Failed',
          provider.errorMessage ?? 'Failed to complete sale. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _translatePaymentMethod(String displayMethod) {
    switch (displayMethod) {
      case 'Cash':
        return 'CASH';
      case 'Card':
        return 'CARD';
      case 'Bank Transfer':
        return 'BANK_TRANSFER';
      case 'Credit':
        return 'CREDIT';
      case 'Split':
        return 'SPLIT';
      default:
        return 'CASH';
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _updateAmountFromSplit() {
    if (_isSplitPayment) {
      final cashAmount = double.tryParse(_cashAmountController.text) ?? 0.0;
      final cardAmount = double.tryParse(_cardAmountController.text) ?? 0.0;
      final bankAmount = double.tryParse(_bankTransferAmountController.text) ?? 0.0;
      final totalAmount = cashAmount + cardAmount + bankAmount;

      setState(() {
        _amountPaidController.text = totalAmount.toStringAsFixed(0);
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
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 95.w,
                    small: 90.w,
                    medium: 85.w,
                    large: 75.w,
                    ultrawide: 65.w,
                  ),
                  maxHeight: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 95.h,
                    small: 90.h,
                    medium: 85.h,
                    large: 80.h,
                    ultrawide: 75.h,
                  ),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('large'),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: Offset(0, context.cardPadding),
                    ),
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
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
              Icons.payment_rounded,
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
                  context.shouldShowCompactLayout
                      ? l10n.checkout
                      : l10n.checkoutAndPayment,
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
                    l10n.completeTheSaleTransaction,
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
          if (context.shouldShowFullLayout)
            Consumer<SalesProvider>(
              builder: (context, provider, child) {
                return Container(
                  padding: EdgeInsets.all(context.smallPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${provider.cartTotalItems} ${l10n.items}',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: AppTheme.pureWhite.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        'PKR ${provider.cartGrandTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(width: context.smallPadding),
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
              _buildOrderSummaryCard(),
              SizedBox(height: context.cardPadding),
              _buildPaymentMethodCard(),
              SizedBox(height: context.cardPadding),
              if (_showAdvancedOptions) ...[
                _buildAdvancedOptionsCard(),
                SizedBox(height: context.cardPadding),
              ],
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildOrderSummaryCard(),
                    if (_showAdvancedOptions) ...[
                      SizedBox(height: context.cardPadding),
                      _buildAdvancedOptionsCard(),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildPaymentMethodCard(),
                    SizedBox(height: context.cardPadding),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SalesProvider>(
      builder: (context, provider, child) {
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
                  Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.blue,
                    size: context.iconSize('medium'),
                  ),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.orderSummary,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.cardPadding),
              if (provider.selectedCustomer != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.grey[600],
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.selectedCustomer!.name,
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                          Text(
                            provider.selectedCustomer!.phone,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding),
                Divider(color: Colors.grey.shade300),
                SizedBox(height: context.smallPadding),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.items} (${provider.cartTotalItems})',
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  Text(
                    'PKR ${provider.cartSubtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                ],
              ),
              if (provider.overallDiscount > 0) ...[
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.discount,
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      '- PKR ${provider.overallDiscount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
              if (provider.gstPercentage > 0) ...[
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST (${provider.gstPercentage}%)',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      'PKR ${provider.cartGstAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ],
                ),
              ],
              if (provider.taxPercentage > 0) ...[
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.tax} (${provider.taxPercentage}%)',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      'PKR ${provider.cartTaxAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: context.smallPadding),
              Divider(color: Colors.grey.shade400, thickness: 1.5),
              SizedBox(height: context.smallPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.grandTotal,
                    style: TextStyle(
                      fontSize: context.headerFontSize * 0.8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  Text(
                    'PKR ${provider.cartGrandTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.headerFontSize * 0.8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard() {
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
              Icon(
                Icons.payment_rounded,
                color: Colors.green,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentMethod,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentMethod,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value ?? 'Cash';
                    _isSplitPayment = value == 'Split';
                  });
                },
                items: [
                  l10n.cash,
                  l10n.card,
                  l10n.bankTransfer,
                  l10n.credit,
                  l10n.split,
                ].map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.cardPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(method),
                            color: AppTheme.primaryMaroon,
                            size: context.iconSize('medium'),
                          ),
                          SizedBox(width: context.smallPadding),
                          Text(
                            method,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: AppTheme.charcoalGray,
                            ),
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
          if (_isSplitPayment) ...[
            Text(
              l10n.splitPaymentDetails,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoalGray,
              ),
            ),
            SizedBox(height: context.smallPadding),
            PremiumTextField(
              label: l10n.cashAmount,
              controller: _cashAmountController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.money_rounded,
              onChanged: (value) => _updateAmountFromSplit(),
            ),
            SizedBox(height: context.smallPadding),
            PremiumTextField(
              label: l10n.cardAmount,
              controller: _cardAmountController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.credit_card_rounded,
              onChanged: (value) => _updateAmountFromSplit(),
            ),
            SizedBox(height: context.smallPadding),
            PremiumTextField(
              label: l10n.bankTransferAmount,
              controller: _bankTransferAmountController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.account_balance_rounded,
              onChanged: (value) => _updateAmountFromSplit(),
            ),
            SizedBox(height: context.cardPadding),
          ],
          PremiumTextField(
            label: l10n.amountPaid,
            controller: _amountPaidController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money_rounded,
            enabled: !_isSplitPayment,
            validator: (value) {
              if (value?.isEmpty ?? true) return l10n.pleaseEnterAmountPaid;
              final amount = double.tryParse(value!);
              if (amount == null || amount < 0)
                return l10n.pleaseEnterValidAmount;
              return null;
            },
          ),
          Consumer<SalesProvider>(
            builder: (context, provider, child) {
              final amountPaid =
                  double.tryParse(_amountPaidController.text) ?? 0.0;
              final grandTotal = provider.cartGrandTotal;
              final difference = amountPaid - grandTotal;

              if (difference == 0) return const SizedBox.shrink();

              return Container(
                margin: EdgeInsets.only(top: context.smallPadding),
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  color: difference > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(
                    color: difference > 0
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      difference > 0 ? l10n.change : l10n.remaining,
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: difference > 0
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    Text(
                      'PKR ${difference.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: difference > 0
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: context.cardPadding),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  setState(() => _showAdvancedOptions = !_showAdvancedOptions),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showAdvancedOptions
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.primaryMaroon,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      _showAdvancedOptions
                          ? l10n.hideAdvancedOptions
                          : l10n.showAdvancedOptions,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryMaroon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: Colors.orange,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.advancedOptions,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.overallDiscountPkr,
            controller: _overallDiscountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.local_offer_rounded,
            onChanged: (value) {
              print('🔍 Overall discount field changed');
              print('🔍 Input value: $value');
              
              final discount = double.tryParse(value) ?? 0.0;
              print('🔍 Parsed discount: $discount');
              
              final provider = Provider.of<SalesProvider>(context, listen: false);
              print('🔍 Cart subtotal: ${provider.cartSubtotal}');
              
              // Ensure discount doesn't exceed cart subtotal
              final maxDiscount = provider.cartSubtotal;
              print('🔍 Maximum allowed discount: $maxDiscount');
              
              if (discount >= 0 && discount <= maxDiscount) {
                provider.setOverallDiscount(discount);
                print('✅ Set overall discount to: $discount');
              } else if (discount > maxDiscount) {
                // Set to maximum allowed discount
                provider.setOverallDiscount(maxDiscount);
                _overallDiscountController.text = maxDiscount.toStringAsFixed(0);
                print('⚠️ Discount exceeded max, set to: $maxDiscount');
              } else {
                // Reset to 0 for negative values
                provider.setOverallDiscount(0.0);
                _overallDiscountController.text = '0';
                print('❌ Negative discount, reset to 0');
              }
            },
          ),
          SizedBox(height: context.smallPadding),
          PremiumTextField(
            label: l10n.gstPercentage,
            controller: _gstController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.receipt_rounded,
            onChanged: (value) {},
          ),
          SizedBox(height: context.smallPadding),
          PremiumTextField(
            label: l10n.additionalTax,
            controller: _taxController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.account_balance_rounded,
            onChanged: (value) {},
          ),
          SizedBox(height: context.smallPadding),
          PremiumTextField(
            label: l10n.notesOptional,
            controller: _notesController,
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            hint: l10n.anySpecialInstructionsOrRemarks,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SalesProvider>(
      builder: (context, provider, child) {
        if (context.shouldShowCompactLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumButton(
                text: provider.isLoading ? l10n.processing : l10n.completeSale,
                onPressed: provider.isLoading ? null : _handleCheckout,
                isLoading: provider.isLoading,
                height: context.buttonHeight,
                icon: Icons.check_circle_rounded,
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
                flex: 2,
                child: PremiumButton(
                  text: provider.isLoading
                      ? l10n.processing
                      : l10n.completeSale,
                  onPressed: provider.isLoading ? null : _handleCheckout,
                  isLoading: provider.isLoading,
                  height: context.buttonHeight / 1.5,
                  icon: Icons.check_circle_rounded,
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
}