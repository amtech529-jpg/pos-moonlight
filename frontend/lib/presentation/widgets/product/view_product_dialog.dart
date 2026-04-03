import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';

import '../../../src/models/product/product_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../../../l10n/app_localizations.dart';

class ViewProductDetailsDialog extends StatefulWidget {
  final ProductModel product;

  const ViewProductDetailsDialog({super.key, required this.product});

  @override
  State<ViewProductDetailsDialog> createState() => _ViewProductDetailsDialogState();
}

class _ViewProductDetailsDialogState extends State<ViewProductDetailsDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
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
          backgroundColor: Colors.black.withOpacity(0.7 * (_fadeAnimation.value.clamp(0.0, 1.0))),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value.clamp(0.1, 2.0),
              child: Container(
                width: context.dialogWidth ?? 700,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 85.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
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
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: true))),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: true))),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildContent(isCompact: false))),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.green, Colors.greenAccent]),
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
            child: Icon(Icons.inventory_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.productDetails,
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
                    l10n.viewCompleteProductInformation,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.product.id ?? l10n.notAvailable,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          SizedBox(width: context.smallPadding),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClose,
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

  Widget _buildContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductNameCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildDescriptionCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildPriceStockCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildRentalInfoCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildAttributesCard(isCompact),
          SizedBox(height: context.cardPadding),
          _buildPiecesCard(isCompact),
          SizedBox(height: context.mainPadding),
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton(
              text: l10n.close,
              onPressed: _handleClose,
              height: context.buttonHeight / (isCompact ? 1 : 1.5),
              isOutlined: true,
              backgroundColor: Colors.grey[600],
              textColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductNameCard(bool isCompact) {
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
              Icon(Icons.label_outline, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productName,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: Icon(Icons.inventory, color: AppTheme.pureWhite, size: context.iconSize('small')),
                ),
                SizedBox(width: context.cardPadding),
                Text(
                  widget.product.name ?? l10n.unnamedProduct,
                  style: TextStyle(fontSize: context.bodyFontSize * 1.1, fontWeight: FontWeight.w700, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.grey[700], size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              widget.product.detail?.isEmpty ?? true ? l10n.noDetailsProvided : widget.product.detail!,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: widget.product.detail?.isEmpty ?? true ? Colors.grey[500] : AppTheme.charcoalGray,
                height: 1.5,
                fontStyle: widget.product.detail?.isEmpty ?? true ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStockCard(bool isCompact) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildPriceStockCompact(),
      small: _buildPriceStockCompact(),
      medium: _buildPriceStockExpanded(),
      large: _buildPriceStockExpanded(),
      ultrawide: _buildPriceStockExpanded(),
    );
  }

  Widget _buildPriceStockCompact() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money, size: context.iconSize('small'), color: Colors.purple),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.price,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                'PKR ${widget.product.price?.toStringAsFixed(0) ?? l10n.notAvailable}',
                style: TextStyle(fontSize: context.bodyFontSize * 1.2, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: context.iconSize('small'), color: Colors.orange),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.costPrice,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.product.formattedCostPrice,
                style: TextStyle(
                  fontSize: context.bodyFontSize * 1.2,
                  fontWeight: FontWeight.w700,
                  color: widget.product.hasCostPrice ? AppTheme.charcoalGray : Colors.grey[500],
                ),
              ),
              if (widget.product.hasCostPrice) ...[
                SizedBox(height: context.smallPadding / 2),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: context.iconSize('small'), color: Colors.green),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      '${l10n.profit}: ${widget.product.formattedProfitAmount} (${widget.product.formattedProfitMargin})',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(height: context.smallPadding / 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: context.iconSize('small'), color: Colors.orange[700]),
                      SizedBox(width: context.smallPadding / 2),
                      Flexible(
                        child: Text(
                          l10n.setCostPriceToCalculateProfitMargin,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: (widget.product.stockStatusColor ?? Colors.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, size: context.iconSize('small'), color: widget.product.stockStatusColor ?? Colors.grey),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.stockStatus,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                l10n.unitsCount(widget.product.quantity ?? 0),
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              SizedBox(height: context.smallPadding / 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
                decoration: BoxDecoration(
                  color: (widget.product.stockStatusColor ?? Colors.grey).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  widget.product.stockStatusText ?? l10n.unknown,
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: widget.product.stockStatusColor ?? Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        
        // Barcode Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_2_outlined, size: context.iconSize('small'), color: Colors.blue),
                  SizedBox(width: context.smallPadding),
                  Text(
                    'Barcode',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.product.displayBarcode,
                style: TextStyle(
                  fontSize: context.bodyFontSize * 1.1,
                  fontWeight: FontWeight.w600,
                  color: widget.product.hasBarcode ? AppTheme.charcoalGray : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        
        // SKU Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tag_outlined, size: context.iconSize('small'), color: Colors.green),
                  SizedBox(width: context.smallPadding),
                  Text(
                    'SKU',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding / 2),
              Text(
                widget.product.displaySku,
                style: TextStyle(
                  fontSize: context.bodyFontSize * 1.1,
                  fontWeight: FontWeight.w600,
                  color: widget.product.hasSku ? AppTheme.charcoalGray : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceStockExpanded() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: context.iconSize('small'), color: Colors.purple),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.price,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  'PKR ${widget.product.price?.toStringAsFixed(0) ?? l10n.notAvailable}',
                  style: TextStyle(fontSize: context.bodyFontSize * 1.2, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: context.iconSize('small'), color: Colors.orange),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.costPrice,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.product.formattedCostPrice,
                  style: TextStyle(
                    fontSize: context.bodyFontSize * 1.2,
                    fontWeight: FontWeight.w700,
                    color: widget.product.costPrice != null ? AppTheme.charcoalGray : Colors.grey[500],
                  ),
                ),
                if (widget.product.costPrice != null) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    '${l10n.profit}: ${widget.product.formattedProfitAmount} (${widget.product.formattedProfitMargin})',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: (widget.product.stockStatusColor ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: context.iconSize('small'), color: widget.product.stockStatusColor ?? Colors.grey),
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.stockStatus,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  l10n.unitsCount(widget.product.quantity ?? 0),
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                SizedBox(height: context.smallPadding / 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
                  decoration: BoxDecoration(
                    color: (widget.product.stockStatusColor ?? Colors.grey).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Text(
                    widget.product.stockStatusText ?? l10n.unknown,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: widget.product.stockStatusColor ?? Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        
        // Barcode Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2_outlined, size: context.iconSize('small'), color: Colors.blue),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'Barcode',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.product.displayBarcode,
                  style: TextStyle(
                    fontSize: context.bodyFontSize * 1.1,
                    fontWeight: FontWeight.w600,
                    color: widget.product.hasBarcode ? AppTheme.charcoalGray : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        
        // SKU Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_outlined, size: context.iconSize('small'), color: Colors.green),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'SKU',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  widget.product.displaySku,
                  style: TextStyle(
                    fontSize: context.bodyFontSize * 1.1,
                    fontWeight: FontWeight.w600,
                    color: widget.product.hasSku ? AppTheme.charcoalGray : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesCard(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productAttributes,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildAttributesCompact(),
            small: _buildAttributesCompact(),
            medium: _buildAttributesExpanded(),
            large: _buildAttributesExpanded(),
            ultrawide: _buildAttributesExpanded(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesCompact() {
    final l10n = AppLocalizations.of(context)!;

    final fabric = widget.product.fabric;
    final color = widget.product.color;
    final bool hasFabric = fabric != null && fabric.isNotEmpty && fabric.toLowerCase() != 'none';
    final bool hasColor = color != null && color.isNotEmpty && color.toLowerCase() != 'none';

    if (!hasFabric && !hasColor) {
      return Center(
        child: Text(
          l10n.notAvailable,
          style: TextStyle(fontSize: context.subtitleFontSize, fontStyle: FontStyle.italic, color: Colors.grey[500]),
        ),
      );
    }

    return Column(
      children: [
        if (hasColor)
          Row(
            children: [
              Icon(Icons.color_lens_outlined, size: 16, color: Colors.grey[600]),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.color}:',
                style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Text(
                    color!,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        if (hasFabric && hasColor) SizedBox(height: context.cardPadding),
        if (hasFabric)
          Row(
            children: [
              Icon(Icons.texture_outlined, size: 16, color: Colors.grey[600]),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.fabric}:',
                style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Text(
                    fabric!,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAttributesExpanded() {
    final l10n = AppLocalizations.of(context)!;

    final fabric = widget.product.fabric;
    final color = widget.product.color;
    final bool hasFabric = fabric != null && fabric.isNotEmpty && fabric.toLowerCase() != 'none';
    final bool hasColor = color != null && color.isNotEmpty && color.toLowerCase() != 'none';

    if (!hasFabric && !hasColor) {
      return Center(
        child: Text(
          l10n.notAvailable,
          style: TextStyle(fontSize: context.subtitleFontSize, fontStyle: FontStyle.italic, color: Colors.grey[500]),
        ),
      );
    }

    return Row(
      children: [
        if (hasColor)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.color}:',
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                SizedBox(height: context.smallPadding / 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.color_lens_outlined, size: 12, color: Colors.grey[600]),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        color!,
                        style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (hasColor && hasFabric) SizedBox(width: context.cardPadding),
        if (hasFabric)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.fabric}:',
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                SizedBox(height: context.smallPadding / 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.texture_outlined, size: 12, color: Colors.grey[600]),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        fabric!,
                        style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (hasFabric && !hasColor) const Spacer(),
      ],
    );
  }

  Widget _buildPiecesCard(bool isCompact) {
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
              Icon(Icons.category_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productPieces,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: (widget.product.pieces?.isNotEmpty ?? false)
                ? Wrap(
              spacing: context.smallPadding,
              runSpacing: context.smallPadding,
              children: widget.product.pieces!.map((piece) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    piece,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.orange[700]),
                  ),
                );
              }).toList(),
            )
                : Text(
              l10n.noPiecesSpecified,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, color: Colors.green[700], size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Text(
                  l10n.productActive,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRentalInfoCard(bool isCompact) {
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
              Icon(Icons.precision_manufacturing_outlined, color: Colors.teal, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              const Text(
                'Inventory Classification',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              _buildModernTag(
                label: widget.product.isRental ? 'RENTAL' : 'SALE ONLY',
                color: widget.product.isRental ? Colors.teal : Colors.grey,
                icon: Icons.vpn_key_outlined,
              ),
              SizedBox(width: context.smallPadding),
              _buildModernTag(
                label: widget.product.isConsumable ? 'CONSUMABLE' : 'EQUIPMENT',
                color: widget.product.isConsumable ? Colors.orange : Colors.blue,
                icon: Icons.layers_outlined,
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Serial Number',
            value: widget.product.serialNumber ?? 'No serial recorded',
            isCompact: isCompact,
          ),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Warehouse Location',
            value: widget.product.warehouseLocation ?? 'Not assigned',
            isCompact: isCompact,
          ),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(
            icon: Icons.payments_outlined,
            label: 'Pricing Model',
            value: widget.product.pricingType.replaceAll('_', ' '),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTag({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: context.smallPadding / 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, required bool isCompact}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: context.smallPadding),
        Text(
          '$label:',
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
