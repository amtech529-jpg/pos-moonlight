import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../widgets/globals/text_field.dart';
import '../../widgets/globals/drop_down.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/custom_date_picker.dart';
import '../../../src/theme/app_theme.dart';

class EditInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const EditInvoiceDialog({super.key, required this.invoice});

  @override
  State<EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _termsController;
  late TextEditingController _writeOffController;
  late TextEditingController _paymentAmountController;

  DateTime? _selectedDueDate;
  String? _selectedStatus;
  String? _selectedPaymentMethod = 'CASH';
  bool _isLoading = false;
  bool _showPaymentSection = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes ?? '');
    _termsController = TextEditingController(text: widget.invoice.termsConditions ?? '');
    _writeOffController = TextEditingController(text: widget.invoice.writeOffAmount.toStringAsFixed(0));
    _paymentAmountController = TextEditingController(text: '0');
    _selectedDueDate = widget.invoice.dueDate;
    _selectedStatus = widget.invoice.status;

    // Add listener for dynamic calculations
    _paymentAmountController.addListener(() {
      if (mounted) {
        final amount = double.tryParse(_paymentAmountController.text) ?? 0;
        if (amount > 0) {
          setState(() {
            // Auto-update status based on payment amount
            final totalPaidNow = widget.invoice.amountPaid + amount;
            if (totalPaidNow < widget.invoice.totalAmount && totalPaidNow > 0) {
              _selectedStatus = 'PARTIALLY_PAID';
            } else if (totalPaidNow >= widget.invoice.totalAmount) {
              _selectedStatus = 'PAID';
            }
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    if (_termsController.text.isEmpty) {
      _termsController.text = l10n.standardTermsAndConditionsApply;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    _writeOffController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('large'))),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  children: [
                    Icon(Icons.edit_document, color: AppTheme.primaryMaroon, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.editInvoiceWithNumber(widget.invoice.invoiceNumber),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // --- Financial Summary ---
                _buildFinancialSummary(l10n),
                const SizedBox(height: 24),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: (context.dialogWidth - 64) / 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Status ---
                          const Text("Invoice Status *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          PremiumDropdownField<String>(
                            label: "",
                            hint: "Select Status",
                            value: _selectedStatus,
                            items: [
                              DropdownItem(value: 'ISSUED', label: "Pending"),
                              DropdownItem(value: 'PAID', label: "Paid"),
                              DropdownItem(value: 'PARTIALLY_PAID', label: "Partially Paid"),
                              DropdownItem(value: 'CLOSED', label: "Closed"),
                              DropdownItem(value: 'WRITTEN_OFF', label: "Written Off"),
                            ],
                            onChanged: (value) => setState(() => _selectedStatus = value),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: (context.dialogWidth - 64) / 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Due Date ---
                          const Text("Due Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              context.showSyncfusionDateTimePicker(
                                initialDate: _selectedDueDate ?? DateTime.now(),
                                initialTime: TimeOfDay.now(),
                                showTimeInline: false,
                                onDateTimeSelected: (date, _) => setState(() => _selectedDueDate = date),
                              );
                            },
                            child: IgnorePointer(
                              child: PremiumTextField(
                                label: "",
                                controller: TextEditingController(
                                  text: _selectedDueDate != null
                                      ? "${_selectedDueDate!.day}-${_selectedDueDate!.month}-${_selectedDueDate!.year}"
                                      : "Not Set",
                                ),
                                prefixIcon: Icons.calendar_today,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Write Off Section ---
                Row(
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        label: "Write-off Amount",
                        hint: "Adjusted final amount",
                        controller: _writeOffController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.edit_off_outlined,
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Payment Section ---
                if (widget.invoice.amountDue > 0) ...[
                  const Text("Record New Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: (context.dialogWidth - 100) / 2,
                                child: PremiumTextField(
                                  label: "Payment Amount",
                                  hint: "Enter PKR",
                                  controller: _paymentAmountController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.payments_outlined,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final double? amount = double.tryParse(value);
                                      if (amount != null && amount > widget.invoice.amountDue) {
                                        return 'Exceeds remaining Rs. ${widget.invoice.amountDue.toStringAsFixed(0)}';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: (context.dialogWidth - 100) / 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    PremiumDropdownField<String>(
                                      label: "",
                                      hint: "Method",
                                      value: _selectedPaymentMethod,
                                      items: [
                                        DropdownItem(value: 'CASH', label: "Cash"),
                                        DropdownItem(value: 'BANK_TRANSFER', label: "Bank Transfer"),
                                        DropdownItem(value: 'CARD', label: "Card"),
                                        DropdownItem(value: 'MOBILE_PAYMENT', label: "Mobile Pay"),
                                      ],
                                      onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // The 'Add Payment' button was removed here. Payment will be saved via 'Update Invoice'.
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                ],

                // --- Notes & Terms ---
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: (context.dialogWidth - 64) / 2,
                      child: PremiumTextField(
                        label: l10n.notes,
                        hint: "Internal notes",
                        controller: _notesController,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(
                      width: (context.dialogWidth - 64) / 2,
                      child: PremiumTextField(
                        label: l10n.termsAndConditions,
                        hint: "Policy notes",
                        controller: _termsController,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // --- Actions ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PremiumButton(
                      text: l10n.updateInvoice,
                      onPressed: _isLoading ? null : _updateInvoice,
                      isLoading: _isLoading,
                      backgroundColor: AppTheme.primaryMaroon,
                      width: 150,
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

  Widget _buildFinancialSummary(AppLocalizations l10n) {
    final enteredPayment = double.tryParse(_paymentAmountController.text) ?? 0;
    final writeOff = double.tryParse(_writeOffController.text) ?? 0;
    
    // If status is terminal, the backend will auto-clear the balance. Show that in the UI.
    final bool isTerminalStatus = ['WRITTEN_OFF', 'CLOSED', 'PAID'].contains(_selectedStatus);
    
    final double remainingAfterPayment = isTerminalStatus 
        ? 0 
        : (widget.invoice.amountDue - enteredPayment - (writeOff - widget.invoice.writeOffAmount)).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildSummaryLine("Grand Total", widget.invoice.grandTotal, isBold: true),
          const SizedBox(height: 8),
          _buildSummaryLine("Total Paid", widget.invoice.amountPaid, color: Colors.green),
          if (widget.invoice.writeOffAmount > 0)
            _buildSummaryLine("Previous Write-off", widget.invoice.writeOffAmount, color: Colors.grey),
          const Divider(),
          _buildSummaryLine(
            "Balance Due", 
            widget.invoice.amountDue, 
            isBold: true, 
            color: widget.invoice.amountDue > 0 ? Colors.red : Colors.green
          ),
          if (enteredPayment > 0 || writeOff != widget.invoice.writeOffAmount) ...[
            const SizedBox(height: 8),
            if (enteredPayment > 0)
              _buildSummaryLine(
                "New Payment", 
                enteredPayment, 
                color: Colors.blue.shade700,
                isBold: true,
              ),
            if (writeOff != widget.invoice.writeOffAmount)
              _buildSummaryLine(
                "New Write-off", 
                writeOff, 
                color: Colors.purple.shade700,
                isBold: true,
              ),
            const Divider(),
            _buildSummaryLine(
              "Remaining Balance", 
              remainingAfterPayment, 
              isBold: true, 
              color: remainingAfterPayment > 0 ? Colors.orange.shade800 : Colors.green.shade700
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, double value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey[700])),
        Text(
          "Rs. ${value.toStringAsFixed(0)}", 
          style: TextStyle(
            fontSize: 15, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
            color: color ?? Colors.black
          )
        ),
      ],
    );
  }





  Future<void> _updateInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0;

    try {
      // If a payment was entered, apply it
      if (paymentAmount > 0) {
        final paymentSuccess = await context.read<InvoiceProvider>().applyInvoicePayment(
          invoiceId: widget.invoice.id,
          amount: paymentAmount,
          paymentMethod: _selectedPaymentMethod ?? 'CASH',
        );

        // If the payment failed on the backend, stop processing and show the error.
        if (!paymentSuccess) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      final success = await context.read<InvoiceProvider>().updateInvoice(
        id: widget.invoice.id,
        status: _selectedStatus,
        dueDate: _selectedDueDate,
        notes: _notesController.text,
        writeOffAmount: double.tryParse(_writeOffController.text) ?? 0,
      );

      if (success && mounted) {
        // Specifically telling provider to refresh so the table list catches up with recent payments
        await context.read<InvoiceProvider>().loadInvoices(refresh: true);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ [EditInvoiceDialog] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}