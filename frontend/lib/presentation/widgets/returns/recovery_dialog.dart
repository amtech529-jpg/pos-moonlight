import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/rental_return_provider.dart';
import '../../../src/models/rental_return_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';

class RecoveryDialog extends StatefulWidget {
  final RentalReturnModel rentalReturn;

  const RecoveryDialog({super.key, required this.rentalReturn});

  @override
  State<RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<RecoveryDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _recoveryType = 'CUSTOMER_PAYMENT';
  
  final Map<String, String> _typeOptions = {
    'CUSTOMER_PAYMENT': 'Separate Customer Payment',
    'CUSTOMER_DEDUCTION': 'Deducted from Customer Payment',
    'INSURANCE': 'Insurance Claim',
    'STAFF_DEDUCTION': 'Deducted from Staff Salary',
    'WRITE_OFF': 'Written Off',
  };

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Default amount to balance if positive
    double balance = widget.rentalReturn.damageCharges; // Simple default
    _amountController.text = balance > 0 ? balance.toStringAsFixed(0) : '';

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<RentalReturnProvider>(context, listen: false);
      
      final success = await provider.addDamageRecovery(
        returnId: widget.rentalReturn.id,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        recoveryType: _recoveryType,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Recovery recorded successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.of(context).pop();
        } else {
          final errorMessage = (provider.error != null && provider.error!.isNotEmpty) 
              ? provider.error! 
              : 'Failed to record recovery';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.shouldShowCompactLayout ? 95.w : 500,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, color: AppTheme.primaryMaroon, size: 28),
                          SizedBox(width: 12),
                          Text('Add Damage Recovery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Spacer(),
                          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close)),
                        ],
                      ),
                      Divider(),
                      SizedBox(height: 16),
                      Text('Order: ${widget.rentalReturn.orderNumber}', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('Customer: ${widget.rentalReturn.customerName}'),
                      Text('Total Damage Charges: Rs. ${widget.rentalReturn.damageCharges.toStringAsFixed(0)}', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24),
                      PremiumDropdownField<String>(
                        label: 'Recovery Type',
                        value: _recoveryType,
                        items: _typeOptions.entries.map((e) => DropdownItem(value: e.key, label: e.value)).toList(),
                        onChanged: (val) => setState(() => _recoveryType = val!),
                      ),
                      SizedBox(height: 16),
                      PremiumTextField(
                        label: 'Amount Recovered (PKR)',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'required';
                          if (double.tryParse(val) == null) return 'invalid number';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      PremiumTextField(
                        label: 'Notes',
                        controller: _notesController,
                        maxLines: 2,
                      ),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel (منسوخ)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white),
                            child: Text(
                              'Record Recovery (درج کریں)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          ),
        );
      }
    );
  }
}
