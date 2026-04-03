import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../../../src/services/category_service.dart';
import '../../../src/models/category/category_model.dart';
import '../../../src/models/product/product_model.dart';

class AddProductDialog extends StatefulWidget {
  final bool initialIsRental;
  final bool initialIsConsumable;
  final ProductModel? product;

  const AddProductDialog({
    super.key,
    this.initialIsRental = true,
    this.initialIsConsumable = false,
    this.product,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController(); // Added min stock controller
  
  // Category logic
  final _categoryService = CategoryService();
  String? _selectedCategoryId;
  String _categorySearchText = '';
  final _categoryController = TextEditingController();
  // Extra optional fields
  final _serialNumberController = TextEditingController();
  final _warehouseLocationController = TextEditingController();
  
  // Focus Nodes
  late FocusNode _nameFocusNode;
  late FocusNode _detailFocusNode;
  late FocusNode _priceFocusNode;
  late FocusNode _quantityFocusNode;
  late FocusNode _minStockFocusNode;
  late FocusNode _categoryFocusNode;
  late FocusNode _serialFocusNode;
  late FocusNode _locationFocusNode;

  List<String> _selectedPieces = [];
  late bool _isRental;
  late bool _isConsumable;
  String _pricingType = 'PER_DAY';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isRental = widget.product?.isRental ?? widget.initialIsRental;
    _isConsumable = widget.product?.isConsumable ?? widget.initialIsConsumable;
    
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _detailController.text = widget.product!.detail;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _categoryController.text = widget.product!.categoryName ?? '';
      _serialNumberController.text = widget.product!.serialNumber ?? '';
      _warehouseLocationController.text = widget.product!.warehouseLocation ?? '';
      _minStockController.text = widget.product!.minStockThreshold?.toString() ?? '5';
      _pricingType = widget.product!.pricingType ?? 'PER_DAY';
    } else {
      _minStockController.text = '5';
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _nameFocusNode = FocusNode();
    _detailFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    _minStockFocusNode = FocusNode();
    _categoryFocusNode = FocusNode();
    _serialFocusNode = FocusNode();
    _locationFocusNode = FocusNode();

    _setupKeyboardNavigation();
  }

  void _setupKeyboardNavigation() {
    // Backspace navigation helper
    KeyEventResult handleBack(TextEditingController controller, FocusNode previous, KeyEvent event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        if (controller.text.isEmpty || (controller.text == '0' || controller.text == '5')) {
          previous.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    _detailFocusNode.onKeyEvent = (node, event) => handleBack(_detailController, _nameFocusNode, event);
    _priceFocusNode.onKeyEvent = (node, event) => handleBack(_priceController, _detailFocusNode, event);
    _quantityFocusNode.onKeyEvent = (node, event) => handleBack(_quantityController, _priceFocusNode, event);
    _minStockFocusNode.onKeyEvent = (node, event) => handleBack(_minStockController, _quantityFocusNode, event);
    _categoryFocusNode.onKeyEvent = (node, event) => handleBack(_categoryController, _minStockFocusNode, event);
    _serialFocusNode.onKeyEvent = (node, event) => handleBack(_serialNumberController, _categoryFocusNode, event);
    _locationFocusNode.onKeyEvent = (node, event) => handleBack(_warehouseLocationController, _serialFocusNode, event);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _detailController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _categoryController.dispose();
    _serialNumberController.dispose();
    _warehouseLocationController.dispose();
    _nameFocusNode.dispose();
    _detailFocusNode.dispose();
    _priceFocusNode.dispose();
    _quantityFocusNode.dispose();
    _minStockFocusNode.dispose();
    _categoryFocusNode.dispose();
    _serialFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProductProvider>();

    if (_formKey.currentState?.validate() ?? false) {
      // Validate Category logic
      if (_selectedCategoryId == null && _categorySearchText.isEmpty) {
        _showErrorSnackbar('Please select or type a category');
        return;
      }

      String finalCategoryId = '';

      // Handle Category Creation if needed
      if (_selectedCategoryId != null) {
          finalCategoryId = _selectedCategoryId!;
      } else {
          // Check if category exists by name in provider
          final existing = provider.categories.firstWhere(
             (c) => c.name.toLowerCase() == _categorySearchText.toLowerCase(), 
             orElse: () => CategoryModel(id: '', name: '', description: '', isActive: false, createdAt: DateTime.now(), updatedAt: DateTime.now())
          );
          
          if (existing.id.isNotEmpty) {
             finalCategoryId = existing.id;
          } else {
             // Create new category
             final result = await _categoryService.createCategory(name: _categorySearchText, description: "Auto-created");
             if (result.success && result.data != null) {
                finalCategoryId = result.data!.id;
                // Reload categories to keep provider in sync
                provider.loadCategories(); 
             } else {
                if (mounted) _showErrorSnackbar('Failed to create category: ${result.message}');
                return;
             }
          }
      }

      final bool isEditing = widget.product != null;
      
      bool success = false;
      ProductModel? resultModel;

      if (isEditing) {
        success = await provider.updateProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          detail: _detailController.text.trim(),
          price: double.tryParse(_priceController.text) ?? 0,
          quantity: int.tryParse(_quantityController.text) ?? 0,
          categoryId: finalCategoryId,
          pricingType: _pricingType,
          isRental: _isRental,
          isConsumable: _isConsumable,
          minStockThreshold: int.tryParse(_minStockController.text) ?? 5,
          serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
          warehouseLocation: _warehouseLocationController.text.trim().isEmpty ? null : _warehouseLocationController.text.trim(),
        );
        if (success) {
          resultModel = widget.product; // Just to signal success back
        }
      } else {
        resultModel = await provider.addProduct(
          name: _nameController.text.trim(),
          detail: _detailController.text.trim(),
          price: double.tryParse(_priceController.text) ?? 0,
          quantity: int.tryParse(_quantityController.text) ?? 0,
          categoryId: finalCategoryId,
          pricingType: _pricingType,
          isRental: _isRental,
          isConsumable: _isConsumable,
          serialNumber: _serialNumberController.text.isEmpty ? null : _serialNumberController.text,
          warehouseLocation: _warehouseLocationController.text.isEmpty ? null : _warehouseLocationController.text,
          minStockThreshold: int.tryParse(_minStockController.text) ?? 5,
        );
        success = resultModel != null;
      }

      if (mounted) {
        if (success) {
          _showSuccessSnackbar(isEditing: isEditing);
          Navigator.of(context).pop(resultModel);
        } else {
          _showErrorSnackbar(
            provider.errorMessage ?? (isEditing ? 'Failed to update' : '${l10n.failedToAdd} ${l10n.product}'),
          );
        }
      }
    }
  }

  void _showSuccessSnackbar({bool isEditing = false}) {
    final l10n = AppLocalizations.of(context)!;

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
              isEditing 
                ? 'Product updated successfully!'
                : '${l10n.product} ${l10n.addedSuccessfully}!',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: AppTheme.primaryMaroon,
        colorScheme: const ColorScheme.light(
          primary: AppTheme.primaryMaroon,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(
              0.5 * (_fadeAnimation.value.clamp(0.0, 1.0)),
            ),
            body: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value.clamp(0.1, 2.0),
                child: Container(
                  width: context.dialogWidth ?? 600,
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 90.w,
                      small: 85.w,
                      medium: 75.w,
                      large: 65.w,
                      ultrawide: 55.w,
                    ),
                    maxHeight: 90.h,
                  ),
                  margin: EdgeInsets.all(context.mainPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: _buildTabletLayout(),
                    small: _buildMobileLayout(),
                    medium: _buildDesktopLayout(),
                    large: _buildDesktopLayout(),
                    ultrawide: _buildDesktopLayout(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), _buildFormContent(isCompact: true)],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), _buildFormContent(isCompact: true)],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), _buildFormContent(isCompact: false)],
      ),
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
              Icons.inventory_rounded,
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
                  widget.product != null
                      ? 'Edit Tool/Consumable'
                      : (context.shouldShowCompactLayout
                          ? '${l10n.add} ${l10n.product}'
                          : '${l10n.add} ${l10n.newProduct}'),
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
                    l10n.createNewProductEntry,
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

  Widget _buildFormContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Autocomplete<ProductModel>(
                  focusNode: _nameFocusNode,
                  textEditingController: _nameController,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<ProductModel>.empty();
                    }
                    return provider.allProducts.where((option) =>
                        option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => option.name,
                  onSelected: (selection) {
                    setState(() {
                      _nameController.text = selection.name;
                      _detailController.text = selection.detail;
                      _priceController.text = selection.price.toString();
                      _selectedCategoryId = selection.categoryId;
                      _categoryController.text = selection.categoryName ?? '';
                      _categorySearchText = selection.categoryName ?? '';
                    });
                    _detailFocusNode.requestFocus();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return PremiumTextField(
                      label: '${l10n.product} ${l10n.name}',
                      hint: isCompact ? '${l10n.enterEmail} ${l10n.name}' : '${l10n.enterEmail} ${l10n.product} ${l10n.name}',
                      controller: controller,
                      focusNode: focusNode,
                      prefixIcon: Icons.label_outlined,
                      onSubmitted: (_) {
                        onSubmitted();
                        _detailFocusNode.requestFocus();
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) return '${l10n.pleaseEnter} ${l10n.product} ${l10n.name}';
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: Colors.white,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.name, style: const TextStyle(color: Colors.black)),
                                subtitle: Text(option.categoryName ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: '${l10n.product} ${l10n.detail}',
              hint: isCompact
                  ? '${l10n.enterEmail} ${l10n.details}'
                  : '${l10n.enterEmail} ${l10n.product} ${l10n.description}',
              controller: _detailController,
              focusNode: _detailFocusNode,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              onSubmitted: (_) => _priceFocusNode.requestFocus(),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.product} ${l10n.details}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.price,
              hint: isCompact
                  ? '${l10n.enterEmail} ${l10n.price}'
                  : '${l10n.enterEmail} ${l10n.price} (PKR)',
              controller: _priceController,
              focusNode: _priceFocusNode,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              selectAllOnFocus: true,
              onSubmitted: (_) => _quantityFocusNode.requestFocus(),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.price}';
                }
                final price = double.tryParse(value!);
                if (price == null || price <= 0) {
                  return '${l10n.pleaseEnterValid} ${l10n.price}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.quantity,
                    hint: isCompact
                        ? '${l10n.enterEmail} ${l10n.qty}'
                        : '${l10n.enterEmail} ${l10n.quantity}',
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    selectAllOnFocus: true,
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _minStockFocusNode.requestFocus(),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return '${l10n.pleaseEnter} ${l10n.quantity}';
                      }
                      final quantity = int.tryParse(value!);
                      if (quantity == null || quantity < 0) {
                        return '${l10n.pleaseEnterValid} ${l10n.quantity}';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumDropdownField<String>(
                    label: 'Pricing Type',
                    hint: 'Select pricing model',
                    prefixIcon: Icons.payments_outlined,
                    items: [
                      DropdownItem(value: 'PER_DAY', label: 'Per Day'),
                      DropdownItem(value: 'PER_EVENT', label: 'Per Event'),
                    ],
                    value: _pricingType,
                    onChanged: (value) {
                      if (value != null) setState(() => _pricingType = value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Rental & Consumable Toggles
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isRental = !_isRental),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Checkbox(
                            value: _isRental,
                            onChanged: (val) => setState(() => _isRental = val ?? true),
                            activeColor: AppTheme.primaryMaroon,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Rental Item',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isConsumable = !_isConsumable),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Checkbox(
                            value: _isConsumable,
                            onChanged: (val) => setState(() => _isConsumable = val ?? false),
                            activeColor: AppTheme.primaryMaroon,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Consumable',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Serial Number and Warehouse Location
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: 'Serial/Tag Number',
                    hint: 'Unique identifier',
                    controller: _serialNumberController,
                    focusNode: _serialFocusNode,
                    prefixIcon: Icons.qr_code_scanner_rounded,
                    onSubmitted: (_) => _locationFocusNode.requestFocus(),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: 'Warehouse Location',
                    hint: 'e.g. Rack A1, Shelf 2',
                    controller: _warehouseLocationController,
                    focusNode: _locationFocusNode,
                    prefixIcon: Icons.location_on_outlined,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Min Stock Threshold
            PremiumTextField(
              label: 'Min Stock Threshold',
              hint: 'e.g. 5',
              controller: _minStockController,
              focusNode: _minStockFocusNode,
              selectAllOnFocus: true,
              prefixIcon: Icons.warning_amber_rounded,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _categoryFocusNode.requestFocus(),
            ),
            SizedBox(height: context.cardPadding),

            // Category Selection
            // Category Selection (Autocomplete)
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Autocomplete<CategoryModel>(
                      focusNode: _categoryFocusNode,
                      textEditingController: _categoryController,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        _categorySearchText = textEditingValue.text;
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<CategoryModel>.empty();
                        }
                        return provider.categories.where((CategoryModel option) {
                          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (CategoryModel option) => option.name,
                      onSelected: (CategoryModel selection) {
                        setState(() {
                          _selectedCategoryId = selection.id;
                          _categorySearchText = selection.name;
                          _categoryController.text = selection.name;
                        });
                        _serialFocusNode.requestFocus();
                      },
                      fieldViewBuilder: (BuildContext context, TextEditingController controller, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                         return PremiumTextField(
                          controller: controller,
                          focusNode: focusNode,
                          label: l10n.category,
                          hint: "Type category (e.g. Lights, Wiring)...",
                          prefixIcon: Icons.category_outlined,
                          onChanged: (text) {
                            _categorySearchText = text;
                            _categoryController.text = text; // Sync
                             _selectedCategoryId = null; 
                          },
                          onSubmitted: (val) {
                            onFieldSubmitted();
                            _serialFocusNode.requestFocus();
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Theme(
                            data: ThemeData(
                              brightness: Brightness.light,
                              textTheme: const TextTheme(
                                bodyLarge: TextStyle(color: Colors.black87),
                                bodyMedium: TextStyle(color: Colors.black87),
                                titleMedium: TextStyle(color: Colors.black87),
                              ),
                            ),
                            child: Material(
                              elevation: 8.0,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                                  maxHeight: 250,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: index != options.length - 1
                                              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                option.name,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(" * Type a new category name to create automatically.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                );
              },
            ),
            SizedBox(height: context.cardPadding),
            SizedBox(height: context.cardPadding),

            SizedBox(height: context.cardPadding),

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
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    final bool isEditing = widget.product != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: isEditing ? 'Update Product' : '${l10n.add} ${l10n.product}',
              onPressed: provider.isLoading ? null : _handleSubmit,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
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
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: '${l10n.add} ${l10n.product}',
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.add_rounded,
              );
            },
          ),
        ),
      ],
    );
  }
}
