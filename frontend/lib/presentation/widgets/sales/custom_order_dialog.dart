import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/models/customer/customer_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/models/sales/request_models.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import 'order_success_dialog.dart';

class CreateCustomOrderDialog extends StatefulWidget {
  final ProductModel product;

  const CreateCustomOrderDialog({super.key, required this.product});

  @override
  State<CreateCustomOrderDialog> createState() =>
      _CreateCustomOrderDialogState();
}

class _CreateCustomOrderDialogState extends State<CreateCustomOrderDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _quantityController = TextEditingController(text: '1');
  final _totalAmountController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _measurementsController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  CustomerModel? _selectedCustomer;
  DateTime _selectedDeliveryDate = DateTime.now().add(const Duration(days: 30));
  int _quantity = 1;
  double _totalAmount = 0.0;
  double _advanceAmount = 0.0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _customOptions = [];

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

    // Initialize with product price
    _totalAmount = widget.product.price;
    _totalAmountController.text = _totalAmount.toStringAsFixed(0);
    _advanceAmount = _totalAmount * 0.5; // 50% advance by default
    _advanceAmountController.text = _advanceAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _quantityController.dispose();
    _totalAmountController.dispose();
    _advanceAmountController.dispose();
    _notesController.dispose();
    _measurementsController.dispose();
    super.dispose();
  }

  void _handleCreateOrder() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final provider = Provider.of<SalesProvider>(context, listen: false);

      try {
        // Create a custom sale with advance payment
        // ✅ FIX: capture boolean success, not the ID directly
        final success = await provider.createSale(
          CreateSaleRequest(
            customerId: _selectedCustomer!.id,
            overallDiscount: 0.0,
            taxConfiguration: TaxConfiguration(),
            paymentMethod: 'ADVANCE',
            notes: _getCustomizationNotes(),
            saleItems: [
              CreateSaleItemRequest(
                productId: widget.product.id,
                unitPrice: widget.product.price,
                quantity: _quantity,
                itemDiscount: 0.0,
                customizationNotes: _getCustomizationNotes(),
              ),
            ],
            amountPaid: _advanceAmount,
          ),
        );

        setState(() => _isLoading = false);

        if (mounted && success) {
          // ✅ FIX: Get the newly created sale from the top of the list
          // The provider inserts new sales at index 0
          final newSale = provider.sales.first;
          _handleSuccess(newSale.id, newSale.invoiceNumber);
        }
      } catch (e) {
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleSuccess(String saleId, String invoiceNumber) {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OrderSuccessDialog(
          saleId: saleId, // ✅ Now passed correctly
          invoiceNumber: invoiceNumber, // ✅ Now passed correctly
          totalPrice: _totalAmount,
          advanceAmount: _advanceAmount,
          deliveryDate: _selectedDeliveryDate,
        ),
      );
    });
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  String _getCustomizationNotes() {
    List<String> notes = [];

    if (_notesController.text.isNotEmpty) {
      notes.add('Special Instructions: ${_notesController.text}');
    }

    if (_measurementsController.text.isNotEmpty) {
      notes.add('Measurements: ${_measurementsController.text}');
    }

    if (_customOptions.isNotEmpty) {
      notes.add(
        'Custom Options: ${_customOptions.map((option) => '${option['label']}: ${option['value']}').join(', ')}',
      );
    }

    return notes.join('\n');
  }

  Map<String, dynamic> _getCustomOptions() {
    return {
      'delivery_date': _selectedDeliveryDate.toIso8601String(),
      'custom_options': _customOptions,
      'measurements': _measurementsController.text,
      'special_instructions': _notesController.text,
    };
  }

  void _updateTotalAmount() {
    setState(() {
      _totalAmount = (widget.product.price * _quantity);
      _totalAmountController.text = _totalAmount.toStringAsFixed(0);

      // Update advance amount to maintain percentage
      final advancePercentage = _totalAmount > 0
          ? (_advanceAmount / _totalAmount)
          : 0.5;
      _advanceAmount = _totalAmount * advancePercentage.clamp(0.0, 1.0);
      _advanceAmountController.text = _advanceAmount.toStringAsFixed(0);
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
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 95.w,
                    small: 90.w,
                    medium: 85.w,
                    large: 80.w,
                    ultrawide: 75.w,
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
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.purpleAccent],
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
              Icons.assignment_rounded,
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
                      ? 'Custom Order'
                      : 'Create Custom Order',
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                  ),
                ),
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    color: AppTheme.pureWhite.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!_isLoading)
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
              _buildProductInfo(),
              SizedBox(height: context.cardPadding),
              _buildCustomerSelection(),
              SizedBox(height: context.cardPadding),
              _buildOrderDetails(),
              SizedBox(height: context.cardPadding),
              _buildCustomizationOptions(),
              SizedBox(height: context.cardPadding),
              _buildPricingSection(),
              SizedBox(height: context.cardPadding),
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
              // Left Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProductInfo(),
                    SizedBox(height: context.cardPadding),
                    _buildCustomerSelection(),
                    SizedBox(height: context.cardPadding),
                    _buildOrderDetails(),
                  ],
                ),
              ),

              SizedBox(width: context.cardPadding),

              // Right Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildCustomizationOptions(),
                    SizedBox(height: context.cardPadding),
                    _buildPricingSection(),
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

  Widget _buildProductInfo() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.purple,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Product Information',
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Icon(
                  Icons.checkroom_outlined,
                  color: Colors.grey[500],
                  size: context.iconSize('large'),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      widget.product.detail,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            //  color: _getColorFromName(widget.product.color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        SizedBox(width: context.smallPadding / 2),
                        Text(
                          '${widget.product.color} • ${widget.product.fabric}',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Base Price',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'PKR ${widget.product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelection() {
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
                Icons.person_rounded,
                color: Colors.blue,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Customer Selection',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          Consumer<SalesProvider>(
            builder: (context, provider, child) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CustomerModel?>(
                    value: _selectedCustomer,
                    isExpanded: true,
                    hint: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.cardPadding / 2,
                      ),
                      child: Text(
                        'Select Customer *',
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    onChanged: (customer) =>
                        setState(() => _selectedCustomer = customer),
                    items: provider.customers
                        .map(
                          (customer) => DropdownMenuItem<CustomerModel?>(
                            value: customer,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.cardPadding / 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    customer.name,
                                    style: TextStyle(
                                      fontSize: context.bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.charcoalGray,
                                    ),
                                  ),
                                  Text(
                                    customer.phone,
                                    style: TextStyle(
                                      fontSize: context.captionFontSize,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),

          if (_selectedCustomer != null) ...[
            SizedBox(height: context.smallPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: Colors.blue,
                    size: context.iconSize('medium'),
                  ),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!.name,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                        Text(
                          '${_selectedCustomer!.phone} • ${_selectedCustomer!.email ?? 'No email'}',
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
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
                Icons.event_note_rounded,
                color: Colors.orange,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          // Quantity
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                  _quantityController.text = _quantity
                                      .toString();
                                });
                                _updateTotalAmount();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.smallPadding),
                          child: Icon(
                            Icons.remove,
                            color: _quantity > 1 ? Colors.orange : Colors.grey,
                            size: context.iconSize('medium'),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      padding: EdgeInsets.symmetric(
                        vertical: context.smallPadding,
                      ),
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 1;
                          setState(() => _quantity = qty.clamp(1, 100));
                          _updateTotalAmount();
                        },
                        validator: (value) {
                          final qty = int.tryParse(value ?? '') ?? 0;
                          if (qty < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _quantity++;
                            _quantityController.text = _quantity.toString();
                          });
                          _updateTotalAmount();
                        },
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.smallPadding),
                          child: Icon(
                            Icons.add,
                            color: Colors.orange,
                            size: context.iconSize('medium'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          // Delivery Date
          Text(
            'Delivery Date',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeliveryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDeliveryDate = date);
                  }
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding / 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.orange,
                        size: context.iconSize('medium'),
                      ),
                      SizedBox(width: context.smallPadding),
                      Expanded(
                        child: Text(
                          '${_selectedDeliveryDate.day}/${_selectedDeliveryDate.month}/${_selectedDeliveryDate.year}',
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationOptions() {
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
                Icons.tune_rounded,
                color: Colors.green,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Customization Options',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          // Measurements
          PremiumTextField(
            label: 'Measurements',
            controller: _measurementsController,
            prefixIcon: Icons.straighten_rounded,
            maxLines: 3,
            hint:
                'Enter custom measurements (e.g., Chest: 38", Waist: 32", Length: 42")',
          ),

          SizedBox(height: context.smallPadding),

          // Special Instructions
          PremiumTextField(
            label: 'Special Instructions',
            controller: _notesController,
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            hint:
                'Any special requirements, fabric preferences, design changes...',
          ),

          SizedBox(height: context.cardPadding),

          // Add Custom Options Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAddCustomOptionDialog,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.green,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'Add Custom Option',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Custom Options List
          if (_customOptions.isNotEmpty) ...[
            SizedBox(height: context.smallPadding),
            ..._customOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: context.smallPadding / 2),
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('small'),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['label'],
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                          Text(
                            option['value'],
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _customOptions.removeAt(index)),
                        borderRadius: BorderRadius.circular(
                          context.borderRadius('small'),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.smallPadding / 2),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: context.iconSize('small'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: Colors.indigo,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'Pricing Details',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          // Total Amount
          PremiumTextField(
            label: 'Total Order Amount (PKR)',
            controller: _totalAmountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.receipt_rounded,
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null || amount <= 0)
                return 'Please enter a valid amount';
              return null;
            },
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              setState(() {
                _totalAmount = amount;
                // Adjust advance amount to maintain reasonable percentage
                if (_advanceAmount > amount) {
                  _advanceAmount = amount * 0.5;
                  _advanceAmountController.text = _advanceAmount
                      .toStringAsFixed(0);
                }
              });
            },
          ),

          SizedBox(height: context.smallPadding),

          // Advance Amount
          PremiumTextField(
            label: 'Advance Payment (PKR)',
            controller: _advanceAmountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.account_balance_wallet_rounded,
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null || amount < 0)
                return 'Please enter a valid amount';
              if (amount > _totalAmount) return 'Cannot exceed total amount';
              return null;
            },
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              setState(() => _advanceAmount = amount);
            },
          ),

          SizedBox(height: context.smallPadding),

          // Quick Advance Percentage Buttons
          Text(
            'Quick Advance Options',
            style: TextStyle(
              fontSize: context.subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding / 2),
          Row(
            children: [25, 50, 75, 100].map((percentage) {
              final amount = (_totalAmount * percentage) / 100;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: percentage != 100 ? context.smallPadding / 2 : 0,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _advanceAmount = amount;
                          _advanceAmountController.text = amount
                              .toStringAsFixed(0);
                        });
                      },
                      borderRadius: BorderRadius.circular(
                        context.borderRadius('small'),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: context.smallPadding / 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _advanceAmount == amount
                                ? Colors.indigo
                                : Colors.indigo.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(
                            context.borderRadius('small'),
                          ),
                          color: _advanceAmount == amount
                              ? Colors.indigo.withOpacity(0.1)
                              : null,
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: context.cardPadding),

          // Order Summary
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.indigo.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Price × $_quantity:',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      'PKR ${(widget.product.price * _quantity).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      'PKR ${_totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advance Payment:',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'PKR ${_advanceAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Amount:',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      'PKR ${(_totalAmount - _advanceAmount).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
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

  Widget _buildActionButtons() {
    if (context.shouldShowCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumButton(
            text: _isLoading ? 'Creating Order...' : 'Create Order',
            onPressed: _isLoading ? null : _handleCreateOrder,
            isLoading: _isLoading,
            height: context.buttonHeight,
            icon: Icons.assignment_turned_in_rounded,
            backgroundColor: Colors.purple,
          ),
          SizedBox(height: context.cardPadding),
          PremiumButton(
            text: 'Cancel',
            onPressed: _isLoading ? null : _handleCancel,
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
              text: 'Cancel',
              onPressed: _isLoading ? null : _handleCancel,
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
              text: _isLoading ? 'Creating Order...' : 'Create Order',
              onPressed: _isLoading ? null : _handleCreateOrder,
              isLoading: _isLoading,
              height: context.buttonHeight / 1.5,
              icon: Icons.assignment_turned_in_rounded,
              backgroundColor: Colors.purple,
            ),
          ),
        ],
      );
    }
  }

  void _showAddCustomOptionDialog() {
    final labelController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius()),
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
              // Header
              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(context.borderRadius()),
                    topRight: Radius.circular(context.borderRadius()),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.green,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'Add Custom Option',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(context.cardPadding),
                child: Column(
                  children: [
                    PremiumTextField(
                      label: 'Option Name',
                      controller: labelController,
                      prefixIcon: Icons.label_rounded,
                      hint: 'e.g., Embroidery Style, Button Type',
                    ),
                    SizedBox(height: context.smallPadding),
                    PremiumTextField(
                      label: 'Option Value',
                      controller: valueController,
                      prefixIcon: Icons.edit_rounded,
                      hint: 'e.g., Gold Thread, Pearl Buttons',
                    ),
                    SizedBox(height: context.cardPadding),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                            isOutlined: true,
                            backgroundColor: Colors.grey[600],
                            textColor: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: context.cardPadding),
                        Expanded(
                          child: PremiumButton(
                            text: 'Add',
                            onPressed: () {
                              if (labelController.text.isNotEmpty &&
                                  valueController.text.isNotEmpty) {
                                setState(() {
                                  _customOptions.add({
                                    'label': labelController.text,
                                    'value': valueController.text,
                                  });
                                });
                                Navigator.of(context).pop();
                              }
                            },
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'navy':
        return Colors.indigo;
      case 'maroon':
        return Colors.red[900]!;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey[400]!;
      case 'beige':
        return Colors.brown[200]!;
      default:
        return Colors.grey;
    }
  }
}
