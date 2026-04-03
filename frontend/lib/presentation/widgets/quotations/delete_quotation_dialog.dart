import 'package:flutter/material.dart';
import '../../../../src/models/quotation/quotation_model.dart';
import '../../../../src/theme/app_theme.dart';

class DeleteQuotationDialog extends StatelessWidget {
  final QuotationModel quotation;

  const DeleteQuotationDialog({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Delete Quotation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        'Are you sure you want to delete quotation "${quotation.quotationNumber}" for ${quotation.customerName}?\nThis action cannot be undone.',
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}
