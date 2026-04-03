import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../../../src/services/pdf_invoice_service.dart';

class ViewSaleDialog extends StatefulWidget {
  final SaleModel sale;

  const ViewSaleDialog({super.key, required this.sale});

  @override
  State<ViewSaleDialog> createState() => _ViewSaleDialogState();
}

class _ViewSaleDialogState extends State<ViewSaleDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _handlePrint() {
    PdfInvoiceService.printInvoice(widget.sale);
  }

  @override
  Widget build(BuildContext context) {
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 85.w, large: 75.w, ultrawide: 65.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context, tablet: 90.h, small: 85.h, medium: 80.h, large: 75.h, ultrawide: 70.h),
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
                  tablet: _buildCompactLayout(),
                  small: _buildCompactLayout(),
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

  Widget _buildCompactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(controller: _scrollController, child: _buildContent(isCompact: true)),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(controller: _scrollController, child: _buildContent(isCompact: false)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [widget.sale.statusColor, widget.sale.statusColor.withOpacity(0.8)]),
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
            child: Icon(Icons.receipt_long_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.saleDetails : l10n.saleInvoiceDetails,
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
                    widget.sale.formattedInvoiceNumber,
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

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: AppTheme.pureWhite, shape: BoxShape.circle),
                ),
                SizedBox(width: context.smallPadding / 2),
                Text(
                  widget.sale.status,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                ),
              ],
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
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInvoiceHeader(isCompact),
          SizedBox(height: context.cardPadding),
          _buildCustomerInfo(isCompact),
          SizedBox(height: context.cardPadding),
          _buildItemsList(isCompact),
          SizedBox(height: context.cardPadding),
          _buildPaymentInfo(isCompact),
          SizedBox(height: context.cardPadding),
          _buildOrderSummary(isCompact),
          if (widget.sale.notes?.isNotEmpty == true) ...[SizedBox(height: context.cardPadding), _buildNotesSection(isCompact)],
          SizedBox(height: context.mainPadding),
          _buildActionButtons(isCompact),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: isCompact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceField(l10n, l10n.invoiceNumber, widget.sale.formattedInvoiceNumber),
          SizedBox(height: context.smallPadding),
          _buildInvoiceField(l10n, l10n.saleId, widget.sale.id),
          SizedBox(height: context.smallPadding),
          _buildInvoiceField(l10n, l10n.dateTime, widget.sale.dateTimeText),
          SizedBox(height: context.smallPadding),
          _buildInvoiceField(l10n, l10n.createdBy, widget.sale.createdBy ?? l10n.unknown),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInvoiceField(l10n, l10n.invoiceNumber, widget.sale.formattedInvoiceNumber),
                SizedBox(height: context.smallPadding),
                _buildInvoiceField(l10n, l10n.saleId, widget.sale.id),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInvoiceField(l10n, l10n.dateTime, widget.sale.dateTimeText),
                SizedBox(height: context.smallPadding),
                _buildInvoiceField(l10n, l10n.createdBy, widget.sale.createdBy ?? l10n.unknown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceField(AppLocalizations l10n, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(bool isCompact) {
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
              Icon(Icons.person_rounded, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.customerInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          isCompact
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceField(l10n, l10n.name, widget.sale.customerName),
              SizedBox(height: context.smallPadding),
              _buildInvoiceField(l10n, l10n.phone, widget.sale.customerPhone),
              SizedBox(height: context.smallPadding),
              _buildInvoiceField(l10n, l10n.customerId, widget.sale.customerId!),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceField(l10n, l10n.name, widget.sale.customerName),
                    SizedBox(height: context.smallPadding),
                    _buildInvoiceField(l10n, l10n.phone, widget.sale.customerPhone),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildInvoiceField(l10n, l10n.customerId, widget.sale.customerId!)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(bool isCompact) {
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
              Icon(Icons.shopping_bag_rounded, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.items} (${widget.sale.totalItems})',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          ...widget.sale.saleItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildSaleItem(l10n, index, item, isCompact);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSaleItem(AppLocalizations l10n, int index, SaleItemModel item, bool isCompact) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.smallPadding),
              _buildItemDetails(l10n, item, isCompact),
              if (item.customizationNotes != null && item.customizationNotes!.isNotEmpty) ...[
                SizedBox(height: context.smallPadding),
                Container(
                  padding: EdgeInsets.all(context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note_outlined, color: Colors.blue, size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          '${l10n.note}: ${item.customizationNotes}',
                          style: TextStyle(fontSize: context.captionFontSize, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (index < widget.sale.saleItems.length - 1) SizedBox(height: context.smallPadding),
      ],
    );
  }

  Widget _buildItemDetails(AppLocalizations l10n, SaleItemModel item, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.unitPrice}:', style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600])),
              Text(
                'PKR ${item.unitPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.quantity}:', style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600])),
              Text(
                item.quantity.toString(),
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          if (item.itemDiscount > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.discount}:', style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600])),
                Text(
                  'PKR ${item.itemDiscount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              ],
            ),
          ],
          SizedBox(height: context.smallPadding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.lineTotal}:', style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              Text(
                'PKR ${item.lineTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.unitPrice}: PKR ${item.unitPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, color: AppTheme.charcoalGray),
              ),
              Text(
                '${l10n.quantity}: ${item.quantity}',
                style: TextStyle(fontSize: context.subtitleFontSize, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.itemDiscount > 0)
                Text(
                  '${l10n.discount}: PKR ${item.itemDiscount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.orange),
                ),
              Text(
                '${l10n.total}: PKR ${item.lineTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(bool isCompact) {
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
              Icon(_getPaymentMethodIcon(widget.sale.paymentMethod), color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          isCompact
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceField(l10n, l10n.paymentMethod, widget.sale.paymentMethod),
              SizedBox(height: context.smallPadding),
              _buildInvoiceField(l10n, l10n.amountPaid, 'PKR ${widget.sale.amountPaid.toStringAsFixed(0)}'),
              if (widget.sale.remainingAmount > 0) ...[
                SizedBox(height: context.smallPadding),
                _buildInvoiceField(l10n, l10n.remaining, 'PKR ${widget.sale.remainingAmount.toStringAsFixed(0)}'),
              ],
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceField(l10n, l10n.paymentMethod, widget.sale.paymentMethod),
                    SizedBox(height: context.smallPadding),
                    _buildInvoiceField(l10n, l10n.amountPaid, 'PKR ${widget.sale.amountPaid.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              if (widget.sale.remainingAmount > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildInvoiceField(l10n, l10n.remaining, 'PKR ${widget.sale.remainingAmount.toStringAsFixed(0)}')],
                  ),
                ),
            ],
          ),

          if (widget.sale.splitPaymentDetails != null && widget.sale.splitPaymentDetails!.isNotEmpty) ...[
            SizedBox(height: context.cardPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.splitPaymentDetails,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  ),
                  SizedBox(height: context.smallPadding),
                  Text(
                    widget.sale.splitPaymentDetails?.toString() ?? l10n.noSplitPaymentDetails,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary(bool isCompact) {
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
              Icon(Icons.calculate_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderSummary,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildSummaryRow(l10n.subtotal, 'PKR ${widget.sale.subtotal.toStringAsFixed(0)}'),

          if (widget.sale.overallDiscount > 0) ...[
            SizedBox(height: context.smallPadding / 2),
            _buildSummaryRow('${l10n.overallDiscount}', '- PKR ${widget.sale.overallDiscount.toStringAsFixed(0)}', Colors.orange),
          ],

          if (widget.sale.taxConfiguration.hasTaxes) ...[
            ...widget.sale.taxConfiguration.taxList.map(
                  (tax) => Column(
                children: [
                  SizedBox(height: context.smallPadding / 2),
                  _buildSummaryRow('${tax.name} (${tax.percentage}%)', 'PKR ${tax.amount.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ],

          SizedBox(height: context.smallPadding),
          Divider(color: Colors.grey.shade400, thickness: 1.5),
          SizedBox(height: context.smallPadding),

          _buildSummaryRow(
            l10n.grandTotal,
            'PKR ${widget.sale.grandTotal.toStringAsFixed(0)}',
            AppTheme.primaryMaroon,
            true,
            context.headerFontSize * 0.8,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? color, bool isBold = false, double? fontSize]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? context.subtitleFontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppTheme.charcoalGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize ?? context.subtitleFontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppTheme.charcoalGray,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_outlined, color: Colors.grey[700], size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.notesRemarks,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            widget.sale.notes ?? l10n.noNotesAvailable,
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCompact) {
    final l10n = AppLocalizations.of(context)!;

    return isCompact
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.printReceipt,
          onPressed: _handlePrint,
          height: context.buttonHeight,
          icon: Icons.print_rounded,
          backgroundColor: Colors.green,
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.close,
          onPressed: _handleClose,
          isOutlined: true,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    )
        : Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.close,
            onPressed: _handleClose,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: PremiumButton(
            text: l10n.printReceipt,
            onPressed: _handlePrint,
            height: context.buttonHeight / 1.5,
            icon: Icons.print_rounded,
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Icons.money_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'BANK_TRANSFER':
      case 'BANK TRANSFER':
        return Icons.account_balance_rounded;
      case 'CREDIT':
        return Icons.account_balance_wallet_rounded;
      case 'SPLIT':
        return Icons.call_split_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}
