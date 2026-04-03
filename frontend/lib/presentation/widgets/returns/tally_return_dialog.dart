import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/rental_return_provider.dart';
import '../../../src/models/rental_return_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';

class TallyReturnDialog extends StatefulWidget {
  final RentalReturnModel rentalReturn;

  const TallyReturnDialog({super.key, required this.rentalReturn});

  @override
  State<TallyReturnDialog> createState() => _TallyReturnDialogState();
}

class _TallyReturnDialogState extends State<TallyReturnDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _notesController = TextEditingController();

  late List<TallyItemInput> _tallyItems;
  String _responsibility = 'NONE';
  final List<String> _responsibilityChoices = ['NONE', 'CUSTOMER', 'INTERNAL'];
  bool _restoreStock = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.rentalReturn.notes ?? '';
    _responsibility = widget.rentalReturn.responsibility;
    
    // Initialize items from the existing return
    _tallyItems = widget.rentalReturn.items.map((item) {
      return TallyItemInput(
        id: item.id,
        productId: item.productId,
        productName: item.productName,
        qtySent: item.qtySent,
        returned: item.qtyReturned,
        damaged: item.qtyDamaged,
        missing: item.qtyMissing,
        damageCharge: item.damageCharge,
        conditionNotes: item.conditionNotes ?? '',
        isPartnerItem: item.isPartnerItem,
      );
    }).toList();

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
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<RentalReturnProvider>(context, listen: false);
      
      // Validate total accounted vs qty sent
      for (final item in _tallyItems) {
        if (item.totalAccounted > item.qtySent) {
          _showSnackbar(
            'Total for ${item.productName} (${item.totalAccounted}) exceeds items sent (${item.qtySent}).',
            Colors.red,
          );
          return;
        }
      }

      final itemsData = _tallyItems.map((input) {
        return {
          'id': input.id,
          'product': input.productId,
          'qty_sent': input.qtySent,
          'qty_returned': input.returned,
          'qty_damaged': input.damaged,
          'qty_missing': input.missing,
          'damage_charge': input.damageCharge,
          'condition_notes': input.conditionNotes,
          'is_partner_item': input.isPartnerItem,
        };
      }).toList();

      final success = await provider.tallyReturn(
        returnId: widget.rentalReturn.id,
        items: itemsData,
        damageCharges: _tallyItems.fold<double>(0.0, (sum, item) => sum + item.damageCharge),
        responsibility: _responsibility,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          _showSnackbar('Tally updated successfully!', Colors.green);
          Navigator.of(context).pop();
        } else {
          final errorMessage = (provider.error != null && provider.error!.isNotEmpty) 
              ? provider.error! 
              : 'Failed to update tally record';
          _showSnackbar(errorMessage, Colors.red);
        }
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.shouldShowCompactLayout ? 95.w : context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: context.maxContentWidth,
                  maxHeight: 90.h,
                ),
                margin: context.pagePadding,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(l10n),
                    Flexible(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: EdgeInsets.all(context.cardPadding),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order: ${widget.rentalReturn.orderNumber}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text('Customer: ${widget.rentalReturn.customerName}'),
                                SizedBox(height: context.cardPadding),
                                _buildItemsList(),
                                SizedBox(height: context.cardPadding),
                                 PremiumDropdownField<String>(
                                   label: 'Responsibility (ذمہ داری)',
                                   hint: 'Select Responsibility',
                                   prefixIcon: Icons.person_pin_rounded,
                                   value: _responsibility,
                                   items: _responsibilityChoices.map((c) => DropdownItem(value: c, label: c)).toList(),
                                   onChanged: (val) {
                                     if (val != null) setState(() => _responsibility = val);
                                   },
                                 ),
                                 SizedBox(height: context.cardPadding),
                                 PremiumTextField(
                                   label: 'Return Notes (تفصیل)',
                                   controller: _notesController,
                                    prefixIcon: Icons.note_alt_outlined,
                                   maxLines: 2,
                                 ),
                                const SizedBox(height: 100), // Added extra space for button visibility
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppTheme.pureWhite, size: 32),
          SizedBox(width: 12),
          Text(
            'Tally Returned Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.pureWhite),
          ),
          Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppTheme.pureWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items Inventory',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: 12),
        ..._tallyItems.map((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  Widget _buildItemRow(TallyItemInput item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold)),
              if (item.isPartnerItem) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Partner Item',
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          Text('Sent: ${item.qtySent}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Returned (واپس)', 
                  item.productId + '_ret', 
                  item.returned, 
                  (val) => setState(() => item.returned = val), 
                  max: item.qtySent,
                  icon: Icons.assignment_turned_in_outlined,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  'Damaged (خراب)', 
                  item.productId + '_dmg', 
                  item.damaged, 
                  (val) => setState(() => item.damaged = val),
                  icon: Icons.report_problem_outlined,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  'Missing (غائب)', 
                  item.productId + '_mis', 
                  item.missing, 
                  (val) => setState(() => item.missing = val),
                  icon: Icons.help_outline_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              item.totalAccounted != item.qtySent 
                  ? '⚠️ Accounted: ${item.totalAccounted} / ${item.qtySent} (Unmatched)'
                  : '✅ All items accounted (${item.qtySent}/${item.qtySent})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: item.totalAccounted != item.qtySent ? Colors.orange : Colors.green,
              ),
            ),
          ),
          if (item.damaged > 0 || item.missing > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                  Expanded(
                    child: PremiumTextField(
                      label: 'Charge (جرمانہ)',
                      initialValue: item.damageCharge.toString(),
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.money_off,
                      onChanged: (val) => item.damageCharge = double.tryParse(val) ?? 0,
                    ),
                  ),
                SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PremiumTextField(
                      label: 'Condition Notes (تفصیل)',
                      initialValue: item.conditionNotes,
                      prefixIcon: Icons.note_alt_outlined,
                      onChanged: (val) => item.conditionNotes = val,
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, String key, int value, Function(int) onChanged, {int? max, IconData? icon, Color? color}) {
    return PremiumTextField(
      label: label,
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      prefixIcon: icon,
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(0);
          return;
        }
        final v = int.tryParse(val) ?? 0;
        onChanged(v);
      },
      validator: (val) {
        final v = int.tryParse(val ?? '') ?? 0;
        if (max != null && v > max) return 'Max $max';
        return null;
      },
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
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
          Consumer<RentalReturnProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Update Tally (درج کریں)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TallyItemInput {
  final String id;
  final String productId;
  final String productName;
  final int qtySent;
  int returned;
  int damaged;
  int missing;
  double damageCharge;
  String conditionNotes;
  final bool isPartnerItem;

  TallyItemInput({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qtySent,
    this.returned = 0,
    this.damaged = 0,
    this.missing = 0,
    this.damageCharge = 0,
    this.conditionNotes = '',
    this.isPartnerItem = false,
  });

  int get totalAccounted => returned + damaged + missing;
}
