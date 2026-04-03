import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../widgets/globals/text_field.dart'; // ✅ Use PremiumTextField

class EditReceiptDialog extends StatefulWidget {
  final ReceiptModel receipt;

  const EditReceiptDialog({super.key, required this.receipt});

  @override
  State<EditReceiptDialog> createState() => _EditReceiptDialogState();
}

class _EditReceiptDialogState extends State<EditReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.receipt.notes ?? '';
    _selectedStatus = widget.receipt.status;
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
                  Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.editReceiptWithNumber(widget.receipt.receiptNumber),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Status Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: l10n.statusRequired,
                  border: const OutlineInputBorder(),
                  hintText: l10n.selectReceiptStatus,
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                dropdownColor: Colors.white,
                items: [
                  DropdownMenuItem(value: 'GENERATED', child: Text(l10n.generated)),
                  DropdownMenuItem(value: 'SENT', child: Text(l10n.sent)),
                  DropdownMenuItem(value: 'VIEWED', child: Text(l10n.viewed)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseSelectStatus;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --- Notes ---
              PremiumTextField(
                label: l10n.notes,
                hint: l10n.additionalReceiptNotes,
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
                    onPressed: _isLoading ? null : _updateReceipt,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(l10n.updateReceipt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateReceipt() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = context.read<ReceiptProvider>();
      final success = await receiptProvider.updateReceipt(
        id: widget.receipt.id,
        status: _selectedStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateReceipt}: $e'),
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