import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_field.dart';
import '../../widgets/globals/drop_down.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/custom_date_picker.dart';

class CreateInvoiceDialog extends StatefulWidget {
  const CreateInvoiceDialog({super.key});

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedOrderId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDueDate = DateTime.now().add(const Duration(days: 15));

    // Load orders if empty
    Future.microtask(() {
      final orderProvider = context.read<OrderProvider>();
      debugPrint('🔍 [CreateInvoiceDialog] Loading orders for invoicing...');
      orderProvider.loadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_termsController.text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _termsController.text = l10n.standardTermsAndConditionsApply ?? "Standard terms apply";
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('large'))),
      backgroundColor: Colors.white,
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryMaroon, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Convert Order to Invoice",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.charcoalGray),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 1. Select Order Dropdown
              const Text("Select Order *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Consumer2<OrderProvider, InvoiceProvider>(
                builder: (context, orderProvider, invoiceProvider, child) {
                  final invoicedOrderIds = invoiceProvider.invoices
                      .where((inv) => inv.orderId != null)
                      .map((inv) => inv.orderId!)
                      .toSet();

                  final orders = orderProvider.allOrders
                      .where((order) => !invoicedOrderIds.contains(order.id))
                      .toList();
                  
                  if (orders.isEmpty && !orderProvider.isLoading) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('No orders available to invoice. Please create an order first.', style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                    );
                  }
                  
                  return PremiumDropdownField<String>(
                    label: "",
                    hint: "Choose an existing order...",
                    value: _selectedOrderId,
                    items: orders.map((order) {
                      final orderIdShort = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
                      return DropdownItem(
                        value: order.id,
                        label: 'ORD-#$orderIdShort | ${order.customerName} (Rs. ${order.totalAmount.toStringAsFixed(0)})',
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedOrderId = value),
                    validator: (value) => value == null ? "Please select an order" : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Due Date
              const Text("Payment Due Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                          : "Select Date",
                    ),
                    prefixIcon: Icons.calendar_today_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Notes
              const Text("Additional Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              PremiumTextField(
                label: "",
                hint: "E.g. Special instructions for delivery...",
                controller: _notesController,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PremiumButton(
                    text: l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.grey.shade200,
                    textColor: Colors.grey.shade700,
                    width: 100,
                  ),
                  const SizedBox(width: 12),
                  Consumer2<OrderProvider, InvoiceProvider>(
                    builder: (context, orderProvider, invoiceProvider, child) {
                      final invoicedOrderIds = invoiceProvider.invoices.where((inv) => inv.orderId != null).map((inv) => inv.orderId!).toSet();
                      final hasValidOrders = orderProvider.allOrders.any((order) => !invoicedOrderIds.contains(order.id));
                      
                      return PremiumButton(
                        text: "Generate Invoice",
                        onPressed: (!hasValidOrders || _isLoading) ? null : _createInvoiceFromOrder,
                        isLoading: _isLoading,
                        width: 180,
                        icon: Icons.auto_awesome_rounded,
                        backgroundColor: !hasValidOrders ? Colors.grey : AppTheme.primaryMaroon,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvoiceFromOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('🔍 [CreateInvoiceDialog] Generating invoice from order: $_selectedOrderId');
      
      final success = await context.read<InvoiceProvider>().generateInvoiceFromOrder(
        orderId: _selectedOrderId!,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success! Invoice generated from Order."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        final errorMsg = context.read<InvoiceProvider>().error ?? "Operation failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('❌ [CreateInvoiceDialog] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}