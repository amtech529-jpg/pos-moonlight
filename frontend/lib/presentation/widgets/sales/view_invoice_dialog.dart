import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _directPrint() async {
    if (_isSyncing) return;
    
    try {
      final bytes = await _generatePdfBytesForPreview(context);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Invoice_${widget.invoice.invoiceNumber}',
      );
    } catch (e) {
      if (kDebugMode) print('Error printing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open print dialog.')),
      );
    }
  }

  Future<void> _openExternally() async {
    try {
      final bytes = await _generatePdfBytesForPreview(context);
      if (bytes.isEmpty) return;
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Invoice_${widget.invoice.invoiceNumber.replaceAll('#', '')}.pdf');
      await file.writeAsBytes(bytes);
      
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open in web view: $e'), backgroundColor: Colors.red),
        );
      }
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

    if (resolvedCustomer != null) {
       if (resolvedCustomer!.businessName != null && resolvedCustomer!.businessName!.trim().isNotEmpty) {
          displayName = resolvedCustomer!.businessName!;
       } else {
          displayName = resolvedCustomer!.name;
       }
    } else if (resolvedSale?.customerName != null && resolvedSale!.customerName.isNotEmpty) {
       displayName = resolvedSale!.customerName;
    }

    // 5. Items Recovery
    List<SaleItemModel> finalItems = [];
    if (resolvedSale != null && (resolvedSale!.saleItems.isNotEmpty)) {
       finalItems = List.from(resolvedSale!.saleItems);
    }
    
    if (finalItems.isEmpty) {
       final invNum = effectiveInvoice.invoiceNumber.replaceAll('#', '').trim();
       final match = salesProvider.sales.where((s) => s.invoiceNumber == invNum).firstOrNull;
       if (match != null && match.saleItems.isNotEmpty) {
         finalItems = List.from(match.saleItems);
       }
    }

    if (finalItems.isEmpty && (associatedOrderModel != null || effectiveInvoice.orderId != null)) {
       final oId = associatedOrderModel?.id ?? effectiveInvoice.orderId ?? '';
       if (oId.isNotEmpty) {
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
           }
         } catch(e) {}
       }
    }
    
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
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Compact Professional Header
          Container(
            padding: EdgeInsets.only(
              left: 20, 
              right: 20, 
              top: MediaQuery.of(context).padding.top + 8, 
              bottom: 8
            ),
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Invoice: ${widget.invoice.invoiceNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _isSyncing ? null : _directPrint,
                      icon: const Icon(Icons.print_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        "PRINT",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Preview Area (Maximized & Scaled)
          Expanded(
            child: _isSyncing
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    color: const Color(0xFF1A1A1A), 
                    child: PdfPreview(
                        build: (format) => _generatePdfBytesForPreview(context),
                        useActions: false,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        allowPrinting: true,
                        allowSharing: true,
                        initialPageFormat: PdfPageFormat.a4,
                        maxPageWidth: 710, 
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                        pdfFileName: 'Invoice_${widget.invoice.invoiceNumber}.pdf',
                        loadingWidget: const Center(child: CircularProgressIndicator()),
                      ),
                  ),
          ),
        ],
      ),
    );
  }
}
