import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';
import '../globals/custom_date_picker.dart';
import 'product_selection_dialog.dart';

class AddOrderDialog extends StatefulWidget {
  const AddOrderDialog({super.key});

  @override
  State<AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends State<AddOrderDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _customerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advancePaymentController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _partnerRateController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customizationController = TextEditingController();
  final _remainingAmountController = TextEditingController();
  
  // Focus Nodes
  final _quantityFocusNode = FocusNode();
  final _unitPriceFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  final _partnerRateFocusNode = FocusNode();
  final _eventNameFocusNode = FocusNode();
  final _eventLocationFocusNode = FocusNode();

  // Form state
  Customer? _selectedCustomer;
  OrderStatus _selectedStatus = OrderStatus.PENDING;
  DateTime? _selectedDeliveryDate;
  DateTime? _selectedEventDate;
  DateTime? _selectedReturnDate;
  bool _rentedFromPartner = false;

  // Product selection state
  List<OrderItemModel> _orderItems = [];
  double _totalAmount = 0.0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form progress tracking
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Options
  final List<OrderStatus> _orderStatuses = [
    OrderStatus.PENDING,
    OrderStatus.CONFIRMED,
    OrderStatus.READY,
    OrderStatus.DELIVERED,
    OrderStatus.CANCELLED,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );

    _scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut
    ));

    _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack
    ));

    _advancePaymentController.addListener(_updateRemainingAmount);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _customerController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _advancePaymentController.dispose();
    _expectedDeliveryDateController.dispose();
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _eventDateController.dispose();
    _returnDateController.dispose();
    _partnerRateController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    _customizationController.dispose();
    _remainingAmountController.dispose();
    _quantityFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    _notesFocusNode.dispose();
    _partnerRateFocusNode.dispose();
    _eventNameFocusNode.dispose();
    _eventLocationFocusNode.dispose();
    
    // Clear filters and search from provider when closing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        provider.clearFilters(); // Reset search/filters when closing order dialog
      }
    });

    super.dispose();
  }

  void _handleCustomerChange(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerController.text = customer.name;
      }
    });
  }

  void _handleStatusChange(OrderStatus status) {
    setState(() {
      _selectedStatus = status;
    });
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

  void _updateRemainingAmount() {
    final total = double.tryParse(_totalAmountController.text.replaceAll('PKR ', '')) ?? _totalAmount;
    final advance = double.tryParse(_advancePaymentController.text.trim()) ?? 0.0;
    final remaining = total - advance;
    _remainingAmountController.text = 'PKR ${remaining.toStringAsFixed(2)}';
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedCustomer != null;
      case 1:
        return _orderItems.isNotEmpty && _totalAmountController.text.isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCustomer == null) {
        _showErrorSnackbar(l10n.pleaseSelectSale);
        return;
      }

      if (_orderItems.isEmpty) {
        _showErrorSnackbar(l10n.addProductsToStartSale);
        return;
      }

      final provider = Provider.of<OrderProvider>(context, listen: false);

      final success = await provider.createOrder(
        customer: _selectedCustomer!.id,
        items: _orderItems,
        description: _descriptionController.text.trim(),
        advancePayment: double.tryParse(_advancePaymentController.text.trim()) ?? 0.0,
        dateOrdered: DateTime.now(),
        expectedDeliveryDate: _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 14)),
        eventName: _eventNameController.text.trim(),
        eventLocation: _eventLocationController.text.trim(),
        eventDate: _selectedEventDate,
        returnDate: _selectedReturnDate,
        status: _selectedStatus.name.toUpperCase(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          await _animationController.reverse();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(_getUserFriendlyErrorMessage(provider.errorMessage ?? 'Error'));
        }
      }
    }
  }

  String _getUserFriendlyErrorMessage(String errorMessage) {
    final l10n = AppLocalizations.of(context)!;

    if (errorMessage.contains('Invalid customer')) {
      return l10n.pleaseSelectSale;
    } else if (errorMessage.contains('Date has wrong format')) {
      return '${l10n.dueDate} ${l10n.error}';
    } else if (errorMessage.contains('cannot be before order date')) {
      return '${l10n.dueDate} ${l10n.error}';
    } else if (errorMessage.contains('cannot be negative')) {
      return '${l10n.advancePayment} ${l10n.error}';
    } else if (errorMessage.contains('not active')) {
      return l10n.pleaseSelectSale;
    } else if (errorMessage.contains('not a valid choice')) {
      return '${l10n.status} ${l10n.error}';
    }
    return errorMessage;
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
              '${l10n.orders} ${l10n.success}!',
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

  void _handleCancel() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: context.shouldShowCompactLayout ? 95.w : context.dialogWidth,
                  constraints: BoxConstraints(
                    maxWidth: context.maxContentWidth,
                    maxHeight: context.shouldShowCompactLayout ? 95.h : 90.h,
                  ),
                  margin: context.pagePadding,
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius('large')),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: context.shadowBlur('heavy'),
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEnhancedHeader(),
                      if (context.shouldShowCompactLayout) _buildProgressIndicator(),
                      Flexible(child: _buildFormContent()),
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

  Widget _buildEnhancedHeader() {
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
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(
              Icons.shopping_cart_rounded,
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
                  context.shouldShowCompactLayout ? l10n.newOrder : '${l10n.add} ${l10n.orders}',
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
                    l10n.createOrder,
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

  Widget _buildProgressIndicator() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.cardPadding,
        vertical: context.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, l10n.info, Icons.info_outline),
          _buildStepConnector(0),
          _buildStepIndicator(1, l10n.products, Icons.shopping_bag_outlined),
          _buildStepConnector(1),
          _buildStepIndicator(2, l10n.view, Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? AppTheme.primaryMaroon
                  : AppTheme.lightGray.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryMaroon
                    : AppTheme.lightGray,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive
                  ? AppTheme.pureWhite
                  : AppTheme.lightGray,
              size: context.iconSize('medium'),
            ),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            label,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppTheme.primaryMaroon
                  : AppTheme.lightGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.symmetric(horizontal: context.smallPadding),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green
              : AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1CustomerDetails(),
                _buildStep2ProductSelection(),
                _buildStep3ReviewOrder(),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildStep1CustomerDetails() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('${l10n.customer} & ${l10n.orders}', Icons.person_outline),
          SizedBox(height: context.cardPadding),

          // Customer Selection Card
          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.selectCustomer, Icons.person_search_rounded),
                SizedBox(height: context.cardPadding),
                Consumer<CustomerProvider>(
                  builder: (context, customerProvider, child) {
                    return PremiumDropdownField<Customer>(
                      label: '${l10n.customer} *',
                      hint: l10n.selectCustomer,
                      items: customerProvider.customers
                          .map((customer) => DropdownItem<Customer>(
                          value: customer,
                          label: '${customer.orderDisplayName} (${customer.phone})'
                      ))
                          .toList(),
                      value: _selectedCustomer,
                      onChanged: _handleCustomerChange,
                      validator: (value) {
                        if (value == null) {
                          return l10n.pleaseSelectSale;
                        }
                        return null;
                      },
                      prefixIcon: Icons.person_search_rounded,
                    );
                  },
                ),

                if (_selectedCustomer != null) ...[
                  SizedBox(height: context.cardPadding),
                  _buildCustomerInfo(),
                ],
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          // Event Details Card
          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Event Details', Icons.event_note_rounded),
                SizedBox(height: context.cardPadding),
                Row(
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        label: 'Event Name',
                        hint: 'e.g. Wedding of X',
                        controller: _eventNameController,
                        prefixIcon: Icons.festival_rounded,
                        focusNode: _eventNameFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_eventLocationFocusNode),
                      ),
                    ),
                    SizedBox(width: context.cardPadding),
                    Expanded(
                      child: PremiumTextField(
                        label: 'Event Location',
                        hint: 'Venue / Hall Name',
                        controller: _eventLocationController,
                        prefixIcon: Icons.location_on_rounded,
                        focusNode: _eventLocationFocusNode,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.cardPadding),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedEventDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.primaryMaroon,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                  textTheme: const TextTheme(
                                    bodyLarge: TextStyle(color: Colors.black87),
                                    bodyMedium: TextStyle(color: Colors.black87),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              _selectedEventDate = date;
                              _eventDateController.text = '${date.day}/${date.month}/${date.year}';
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: PremiumTextField(
                            label: 'Event Date',
                            hint: 'Select Date',
                            controller: _eventDateController,
                            prefixIcon: Icons.calendar_today_rounded,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.cardPadding),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedReturnDate ?? (_selectedEventDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1))),
                            firstDate: _selectedEventDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.primaryMaroon,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                  textTheme: const TextTheme(
                                    bodyLarge: TextStyle(color: Colors.black87),
                                    bodyMedium: TextStyle(color: Colors.black87),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              _selectedReturnDate = date;
                              _returnDateController.text = '${date.day}/${date.month}/${date.year}';
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: PremiumTextField(
                            label: 'Return Date',
                            hint: 'Select Date',
                            controller: _returnDateController,
                            prefixIcon: Icons.event_available_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          // Order Details Card
          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.info, Icons.description_outlined),
                SizedBox(height: context.cardPadding),
                PremiumTextField(
                  label: l10n.notes,
                  hint: l10n.additionalReceiptNotes,
                  controller: _descriptionController,
                  prefixIcon: Icons.description_outlined,
                  focusNode: _notesFocusNode,
                  maxLines: context.shouldShowCompactLayout ? 3 : 4,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    return null;
                  },
                ),

                SizedBox(height: context.cardPadding),

                Text(
                  l10n.status,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.smallPadding),
                Wrap(
                  spacing: context.smallPadding,
                  runSpacing: context.smallPadding,
                  children: _orderStatuses.map((status) => _buildStatusChip(status)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2ProductSelection() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(l10n.products, Icons.shopping_cart_outlined),
          SizedBox(height: context.cardPadding),

          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('${l10n.add} ${l10n.products}', Icons.add_shopping_cart),
                SizedBox(height: context.cardPadding),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showProductSelectionDialog,
                    icon: Icon(
                        Icons.add_shopping_cart,
                        color: AppTheme.pureWhite,
                        size: context.iconSize('medium')
                    ),
                    label: Text(
                      '${l10n.add} ${l10n.products}',
                      style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: AppTheme.pureWhite,
                      padding: EdgeInsets.symmetric(
                        vertical: context.cardPadding,
                        horizontal: context.cardPadding * 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadius())
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                SizedBox(height: context.cardPadding),

                if (_orderItems.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                          Icons.shopping_bag,
                          color: AppTheme.primaryMaroon,
                          size: context.iconSize('medium')
                      ),
                      SizedBox(width: context.smallPadding),
                      Text(
                        '${l10n.products} (${_orderItems.length})',
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.cardPadding),

                  ..._orderItems.map((item) => _buildProductCard(item)).toList(),

                  SizedBox(height: context.cardPadding),
                  _buildTotalAmountCard(),
                ] else ...[
                  _buildEmptyProductsState(),
                ],
              ],
            ),
          ),

          if (_orderItems.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            _buildFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(l10n.payment, Icons.account_balance_wallet_outlined),
                  SizedBox(height: context.cardPadding),

                  PremiumTextField(
                    label: '${l10n.total} ${l10n.amount} (PKR) *',
                    hint: l10n.amount,
                    controller: _totalAmountController,
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_partnerRateFocusNode),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return l10n.paidAmount;
                      }
                      if (double.tryParse(value!) == null) {
                        return l10n.amount;
                      }
                      if (double.parse(value) <= 0) {
                        return '${l10n.amount} > 0';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: context.cardPadding),

                  PremiumTextField(
                    label: '${l10n.advancePayment} (PKR)',
                    hint: l10n.advancePayment,
                    controller: _advancePaymentController,
                    prefixIcon: Icons.payment_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return l10n.amount;
                        }
                        final advance = double.parse(value);
                        final total = double.tryParse(_totalAmountController.text) ?? 0;
                        if (advance < 0) {
                          return '${l10n.advancePayment} ${l10n.error}';
                        }
                        if (advance > total) {
                          return '${l10n.advancePayment} ${l10n.error}';
                        }
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: context.cardPadding),

                  PremiumTextField(
                    label: '${l10n.remainingAmount} (PKR)',
                    hint: l10n.remainingAmountToBePaid,
                    controller: _remainingAmountController,
                    prefixIcon: Icons.account_balance_outlined,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3ReviewOrder() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('${l10n.view} & ${l10n.confirm}', Icons.check_circle_outline),
          SizedBox(height: context.cardPadding),

          // Order Summary Card
          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.salesOverview, Icons.summarize_outlined),
                SizedBox(height: context.cardPadding),

                if (_selectedCustomer != null) ...[
                  _buildSummaryRow(l10n.customer, _selectedCustomer!.name, Icons.person),
                  _buildSummaryRow(l10n.phone, _selectedCustomer!.phone, Icons.phone),
                  _buildSummaryRow(l10n.email, _selectedCustomer!.email, Icons.email),
                  Divider(height: context.cardPadding * 2),
                ],

                _buildSummaryRow(l10n.notes, _descriptionController.text, Icons.description),
                _buildSummaryRow(l10n.status, _getStatusText(_selectedStatus), Icons.info,
                    valueColor: _getStatusColor(_selectedStatus)),
                _buildSummaryRow(l10n.products, '${_orderItems.length} ${l10n.items}', Icons.shopping_bag),
                _buildSummaryRow('${l10n.total} ${l10n.amount}', 'PKR ${_totalAmount.toStringAsFixed(2)}', Icons.attach_money,
                    valueColor: AppTheme.primaryMaroon, isBold: true),

                if (_advancePaymentController.text.isNotEmpty) ...[
                  _buildSummaryRow(l10n.advancePayment,
                      'PKR ${double.tryParse(_advancePaymentController.text)?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.payment),
                  _buildSummaryRow(l10n.remainingAmount,
                      'PKR ${(_totalAmount - (double.tryParse(_advancePaymentController.text) ?? 0.0)).toStringAsFixed(2)}',
                      Icons.account_balance_outlined,
                      valueColor: Colors.orange[800]),
                ],

                if (_selectedDeliveryDate != null) ...[
                  _buildSummaryRow(l10n.dueDate,
                      '${_selectedDeliveryDate!.day.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.month.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.year}',
                      Icons.calendar_today),
                ],
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          // Delivery Information
          _buildFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.delivered, Icons.local_shipping_outlined),
                SizedBox(height: context.cardPadding),

                InkWell(
                  onTap: () async {
                    await context.showSyncfusionDateTimePicker(
                      initialDate: _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
                      initialTime: TimeOfDay.now(),
                      title: l10n.dueDate,
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
                      color: AppTheme.primaryMaroon.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.primaryMaroon,
                          size: context.iconSize('medium'),
                        ),
                        SizedBox(width: context.smallPadding),
                        Expanded(
                          child: Text(
                            _selectedDeliveryDate != null
                                ? '${l10n.dueDate}: ${_selectedDeliveryDate!.day.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.month.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.year}'
                                : l10n.dueDate,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: _selectedDeliveryDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: _selectedDeliveryDate != null
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryMaroon,
                          size: context.iconSize('small'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryMaroon,
            size: context.iconSize('medium'),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
        SizedBox(width: context.smallPadding),
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: context.shouldShowCompactLayout ? 50 : 60,
            height: context.shouldShowCompactLayout ? 50 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _selectedCustomer!.initials,
                style: TextStyle(
                  fontSize: context.shouldShowCompactLayout ? 16 : 20,
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding,
                        vertical: context.smallPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        _selectedCustomer!.id,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMaroon,
                        ),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        _selectedCustomer!.name,
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
                if (!context.shouldShowCompactLayout) ...[ SizedBox(height: context.smallPadding),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: AppTheme.lightGray),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        _selectedCustomer!.phone,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                      SizedBox(width: context.cardPadding),
                      Icon(Icons.email, size: 14, color: AppTheme.charcoalGray),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          _selectedCustomer!.email,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            color: AppTheme.charcoalGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final isSelected = _selectedStatus == status;
    final color = _getStatusColor(status);

    return InkWell(
      onTap: () => _handleStatusChange(status),
      borderRadius: BorderRadius.circular(context.borderRadius()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.cardPadding,
          vertical: context.smallPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.lightGray.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(
            color: isSelected ? color : AppTheme.lightGray.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              size: context.iconSize('medium'),
              color: isSelected ? color : AppTheme.charcoalGray.withOpacity(0.5),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              _getStatusText(status),
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppTheme.charcoalGray.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(OrderItemModel item) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: context.smallPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primaryMaroon,
              size: context.iconSize('medium'),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding,
                        vertical: context.smallPadding / 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        '${l10n.quantity}: ${item.quantity}',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMaroon,
                        ),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'PKR ${item.unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (item.rentedFromPartner) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      'Rented from Partner',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (item.customizationNotes.isNotEmpty) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    '${l10n.notes}: ${item.customizationNotes}',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${item.lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryMaroon,
                ),
              ),
              SizedBox(height: context.smallPadding),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _orderItems.removeWhere((orderItem) => orderItem.productId == item.productId);
                      _calculateTotalAmount();
                    });
                  },
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  child: Container(
                    padding: EdgeInsets.all(context.smallPadding / 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: context.iconSize('medium'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryMaroon.withOpacity(0.1),
            AppTheme.secondaryMaroon.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.total} ${l10n.amount}:',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          Text(
            'PKR ${_totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: context.headerFontSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding * 2),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.3), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: AppTheme.lightGray,
            size: context.iconSize('large'),
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.noProductsFound,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.addProductsToStartSale,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.iconSize('small'), color: AppTheme.primaryMaroon),
          SizedBox(width: context.smallPadding),
          SizedBox(
            width: context.shouldShowCompactLayout ? 80 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightGray,
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppTheme.charcoalGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          top: BorderSide(
            color: AppTheme.lightGray.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: PremiumButton(
                text: l10n.cancel,
                onPressed: _previousStep,
                isOutlined: true,
                height: context.buttonHeight,
                backgroundColor: AppTheme.lightGray,
                textColor: AppTheme.lightGray,
                icon: Icons.arrow_back,
              ),
            ),
            SizedBox(width: context.cardPadding),
          ],

          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: _currentStep < 2
                ? PremiumButton(
              text: _currentStep == 0 ? '${l10n.products}' : l10n.view,
              onPressed: _canProceedToNextStep() ? _nextStep : null,
              height: context.buttonHeight,
              backgroundColor: AppTheme.primaryMaroon,
              icon: Icons.arrow_forward,
            )
                : Consumer<OrderProvider>(
              builder: (context, provider, child) {
                return PremiumButton(
                  text: l10n.createOrder,
                  onPressed: provider.isLoading ? null : _handleSubmit,
                  isLoading: provider.isLoading,
                  height: context.buttonHeight,
                  backgroundColor: AppTheme.primaryMaroon,
                  icon: Icons.check_circle,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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
        return l10n.pending;  // Changed from l10n.draft
      case OrderStatus.CONFIRMED:
        return l10n.confirmed;
      case OrderStatus.READY:
        return l10n.ready;  // Changed from l10n.status
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

  void _showProductSelectionDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final results = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProductSelectionDialog(
          eventDate: _selectedEventDate,
          returnDate: _selectedReturnDate,
          excludeProductIds: _orderItems.map((item) => item.productId).toList(),
        );
      },
    );

    if (results != null) {
      for (final result in results) {
        final product = result['product'] as ProductModel;
        final quantity = result['quantity'] as int;
        final unitPrice = result['unitPrice'] as double;
        final customizationNotes = result['customizationNotes'] as String?;
        final rentedFromPartner = result['rentedFromPartner'] as bool? ?? false;
        final partnerId = result['partnerId'] as String?;
        final partnerRate = result['partnerRate'] as double?;

        // Calculate rental days for pricing logic
        int effectiveDays = 1;
        if (product.pricingType == 'PER_DAY' && _selectedEventDate != null && _selectedReturnDate != null) {
          effectiveDays = _selectedReturnDate!.difference(_selectedEventDate!).inDays;
          if (effectiveDays < 1) effectiveDays = 1;
        }

        final existingItemIndex = _orderItems.indexWhere((item) => item.productId == product.id && item.rentedFromPartner == rentedFromPartner);

        if (existingItemIndex != -1) {
          setState(() {
            final currentQty = _orderItems[existingItemIndex].quantity + quantity;
            final currentRate = unitPrice;
            _orderItems[existingItemIndex] = _orderItems[existingItemIndex].copyWith(
              quantity: currentQty,
              rate: currentRate,
              days: effectiveDays,
              lineTotal: currentQty * currentRate * effectiveDays,
              totalValue: currentQty * currentRate * effectiveDays,
              customizationNotes: customizationNotes ?? _orderItems[existingItemIndex].customizationNotes,
            );
          });
        } else {
          final itemTotal = quantity * unitPrice * effectiveDays;
          final newOrderItem = OrderItemModel(
            id: '',
            orderId: '',
            productId: product.id,
            productName: product.name,
            productFabric: product.fabric,
            productColor: product.color,
            quantity: quantity,
            rate: unitPrice,
            days: effectiveDays,
            customizationNotes: customizationNotes ?? '',
            lineTotal: itemTotal,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            currentStock: product.quantity,
            totalValue: itemTotal,
            productDisplayInfo: {
              'name': product.name,
              'fabric': product.fabric,
              'color': product.color,
              'price': product.price
            },
            rentedFromPartner: rentedFromPartner,
            partnerId: partnerId,
            partnerRate: partnerRate,
          );
          setState(() {
            _orderItems.add(newOrderItem);
          });
        }
      }

      _calculateTotalAmount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.pureWhite),
                SizedBox(width: context.smallPadding),
                Text('${results.length > 1 ? "Items" : results.first['product'].name} ${l10n.add}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
          ),
        );
      }
    }
  }

  void _calculateTotalAmount() {
    _totalAmount = _orderItems.fold(0.0, (sum, item) => sum + item.lineTotal);
    _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    _updateRemainingAmount();
  }
}
