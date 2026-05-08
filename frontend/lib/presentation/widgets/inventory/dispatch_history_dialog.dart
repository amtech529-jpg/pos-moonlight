import 'package:flutter/material.dart';
import 'package:frontend/src/models/dispatch/dispatch_form_model.dart';
import 'package:frontend/src/providers/dispatch_provider.dart';
import 'package:frontend/src/providers/product_provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/services/pdf_gate_pass_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'add_dispatch_form_dialog.dart';

class DispatchHistoryDialog extends StatefulWidget {
  const DispatchHistoryDialog({super.key});

  @override
  State<DispatchHistoryDialog> createState() => _DispatchHistoryDialogState();
}

class _DispatchHistoryDialogState extends State<DispatchHistoryDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DispatchProvider>().loadDispatchForms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gate Pass History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Driver, Vehicle, or Order ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => context.read<DispatchProvider>().loadDispatchForms(search: val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<DispatchProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            (provider.error == null || provider.error!.isEmpty) 
                              ? 'An error occurred while loading data' 
                              : provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black, 
                              fontSize: 14, 
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => provider.loadDispatchForms(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBD0D1D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (provider.forms.isEmpty) {
                    return const Center(child: Text('No Gate Passes found.'));
                  }
                  return ListView.separated(
                    itemCount: provider.forms.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final form = provider.forms[index];
                      final displayId = form.orderId != null 
                          ? (form.orderId!.length >= 8 ? form.orderId!.substring(0, 8).toUpperCase() : form.orderId!.toUpperCase())
                          : "STANDALONE";
                      return ListTile(
                        hoverColor: Colors.grey.shade50,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFBD0D1D).withOpacity(0.1),
                          child: const Icon(Icons.local_shipping, color: Color(0xFFBD0D1D), size: 20),
                        ),
                        title: Text(
                          form.orderId != null ? 'Order #$displayId - ${form.driverName}' : 'Standalone - ${form.driverName}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Vehicle: ${form.vehicleNumber} (${form.vehicleType ?? 'N/A'}) | Staff: ${form.staffName}\n${DateFormat('dd MMM yyyy, hh:mm a').format(form.createdAt.toLocal())}',
                            style: TextStyle(
                              color: Colors.grey.shade800, 
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _showEditDialog(context, form),
                              tooltip: 'Edit Logistics',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _confirmDelete(context, form),
                              tooltip: 'Delete Gate Pass',
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () => PdfGatePassService.printGatePass(form),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBD0D1D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.print, size: 16, color: Colors.white),
                                label: const Text(
                                  'Re-Print',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DispatchFormModel form) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light().copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(primary: Colors.red, onSurface: Colors.black),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Gate Pass?', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete this gate pass?\n\nThis will revert the stock deduction and make any associated orders searchable again.',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<DispatchProvider>().deleteDispatchForm(form.id);
                if (success && context.mounted) {
                  // Refresh other providers and AWAIT to ensure UI updates
                  await context.read<ProductProvider>().initialize();
                  await context.read<OrderProvider>().refreshOrders();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gate Pass deleted successfully')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, DispatchFormModel form) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddDispatchFormDialog(existingForm: form),
    );
  }
}
