import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/pdf_invoice_service.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_button.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/services/order_service.dart';
import '../../../src/services/order_item_service.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/providers/order_provider.dart';

class ViewInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const ViewInvoiceDialog({super.key, required this.invoice});

  @override
  State<ViewInvoiceDialog> createState() => _ViewInvoiceDialogState();
}

class _ViewInvoiceDialogState extends State<ViewInvoiceDialog> {
  Future<Uint8List> _generatePdfBytesForPreview() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    String saleId = widget.invoice.saleId;
    if (saleId.isEmpty) saleId = widget.invoice.id;

    SaleModel? sale;
    try {
      if (saleId.isNotEmpty && saleId != widget.invoice.id) {
        sale = await salesProvider.getSaleById(saleId);
      }
    } catch (_) {}

    // If sale was found but has no items, OR if sale wasn't found - try to enrich/fetch from Order
    bool hasItems = sale != null && sale.saleItems.isNotEmpty;
    
    if (!hasItems) {
      String? effectiveOrderId = (widget.invoice.orderId != null && widget.invoice.orderId!.isNotEmpty) 
          ? widget.invoice.orderId 
          : widget.invoice.id;

      if (effectiveOrderId != null && effectiveOrderId.isNotEmpty) {
        try {
          final orderRes = await OrderService().getOrderById(effectiveOrderId);
          if (orderRes.success && orderRes.data != null) {
            final order = orderRes.data!;
            final itemsRes = await OrderItemService().getOrderItemsByOrder(order.id);
            
            List<SaleItemModel> mappedItems = [];
            if (itemsRes.success && itemsRes.data != null) {
              mappedItems = itemsRes.data!.orderItems.map((oi) => SaleItemModel(
                id: oi.id,
                saleId: widget.invoice.saleId,
                orderItemId: oi.id,
                productId: oi.productId,
                productName: oi.productName,
                unitPrice: oi.rate,
                quantity: oi.quantity,
                days: oi.days,
                pricingType: 'PER_DAY',
                itemDiscount: 0.0,
                lineTotal: oi.lineTotal,
                customizationNotes: oi.customizationNotes,
                isActive: oi.isActive,
                createdAt: oi.createdAt,
                updatedAt: oi.updatedAt ?? oi.createdAt,
              )).toList();
            }
            
            if (sale != null) {
              // Enrich existing sale with order details if items were missing
              sale = sale.copyWith(
                saleItems: mappedItems,
                customerPhone: order.eventLocation ?? sale.customerPhone,
                notes: order.eventName ?? sale.notes,
              );
            } else {
              // Create new temporary sale from order
              sale = SaleModel(
                id: widget.invoice.saleId,
                invoiceNumber: widget.invoice.invoiceNumber,
                dateOfSale: widget.invoice.issueDate,
                customerName: widget.invoice.customerName,
                customerPhone: order.eventLocation ?? 'Unknown Location',
                subtotal: widget.invoice.grandTotal,
                overallDiscount: 0.0,
                taxConfiguration: TaxConfiguration(),
                gstPercentage: 0.0,
                taxAmount: 0.0,
                grandTotal: widget.invoice.grandTotal,
                amountPaid: widget.invoice.amountPaid,
                remainingAmount: widget.invoice.amountDue,
                isFullyPaid: widget.invoice.status == 'PAID' || widget.invoice.amountDue <= 0,
                paymentMethod: 'CASH',
                status: widget.invoice.status,
                notes: order.eventName ?? 'Unknown Event',
                isActive: widget.invoice.isActive,
                createdAt: widget.invoice.createdAt,
                updatedAt: widget.invoice.updatedAt,
                createdBy: widget.invoice.createdBy,
                saleItems: mappedItems,
              );
            }
          }
        } catch (_) {}
      }
      
      if (sale == null) {
        sale = SaleModel(
          id: widget.invoice.saleId,
          invoiceNumber: widget.invoice.invoiceNumber,
          dateOfSale: widget.invoice.issueDate,
          customerName: widget.invoice.customerName,
          customerPhone: 'SUMMARY',
          subtotal: widget.invoice.grandTotal,
          overallDiscount: 0.0,
          taxConfiguration: TaxConfiguration(),
          gstPercentage: 0.0,
          taxAmount: 0.0,
          grandTotal: widget.invoice.grandTotal,
          amountPaid: widget.invoice.amountPaid,
          remainingAmount: widget.invoice.amountDue,
          isFullyPaid: widget.invoice.status == 'PAID' || widget.invoice.amountDue <= 0,
          paymentMethod: 'CASH',
          status: widget.invoice.status,
          notes: widget.invoice.notes ?? "",
          isActive: widget.invoice.isActive,
          createdAt: widget.invoice.createdAt,
          updatedAt: widget.invoice.updatedAt,
          createdBy: widget.invoice.createdBy,
          saleItems: [],
        );
      }
    }

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    String? customerId = sale.customerId ?? widget.invoice.customerId;
    if (customerId == null && widget.invoice.orderId != null) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final matchingOrder = orderProvider.allOrders.where((o) => o.id == widget.invoice.orderId).firstOrNull;
      if (matchingOrder != null) {
        customerId = matchingOrder.customerId;
      }
    }
    final customer = customerProvider.allCustomers.where((c) => c.id == customerId).firstOrNull;
    final displayName = customer?.orderDisplayName ?? sale.customerName;
    
    final patchedSale = sale.copyWith(customerName: displayName);
    return await PdfInvoiceService.generatePdfBytes(patchedSale);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 850,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.primaryMaroon),
                      const SizedBox(width: 10),
                      Text(
                        "Invoice Preview", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryMaroon)
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // PDF Preview
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: PdfPreview(
                  build: (format) => _generatePdfBytesForPreview(),
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  padding: const EdgeInsets.all(10),
                  pdfFileName: 'Invoice_${widget.invoice.invoiceNumber}.pdf',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
