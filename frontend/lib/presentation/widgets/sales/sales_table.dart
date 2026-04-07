import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/pdf_invoice_service.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/order/order_model.dart';

class SalesTable extends StatefulWidget {
  final Function(SaleModel) onEdit;
  final Function(SaleModel) onDelete;
  final Function(SaleModel) onView;
  final bool canEdit;
  final bool canDelete;

  const SalesTable({
    super.key, 
    required this.onEdit, 
    required this.onDelete, 
    required this.onView,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  State<SalesTable> createState() => _SalesTableState();
}

class _SalesTableState extends State<SalesTable> {
  late ScrollController _headerScrollController;
  late ScrollController _contentHorizontalScrollController;
  late ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _contentHorizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();

    // Link the header and content horizontal scrolling
    _headerScrollController.addListener(() {
      if (_contentHorizontalScrollController.hasClients &&
          _headerScrollController.offset != _contentHorizontalScrollController.offset) {
        _contentHorizontalScrollController.jumpTo(_headerScrollController.offset);
      }
    });

    _contentHorizontalScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _contentHorizontalScrollController.offset != _headerScrollController.offset) {
        _headerScrollController.jumpTo(_contentHorizontalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _contentHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: context.shadowBlur(),
              offset: Offset(0, context.smallPadding)
          )
        ],
      ),
      // Add height constraint to prevent overflow
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% of screen height
      ),
      child: Consumer<SalesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: SizedBox(
                width: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                height: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
              ),
            );
          }

          if (provider.sales.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            mainAxisSize: MainAxisSize.min, // Use minimum size
            children: [
              // 1. Table Header (Horizontal Scroll)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(context.borderRadius('large')),
                    topRight: Radius.circular(context.borderRadius('large')),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _headerScrollController, // Controlled by header controller
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                      width: _getTableWidth(context),
                      padding: EdgeInsets.all(context.cardPadding),
                      child: _buildTableHeader(context)
                  ),
                ),
              ),

              // 2. Table Content (Vertical + Horizontal Scroll)
              Flexible( // Use Flexible instead of Expanded
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController, // Vertical Scrolling
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _contentHorizontalScrollController,
                      thumbVisibility: true,
                      notificationPredicate: (notification) => notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _contentHorizontalScrollController, // Controlled by content horizontal controller
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Container(
                          width: _getTableWidth(context),
                          // Use Column instead of ListView inside SingleChildScrollView to avoid conflicts
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Use minimum size
                            children: provider.sales.asMap().entries.map((entry) {
                              return _buildTableRow(context, entry.value, entry.key);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    return ResponsiveBreakpoints.responsive(context, tablet: 1400.0, small: 1600.0, medium: 1800.0, large: 2000.0, ultrawide: 2200.0);
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildHeaderCell(context, l10n.saleId)),
        Container(width: columnWidths[1], child: _buildHeaderCell(context, l10n.invoiceNumber)),
        Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.customer)),
        Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.items)),
        Container(width: columnWidths[4], child: _buildHeaderCell(context, l10n.subtotal)),
        Container(width: columnWidths[5], child: _buildHeaderCell(context, l10n.discount)),
        Container(width: columnWidths[6], child: _buildHeaderCell(context, l10n.gst)),
        Container(width: columnWidths[7], child: _buildHeaderCell(context, l10n.grandTotal)),
        Container(width: columnWidths[8], child: _buildHeaderCell(context, l10n.paid)),
        Container(width: columnWidths[9], child: _buildHeaderCell(context, l10n.remaining)),
        Container(width: columnWidths[10], child: _buildHeaderCell(context, l10n.payment)),
        Container(width: columnWidths[11], child: _buildHeaderCell(context, l10n.date)),
        Container(width: columnWidths[12], child: _buildHeaderCell(context, l10n.status)),
        Container(width: columnWidths[13], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return [
      120.0, // Sale ID
      120.0, // Invoice Number
      200.0, // Customer
      80.0, // Items
      110.0, // Subtotal
      100.0, // Discount
      80.0, // GST
      120.0, // Grand Total
      110.0, // Amount Paid
      110.0, // Remaining
      120.0, // Payment Method
      120.0, // Date
      100.0, // Status
      220.0, // Actions
    ];
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray, letterSpacing: 0.2),
    );
  }

  Widget _buildTableRow(BuildContext context, SaleModel sale, int index) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    String displayCustomerName = sale.customerName;
    
    if (sale.customerId != null && sale.customerId!.isNotEmpty) {
      final customer = customerProvider.allCustomers.where((c) => c.id == sale.customerId).firstOrNull;
      if (customer != null && customer.customerType == 'BUSINESS' && customer.businessName != null && customer.businessName!.isNotEmpty) {
        displayCustomerName = customer.businessName!;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
      child: Row(
        children: [
          // Sale ID
          Container(
            width: columnWidths[0],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                sale.id,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Invoice Number
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              sale.formattedInvoiceNumber,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
          ),

          // Customer
          Container(
            width: columnWidths[2],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayCustomerName,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sale.customerPhone,
                  style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Items Count
          Container(
            width: columnWidths[3],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Text(
                sale.totalItems.toString(),
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Subtotal
          Container(
            width: columnWidths[4],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              'PKR ${sale.subtotal.toStringAsFixed(0)}',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
          ),

          // Discount
          Container(
            width: columnWidths[5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: sale.overallDiscount > 0
                ? Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                'PKR ${sale.overallDiscount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.orange[700]),
              ),
            )
                : Text(
              '-',
              style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),

          // GST
          Container(
            width: columnWidths[6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              '${sale.gstPercentage}%',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
            ),
          ),

          // Grand Total
          Container(
            width: columnWidths[7],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                'PKR ${sale.grandTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
              ),
            ),
          ),

          // Amount Paid
          Container(
            width: columnWidths[8],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              'PKR ${sale.amountPaid.toStringAsFixed(0)}',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ),

          // Remaining Amount
          Container(
            width: columnWidths[9],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: sale.remainingAmount > 0
                ? Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Text(
                'PKR ${sale.remainingAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.red),
              ),
            )
                : Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                l10n.paid,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ),
          ),

          // Payment Method
          Container(
            width: columnWidths[10],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(sale.paymentMethod).withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPaymentMethodIcon(sale.paymentMethod), color: _getPaymentMethodColor(sale.paymentMethod), size: context.iconSize('small')),
                  SizedBox(width: context.smallPadding / 2),
                  Expanded(
                    child: Text(
                      _getLocalizedPaymentMethod(l10n, sale.paymentMethod),
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: _getPaymentMethodColor(sale.paymentMethod),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Date
          Container(
            width: columnWidths[11],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              sale.dateTimeText,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
            ),
          ),

          // Status
          Container(
            width: columnWidths[12],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(color: sale.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: sale.statusColor, shape: BoxShape.circle),
                  ),
                  SizedBox(width: context.smallPadding / 2),
                  Expanded(
                    child: Text(
                      _getLocalizedStatus(l10n, sale.status),
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: sale.statusColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            width: columnWidths[13],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _buildActions(context, sale),
          ),
        ],
      ),
    );
  }

  String _getLocalizedPaymentMethod(AppLocalizations l10n, String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return l10n.cash;
      case 'CARD':
        return l10n.card;
      case 'BANK_TRANSFER':
      case 'BANK TRANSFER':
        return l10n.bankTransfer;
      case 'MOBILE_PAYMENT':
      case 'MOBILE PAYMENT':
        return l10n.mobilePayment;
      case 'CREDIT':
        return l10n.credit;
      case 'SPLIT':
        return l10n.split;
      default:
        return method;
    }
  }

  String _getLocalizedStatus(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return l10n.draft;
      case 'CONFIRMED':
        return l10n.confirmed;
      case 'INVOICED':
        return l10n.invoiced;
      case 'ISSUED':
        return l10n.pending;
      case 'SENT':
        return l10n.unpaid;
      case 'PAID':
        return l10n.paid;
      case 'DELIVERED':
        return l10n.delivered;
      case 'CANCELLED':
        return l10n.cancelled;
      case 'RETURNED':
        return l10n.returned;
      default:
        return status;
    }
  }

  Widget _buildActions(BuildContext context, SaleModel sale) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onView(sale),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.visibility_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        if (widget.canEdit)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onEdit(sale),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.5),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.edit_outlined, color: Colors.orange, size: context.iconSize('small')),
              ),
            ),
          ),

        if (widget.canEdit) SizedBox(width: context.smallPadding / 2),

        // Print Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
              
              OrderModel? associatedOrder;
              if (sale.orderId != null && sale.orderId!.isNotEmpty) {
                associatedOrder = orderProvider.allOrders.where((o) => o.id == sale.orderId).firstOrNull;
              }
              
              CustomerModel? customer;
              if (sale.customerId != null && sale.customerId!.isNotEmpty) {
                customer = customerProvider.allCustomers.where((c) => c.id == sale.customerId).firstOrNull;
              }
              
              PdfInvoiceService.printInvoice(sale, associatedOrder: associatedOrder, customer: customer);
            },
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.print_outlined, color: Colors.green, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        if (widget.canDelete)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onDelete(sale),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding * 0.5),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
              ),
            ),
          ),

        if (!widget.canEdit && !widget.canDelete)
           Text(
            "View-only",
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.receipt_long_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noSalesRecordsFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.completeFirstSaleMessage,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'CARD':
        return Colors.blue;
      case 'BANK_TRANSFER':
      case 'BANK TRANSFER':
        return Colors.purple;
      case 'CREDIT':
        return Colors.orange;
      case 'SPLIT':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
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