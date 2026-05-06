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
import 'package:frontend/presentation/widgets/globals/keyboard_scrollable.dart';


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
  List<CategoryModel> _categorySearchResults = [];
  final _categoryController = TextEditingController();
  
  // Extra optional fields
  final _serialNumberController = TextEditingController();
  final _warehouseLocationController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _detailFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _minStockFocusNode = FocusNode();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _serialFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _rentalFocusNode = FocusNode();
  final FocusNode _consumableFocusNode = FocusNode();
  final FocusNode _pricingFocusNode = FocusNode();
  final FocusNode _optionsFocusNode = FocusNode();
  final List<FocusNode> _categoryResultFocusNodes = [];
  final ScrollController _categoryResultScrollController = ScrollController();

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

    _animationController.forward();

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

    _categoryFocusNode.addListener(() {
      if (_categoryFocusNode.hasFocus) {
        // ignore: invalid_use_of_protected_member
        _categoryController.notifyListeners(); 
      }
    });

    _consumableFocusNode.skipTraversal = _isRental;

    _saveFocusNode.addListener(() {
      if (_saveFocusNode.hasFocus && _saveFocusNode.context != null) {
        Future.microtask(() {
          Scrollable.ensureVisible(
            _saveFocusNode.context!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });


    // Load categories to ensure they are available in the dropdown
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().loadCategories();
      }
    });

    _animationController.forward();
  }

  // Helper for backspace navigation
  KeyEventResult _handleBack(TextEditingController controller, FocusNode previous, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (controller.text.isEmpty || (controller.text == '0' || controller.text == '5')) {
        previous.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
    _saveFocusNode.dispose();
    _rentalFocusNode.dispose();
    _consumableFocusNode.dispose();
    _pricingFocusNode.dispose();
    _optionsFocusNode.dispose();
    for (var node in _categoryResultFocusNodes) {
      node.dispose();
    }
    _categoryResultScrollController.dispose();
    super.dispose();
  }

  void _searchCategories(String query) {
    final provider = context.read<ProductProvider>();
    final categories = provider.categories;

    setState(() {
      _categorySearchText = query;
      if (query.isEmpty) {
        _categorySearchResults = categories;
      } else {
        _categorySearchResults = categories.where((c) => 
          c.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategoryId = category.id;
      _categorySearchText = category.name;
      _categoryController.text = category.name;
      _categorySearchResults = [];
    });
    _saveFocusNode.requestFocus();
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
                  child: KeyboardScrollable(
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
              onKeyEvent: (node, event) => _handleBack(_detailController, _nameFocusNode, event),
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
              onKeyEvent: (node, event) => _handleBack(_priceController, _detailFocusNode, event),
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
                    onSubmitted: (_) => _pricingFocusNode.requestFocus(),
                    onKeyEvent: (node, event) => _handleBack(_quantityController, _priceFocusNode, event),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumDropdownField<String>(
                    focusNode: _pricingFocusNode,
                    label: 'Pricing Type',
                    hint: 'Select pricing model',
                    prefixIcon: Icons.payments_outlined,
                    focusColor: AppTheme.accentGold,
                    items: [
                      DropdownItem(value: 'PER_DAY', label: 'Per Day'),
                      DropdownItem(value: 'PER_EVENT', label: 'Per Event'),
                    ],
                    value: _pricingType,
                    onChanged: (value) {
                      if (value != null) setState(() => _pricingType = value);
                      _rentalFocusNode.requestFocus();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _rentalFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.space) {
                          setState(() {
                            _isRental = !_isRental;
                            if (_isRental) {
                              _isConsumable = false;
                              _consumableFocusNode.skipTraversal = true;
                            } else {
                              _consumableFocusNode.skipTraversal = false;
                            }
                          });
                          return KeyEventResult.handled;
                        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                          if (_isRental) {
                            Future.microtask(() => _serialFocusNode.requestFocus());
                          } else {
                            Future.microtask(() => _consumableFocusNode.requestFocus());
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _isRental = !_isRental;
                              if (_isRental) {
                                _isConsumable = false;
                                _consumableFocusNode.skipTraversal = true;
                              } else {
                                _consumableFocusNode.skipTraversal = false;
                              }
                            });
                            if (_isRental) {
                              _serialFocusNode.requestFocus();
                            } else {
                              _consumableFocusNode.requestFocus();
                            }
                          },
                          child: Container(
                            decoration: isFocused ? BoxDecoration(
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                              border: Border.all(color: AppTheme.accentGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ) : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Checkbox(
                                    value: _isRental,
                                    onChanged: (val) {
                                      setState(() {
                                        _isRental = val ?? true;
                                        if (_isRental) {
                                          _isConsumable = false;
                                          _consumableFocusNode.skipTraversal = true;
                                        } else {
                                          _consumableFocusNode.skipTraversal = false;
                                        }
                                      });
                                      if (_isRental) {
                                        _serialFocusNode.requestFocus();
                                      } else {
                                        _consumableFocusNode.requestFocus();
                                      }
                                    },
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
                        );
                      }
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: Focus(
                    focusNode: _consumableFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.space) {
                          setState(() {
                            _isConsumable = !_isConsumable;
                            if (_isConsumable) _isRental = false;
                          });
                          return KeyEventResult.handled;
                        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                          Future.microtask(() => _serialFocusNode.requestFocus());
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _isConsumable = !_isConsumable;
                              if (_isConsumable) _isRental = false;
                            });
                            _serialFocusNode.requestFocus();
                          },
                          child: Container(
                            decoration: isFocused ? BoxDecoration(
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                              border: Border.all(color: AppTheme.accentGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ) : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Checkbox(
                                    value: _isConsumable,
                                    onChanged: (val) {
                                      setState(() {
                                        _isConsumable = val ?? false;
                                        if (_isConsumable) _isRental = false;
                                      });
                                      _serialFocusNode.requestFocus();
                                    },
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
                        );
                      }
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
                    onKeyEvent: (node, event) => _handleBack(_serialNumberController, _categoryFocusNode, event),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: 'Warehouse Location',
                    controller: _warehouseLocationController,
                    focusNode: _locationFocusNode,
                    prefixIcon: Icons.location_on_outlined,
                    onSubmitted: (_) => _minStockFocusNode.requestFocus(),
                    onKeyEvent: (node, event) => _handleBack(_warehouseLocationController, _serialFocusNode, event),
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
              onKeyEvent: (node, event) => _handleBack(_minStockController, _quantityFocusNode, event),
            ),
            SizedBox(height: context.cardPadding),

            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PremiumTextField(
                            controller: _categoryController,
                            focusNode: _categoryFocusNode,
                            label: l10n.category,
                            hint: "Type category...",
                            prefixIcon: Icons.category_outlined,
                            textInputAction: TextInputAction.next,
                            onChanged: _searchCategories,
                            onTap: () {
                              if (_categoryController.text.isEmpty) {
                                _searchCategories('');
                              }
                            },
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent) {
                                if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
                                    (event.logicalKey == LogicalKeyboardKey.tab && !HardwareKeyboard.instance.isShiftPressed)) {
                                  if (_categoryResultFocusNodes.isNotEmpty) {
                                    _categoryResultFocusNodes[0].requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            onSubmitted: (_) {
                              if (_categorySearchResults.isNotEmpty) {
                                _selectCategory(_categorySearchResults[0]);
                              } else {
                                _saveFocusNode.requestFocus();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_categorySearchResults.isNotEmpty) _buildCategoryResults(),
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
        const SizedBox(width: 20),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: 'Update Product',
                focusNode: _saveFocusNode,
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

  Widget _buildCategoryResults() {
    // Ensure focus nodes match options length
    if (_categoryResultFocusNodes.length != _categorySearchResults.length) {
      for (var node in _categoryResultFocusNodes) node.dispose();
      _categoryResultFocusNodes.clear();
      _categoryResultFocusNodes.addAll(List.generate(_categorySearchResults.length, (index) => FocusNode()));
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        controller: _categoryResultScrollController,
        child: Column(
          children: _categorySearchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final focusNode = _categoryResultFocusNodes[index];

            return Focus(
              focusNode: focusNode,
              onFocusChange: (focused) {
                if (focused) {
                  Scrollable.ensureVisible(context, 
                    alignment: 0.5, 
                    duration: const Duration(milliseconds: 200),
                  );
                }
                setState(() {});
              },
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (index < _categoryResultFocusNodes.length - 1) {
                      _categoryResultFocusNodes[index + 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                    if (!HardwareKeyboard.instance.isShiftPressed) {
                      if (index < _categoryResultFocusNodes.length - 1) {
                        _categoryResultFocusNodes[index + 1].requestFocus();
                        return KeyEventResult.handled;
                      } else {
                        _saveFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                    } else {
                      if (index > 0) {
                        _categoryResultFocusNodes[index - 1].requestFocus();
                        return KeyEventResult.handled;
                      } else {
                        _categoryFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectCategory(category);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: InkWell(
                onTap: () => _selectCategory(category),
                canRequestFocus: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus ? AppTheme.primaryMaroon.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: focusNode.hasFocus ? AppTheme.primaryMaroon : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: focusNode.hasFocus ? AppTheme.primaryMaroon : Colors.black87,
                            fontSize: 14,
                            fontWeight: focusNode.hasFocus ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
