import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class CustomizeAndAddDialog extends StatefulWidget {
  final ProductModel product;

  const CustomizeAndAddDialog({super.key, required this.product});

  @override
  State<CustomizeAndAddDialog> createState() => _CustomizeAndAddDialogState();
}

class _CustomizeAndAddDialogState extends State<CustomizeAndAddDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _customPriceController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _quantity = 1;
  double _itemDiscount = 0.0;
  bool _isCustomPrice = false;
  bool _hasNotes = false;

  String _selectedSize = '';
  String _selectedFitting = 'Standard';
  String _selectedEmbroidery = 'None';
  String _selectedFabricQuality = 'Standard';
  Color _selectedAccentColor = Colors.transparent;
  bool _expressDelivery = false;
  bool _giftWrapping = false;

  final List<String> _availableSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'Custom',
  ];
  final List<String> _fittingOptions = [
    'Slim Fit',
    'Standard',
    'Loose Fit',
    'Custom Tailored',
  ];
  final List<String> _embroideryOptions = [
    'None',
    'Basic',
    'Premium',
    'Luxury Hand Work',
  ];
  final List<String> _fabricQualityOptions = ['Standard', 'Premium', 'Luxury'];
  final List<Color> _accentColors = [
    Colors.transparent,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.orange,
  ];

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
    _customPriceController.text = widget.product.price.toStringAsFixed(0);
    _selectedSize = _availableSizes[2];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      final customPrice = _isCustomPrice
          ? double.tryParse(_customPriceController.text) ?? widget.product.price
          : widget.product.price;
      final notes = _buildCustomizationNotes();
      final additionalCharges = _calculateAdditionalCharges();
      final finalPrice = customPrice + additionalCharges;
      final productToAdd = (additionalCharges > 0 || _isCustomPrice)
          ? widget.product.copyWith(price: finalPrice)
          : widget.product;

      provider.addToCartWithCustomization(
        productId: productToAdd.id,
        productName: productToAdd.name,
        unitPrice: productToAdd.price,
        quantity: _quantity,
        itemDiscount: _itemDiscount,
        customizationNotes: notes,
      );

      _handleSuccess();
    }
  }

  void _handleSuccess() {
    final l10n = AppLocalizations.of(context)!;

    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      // Snackbar removed - no longer shows "customized added to cart" confirmation
    });
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  double get _currentPrice {
    return _isCustomPrice
        ? double.tryParse(_customPriceController.text) ?? widget.product.price
        : widget.product.price;
  }

  double _calculateAdditionalCharges() {
    double charges = 0.0;
    if (_selectedSize == 'Custom') charges += 2000;
    switch (_selectedFitting) {
      case 'Custom Tailored':
        charges += 3000;
        break;
      case 'Slim Fit':
        charges += 500;
        break;
    }
    switch (_selectedEmbroidery) {
      case 'Basic':
        charges += 1500;
        break;
      case 'Premium':
        charges += 4000;
        break;
      case 'Luxury Hand Work':
        charges += 8000;
        break;
    }
    switch (_selectedFabricQuality) {
      case 'Premium':
        charges += widget.product.price * 0.3;
        break;
      case 'Luxury':
        charges += widget.product.price * 0.6;
        break;
    }
    if (_expressDelivery) charges += 1000;
    if (_giftWrapping) charges += 500;
    return charges;
  }

  double get _lineTotal {
    final basePrice = _currentPrice + _calculateAdditionalCharges();
    return (basePrice * _quantity) - _itemDiscount;
  }

  String _buildCustomizationNotes() {
    final l10n = AppLocalizations.of(context)!;
    List<String> notes = [];
    notes.add('${l10n.size}: $_selectedSize');
    notes.add('${l10n.fitting}: $_selectedFitting');
    if (_selectedEmbroidery != 'None')
      notes.add('${l10n.embroidery}: $_selectedEmbroidery');
    notes.add('${l10n.fabricQuality}: $_selectedFabricQuality');
    if (_selectedAccentColor != Colors.transparent) {
      notes.add('${l10n.accentColor}: ${_getColorName(_selectedAccentColor)}');
    }
    if (_expressDelivery) notes.add(l10n.expressDeliveryRequired);
    if (_giftWrapping) notes.add(l10n.giftWrappingRequired);
    if (_hasNotes && _notesController.text.isNotEmpty) {
      notes.add('${l10n.specialInstructions}: ${_notesController.text}');
    }
    return notes.join(' • ');
  }

  String _getColorName(Color color) {
    final l10n = AppLocalizations.of(context)!;
    if (color == Colors.transparent) return l10n.none;
    if (color == Colors.red) return l10n.red;
    if (color == Colors.blue) return l10n.blue;
    if (color == Colors.green) return l10n.green;
    if (color == Colors.purple) return l10n.purple;
    if (color == Colors.pink) return l10n.pink;
    if (color == Colors.orange) return l10n.orange;
    return l10n.custom;
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
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
              Icons.tune_rounded,
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
                  l10n.customizeAndAdd,
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
              _buildQuantityAndPricing(),
              SizedBox(height: context.cardPadding),
              _buildSizeAndFitting(),
              SizedBox(height: context.cardPadding),
              _buildCustomizationOptions(),
              SizedBox(height: context.cardPadding),
              _buildAdditionalServices(),
              SizedBox(height: context.cardPadding),
              _buildSpecialInstructionsSection(),
              SizedBox(height: context.cardPadding),
              _buildOrderSummary(),
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
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProductInfo(),
                    SizedBox(height: context.cardPadding),
                    _buildQuantityAndPricing(),
                    SizedBox(height: context.cardPadding),
                    _buildSizeAndFitting(),
                    SizedBox(height: context.cardPadding),
                    _buildOrderSummary(),
                  ],
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildCustomizationOptions(),
                    SizedBox(height: context.cardPadding),
                    _buildAdditionalServices(),
                    SizedBox(height: context.cardPadding),
                    _buildSpecialInstructionsSection(),
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
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.blue,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productInformation,
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
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            // color: _getColorFromName(widget.product.color),
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
                    SizedBox(height: context.smallPadding / 2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding,
                        vertical: context.smallPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.product.stockStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          context.borderRadius('small'),
                        ),
                      ),
                      child: Text(
                        l10n.stockAvailable(widget.product.quantity),
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w500,
                          color: widget.product.stockStatusColor,
                        ),
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

  Widget _buildQuantityAndPricing() {
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
                Icons.shopping_cart_rounded,
                color: Colors.green,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.quantityAndPricing,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.quantity,
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
                              }
                            : null,
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.smallPadding),
                          child: Icon(
                            Icons.remove,
                            color: _quantity > 1 ? Colors.green : Colors.grey,
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
                          setState(
                            () => _quantity = qty.clamp(
                              1,
                              widget.product.quantity,
                            ),
                          );
                        },
                        validator: (value) {
                          final qty = int.tryParse(value ?? '') ?? 0;
                          if (qty < 1) return l10n.minQuantity;
                          if (qty > widget.product.quantity)
                            return l10n.maxQuantity(widget.product.quantity);
                          return null;
                        },
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _quantity < widget.product.quantity
                            ? () {
                                setState(() {
                                  _quantity++;
                                  _quantityController.text = _quantity
                                      .toString();
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.smallPadding),
                          child: Icon(
                            Icons.add,
                            color: _quantity < widget.product.quantity
                                ? Colors.green
                                : Colors.grey,
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
          Row(
            children: [
              Text(
                l10n.customPrice,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _isCustomPrice,
                onChanged: (value) {
                  setState(() {
                    _isCustomPrice = value;
                    if (!value) {
                      _customPriceController.text = widget.product.price
                          .toStringAsFixed(0);
                    }
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_isCustomPrice) ...[
            SizedBox(height: context.smallPadding),
            PremiumTextField(
              label: l10n.customPricePkr,
              controller: _customPriceController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money_rounded,
              validator: (value) {
                final price = double.tryParse(value ?? '');
                if (price == null || price <= 0) return l10n.enterValidPrice;
                return null;
              },
              onChanged: (value) => setState(() {}),
            ),
          ],
          SizedBox(height: context.cardPadding),
          Text(
            l10n.itemDiscountOptional,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: [5, 10, 15, 20].map((percentage) {
              final discountAmount = (_currentPrice * percentage) / 100;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: percentage != 20 ? context.smallPadding / 2 : 0,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _itemDiscount = discountAmount;
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
                            color: _itemDiscount == discountAmount
                                ? Colors.orange
                                : Colors.orange.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(
                            context.borderRadius('small'),
                          ),
                          color: _itemDiscount == discountAmount
                              ? Colors.orange.withOpacity(0.1)
                              : null,
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
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
          if (_itemDiscount > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _itemDiscount = 0.0),
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('small'),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.smallPadding,
                      vertical: context.smallPadding / 2,
                    ),
                    child: Text(
                      l10n.clearDiscount(_itemDiscount.toStringAsFixed(0)),
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeAndFitting() {
    final l10n = AppLocalizations.of(context)!;

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
                Icons.straighten_rounded,
                color: Colors.purple,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.sizeAndFitting,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.size,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding / 2,
            runSpacing: context.smallPadding / 2,
            children: _availableSizes.map((size) {
              final isSelected = _selectedSize == size;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedSize = size),
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('small'),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.smallPadding,
                      vertical: context.smallPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.purple
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(
                        context.borderRadius('small'),
                      ),
                      color: isSelected ? Colors.purple.withOpacity(0.1) : null,
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.fittingStyle,
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFitting,
                isExpanded: true,
                onChanged: (value) =>
                    setState(() => _selectedFitting = value ?? 'Standard'),
                items: _fittingOptions
                    .map(
                      (fitting) => DropdownMenuItem<String>(
                        value: fitting,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.cardPadding / 2,
                          ),
                          child: Text(
                            fitting,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationOptions() {
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
                Icons.palette_rounded,
                color: Colors.orange,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.customizationOptions,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.embroideryWork,
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedEmbroidery,
                isExpanded: true,
                onChanged: (value) =>
                    setState(() => _selectedEmbroidery = value ?? 'None'),
                items: _embroideryOptions
                    .map(
                      (embroidery) => DropdownMenuItem<String>(
                        value: embroidery,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.cardPadding / 2,
                          ),
                          child: Text(
                            embroidery,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.fabricQuality,
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFabricQuality,
                isExpanded: true,
                onChanged: (value) => setState(
                  () => _selectedFabricQuality = value ?? 'Standard',
                ),
                items: _fabricQualityOptions
                    .map(
                      (quality) => DropdownMenuItem<String>(
                        value: quality,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.cardPadding / 2,
                          ),
                          child: Text(
                            quality,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.accentColor,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding / 2,
            runSpacing: context.smallPadding / 2,
            children: _accentColors.map((color) {
              final isSelected = _selectedAccentColor == color;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedAccentColor = color),
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('small'),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color == Colors.transparent
                          ? Colors.grey.shade200
                          : color,
                      borderRadius: BorderRadius.circular(
                        context.borderRadius('small'),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.charcoalGray
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: color == Colors.transparent
                        ? Icon(
                            Icons.close_rounded,
                            color: Colors.grey[600],
                            size: context.iconSize('small'),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServices() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_box_rounded,
                color: Colors.teal,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.additionalServices,
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
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: _expressDelivery
                  ? Colors.teal.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(
                color: _expressDelivery
                    ? Colors.teal.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Switch.adaptive(
                  value: _expressDelivery,
                  onChanged: (value) =>
                      setState(() => _expressDelivery = value),
                  activeColor: Colors.teal,
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expressDelivery,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                      Text(
                        l10n.expressDeliveryDesc,
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
          SizedBox(height: context.smallPadding),
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: _giftWrapping
                  ? Colors.teal.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(
                color: _giftWrapping
                    ? Colors.teal.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Switch.adaptive(
                  value: _giftWrapping,
                  onChanged: (value) => setState(() => _giftWrapping = value),
                  activeColor: Colors.teal,
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.giftWrapping,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                      Text(
                        l10n.giftWrappingDesc,
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
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
    final l10n = AppLocalizations.of(context)!;

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
                Icons.note_outlined,
                color: Colors.indigo,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.specialInstructions,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _hasNotes,
                onChanged: (value) {
                  setState(() {
                    _hasNotes = value;
                    if (!value) {
                      _notesController.clear();
                    }
                  });
                },
                activeColor: Colors.indigo,
              ),
            ],
          ),
          if (_hasNotes) ...[
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.additionalRequirements,
              controller: _notesController,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              hint: l10n.additionalRequirementsHint,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final l10n = AppLocalizations.of(context)!;
    final additionalCharges = _calculateAdditionalCharges();

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Colors.green,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.basePriceQuantity(_quantity),
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'PKR ${(_currentPrice * _quantity).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          if (additionalCharges > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: context.smallPadding / 2),
            if (_selectedSize == 'Custom')
              _buildChargeRow(l10n.customSizeLabel, 2000, l10n),
            if (_selectedFitting == 'Custom Tailored')
              _buildChargeRow(l10n.customTailoring, 3000, l10n),
            if (_selectedFitting == 'Slim Fit')
              _buildChargeRow(l10n.slimFit, 500, l10n),
            if (_selectedEmbroidery != 'None')
              _buildChargeRow(
                '$_selectedEmbroidery',
                _getEmbroideryCharge(),
                l10n,
              ),
            if (_selectedFabricQuality != 'Standard')
              _buildChargeRow(
                '${_selectedFabricQuality} ${l10n.fabric}',
                _getFabricQualityCharge(),
                l10n,
              ),
            if (_expressDelivery)
              _buildChargeRow(l10n.expressDelivery, 1000, l10n),
            if (_giftWrapping) _buildChargeRow(l10n.giftWrapping, 500, l10n),
          ],
          if (additionalCharges > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.subtotalWithCustomizations,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  'PKR ${((_currentPrice + additionalCharges) * _quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
              ],
            ),
          ],
          if (_itemDiscount > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.itemDiscount,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    color: Colors.orange[700],
                  ),
                ),
                Text(
                  '- PKR ${_itemDiscount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
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
                l10n.totalAmount,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'PKR ${_lineTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (_itemDiscount > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('small'),
                  ),
                ),
                child: Text(
                  l10n.youSave(_itemDiscount.toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: context.captionFontSize,
            color: Colors.blue[700],
          ),
        ),
        Text(
          '+PKR ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    if (context.shouldShowCompactLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumButton(
            text: l10n.addToCart,
            onPressed: _handleAddToCart,
            height: context.buttonHeight,
            icon: Icons.add_shopping_cart_rounded,
            backgroundColor: Colors.blue,
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
            child: PremiumButton(
              text: l10n.addToCart,
              onPressed: _handleAddToCart,
              height: context.buttonHeight / 1.5,
              icon: Icons.add_shopping_cart_rounded,
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      );
    }
  }

  double _getEmbroideryCharge() {
    switch (_selectedEmbroidery) {
      case 'Basic':
        return 1500;
      case 'Premium':
        return 4000;
      case 'Luxury Hand Work':
        return 8000;
      default:
        return 0;
    }
  }

  double _getFabricQualityCharge() {
    switch (_selectedFabricQuality) {
      case 'Premium':
        return widget.product.price * 0.3;
      case 'Luxury':
        return widget.product.price * 0.6;
      default:
        return 0;
    }
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
