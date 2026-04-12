import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/models/vendor/vendor_model.dart';

class ProductSelectionDialog extends StatefulWidget {
  final List<String>? excludeProductIds;
  final DateTime? eventDate;
  final DateTime? returnDate;

  const ProductSelectionDialog({
    super.key,
    this.excludeProductIds,
    this.eventDate,
    this.returnDate,
  });

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customizationController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _partnerRateController = TextEditingController();
  final _unitPriceFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  final _partnerRateFocusNode = FocusNode();
  final _eventNameFocusNode = FocusNode();
  final _eventLocationFocusNode = FocusNode();

  String _searchQuery = '';
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  ProductModel? _selectedProduct;
  
  // Date availability state
  Map<String, dynamic> _availabilityMap = {};
  bool _isLoadingAvailability = false;

  // Partner state
  bool _rentedFromPartner = false;
  String? _selectedPartnerId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _loadProducts();
    
    // Reset vendor filters to ensures ALL partners are available in the dropdown
    // This fixed the issue where previous searches in Vendor screen filtered the Order dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<VendorProvider>(context, listen: false).resetAllFiltersAndSearch();
      }
    });

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _customizationController.dispose();
    _partnerRateController.dispose();
    _unitPriceController.dispose();

    // Clear date filters from provider when closing the dialog
    // to avoid affecting other screens like Inventory
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        provider.applyFilters(provider.currentFilters.copyWith(
          startDate: null,
          endDate: null,
        ));
      }
    });
    
    _unitPriceController.dispose();
    _partnerRateController.dispose();
    _notesFocusNode.dispose();
    _eventNameFocusNode.dispose();
    _eventLocationFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    _quantityFocusNode.dispose();
    _partnerRateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      
      // Apply date filters if provided by the order
      if (widget.eventDate != null && widget.returnDate != null) {
        provider.applyFilters(provider.currentFilters.copyWith(
          startDate: widget.eventDate,
          endDate: widget.returnDate,
        ));
      } else {
        await provider.loadProducts();
      }
      _filterProducts();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error loading products: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Date-wise availability check removed.
  // Order screen now uses product.quantityAvailable directly — same as Inventory screen.
  Future<void> _checkDateAvailability() async {}


  void _filterProducts() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    List<ProductModel> products = provider.products;

    if (widget.excludeProductIds != null) {
      products = products
          .where((product) => !widget.excludeProductIds!.contains(product.id))
          .toList();
    }

    // Exclude products that are specifically categorized as "Color" or "Fabric"
    // as requested by the user ("color no fabric products... ya ni ani chayia")
    products = products.where((product) {
      final category = product.categoryName?.toLowerCase() ?? '';
      return category != 'color' && category != 'fabric';
    }).toList();

    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(query);
        final fabricMatch = (product.fabric?.toLowerCase() ?? '').contains(query);
        final colorMatch = (product.color?.toLowerCase() ?? '').contains(query);
        return nameMatch || fabricMatch || colorMatch;
      }).toList();
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Call the provider's search method which handles server-side search and filtering
    Provider.of<ProductProvider>(context, listen: false).searchProducts(query);
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _unitPriceController.text = product.price.toStringAsFixed(2);
    });
  }

  void _addToOrder() {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedProduct == null) {
        _showErrorSnackbar(l10n.pleaseSelectProduct);
        return;
      }

      final totalQuantity = int.tryParse(_quantityController.text) ?? 1;
      final unitPrice = double.tryParse(_unitPriceController.text) ?? _selectedProduct!.price;
      final customizationNotes = _customizationController.text.trim();

      // Get real-time availability for today (same as shown in list)
      int availableQty = _selectedProduct!.dateAvailableQuantity ?? _selectedProduct!.quantityAvailable;
      
      List<Map<String, dynamic>> selectedItems = [];
      
      // Smart Splitting Logic
      // If Partner Rental is ON and requested quantity > available own stock
      if (_rentedFromPartner && totalQuantity > availableQty) {
        // Step 1: Use ALL available own stock first (if any)
        if (availableQty > 0) {
          selectedItems.add({
            'product': _selectedProduct!,
            'quantity': availableQty,
            'unitPrice': unitPrice,
            'customizationNotes': customizationNotes.isNotEmpty ? customizationNotes : null,
            'rentedFromPartner': false,
            'partnerId': null,
            'partnerRate': null,
          });
        }

        // Step 2: Take ONLY the remaining amount from Partner
        selectedItems.add({
          'product': _selectedProduct!,
          'quantity': totalQuantity - availableQty,
          'unitPrice': unitPrice,
          'customizationNotes': customizationNotes.isNotEmpty ? customizationNotes : null,
          'rentedFromPartner': true,
          'partnerId': _selectedPartnerId,
          'partnerRate': double.tryParse(_partnerRateController.text),
        });
      } else {
        // Normal Case: All from one source
        selectedItems.add({
          'product': _selectedProduct!,
          'quantity': totalQuantity,
          'unitPrice': unitPrice,
          'customizationNotes': customizationNotes.isNotEmpty ? customizationNotes : null,
          'rentedFromPartner': _rentedFromPartner,
          'partnerId': _selectedPartnerId,
          'partnerRate': double.tryParse(_partnerRateController.text),
        });
      }

      _animationController.reverse().then((_) {
        if (mounted) Navigator.of(context).pop(selectedItems);
      });
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
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
                    tablet: 90.w,
                    small: 85.w,
                    medium: 75.w,
                    large: 65.w,
                    ultrawide: 55.w,
                  ),
                  maxHeight: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 85.h,
                    small: 80.h,
                    medium: 75.h,
                    large: 70.h,
                    ultrawide: 65.h,
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
                    Flexible(child: _buildFormContent()),
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
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding * 0.8),
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
            padding: EdgeInsets.all(context.smallPadding * 0.7),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('small'),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.shouldShowCompactLayout
                      ? l10n.selectProduct
                      : l10n.selectProductForOrder,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
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

  Widget _buildFormContent() {
    final ScrollController _contentScrollController = ScrollController();
    return Scrollbar(
      controller: _contentScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _contentScrollController,
        child: Padding(
          padding: EdgeInsets.all(context.smallPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchSection(),
                SizedBox(height: context.smallPadding),

                _buildProductListSection(),
                SizedBox(height: context.smallPadding),

                if (_selectedProduct != null) ...[
                  _buildSelectedProductSection(),
                  SizedBox(height: context.smallPadding),
                ],

                ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildCompactButtons(),
                  small: _buildCompactButtons(),
                  medium: _buildDesktopButtons(),
                  large: _buildDesktopButtons(),
                  ultrawide: _buildDesktopButtons(),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding * 0.7),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumTextField(
            label: l10n.searchProducts,
            hint: context.shouldShowCompactLayout
                ? l10n.searchProductsShort
                : l10n.searchProductsByNameFabricOrColor,
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProductListSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding * 0.7),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.availableProducts, Icons.inventory_2),
          SizedBox(height: context.smallPadding),
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              final products = provider.products.where((product) {
                if (widget.excludeProductIds != null && widget.excludeProductIds!.contains(product.id)) {
                  return false;
                }
                return true;
              }).toList();

              if (provider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryMaroon,
                  ),
                );
              }

              if (products.isEmpty) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.all(context.cardPadding * 2),
                    child: Column(
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off,
                          color: AppTheme.charcoalGray,
                          size: context.iconSize('large'),
                        ),
                        SizedBox(height: context.cardPadding),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.noProductsAvailable
                              : l10n.noProductsFound,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: context.smallPadding),
                          Text(
                            l10n.tryAdjustingYourSearchTerms,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 40.h,
                  small: 35.h,
                  medium: 30.h,
                  large: 25.h,
                  ultrawide: 20.h,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = _selectedProduct?.id == product.id;

                    return Container(
                      margin: EdgeInsets.only(bottom: context.smallPadding),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryMaroon.withOpacity(0.1)
                            : AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryMaroon
                              : AppTheme.lightGray.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _selectProduct(product),
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding * 0.6),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMaroon.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    context.borderRadius('small'),
                                  ),
                                ),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: AppTheme.primaryMaroon,
                                  size: context.iconSize('small'),
                                ),
                              ),
                              SizedBox(width: context.cardPadding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      height: context.smallPadding / 2,
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final fabric = product.fabric;
                                        final color = product.color;
                                        final List<String> parts = [];
                                        if (fabric != null && fabric.isNotEmpty && fabric.toLowerCase() != 'none' && fabric.toLowerCase() != 'no fabric') {
                                          parts.add(fabric);
                                        }
                                        if (color != null && color.isNotEmpty && color.toLowerCase() != 'none' && color.toLowerCase() != 'no color') {
                                          parts.add(color);
                                        }
                                        
                                        if (parts.isEmpty) return const SizedBox.shrink();
                                        
                                        return Text(
                                          parts.join(' • '),
                                          style: TextStyle(
                                            fontSize: context.bodyFontSize,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    if (product.fabric != null || product.color != null)
                                      SizedBox(height: context.smallPadding / 2),
                                    Row(
                                      children: [
                                        Text(
                                          'PKR ${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: context.bodyFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryMaroon,
                                          ),
                                        ),
                                        SizedBox(width: context.cardPadding),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.smallPadding,
                                            vertical: context.smallPadding / 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: product.quantity > 0
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              context.borderRadius('small'),
                                            ),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              // Use dateAvailableQuantity if available (from backend date filters)
                                              // Otherwise fall back to quantityAvailable
                                              final int availableQty = product.dateAvailableQuantity ?? product.quantityAvailable;
                                              
                                              return Text(
                                                availableQty > 0
                                                    ? '${l10n.inStock}: $availableQty / ${product.quantity}'
                                                    : l10n.outOfStock,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: availableQty > 0 ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: EdgeInsets.all(
                                    context.smallPadding / 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMaroon,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: AppTheme.pureWhite,
                                    size: context.iconSize('medium'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding * 0.7),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            l10n.selectedProductDetails,
            Icons.check_circle_outline,
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
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
                    _selectedProduct!.name.isNotEmpty
                        ? _selectedProduct!.name[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
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
                    Text(
                      _selectedProduct!.name,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(
                      builder: (context) {
                        final fabric = _selectedProduct!.fabric;
                        final color = _selectedProduct!.color;
                        final List<String> parts = [];
                        if (fabric != null && fabric.isNotEmpty && fabric.toLowerCase() != 'none' && fabric.toLowerCase() != 'no fabric') {
                          parts.add(fabric);
                        }
                        if (color != null && color.isNotEmpty && color.toLowerCase() != 'none' && color.toLowerCase() != 'no color') {
                          parts.add(color);
                        }
                        
                        if (parts.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: EdgeInsets.only(bottom: context.smallPadding / 2),
                          child: Text(
                            parts.join(' • '),
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final enteredQty = int.tryParse(_quantityController.text) ?? 0;
                        
                        // Use dateAvailableQuantity (defaults to today) precisely as shown in list
                        final int availableQty = _selectedProduct!.dateAvailableQuantity ?? _selectedProduct!.quantityAvailable;
                        final remaining = availableQty - enteredQty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.available}: $availableQty / ${_selectedProduct!.quantity} ${l10n.units}',
                              style: TextStyle(
                                fontSize: context.bodyFontSize,
                                fontWeight: FontWeight.w600,
                                color: availableQty > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            if (enteredQty > 0 && !_rentedFromPartner)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Remaining: ${remaining < 0 ? 0 : remaining} ${l10n.units}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: remaining < 0 ? Colors.red : Colors.blueAccent,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildFormFieldsColumn(),
            small: _buildFormFieldsColumn(),
            medium: _buildFormFieldsRow(),
            large: _buildFormFieldsRow(),
            ultrawide: _buildFormFieldsRow(),
          ),
          SizedBox(height: context.smallPadding),
          PremiumTextField(
            label: l10n.customizationNotesOptional,
            hint: context.shouldShowCompactLayout
                ? l10n.enterNotes
                : l10n.specialInstructionsOrCustomizationNotes,
            controller: _customizationController,
            prefixIcon: Icons.description_outlined,
            focusNode: _notesFocusNode,
            maxLines: 3,
            textInputAction: _rentedFromPartner ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) {
              if (_rentedFromPartner) {
                FocusScope.of(context).requestFocus(_partnerRateFocusNode);
              }
            },
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length > 500) {
                return l10n.notesMustBeLessThan500Characters;
              }
              return null;
            },
          ),
          
          SizedBox(height: context.cardPadding),
          _buildPartnerRentalSection(),
          SizedBox(height: context.smallPadding),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding * 0.7),
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
              border: Border.all(
                color: AppTheme.primaryMaroon.withOpacity(0.3),
              ),
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
                      '${l10n.totalAmount}:',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    int previewDays = 1;
                    if (_selectedProduct!.pricingType == 'PER_DAY' && widget.eventDate != null && widget.returnDate != null) {
                      previewDays = widget.returnDate!.difference(widget.eventDate!).inDays;
                      if (previewDays < 1) previewDays = 1;
                    }
                    final quantity = int.tryParse(_quantityController.text) ?? 1;
                    final unitPrice = double.tryParse(_unitPriceController.text) ?? _selectedProduct!.price;
                    final total = unitPrice * quantity * previewDays;
                    
                    return Text(
                      'PKR ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.headerFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryMaroon,
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsRow() {
    return Row(
      children: [
        Expanded(child: _buildQuantityField()),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildUnitPriceField()),
      ],
    );
  }

  Widget _buildFormFieldsColumn() {
    return Column(
      children: [
        _buildQuantityField(),
        SizedBox(height: context.cardPadding),
        _buildUnitPriceField(),
      ],
    );
  }

  Widget _buildQuantityField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: '${l10n.quantity} *',
      hint: l10n.enterQuantity,
      controller: _quantityController,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.numbers,
      focusNode: _quantityFocusNode,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
         FocusScope.of(context).requestFocus(_unitPriceFocusNode);
      },
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return l10n.pleaseEnterQuantity;
        }
        final quantity = int.tryParse(value!);
        if (quantity == null) {
          return l10n.pleaseEnterValidNumber;
        }
        
        // Use today's availability (dateAvailableQuantity) or current available quantity
        final int availableToday = _selectedProduct?.dateAvailableQuantity ?? _selectedProduct?.quantityAvailable ?? 0;
        
        if (!_rentedFromPartner && quantity > availableToday) {
          return 'Only $availableToday available. Use "Partner Rental" for more.';
        }
        return null;
      },
      onChanged: (value) {
        // Redraw to show error message real-time
        setState(() {});
      },
    );
  }

  Widget _buildUnitPriceField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: '${l10n.unitPrice} *',
      hint: l10n.amount,
      controller: _unitPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.attach_money,
      focusNode: _unitPriceFocusNode,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        FocusScope.of(context).requestFocus(_notesFocusNode);
      },
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return l10n.amount;
        }
        if (double.tryParse(value!) == null) {
          return l10n.pleaseEnterValidNumber;
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryMaroon,
          size: context.iconSize('medium'),
        ),
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

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.addToOrder,
          onPressed: _selectedProduct != null ? _addToOrder : null,
          isLoading: _isLoading,
          height: context.buttonHeight,
          icon: Icons.add_rounded,
          backgroundColor: AppTheme.primaryMaroon,
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
          flex: 2,
          child: PremiumButton(
            text: l10n.addToOrder,
            onPressed: _selectedProduct != null ? _addToOrder : null,
            isLoading: _isLoading,
            height: context.buttonHeight / 1.5,
            icon: Icons.add_rounded,
            backgroundColor: AppTheme.primaryMaroon,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerRentalSection() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: context.smallPadding),
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: _rentedFromPartner ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(
              color: _rentedFromPartner ? Colors.amber : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PARTNER RENTAL (Wazir Item)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Is item ko bahar se mangwa rahy hain?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _rentedFromPartner,
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.primaryMaroon,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        _rentedFromPartner = value;
                      });
                    },
                  ),
                ],
              ),
              if (!_rentedFromPartner)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '(Apni product use karne ke liye ise band rakhein)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
        if (_rentedFromPartner) ...[
          SizedBox(height: context.cardPadding),
          Consumer<VendorProvider>(
            builder: (context, vendorProvider, child) {
              return PremiumDropdownField<VendorModel>(
                label: 'Partner / Vendor *',
                hint: 'Select Partner',
                items: vendorProvider.vendors
                    .map((vendor) => DropdownItem<VendorModel>(
                    value: vendor,
                    label: vendor.name
                ))
                    .toList(),
                value: vendorProvider.vendors.any((v) => v.id == _selectedPartnerId)
                    ? vendorProvider.vendors.firstWhere((v) => v.id == _selectedPartnerId)
                    : null,
                onChanged: (vendor) {
                  setState(() {
                    _selectedPartnerId = vendor?.id;
                  });
                },
                validator: (value) {
                  if (_rentedFromPartner && value == null) {
                    return 'Please select a partner';
                  }
                  return null;
                },
                prefixIcon: Icons.handshake_outlined,
              );
            },
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: 'Partner Rate (PKR) *',
            hint: 'Rate charged by partner',
            controller: _partnerRateController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments_outlined,
            focusNode: _partnerRateFocusNode,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (_rentedFromPartner && (value?.isEmpty ?? true)) {
                return 'Please enter partner rate';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
