import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../../../l10n/app_localizations.dart';

class EditPayableDialog extends StatefulWidget {
  final Payable payable;
  const EditPayableDialog({super.key, required this.payable});

  @override
  State<EditPayableDialog> createState() => _EditPayableDialogState();
}

class _EditPayableDialogState extends State<EditPayableDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _newPaymentController;
  late TextEditingController _notesController;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Start with empty — user enters how much they're paying NOW
    _newPaymentController = TextEditingController();
    _notesController = TextEditingController(text: widget.payable.notes ?? '');

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _newPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final newPaymentAmount =
          double.tryParse(_newPaymentController.text.trim()) ?? 0.0;
      final payablesProvider =
          Provider.of<PayablesProvider>(context, listen: false);

      // Use addPayment endpoint — same as invoice partial payment
      final success = await payablesProvider.addPayment(
        payableId: widget.payable.id,
        amount: newPaymentAmount,
        paymentDate: DateTime.now(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar(l10n.payableUpdatedSuccessfully);
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(payablesProvider.errorMessage ??
              l10n.failedToUpdatePayablePleaseTryAgain);
        }
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get _previewNewBalance {
    final entered = double.tryParse(_newPaymentController.text) ?? 0.0;
    return (widget.payable.balanceRemaining - entered).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.payable.balanceRemaining;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor:
              Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 480,
                constraints: BoxConstraints(maxHeight: 90.h, maxWidth: 95.w),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.updatePayment ?? "Record Payment",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  widget.payable.creditorName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Info summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    _infoRow("Creditor",
                                        widget.payable.creditorName),
                                    const Divider(height: 14),
                                    _infoRow("Reason",
                                        widget.payable.reasonOrItem),
                                    const Divider(height: 14),
                                    _infoRow(
                                      "Total Borrowed",
                                      "Rs. ${widget.payable.amountBorrowed.toStringAsFixed(0)}",
                                    ),
                                    const Divider(height: 14),
                                    _infoRow(
                                      "Already Paid",
                                      "Rs. ${widget.payable.amountPaid.toStringAsFixed(0)}",
                                      valueColor: Colors.green,
                                    ),
                                    const Divider(height: 14),
                                    _infoRow(
                                      "Balance Remaining",
                                      "Rs. ${remaining.toStringAsFixed(0)}",
                                      valueColor: Colors.red,
                                      isBold: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // New payment amount field
                              PremiumTextField(
                                label: "Amount Paying Now (PKR)",
                                hint: "Enter payment amount",
                                controller: _newPaymentController,
                                prefixIcon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter the payment amount";
                                  }
                                  final amt = double.tryParse(value);
                                  if (amt == null || amt <= 0) {
                                    return "Enter a valid amount greater than 0";
                                  }
                                  if (amt > remaining) {
                                    return "Cannot exceed remaining balance (Rs. ${remaining.toStringAsFixed(0)})";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Live preview of new balance
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _previewNewBalance > 0
                                      ? Colors.orange.withOpacity(0.07)
                                      : Colors.green.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _previewNewBalance > 0
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _previewNewBalance > 0
                                          ? Icons.account_balance_wallet_outlined
                                          : Icons.check_circle_outline_rounded,
                                      color: _previewNewBalance > 0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("New Balance After Payment",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        Text(
                                          _previewNewBalance > 0
                                              ? "Rs. ${_previewNewBalance.toStringAsFixed(0)} remaining"
                                              : "Fully Paid! ✓",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: _previewNewBalance > 0
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              PremiumTextField(
                                label: l10n.notesOptional,
                                hint: "e.g. Paid via cash / bank transfer",
                                controller: _notesController,
                                prefixIcon: Icons.note_alt_outlined,
                                maxLines: 2,
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: PremiumButton(
                                      text: l10n.cancel,
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      isOutlined: true,
                                      height: 48,
                                      textColor: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child:
                                        Consumer<PayablesProvider>(
                                      builder: (ctx, provider, _) {
                                        return PremiumButton(
                                          text: l10n.updatePayment ??
                                              "Record Payment",
                                          onPressed: provider.isLoading
                                              ? null
                                              : _handleSubmit,
                                          isLoading: provider.isLoading,
                                          height: 48,
                                          backgroundColor:
                                              AppTheme.primaryMaroon,
                                        );
                                      },
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
      },
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
