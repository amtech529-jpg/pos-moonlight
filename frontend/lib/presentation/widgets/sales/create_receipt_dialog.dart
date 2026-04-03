import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/globals/text_field.dart'; // ✅ PremiumTextField

class CreateReceiptDialog extends StatefulWidget {
  const CreateReceiptDialog({super.key});

  @override
  State<CreateReceiptDialog> createState() => _CreateReceiptDialogState();
}

class _CreateReceiptDialogState extends State<CreateReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedSaleId;
  String? _selectedPaymentId;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentProvider = context.watch<PaymentProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500, // Fixed width helps dialog layout
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // ✅ Fix 1: Prevent Overflow
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ Fix 2: Shrink wrap height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  children: [
                    Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.createNewReceipt,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 1. Select Sale ---
                Consumer<SalesProvider>(
                  builder: (context, salesProvider, child) {
                    if (salesProvider.sales.isEmpty) {
                      return Text(l10n.noSalesAvailable);
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedSaleId,
                      isExpanded: true, // ✅ Fix 3: Avoid width overflow
                      decoration: InputDecoration(
                        labelText: l10n.selectSaleRequired,
                        border: const OutlineInputBorder(),
                        hintText: l10n.chooseASaleToCreateReceiptFor,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: salesProvider.sales.map((sale) {
                        return DropdownMenuItem(
                          value: sale.id,
                          child: Text(
                            '${sale.invoiceNumber} - ${sale.customerName} (PKR ${sale.grandTotal.toStringAsFixed(2)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSaleId = value;
                          _selectedPaymentId = null; // Reset payment when sale changes
                        });

                        // Load payments for this sale
                        if (value != null) {
                          context.read<PaymentProvider>().getPaymentsBySale(value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseSelectASale;
                        }
                        return null;
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // --- 2. Select Payment (Only if Sale is selected) ---
                if (_selectedSaleId != null)
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentId,
                    isExpanded: true, // ✅ Fix 3: Avoid width overflow
                    decoration: const InputDecoration(
                      labelText: "Select Payment",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: Colors.white,
                    hint: paymentProvider.isLoading
                        ? const Text("Loading payments...")
                        : const Text("Choose a payment"),
                    items: paymentProvider.payments.map((payment) {
                      return DropdownMenuItem(
                        value: payment.id,
                        child: Text(
                          '#${payment.id.substring(0, 6)} - ${payment.paymentMethod} (PKR ${payment.amountPaid.toStringAsFixed(2)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentId = value;
                      });
                    },
                    validator: (value) => value == null ? "Please select a payment" : null,
                  ),

                const SizedBox(height: 16),

                // --- 3. Notes ---
                PremiumTextField(
                  label: l10n.notes,
                  hint: l10n.additionalReceiptNotesOptional,
                  controller: _notesController,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // --- Actions ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createReceipt,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text(l10n.createReceipt),
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

  Future<void> _createReceipt() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedSaleId == null || _selectedPaymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both a Sale and a Payment"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = context.read<ReceiptProvider>();

      final success = await receiptProvider.createReceipt(
        saleId: _selectedSaleId!,
        paymentId: _selectedPaymentId!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToCreateReceipt}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}