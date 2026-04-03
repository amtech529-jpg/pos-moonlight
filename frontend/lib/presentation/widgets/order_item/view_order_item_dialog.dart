import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class ViewOrderItemDialog extends StatefulWidget {
  final OrderItemModel orderItem;

  const ViewOrderItemDialog({super.key, required this.orderItem});

  @override
  State<ViewOrderItemDialog> createState() => _ViewOrderItemDialogState();
}

class _ViewOrderItemDialogState extends State<ViewOrderItemDialog> with SingleTickerProviderStateMixin {
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
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
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
                child: Column(
                  children: [
                    _buildHeader(l10n),
                    Expanded(
                      child: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: _buildTabletContent(l10n),
                        small: _buildMobileContent(l10n),
                        medium: _buildDesktopLayout(l10n),
                        large: _buildDesktopLayout(l10n),
                        ultrawide: _buildDesktopLayout(l10n),
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

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildLeftPanel(l10n)),
        Container(width: 1, color: Colors.grey.withOpacity(0.3)),
        Expanded(flex: 3, child: _buildRightPanel(l10n)),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.purpleAccent]),
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
            child: Icon(Icons.visibility_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.viewOrderItem,
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
                    l10n.completeOrderItemInformation,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          widget.orderItem.id.length > 8 ? '${widget.orderItem.id.substring(0, 8)}...' : widget.orderItem.id,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          widget.orderItem.productName.length > 15
                              ? '${widget.orderItem.productName.substring(0, 15)}...'
                              : widget.orderItem.productName,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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

  Widget _buildLeftPanel(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildProductDetailsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildFinancialSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildStatusSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildTimestampsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildCustomizationSection(l10n),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          children: [
            _buildBasicInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildProductDetailsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildFinancialSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildOrderInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildStatusSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildTimestampsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildCustomizationSection(l10n),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          children: [
            _buildBasicInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildProductDetailsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildFinancialSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildOrderInfoSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildStatusSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildTimestampsSection(l10n),
            SizedBox(height: context.cardPadding),
            _buildCustomizationSection(l10n),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(AppLocalizations l10n) {
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
              Icon(Icons.info_outline, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.basicInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(l10n.orderItemId, widget.orderItem.id, Icons.qr_code_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.orderId, widget.orderItem.orderId, Icons.receipt_long_outlined),
        ],
      ),
    );
  }

  Widget _buildProductDetailsSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(l10n.productId, widget.orderItem.productId, Icons.qr_code_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.productName, widget.orderItem.productName, Icons.shopping_bag_outlined),
          SizedBox(height: context.smallPadding),
          if (widget.orderItem.productColor != null && widget.orderItem.productColor!.isNotEmpty) ...[
            _buildInfoRow(l10n.color, widget.orderItem.productColor!, Icons.palette_outlined),
            SizedBox(height: context.smallPadding),
          ],
          if (widget.orderItem.productFabric != null && widget.orderItem.productFabric!.isNotEmpty) ...[
            _buildInfoRow(l10n.fabric, widget.orderItem.productFabric!, Icons.texture_outlined),
            SizedBox(height: context.smallPadding),
          ],
          if (widget.orderItem.currentStock != null) ...[
            _buildInfoRow(l10n.currentStock, '${widget.orderItem.currentStock!} ${l10n.units}', Icons.inventory_outlined),
            SizedBox(height: context.smallPadding),
          ],
          if (widget.orderItem.productDisplayInfo != null && widget.orderItem.productDisplayInfo!.isNotEmpty) ...[
            _buildInfoRow(l10n.productInfo, _formatProductDisplayInfo(widget.orderItem.productDisplayInfo!, l10n), Icons.info_outline),
            SizedBox(height: context.smallPadding),
          ],
          if ((widget.orderItem.productColor == null || widget.orderItem.productColor!.isEmpty) &&
              (widget.orderItem.productFabric == null || widget.orderItem.productFabric!.isEmpty) &&
              widget.orderItem.currentStock == null &&
              (widget.orderItem.productDisplayInfo == null || widget.orderItem.productDisplayInfo!.isEmpty)) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: context.iconSize('small')),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Text(
                      l10n.noAdditionalProductDetailsAvailable,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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

  Widget _buildFinancialSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.financialInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(l10n.quantity, widget.orderItem.quantity.toString(), Icons.numbers_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.unitPrice, 'PKR ${widget.orderItem.unitPrice.toStringAsFixed(2)}', Icons.attach_money_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.lineTotal, 'PKR ${widget.orderItem.lineTotal.toStringAsFixed(2)}', Icons.calculate_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.totalValue, 'PKR ${widget.orderItem.totalValue.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(l10n.orderId, widget.orderItem.orderId, Icons.receipt_outlined),
          SizedBox(height: context.smallPadding),
          _buildInfoRow(l10n.createdDate, _formatDate(widget.orderItem.createdAt), Icons.calendar_today_outlined),
          if (widget.orderItem.updatedAt != null) ...[
            SizedBox(height: context.smallPadding),
            _buildInfoRow(l10n.lastUpdated, _formatDate(widget.orderItem.updatedAt!), Icons.update_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.indigo.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.indigo, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.statusInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildStatusRow(l10n.activeStatus, widget.orderItem.isActive, Icons.check_circle_outline, l10n),
          if (widget.orderItem.hasBeenSold != null) ...[
            SizedBox(height: context.smallPadding),
            _buildStatusRow(l10n.soldStatus, widget.orderItem.hasBeenSold!, Icons.shopping_cart_outlined, l10n),
          ],
          if (widget.orderItem.remainingToSell != null) ...[
            SizedBox(height: context.smallPadding),
            _buildInfoRow(l10n.remainingToSell, widget.orderItem.remainingToSell!.toString(), Icons.inventory_2_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildTimestampsSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_outlined, color: Colors.teal, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.timestamps,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          _buildInfoRow(l10n.createdAt, _formatDateTime(widget.orderItem.createdAt), Icons.add_circle_outline),
          if (widget.orderItem.updatedAt != null) ...[
            SizedBox(height: context.smallPadding),
            _buildInfoRow(l10n.updatedAt, _formatDateTime(widget.orderItem.updatedAt!), Icons.edit_calendar_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_outlined, color: Colors.amber, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.customizationNotes,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Text(
              widget.orderItem.customizationNotes.isNotEmpty ? widget.orderItem.customizationNotes : l10n.noCustomizationNotesAvailable,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: widget.orderItem.customizationNotes.isNotEmpty ? Colors.amber[800] : Colors.grey[600],
                fontStyle: widget.orderItem.customizationNotes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding / 2),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Icon(icon, color: Colors.grey[600], size: context.iconSize('small')),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool value, IconData icon, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding / 2),
          decoration: BoxDecoration(
            color: (value ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
          ),
          child: Icon(icon, color: value ? Colors.green : Colors.red, size: context.iconSize('small')),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: (value ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: (value ? Colors.green : Colors.red).withOpacity(0.3)),
                ),
                child: Text(
                  value ? l10n.active : l10n.inactive,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: value ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildCompactButtons(l10n),
      small: _buildCompactButtons(l10n),
      medium: _buildDesktopButtons(l10n),
      large: _buildDesktopButtons(l10n),
      ultrawide: _buildDesktopButtons(l10n),
    );
  }

  Widget _buildCompactButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.close,
          onPressed: _handleClose,
          height: context.buttonHeight,
          icon: Icons.close_rounded,
          backgroundColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.close,
            onPressed: _handleClose,
            height: context.buttonHeight / 1.5,
            icon: Icons.close_rounded,
            backgroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatProductDisplayInfo(Map<String, dynamic> productInfo, AppLocalizations l10n) {
    try {
      final List<String> infoParts = [];

      if (productInfo['category'] != null) {
        infoParts.add('${l10n.category}: ${productInfo['category']}');
      }
      if (productInfo['brand'] != null) {
        infoParts.add('${l10n.brand}: ${productInfo['brand']}');
      }
      if (productInfo['size'] != null) {
        infoParts.add('${l10n.size}: ${productInfo['size']}');
      }
      if (productInfo['material'] != null) {
        infoParts.add('${l10n.material}: ${productInfo['material']}');
      }
      if (productInfo['style'] != null) {
        infoParts.add('${l10n.style}: ${productInfo['style']}');
      }

      if (infoParts.isEmpty) {
        return l10n.noAdditionalDetails;
      }

      return infoParts.join(' • ');
    } catch (e) {
      return l10n.additionalProductInformationAvailable;
    }
  }
}
