import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/pdf_invoice_service.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_button.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/services/order_service.dart';
import '../../../src/services/order_item_service.dart';
import '../../../src/services/invoice_service.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/customer/customer_model.dart' as cm;
import '../../../src/providers/customer_provider.dart';

class ViewInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const ViewInvoiceDialog({super.key, required this.invoice});

  @override
  State<ViewInvoiceDialog> createState() => _ViewInvoiceDialogState();
}

class _ViewInvoiceDialogState extends State<ViewInvoiceDialog> {
  InvoiceModel? _detailedInvoice;
  bool _isSyncing = true;
  final InvoiceService _invoiceService = InvoiceService();

  @override
  void initState() {
    super.initState();
    _fetchDetailedInvoice();
  }

  Future<void> _fetchDetailedInvoice() async {
    try {
      final response = await _invoiceService.getInvoiceById(widget.invoice.id);
      if (response.success && response.data != null) {
        if (mounted) {
           setState(() {
             _detailedInvoice = response.data;
           });
           
           await _deepSyncAdditionalData();
        }
      } else {
        if (mounted) setState(() => _isSyncing = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _deepSyncAdditionalData() async {
     final invoice = _detailedInvoice ?? widget.invoice;
     final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
     final salesProvider = Provider.of<SalesProvider>(context, listen: false);
     
     final cId = invoice.customerId;
     if (cId != null && cId.isNotEmpty) {
        // fetchCustomerById is async - fetches from API and updates provider
        await customerProvider.fetchCustomerById(cId);
     }

     
     final sId = invoice.saleId;
     if (sId.isNotEmpty) {
        await salesProvider.getSaleById(sId);
     }
     
     if (mounted) {
        setState(() {
          _isSyncing = false;
        });
     }
  }

  Future<Uint8List> _generatePdfBytesForPreview(BuildContext context) async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    final effectiveInvoice = _detailedInvoice ?? widget.invoice;
    final String saleId = effectiveInvoice.saleId;
    
    SaleModel? resolvedSale;
    OrderModel? associatedOrderModel;
    Customer? resolvedCustomer;

    // 1. Resolve Sale
    try {
      if (saleId.isNotEmpty && saleId != effectiveInvoice.id) {
        resolvedSale = await salesProvider.getSaleById(saleId);
      }
      
      if (resolvedSale == null || resolvedSale.saleItems.isEmpty) {
         final invoiceNumToFind = effectiveInvoice.invoiceNumber.replaceAll('#', '');
         final matchingSales = salesProvider.sales.where((s) => s.invoiceNumber == invoiceNumToFind).toList();
         if (matchingSales.isNotEmpty) {
            resolvedSale = await salesProvider.getSaleById(matchingSales.first.id);
         }
      }
    } catch (e) {
      debugPrint('Error resolving sale: $e');
    }

    // 2. Resolve Order
    String finalOrderId = (effectiveInvoice.orderId?.isEmpty ?? true)
          ? effectiveInvoice.id 
          : (resolvedSale?.orderId ?? effectiveInvoice.id);
      
    if (finalOrderId == effectiveInvoice.id) {
       final matchingOrder = orderProvider.allOrders.where((o) => o.id == effectiveInvoice.orderId).firstOrNull;
       if (matchingOrder != null) finalOrderId = matchingOrder.id;
    }

    if (finalOrderId.isNotEmpty && finalOrderId != effectiveInvoice.id) {
        associatedOrderModel = await orderProvider.getOrderById(finalOrderId);
    }

    // 3. Resolve Customer
    String? finalCustomerId = (effectiveInvoice.customerId?.isEmpty ?? true)
          ? (resolvedSale?.customerId ?? '')
          : effectiveInvoice.customerId;

    if (finalCustomerId != null && finalCustomerId.isNotEmpty) {
      resolvedCustomer = await customerProvider.getCustomerById(finalCustomerId);
    }
    
    // 4. Resolve Display Name
    String displayName = (resolvedCustomer != null && resolvedCustomer!.name.isNotEmpty) 
          ? (resolvedCustomer!.businessName ?? resolvedCustomer!.name) 
          : (effectiveInvoice.customerName ?? 'Walk-in Customer');

    // Use business name if available (priority)
    if (resolvedCustomer != null) {
       if (resolvedCustomer!.businessName != null && resolvedCustomer!.businessName!.trim().isNotEmpty) {
          displayName = resolvedCustomer!.businessName!;
       } else {
          displayName = resolvedCustomer!.name;
       }
    } else if (resolvedSale?.customerName != null && resolvedSale!.customerName.isNotEmpty) {
       displayName = resolvedSale!.customerName;
    }

    // 5. Items Recovery (CRITICAL FIX FOR EMPTY COLUMNS)
    List<SaleItemModel> finalItems = [];
    
    // Attempt 1: Get from resolvedSale
    if (resolvedSale != null && (resolvedSale!.saleItems.isNotEmpty)) {
       finalItems = List.from(resolvedSale!.saleItems);
       debugPrint('✅ Found ${finalItems.length} items in resolvedSale');
    }
    
    // Attempt 2: Recover from Search by invoice number if still empty
    if (finalItems.isEmpty) {
       final invNum = effectiveInvoice.invoiceNumber.replaceAll('#', '').trim();
       final match = salesProvider.sales.where((s) => s.invoiceNumber == invNum).firstOrNull;
       if (match != null && match.saleItems.isNotEmpty) {
         finalItems = List.from(match.saleItems);
         debugPrint('✅ Recovered ${finalItems.length} items from sales list match');
       }
    }

    // Attempt 3: Recover from Order Items (LAST RESORT)
    if (finalItems.isEmpty && (associatedOrderModel != null || effectiveInvoice.orderId != null)) {
       final oId = associatedOrderModel?.id ?? effectiveInvoice.orderId ?? '';
       if (oId.isNotEmpty) {
         debugPrint('🔍 Attempting recovery from Order ID: $oId');
         try {
           final orderItemsRes = await OrderItemService().getOrderItemsByOrder(oId);
           if (orderItemsRes.success && orderItemsRes.data != null && orderItemsRes.data!.orderItems.isNotEmpty) {
              finalItems = orderItemsRes.data!.orderItems.map((oi) => SaleItemModel(
                  id: oi.id,
                  saleId: saleId.isEmpty ? effectiveInvoice.id : saleId,
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
              debugPrint('✅ Recovered ${finalItems.length} items from Order Items API');
           }
         } catch(e) {
           debugPrint('❌ Items recovery from order failed: $e');
         }
       }
    }
    
    debugPrint('📊 Final items count for PDF: ${finalItems.length}');
    if (finalItems.isNotEmpty) {
      debugPrint('📦 First item: ${finalItems.first.productName} x ${finalItems.first.quantity}');
    }

    // 6. Build Final Sale Object for PDF
    final saleForPdf = SaleModel(
      id: (resolvedSale?.id ?? saleId).isNotEmpty ? (resolvedSale?.id ?? saleId) : effectiveInvoice.id,
      invoiceNumber: effectiveInvoice.invoiceNumber.replaceAll('#', ''),
      orderId: associatedOrderModel?.id ?? effectiveInvoice.orderId,
      customerId: finalCustomerId,
      customerName: displayName,
      customerPhone: resolvedCustomer?.phone ?? effectiveInvoice.customerPhone ?? '',
      customerEmail: resolvedCustomer?.email ?? '',
      subtotal: effectiveInvoice.totalAmount,
      overallDiscount: effectiveInvoice.totalAmount - effectiveInvoice.grandTotal,
      taxConfiguration: TaxConfiguration(),
      gstPercentage: 0,
      taxAmount: 0,
      grandTotal: effectiveInvoice.grandTotal,
      amountPaid: effectiveInvoice.amountPaid,
      remainingAmount: effectiveInvoice.amountDue,
      isFullyPaid: effectiveInvoice.status.toUpperCase() == 'PAID',
      paymentMethod: resolvedSale?.paymentMethod ?? 'CASH',
      dateOfSale: effectiveInvoice.issueDate,
      status: effectiveInvoice.status,
      notes: effectiveInvoice.notes,
      isActive: true,
      createdAt: effectiveInvoice.createdAt,
      updatedAt: effectiveInvoice.updatedAt,
      saleItems: finalItems, 
    );

    try {
      return await PdfInvoiceService.generatePdfBytes(
        saleForPdf,
        associatedOrder: associatedOrderModel,
        customer: resolvedCustomer,
      );
    } catch (e) {
      debugPrint('❌ Fatal PDf Generation Error: $e');
      // Final fallback to avoid non-nullable return error
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Dialog(
      insetPadding: EdgeInsets.all(isDesktop ? 50 : 10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 75.w : 95.w,
        height: 90.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Preview',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isSyncing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Resolving Data...',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : PdfPreview(
                      build: (format) => _generatePdfBytesForPreview(context),
                      useActions: true,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      allowPrinting: true,
                      allowSharing: true,
                      padding: const EdgeInsets.all(10),
                      pdfFileName: 'Invoice_${widget.invoice.invoiceNumber}.pdf',
                      loadingWidget: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PremiumButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'Close',
                    width: 100,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
