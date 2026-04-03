import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/services/receipt_service.dart';
import '../../widgets/globals/text_button.dart';

class ViewReceiptDialog extends StatefulWidget {
  final SaleModel sale;

  const ViewReceiptDialog({super.key, required this.sale});

  @override
  State<ViewReceiptDialog> createState() => _ViewReceiptDialogState();
}

class _ViewReceiptDialogState extends State<ViewReceiptDialog> {
  bool _isLoading = true;
  ReceiptModel? _receipt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    try {
      final receiptProvider = context.read<ReceiptProvider>();
      
      // Find receipt for this sale
      final receipts = receiptProvider.receipts;
      final receipt = receipts.firstWhere(
        (r) => r.saleId == widget.sale.id,
        orElse: () => ReceiptModel(
          id: '',
          saleId: widget.sale.id,
          saleInvoiceNumber: widget.sale.invoiceNumber,
          customerName: widget.sale.customerName,
          paymentId: '',
          paymentAmount: widget.sale.amountPaid,
          paymentMethod: widget.sale.paymentMethod,
          receiptNumber: 'N/A',
          generatedAt: widget.sale.dateOfSale,
          status: 'NOT_GENERATED',
          emailSent: false,
          isActive: true,
          createdAt: widget.sale.createdAt,
          updatedAt: widget.sale.updatedAt,
          notes: 'No receipt created yet',
        ),
      );

      setState(() {
        _receipt = receipt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load receipt: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.primaryMaroon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receipt Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!),
                  ],
                ),
              )
            else
              _buildReceiptContent(),

            // Actions
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => _printReceipt(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Print',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: AppTheme.primaryMaroon,
          ),
          const SizedBox(height: 16),
          Text(
            'Receipt Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Invoice: ${widget.sale.invoiceNumber}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            'Customer: ${widget.sale.customerName}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          
          // Show correct financial details - calculate from sale items if needed
          _buildReceiptRow('Subtotal:', _formatCurrency(_calculateSubtotal().toString())),
          _buildReceiptRow('Discount:', _formatCurrency(_calculateDiscount().toString())),
          _buildReceiptRow('Grand Total:', _formatCurrency(_calculateGrandTotal().toString()), isBold: true),
          _buildReceiptRow('Amount Paid:', _formatCurrency(widget.sale.amountPaid.toString())),
          _buildReceiptRow('Balance:', _formatCurrency(_calculateBalance().toString())),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  'Click "Print" to generate receipt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // Calculate correct values from sale items
  double _calculateSubtotal() {
    debugPrint('🔍 [ViewReceiptDialog] Calculating subtotal from ${widget.sale.saleItems.length} sale items');
    double subtotal = 0.0;
    for (var item in widget.sale.saleItems) {
      debugPrint('🔍 [ViewReceiptDialog] Item: ${item.productName}, Qty: ${item.quantity}, Price: ${item.unitPrice}');
      subtotal += (item.unitPrice * item.quantity);
    }
    debugPrint('🔍 [ViewReceiptDialog] Calculated subtotal: $subtotal');
    debugPrint('🔍 [ViewReceiptDialog] Original sale.subtotal: ${widget.sale.subtotal}');
    return subtotal;
  }
  
  double _calculateDiscount() {
    debugPrint('🔍 [ViewReceiptDialog] Overall discount: ${widget.sale.overallDiscount}');
    return widget.sale.overallDiscount;
  }
  
  double _calculateGrandTotal() {
    double grandTotal = _calculateSubtotal() - _calculateDiscount();
    debugPrint('🔍 [ViewReceiptDialog] Calculated grand total: $grandTotal');
    debugPrint('🔍 [ViewReceiptDialog] Original sale.grandTotal: ${widget.sale.grandTotal}');
    return grandTotal;
  }
  
  double _calculateBalance() {
    double balance = _calculateGrandTotal() - widget.sale.amountPaid;
    debugPrint('🔍 [ViewReceiptDialog] Amount paid: ${widget.sale.amountPaid}');
    debugPrint('🔍 [ViewReceiptDialog] Calculated balance: $balance');
    debugPrint('🔍 [ViewReceiptDialog] Original sale.remainingAmount: ${widget.sale.remainingAmount}');
    return balance;
  }

  Widget _buildDottedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              margin: EdgeInsets.only(right: index % 2 == 0 ? 2 : 0),
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThermalHeader() {
    return Column(
      children: [
        Text(
          'Moon Light Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'RECEIPT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invoice: ${widget.sale.invoiceNumber}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          _formatDate(widget.sale.dateOfSale.toIso8601String()),
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildThermalCustomerInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer: ${widget.sale.customerName}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          if (widget.sale.customerPhone.isNotEmpty)
            Text(
              'Phone: ${widget.sale.customerPhone}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThermalItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items: ${widget.sale.totalItems}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Show actual sale items
          ...widget.sale.saleItems.map((item) => _buildThermalItem(item)),
        ],
      ),
    );
  }

  Widget _buildThermalItem(SaleItemModel item) {
    final itemTotal = (item.quantity * item.unitPrice) - item.itemDiscount;
    final itemName = item.productName.length > 25 
        ? '${item.productName.substring(0, 25)}...'
        : item.productName;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.quantity} x ${_formatCurrency(item.unitPrice.toString())}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                ),
              ),
              Text(
                _formatCurrency(itemTotal.toString()),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          if (item.itemDiscount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '  Discount:',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.red,
                  ),
                ),
                Text(
                  '-${_formatCurrency(item.itemDiscount.toString())}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildThermalSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal:', _formatCurrency(widget.sale.subtotal.toString())),
          if (widget.sale.overallDiscount > 0)
            _buildSummaryRow('Discount:', _formatCurrency(widget.sale.overallDiscount.toString())),
          if (widget.sale.taxAmount > 0)
            _buildSummaryRow('Tax:', _formatCurrency(widget.sale.taxAmount.toString())),
          _buildDottedLine(),
          _buildSummaryRow(
            'Total:',
            _formatCurrency(widget.sale.grandTotal.toString()),
            isBold: true,
          ),
          _buildSummaryRow(
            'Paid:',
            _formatCurrency(widget.sale.amountPaid.toString()),
          ),
          if (widget.sale.grandTotal != widget.sale.amountPaid)
            _buildSummaryRow(
              'Balance:',
              _formatCurrency((widget.sale.amountPaid - widget.sale.grandTotal).toString()),
            ),
          _buildSummaryRow(
            'Payment:',
            widget.sale.paymentMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildThermalFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'Thank you for your purchase!',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please visit again',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 11 : 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 11 : 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(String amount) {
    try {
      final value = double.parse(amount);
      return 'PKR ${value.toStringAsFixed(2)}';
    } catch (e) {
      return 'PKR $amount';
    }
  }

  void _printReceipt() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      
      // Show loading state
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating receipt for printing...')),
        );
      }

      // Use SalesProvider to generate and print the receipt
      final salesProvider = context.read<SalesProvider>();
      final success = await salesProvider.generateReceiptPdf(widget.sale.id);
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt sent to printer successfully!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to print receipt')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing receipt: $e')),
        );
      }
    }
  }
}
