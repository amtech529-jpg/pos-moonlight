import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:open_file/open_file.dart';
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

class ViewInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const ViewInvoiceDialog({super.key, required this.invoice});

  @override
  State<ViewInvoiceDialog> createState() => _ViewInvoiceDialogState();
}

class _ViewInvoiceDialogState extends State<ViewInvoiceDialog> {
  bool _isPrinting = false;
  bool _isGeneratingPdf = false;

  Future<void> _printInvoice() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      debugPrint('🖨️ [ViewInvoiceDialog] Print Invoice requested for ${widget.invoice.invoiceNumber}');
      
      // Use SalesProvider with the working receipt generation (but will show invoice data)
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      
      debugPrint('🔍 [ViewInvoiceDialog] Calling SalesProvider.generateReceiptPdf with saleId: ${widget.invoice.saleId}');
      
      // Use the working receipt generation - it will show the sale data which includes invoice info
      final success = await salesProvider.generateReceiptPdf(widget.invoice.saleId);
      
      debugPrint('🔍 [ViewInvoiceDialog] generateReceiptPdf result: $success');
      
      if (mounted) {
        if (success) {
          debugPrint('✅ [ViewInvoiceDialog] Invoice print successful');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Invoice sent to printer/saved"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          debugPrint('❌ [ViewInvoiceDialog] Invoice print failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Failed to generate invoice"),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [ViewInvoiceDialog] Invoice print error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text("Error: $e"),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _generatePdfInvoice() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      debugPrint('📄 [ViewInvoiceDialog] Generating PDF for invoice: ${widget.invoice.invoiceNumber}');
      
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      
      String saleId = widget.invoice.saleId;
      if (saleId.isEmpty) {
        debugPrint('⚠️ [ViewInvoiceDialog] Sale ID is empty. Checking fallback to Invoice ID...');
        saleId = widget.invoice.id;
      }

      SaleModel? sale;
      try {
        debugPrint('🔍 [ViewInvoiceDialog] Fetching Sale Details for ID: $saleId');
        if (saleId.isNotEmpty && saleId != widget.invoice.id) {
          sale = await salesProvider.getSaleById(saleId);
        }
      } catch (e) {
        debugPrint('❌ [ViewInvoiceDialog] API Fetch failed: $e');
      }
      
      if (sale == null) {
        bool orderFetched = false;
        
        String? effectiveOrderId = (widget.invoice.orderId != null && widget.invoice.orderId!.isNotEmpty) 
            ? widget.invoice.orderId 
            : widget.invoice.id;

        if (effectiveOrderId != null && effectiveOrderId.isNotEmpty) {
          debugPrint('⚠️ [ViewInvoiceDialog] Sale not found. Fetching Order details for ID: $effectiveOrderId');
          try {
            final orderRes = await OrderService().getOrderById(effectiveOrderId);

            if (orderRes.success && orderRes.data != null) {
              final order = orderRes.data!;
              final itemsRes = await OrderItemService().getOrderItemsByOrder(order.id);
              
              List<SaleItemModel> mappedItems = [];
              if (itemsRes.success && itemsRes.data != null) {
                final orderItems = itemsRes.data!.orderItems;
                mappedItems = orderItems.map((orderItem) => SaleItemModel(
                  id: orderItem.id,
                  saleId: widget.invoice.saleId,
                  orderItemId: orderItem.id,
                  productId: orderItem.productId,
                  productName: orderItem.productName,
                  unitPrice: orderItem.rate,
                  quantity: orderItem.quantity,
                  days: orderItem.days,
                  pricingType: 'PER_DAY',
                  itemDiscount: 0.0,
                  lineTotal: orderItem.lineTotal,
                  customizationNotes: orderItem.customizationNotes,
                  isActive: orderItem.isActive,
                  createdAt: orderItem.createdAt,
                  updatedAt: orderItem.updatedAt ?? orderItem.createdAt,
                )).toList();
              }
              
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
              orderFetched = true;
            }
          } catch (e) {
            debugPrint('❌ [ViewInvoiceDialog] Failed to fetch order items: $e');
          }
        }
        
        if (!orderFetched) {
          sale = SaleModel(
            id: widget.invoice.saleId,
            invoiceNumber: widget.invoice.invoiceNumber,
            dateOfSale: widget.invoice.issueDate,
            customerName: widget.invoice.customerName,
            customerPhone: 'SUMMARY (items not found)',
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
            notes: '(Note: Detailed items not found)\n${widget.invoice.notes ?? ""}',
            isActive: widget.invoice.isActive,
            createdAt: widget.invoice.createdAt,
            updatedAt: widget.invoice.updatedAt,
            createdBy: widget.invoice.createdBy,
            saleItems: [], 
          );
        }
      }

      if (sale != null) {
        await PdfInvoiceService.printInvoice(sale);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _printPdfInvoice() async {
    try {
      debugPrint('🖨️ [ViewInvoiceDialog] Printing PDF for invoice: ${widget.invoice.invoiceNumber}');
      
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      String saleId = widget.invoice.saleId;
      if (saleId.isEmpty) {
        saleId = widget.invoice.id;
      }

      SaleModel? sale;
      try {
        if (saleId.isNotEmpty && saleId != widget.invoice.id) {
          sale = await salesProvider.getSaleById(saleId);
        }
      } catch (_) {}

      if (sale == null) {
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

      if (sale != null) {
        await PdfInvoiceService.printInvoice(sale);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Thermal Receipt Header ---
                  _buildThermalHeader(),
                  const SizedBox(height: 20),
                  
                  // --- Invoice Details ---
                  _buildThermalDivider(),
                  _buildThermalSectionTitle('INVOICE'),
                  _buildThermalDivider(),
                  const SizedBox(height: 10),
                  
                  _buildThermalRow('Invoice #', widget.invoice.invoiceNumber),
                  if (widget.invoice.saleInvoiceNumber.isNotEmpty)
                    _buildThermalRow('Ref #', widget.invoice.saleInvoiceNumber),
                  _buildThermalRow('Customer', widget.invoice.customerName),
                  _buildThermalRow('Date', widget.invoice.formattedIssueDate),
                  if (widget.invoice.dueDate != null) _buildThermalRow('Due Date', widget.invoice.formattedDueDate),
                  _buildThermalRow('Status', widget.invoice.statusDisplay),
                  _buildThermalDivider(),
                  _buildThermalRow('Total Amount', 'PKR ${widget.invoice.grandTotal.toStringAsFixed(2)}'),
                  _buildThermalRow('Amount Paid', 'PKR ${widget.invoice.amountPaid.toStringAsFixed(2)}'),
                  if (widget.invoice.writeOffAmount > 0)
                    _buildThermalRow('Write-Off', 'PKR ${widget.invoice.writeOffAmount.toStringAsFixed(2)}'),
                  _buildThermalRow('Balance Due', 'PKR ${widget.invoice.amountDue.toStringAsFixed(2)}', isBold: true),
                  _buildThermalDivider(),
                  const SizedBox(height: 20),
                  
                  // --- Notes Section ---
                  if (widget.invoice.notes?.isNotEmpty == true) ...[
                    _buildThermalSectionTitle('NOTES'),
                    _buildThermalDivider(),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        widget.invoice.notes!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildThermalDivider(),
                    const SizedBox(height: 20),
                  ],
                  
                  // --- Footer ---
                  _buildThermalFooter(),
                  const SizedBox(height: 20),
                  
                  // --- Status Badge ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.invoice.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.invoice.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.invoice.statusDisplay,
                      style: TextStyle(
                        color: widget.invoice.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Generate PDF Button
                      PremiumButton(
                        text: _isGeneratingPdf ? "Generating..." : "PDF",
                        onPressed: _isGeneratingPdf ? null : _generatePdfInvoice,
                        backgroundColor: Colors.red,
                        width: 80,
                      ),
                      
                      // Print PDF Button
                      PremiumButton(
                        text: "Print PDF",
                        onPressed: _printPdfInvoice,
                        backgroundColor: Colors.green,
                        width: 80,
                      ),
                      
                      // Original Print Button
                      PremiumButton(
                        text: _isPrinting ? "Printing..." : "Print",
                        onPressed: _isPrinting ? null : _printInvoice,
                        backgroundColor: Colors.purple,
                        width: 80,
                      ),
                      
                      // Close Button
                      PremiumButton(
                        text: l10n.close ?? "Close",
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                        width: 80,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThermalHeader() {
    return Column(
      children: [
        // Company Name/Logo placeholder
        Text(
          'INVOICE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Moon Light Events',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildThermalSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildThermalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isBold ? Colors.black : Colors.black54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isBold ? Colors.black : Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalDivider() {
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            40,
            (index) => Expanded(
              child: Container(
                height: 1,
                color: index % 2 == 0 ? Colors.black26 : Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildThermalFooter() {
    return Column(
      children: [
        _buildThermalDivider(),
        const SizedBox(height: 10),
        Text(
          'Thank you for your business!',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This is a computer-generated invoice',
          style: TextStyle(
            fontSize: 8,
            color: Colors.black38,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

}
