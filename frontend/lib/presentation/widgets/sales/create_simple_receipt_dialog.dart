import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/globals/text_field.dart'; // ✅ PremiumTextField
import '../../widgets/globals/text_button.dart'; // ✅ PremiumButton

class CreateSimpleReceiptDialog extends StatefulWidget {
  final String? initialSaleId;
  final bool isViewOnly;
  
  const CreateSimpleReceiptDialog({
    super.key,
    this.initialSaleId,
    this.isViewOnly = false,
  });

  @override
  State<CreateSimpleReceiptDialog> createState() => _CreateSimpleReceiptDialogState();
}

class _CreateSimpleReceiptDialogState extends State<CreateSimpleReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedSaleId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSaleId = widget.initialSaleId;
    _isLoading = true;
    // Load sales data when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final salesProvider = context.read<SalesProvider>();
      final receiptProvider = context.read<ReceiptProvider>();
      
      // Load all sales pages to find eligible ones
      debugPrint('🔍 [ReceiptDialog] Loading all sales to find eligible ones...');
      await salesProvider.loadAllSales();
      debugPrint('🔍 [ReceiptDialog] Total sales loaded: ${salesProvider.sales.length}');
      
      // Clear filters and load all receipts
      receiptProvider.clearFilters();
      receiptProvider.loadReceipts(refresh: true);
      
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.createReceipt ?? "Create Receipt",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Content in Expanded to prevent overflow ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Sale Selection ---
                        Text(
                          l10n.selectSale ?? "Select Sale",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Consumer2<SalesProvider, ReceiptProvider>(
                          builder: (context, salesProvider, receiptProvider, child) {
                            debugPrint('🔍 [ReceiptDialog] SalesProvider state: isLoading=${salesProvider.isLoading}, salesCount=${salesProvider.sales.length}');
                            debugPrint('🔍 [ReceiptDialog] ReceiptProvider state: isLoading=${receiptProvider.isLoading}, receiptsCount=${receiptProvider.receipts.length}');
                            debugPrint('🔍 [ReceiptDialog] ReceiptProvider error: ${receiptProvider.error}');
                            debugPrint('🔍 [ReceiptDialog] ReceiptProvider success: ${receiptProvider.success}');
                            
                            // Show loading if either provider is loading
                            if (salesProvider.isLoading || receiptProvider.isLoading || salesProvider.sales.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Loading data...'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            // Filter sales that have payments (amount_paid > 0) and don't already have receipts
                            final paidSales = salesProvider.sales
                                .where((sale) => sale.amountPaid > 0)
                                .toList();
                            
                            debugPrint('🔍 [ReceiptDialog] Total paid sales: ${paidSales.length}');
                            
                            // Debug: Print all sales with their receipt status
                            for (var sale in paidSales) {
                              final hasReceipt = receiptProvider.receipts.any((receipt) => receipt.saleId == sale.id);
                              debugPrint('🔍 [ReceiptDialog] Sale ${sale.invoiceNumber} (${sale.id.substring(0, 8)}...) - Has receipt: $hasReceipt');
                            }
                            
                            final eligibleSales = paidSales
                                .where((sale) => !receiptProvider.receipts.any((receipt) => receipt.saleId == sale.id))
                                .toList();
                            
                            // Remove duplicates by sale ID
                            final uniqueSales = <String, SaleModel>{};
                            for (final sale in eligibleSales) {
                              uniqueSales[sale.id] = sale;
                            }
                            final finalEligibleSales = uniqueSales.values.toList();
                            
                            debugPrint('🔍 [ReceiptDialog] Paid sales without receipts: ${finalEligibleSales.length}');
                            
                            if (finalEligibleSales.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No eligible sales found. All paid sales already have receipts.',
                                        style: TextStyle(color: Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedSaleId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: l10n.selectSale ?? "Select Sale",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                              dropdownColor: Colors.white,
                              items: finalEligibleSales.map((sale) {
                                return DropdownMenuItem(
                                  value: sale.id,
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 40),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${sale.invoiceNumber} - ${sale.customerName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          'Paid: PKR ${sale.grandTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: sale.amountPaid >= sale.grandTotal ? Colors.green : Colors.orange,
                                            fontSize: 8,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSaleId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.pleaseSelectASale ?? "Please select a sale";
                                }
                                return null;
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        PremiumTextField(
                          controller: _notesController,
                          label: l10n.notes ?? "Notes",
                          hint: "Enter receipt notes (optional)",
                          maxLines: 3,
                          validator: (value) {
                            return null;
                          },
                        ),

                        // --- Receipt Preview ---
                        if (_selectedSaleId != null)
                          Consumer<SalesProvider>(
                            builder: (context, salesProvider, child) {
                              final selectedSale = salesProvider.sales.firstWhere(
                                (sale) => sale.id == _selectedSaleId,
                                orElse: () => SaleModel(
                                  id: '',
                                  invoiceNumber: '',
                                  customerName: '',
                                  customerPhone: '',
                                  subtotal: 0,
                                  overallDiscount: 0,
                                  taxConfiguration: TaxConfiguration(taxes: {}),
                                  gstPercentage: 0,
                                  taxAmount: 0,
                                  grandTotal: 0,
                                  amountPaid: 0,
                                  remainingAmount: 0,
                                  isFullyPaid: false,
                                  paymentMethod: '',
                                  dateOfSale: DateTime.now(),
                                  status: '',
                                  isActive: true,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  saleItems: [],
                                ),
                              );

                              if (selectedSale.id.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long, color: AppTheme.primaryMaroon),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Receipt Preview',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryMaroon,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPreviewRow('Invoice Number', selectedSale.invoiceNumber),
                                    _buildPreviewRow('Customer', selectedSale.customerName),
                                    _buildPreviewRow('Date', _formatDate(selectedSale.dateOfSale.toIso8601String())),
                                    _buildPreviewRow('Payment Method', selectedSale.paymentMethod),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    _buildPreviewRow('Grand Total', _formatCurrency(selectedSale.grandTotal.toString())),
                                    _buildPreviewRow('Amount Paid', _formatCurrency(selectedSale.amountPaid.toString())),
                                    if (selectedSale.grandTotal != selectedSale.amountPaid)
                                      _buildPreviewRow('Balance', _formatCurrency(
                                        (selectedSale.amountPaid - selectedSale.grandTotal).toString()
                                      )),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Action Buttons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel ?? "Cancel"),
                    ),
                    const SizedBox(width: 12),
                    PremiumButton(
                      text: l10n.createReceipt ?? "Create Receipt",
                      onPressed: _isLoading ? null : _createSimpleReceipt,
                      isLoading: _isLoading,
                      icon: Icons.receipt_long,
                      backgroundColor: Theme.of(context).primaryColor,
                      width: 140,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createSimpleReceipt() async {
    if (!_formKey.currentState!.validate() || _selectedSaleId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = context.read<ReceiptProvider>();
      final salesProvider = context.read<SalesProvider>();
      
      final success = await receiptProvider.createSimpleReceipt(
        saleId: _selectedSaleId!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (success) {
        // Refresh sales data to update receipt status
        await salesProvider.loadSales(refresh: true);
        // Also refresh receipts to show the new one
        await receiptProvider.loadReceipts(refresh: true);
        
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog('Receipt created successfully!');
        }
      } else {
        if (mounted) {
          final errorMessage = receiptProvider.error ?? 'Failed to create receipt';
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
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
}
