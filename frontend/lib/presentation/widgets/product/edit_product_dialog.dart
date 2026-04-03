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

class EditProductDialog extends StatefulWidget {
  final ProductModel product;

  const EditProductDialog({
    super.key,
    required this.product,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  
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

  late bool _isRental;
  late bool _isConsumable;
  String _pricingType = 'PER_DAY';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController FIRST before using it
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Initialize FocusNodes BEFORE using them
    _nameFocusNode = FocusNode();
    _detailFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    _minStockFocusNode = FocusNode();
    _categoryFocusNode = FocusNode();
    _serialFocusNode = FocusNode();
    _locationFocusNode = FocusNode();

    // Populate form fields from existing product data
    _isRental = widget.product.isRental;
    _isConsumable = widget.product.isConsumable;
    _nameController.text = widget.product.name;
    _detailController.text = widget.product.detail;
    _priceController.text = widget.product.price.toString();
    _quantityController.text = widget.product.quantity.toString();
    _selectedCategoryId = widget.product.categoryId;
    _categoryController.text = widget.product.categoryName ?? '';
    _categorySearchText = widget.product.categoryName ?? '';
    _serialNumberController.text = widget.product.serialNumber ?? '';
    _warehouseLocationController.text = widget.product.warehouseLocation ?? '';
    _minStockController.text = widget.product.minStockThreshold.toString();
    _pricingType = widget.product.pricingType;

    _setupKeyboardNavigation();
    _animationController.forward();
  }

  void _setupKeyboardNavigation() {
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
      if (_selectedCategoryId == null && _categorySearchText.isEmpty) {
        _showErrorSnackbar('Please select or type a category');
        return;
      }

      String finalCategoryId = '';

      if (_selectedCategoryId != null) {
          finalCategoryId = _selectedCategoryId!;
      } else {
          final existing = provider.categories.firstWhere(
             (c) => c.name.toLowerCase() == _categorySearchText.toLowerCase(), 
             orElse: () => CategoryModel(id: '', name: '', description: '', isActive: false, createdAt: DateTime.now(), updatedAt: DateTime.now())
          );
          
          if (existing.id.isNotEmpty) {
             finalCategoryId = existing.id;
          } else {
             final result = await _categoryService.createCategory(name: _categorySearchText, description: "Auto-created");
             if (result.success && result.data != null) {
                finalCategoryId = result.data!.id;
                provider.loadCategories(); 
             } else {
                if (mounted) _showErrorSnackbar('Failed to create category: ${result.message}');
                return;
             }
          }
      }

      bool success = await provider.updateProduct(
        id: widget.product.id,
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

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackbar(
            provider.errorMessage ?? 'Failed to update product',
          );
        }
      }
    }
  }

  void _showSuccessSnackbar() {
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
            const Text(
              'Product updated successfully!',
              style: TextStyle(
                fontSize: 14,
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
                style: const TextStyle(
                  fontSize: 14,
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildHeader(), _buildFormContent()],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
                const Text(
                  'Edit Product',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  'Update product details in inventory',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.pureWhite.withOpacity(0.9),
                  ),
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
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.pureWhite,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = context.shouldShowCompactLayout;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: '${l10n.product} ${l10n.name}',
              hint: '${l10n.enterEmail} ${l10n.product} ${l10n.name}',
              controller: _nameController,
              focusNode: _nameFocusNode,
              prefixIcon: Icons.label_outlined,
              onSubmitted: (_) => _detailFocusNode.requestFocus(),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.product} ${l10n.name}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: '${l10n.product} ${l10n.detail}',
              hint: '${l10n.enterEmail} ${l10n.product} ${l10n.description}',
              controller: _detailController,
              focusNode: _detailFocusNode,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              onSubmitted: (_) => _priceFocusNode.requestFocus(),
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.price,
              hint: '${l10n.enterEmail} ${l10n.price} (PKR)',
              controller: _priceController,
              focusNode: _priceFocusNode,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              selectAllOnFocus: true,
              onSubmitted: (_) => _quantityFocusNode.requestFocus(),
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.quantity,
                    hint: '${l10n.enterEmail} ${l10n.quantity}',
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    selectAllOnFocus: true,
                    onSubmitted: (_) => _minStockFocusNode.requestFocus(),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumDropdownField<String>(
                    label: 'Pricing Type',
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

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: 'Serial/Tag Number',
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
                    controller: _warehouseLocationController,
                    focusNode: _locationFocusNode,
                    prefixIcon: Icons.location_on_outlined,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: 'Min Stock Threshold',
              controller: _minStockController,
              focusNode: _minStockFocusNode,
              prefixIcon: Icons.warning_amber_rounded,
              keyboardType: TextInputType.number,
              selectAllOnFocus: true,
              onSubmitted: (_) => _categoryFocusNode.requestFocus(),
            ),
            SizedBox(height: context.cardPadding),

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
                          return provider.categories;
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
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                         return PremiumTextField(
                          controller: controller,
                          focusNode: focusNode,
                          label: l10n.category,
                          hint: "Type category...",
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

            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildActionButtons(),
              small: _buildActionButtons(),
              medium: _buildActionButtons(),
              large: _buildActionButtons(),
              ultrawide: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            isOutlined: true,
            height: 48,
            backgroundColor: Colors.grey,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Update Product',
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: 48,
                icon: Icons.save_rounded,
              );
            },
          ),
        ),
      ],
    );
  }
}
