import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class PaymentConfirmationDialog extends StatefulWidget {
  final String saleId;
  final String invoiceNumber;
  final String customerName;
  final double grandTotal;
  final double amountPaid;
  final String currentStatus;
  final Function(bool success)? onPaymentConfirmed;

  const PaymentConfirmationDialog({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.customerName,
    required this.grandTotal,
    required this.amountPaid,
    required this.currentStatus,
    this.onPaymentConfirmed,
  });

  @override
  State<PaymentConfirmationDialog> createState() => _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'CASH';
  bool _isLoading = false;
  bool _isPartialPayment = false;
  Map<String, dynamic>? _workflowSummary;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint("🟢 [PaymentDialog] Initialized for Invoice: ${widget.invoiceNumber}");

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    final remainingAmount = widget.grandTotal - widget.amountPaid;
    _amountController.text = remainingAmount.toStringAsFixed(2);
    _isPartialPayment = remainingAmount < widget.grandTotal;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkflowSummary();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflowSummary() async {
    debugPrint("🔵 [PaymentDialog] Fetching workflow summary...");
    final provider = Provider.of<SalesProvider>(context, listen: false);
    final summary = await provider.getPaymentWorkflowSummary(widget.saleId);
    if (mounted) {
      setState(() {
        _workflowSummary = summary;
      });
      debugPrint("✅ [PaymentDialog] Workflow summary loaded.");
    }
  }

  void _handlePaymentConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    debugPrint("🔘 [PaymentDialog] 'Confirm Payment' Pressed");

    if (!_formKey.currentState!.validate()) {
      debugPrint("❌ [PaymentDialog] Validation Failed");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final reference = _referenceController.text.trim();
      final notes = _notesController.text.trim();

      debugPrint("📋 [PaymentDialog] Data: Amount=$amount, Method=$_selectedPaymentMethod");

      if (!provider.validatePaymentWorkflowData(
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        saleTotal: widget.grandTotal,
        previousAmountPaid: widget.amountPaid,
      )) {
        debugPrint("❌ [PaymentDialog] Invalid Payment Data (Amount exceeds total?)");
        _showErrorDialog(l10n.invalidPaymentAmount);
        setState(() => _isLoading = false);
        return;
      }

      final success = await provider.confirmPaymentWorkflow(
        saleId: widget.saleId,
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        reference: reference.isNotEmpty ? reference : null,
        notes: notes.isNotEmpty ? notes : null,
        isPartialPayment: _isPartialPayment,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          debugPrint("✅ [PaymentDialog] Payment Successful!");
          _showSuccessDialog();
        } else {
          debugPrint("❌ [PaymentDialog] Payment Failed (API Error)");
          _showErrorDialog(l10n.paymentProcessingFailed);
        }
      }
    } catch (e) {
      debugPrint("🛑 [PaymentDialog] Exception: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(l10n.errorOccurred(e.toString()));
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 30), // Increased Size
            const SizedBox(width: 12),
            Text(l10n.paymentConfirmed, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24)), // Increased Size
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.paymentProcessedSuccessfully, style: const TextStyle(fontSize: 18)), // Increased Size
            const SizedBox(height: 16),
            _buildPaymentSummary()
          ],
        ),
        actions: [
          // ✅ PRINT RECEIPT BUTTON ADDED HERE
          TextButton.icon(
            onPressed: () {
              debugPrint("🖨️ [PaymentDialog] 'Print Receipt' Tapped");

              // Placeholder for actual print logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Printing Receipt... (Check Logs)")),
              );

              // FUTURE TODO: Add your printer service call here:
              // context.read<ReceiptProvider>().printReceipt(widget.saleId);
            },
            icon: const Icon(Icons.print, size: 24),
            label: const Text("Print Receipt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close success dialog
              Navigator.of(context).pop(); // Close payment dialog
              widget.onPaymentConfirmed?.call(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.continue_, style: const TextStyle(color: Colors.white, fontSize: 18)), // Increased Size
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 30),
            const SizedBox(width: 12),
            Text(l10n.paymentError, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok, style: const TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final l10n = AppLocalizations.of(context)!;
    final newAmountPaid = widget.amountPaid + (double.tryParse(_amountController.text) ?? 0.0);
    final newRemainingAmount = widget.grandTotal - newAmountPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.creamWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentSummary, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)), // Increased Size
          const SizedBox(height: 12),
          _buildSummaryRow(l10n.invoice, widget.invoiceNumber),
          _buildSummaryRow('${l10n.customer}:', widget.customerName),
          _buildSummaryRow('${l10n.grandTotal}:', 'PKR ${widget.grandTotal.toStringAsFixed(2)}'),
          _buildSummaryRow(l10n.previouslyPaid, 'PKR ${widget.amountPaid.toStringAsFixed(2)}'),
          _buildSummaryRow(l10n.thisPayment, 'PKR ${_amountController.text}'),
          const Divider(height: 16),
          _buildSummaryRow(
            l10n.newBalance,
            'PKR ${newRemainingAmount.toStringAsFixed(2)}',
            isBold: true,
            color: newRemainingAmount > 0 ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: 16))), // Increased Size
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: 16, color: color), // Increased Size
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowProgress() {
    final l10n = AppLocalizations.of(context)!;
    if (_workflowSummary == null) return const SizedBox.shrink();

    final progress = Provider.of<SalesProvider>(context, listen: false).getPaymentWorkflowProgress(_workflowSummary!);
    final isComplete = Provider.of<SalesProvider>(context, listen: false).isPaymentWorkflowComplete(_workflowSummary!);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.paymentProgress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)), // Increased Size
              Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isComplete ? Colors.green : AppTheme.primaryMaroon),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(isComplete ? Colors.green : AppTheme.primaryMaroon),
            minHeight: 12, // Thicker Bar
          ),
          const SizedBox(height: 8),
          Text(
            isComplete ? l10n.paymentComplete : l10n.paymentInProgress,
            style: TextStyle(fontSize: 14, color: isComplete ? Colors.green : Colors.orange, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxWidth: 550, maxHeight: 85.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryMaroon,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payment, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.paymentConfirmation,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700), // Increased Size
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // --- Content ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWorkflowProgress(),
                          _buildPaymentSummary(),

                          const SizedBox(height: 24),

                          // Payment Method
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: InputDecoration(
                              labelText: l10n.paymentMethod,
                              labelStyle: const TextStyle(fontSize: 18), // Increased Size
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            style: const TextStyle(color: Colors.black, fontSize: 18), // Increased Size
                            items: [
                              DropdownMenuItem(value: 'CASH', child: Text(l10n.cash)),
                              DropdownMenuItem(value: 'CARD', child: Text(l10n.creditDebitCard)),
                              DropdownMenuItem(value: 'BANK_TRANSFER', child: Text(l10n.bankTransfer)),
                              DropdownMenuItem(value: 'MOBILE_PAYMENT', child: Text(l10n.mobilePayment)),
                              DropdownMenuItem(value: 'CHECK', child: Text(l10n.check)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                            validator: (value) => (value == null || value.isEmpty) ? l10n.pleaseSelectPaymentMethod : null,
                          ),

                          const SizedBox(height: 20),

                          // Amount
                          PremiumTextField(
                            label: l10n.paymentAmount,
                            hint: l10n.enterAmount,
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.pleaseEnterPaymentAmount;
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
                              if (amount > (widget.grandTotal - widget.amountPaid)) return l10n.amountExceedsBalance;
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Reference
                          PremiumTextField(
                            label: l10n.referenceOptional,
                            hint: l10n.transactionReferenceOrReceipt,
                            controller: _referenceController,
                          ),

                          const SizedBox(height: 20),

                          // Notes
                          PremiumTextField(
                            label: l10n.notesOptional,
                            hint: l10n.additionalNotesAboutPayment,
                            controller: _notesController,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 30),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: AppTheme.primaryMaroon),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancel,
                                    style: const TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.w700, fontSize: 18), // Increased Size
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handlePaymentConfirmation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryMaroon,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                      : Text(
                                    l10n.confirmPayment,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18), // Increased Size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}