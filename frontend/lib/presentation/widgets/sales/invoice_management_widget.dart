import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/pdf_invoice_service.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/globals/text_button.dart';
import 'create_invoice_dialog.dart';
import 'edit_invoice_dialog.dart';
import 'view_invoice_dialog.dart';

class InvoiceManagementWidget extends StatefulWidget {
  const InvoiceManagementWidget({super.key});

  @override
  State<InvoiceManagementWidget> createState() => _InvoiceManagementWidgetState();
}

class _InvoiceManagementWidgetState extends State<InvoiceManagementWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Initialize data immediately without delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 [InvoiceManagementWidget] Initializing InvoiceProvider immediately');
      if (mounted) {
        context.read<InvoiceProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Filters Section ---
            _buildFilters(l10n),
            const SizedBox(height: 16),

            // --- Invoices List ---
            Expanded(child: _buildInvoicesList(l10n)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateInvoiceDialog(context),
        backgroundColor: AppTheme.primaryMaroon,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: l10n.createInvoice ?? "Create Invoice",
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.filters ?? "Filters",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: l10n.search ?? "Search",
                    hintText: "Search by Invoice # or Customer...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    // Cancel previous timer
                    _searchDebounce?.cancel();
                    
                    // Start new timer for debounced search
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        debugPrint('🔍 [InvoiceManagementWidget] Debounced search: $value');
                        context.read<InvoiceProvider>().setFilters(search: value);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Status Dropdown
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus.isEmpty ? null : _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n.status ?? "Status",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l10n.allStatuses ?? "All")),
                    DropdownMenuItem(value: 'DRAFT', child: Text(l10n.draft ?? "Draft")),
                    DropdownMenuItem(value: 'ISSUED', child: const Text("Pending")),
                    DropdownMenuItem(value: 'SENT', child: const Text("Unpaid")),
                    DropdownMenuItem(value: 'PAID', child: Text(l10n.paid ?? "Paid")),
                    DropdownMenuItem(value: 'OVERDUE', child: Text(l10n.overdue ?? "Overdue")),
                    DropdownMenuItem(value: 'CANCELLED', child: const Text("Cancelled")),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? '');
                    context.read<InvoiceProvider>().setFilters(status: value);
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Clear Filters Button
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedStatus = '');
                  context.read<InvoiceProvider>().clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.clearFilters ?? "Clear"),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryMaroon),
              ),
              const SizedBox(width: 8),
              
              // Refresh Button
              TextButton.icon(
                onPressed: () => context.read<InvoiceProvider>().refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh ?? "Refresh"),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryMaroon),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(AppLocalizations l10n) {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.invoices.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon));
        }

        if (provider.error != null && provider.invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('${l10n.error ?? "Error"}: ${provider.error}'),
                const SizedBox(height: 16),
                PremiumButton(
                  text: l10n.retry ?? "Retry",
                  onPressed: () => provider.refresh(),
                  width: 120,
                ),
              ],
            ),
          );
        }

        final invoices = provider.filteredInvoices;

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  l10n.noInvoicesFound ?? "No Invoices Found",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: AppTheme.primaryMaroon,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(invoice, provider, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, InvoiceProvider provider, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invoice.status),
          child: Icon(_getStatusIcon(invoice.status), color: Colors.white, size: 20),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('${l10n.customer ?? "Customer"}: ${invoice.customerName}'),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildAmountColumn("Total", invoice.grandTotal, Colors.black87),
                const SizedBox(width: 16),
                _buildAmountColumn("Paid", invoice.amountPaid, Colors.green.shade700),
                const SizedBox(width: 16),
                _buildAmountColumn("Write-Off", invoice.writeOffAmount, Colors.orange.shade700),
                const SizedBox(width: 16),
                _buildAmountColumn("Due", invoice.amountDue, invoice.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                invoice.statusDisplay,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(invoice.status),
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleInvoiceAction(value, invoice, provider, l10n),
          itemBuilder: (context) => _buildInvoiceActionMenu(l10n),
        ),
        onTap: () => _showInvoiceDetails(invoice, l10n),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        Text(
          'PKR ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.grey;
      case 'ISSUED': return Colors.orange; // Pending
      case 'SENT': return Colors.red; // Unpaid
      case 'PAID': return Colors.green;
      case 'PARTIALLY_PAID': return Colors.blue;
      case 'OVERDUE': return Colors.red;
      case 'CANCELLED': return Colors.red;
      default: return AppTheme.primaryMaroon;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'DRAFT': return Icons.edit_note;
      case 'ISSUED': return Icons.pending_actions_rounded; // Pending
      case 'SENT': return Icons.money_off_rounded; // Unpaid
      case 'PAID': return Icons.check_circle_outline;
      case 'OVERDUE': return Icons.warning_amber_rounded;
      case 'CANCELLED': return Icons.cancel_outlined;
      default: return Icons.receipt;
    }
  }

  List<PopupMenuEntry<String>> _buildInvoiceActionMenu(AppLocalizations l10n) {
    return [
      PopupMenuItem(
        value: 'view',
        child: Row(children: [const Icon(Icons.visibility, color: Colors.blue, size: 20), const SizedBox(width: 10), Text(l10n.view ?? "View")]),
      ),
      PopupMenuItem(
        value: 'edit',
        child: Row(children: [const Icon(Icons.edit, color: Colors.orange, size: 20), const SizedBox(width: 10), Text(l10n.edit ?? "Edit")]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'generate_pdf',
        child: Row(children: [const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), const SizedBox(width: 10), Text("Generate PDF")]),
      ),
      PopupMenuItem(
        value: 'print_pdf',
        child: Row(children: [const Icon(Icons.print, color: Colors.green, size: 20), const SizedBox(width: 10), Text("Print PDF")]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: Row(children: [const Icon(Icons.delete, color: Colors.red, size: 20), const SizedBox(width: 10), Text(l10n.delete ?? "Delete")]),
      ),
    ];
  }

  void _handleInvoiceAction(String action, InvoiceModel invoice, InvoiceProvider provider, AppLocalizations l10n) {
    switch (action) {
      case 'view':
        _showInvoiceDetails(invoice, l10n);
        break;
      case 'edit':
        _showEditInvoiceDialog(invoice);
        break;
      case 'generate_pdf':
        _generatePdfInvoice(invoice, l10n);
        break;
      case 'print_pdf':
        _printPdfInvoice(invoice, l10n);
        break;
      case 'delete':
        _showDeleteInvoiceDialog(invoice, provider, l10n);
        break;
    }
  }

  void _showCreateInvoiceDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const CreateInvoiceDialog());
  }

  void _showInvoiceDetails(InvoiceModel invoice, AppLocalizations l10n) {
    debugPrint('🔍 [InvoiceManagementWidget] Showing invoice details for: ${invoice.invoiceNumber}');
    
    showDialog(
      context: context,
      builder: (context) => ViewInvoiceDialog(invoice: invoice),
    );
  }

  void _showEditInvoiceDialog(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => EditInvoiceDialog(invoice: invoice),
    );
  }

  void _generatePdfInvoice(InvoiceModel invoice, AppLocalizations l10n) async {
    debugPrint('🔍 [InvoiceManagementWidget] Generating PDF for invoice: ${invoice.invoiceNumber}');
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      // Convert InvoiceModel to SaleModel with proper field mapping
      final sale = SaleModel(
        id: invoice.saleId,
        invoiceNumber: invoice.saleInvoiceNumber,
        dateOfSale: invoice.issueDate,
        customerName: invoice.customerName,
        customerPhone: '', // InvoiceModel doesn't have phone field, using empty string
        subtotal: invoice.grandTotal, // Using grandTotal as subtotal since InvoiceModel doesn't have subtotal
        overallDiscount: 0.0, // InvoiceModel doesn't have discount field
        taxConfiguration: TaxConfiguration(), // Empty tax configuration
        gstPercentage: 0.0, // InvoiceModel doesn't have GST field
        taxAmount: 0.0, // InvoiceModel doesn't have tax field
        grandTotal: invoice.grandTotal,
        amountPaid: invoice.status == 'PAID' ? invoice.grandTotal : 0.0, // Assume paid if status is PAID
        remainingAmount: invoice.status == 'PAID' ? 0.0 : invoice.grandTotal, // Assume full balance if not paid
        isFullyPaid: invoice.status == 'PAID', // Check if status is PAID
        paymentMethod: 'CASH', // Default payment method
        status: invoice.status,
        notes: invoice.notes,
        isActive: invoice.isActive,
        createdAt: invoice.createdAt,
        updatedAt: invoice.updatedAt,
        createdBy: invoice.createdBy,
        saleItems: [], // InvoiceModel doesn't have items, so using empty list
      );

      // Generate PDF
      final filePath = await PdfInvoiceService.generateInvoicePdf(sale);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF generated successfully!"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "Open",
              textColor: Colors.white,
              onPressed: () async {
                await OpenFile.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printPdfInvoice(InvoiceModel invoice, AppLocalizations l10n) async {
    debugPrint('🔍 [InvoiceManagementWidget] Printing PDF for invoice: ${invoice.invoiceNumber}');
    
    try {
      // Convert InvoiceModel to SaleModel with proper field mapping
      final sale = SaleModel(
        id: invoice.saleId,
        invoiceNumber: invoice.saleInvoiceNumber,
        dateOfSale: invoice.issueDate,
        customerName: invoice.customerName,
        customerPhone: '', // InvoiceModel doesn't have phone field, using empty string
        subtotal: invoice.grandTotal, // Using grandTotal as subtotal since InvoiceModel doesn't have subtotal
        overallDiscount: 0.0, // InvoiceModel doesn't have discount field
        taxConfiguration: TaxConfiguration(), // Empty tax configuration
        gstPercentage: 0.0, // InvoiceModel doesn't have GST field
        taxAmount: 0.0, // InvoiceModel doesn't have tax field
        grandTotal: invoice.grandTotal,
        amountPaid: invoice.status == 'PAID' ? invoice.grandTotal : 0.0, // Assume paid if status is PAID
        remainingAmount: invoice.status == 'PAID' ? 0.0 : invoice.grandTotal, // Assume full balance if not paid
        isFullyPaid: invoice.status == 'PAID', // Check if status is PAID
        paymentMethod: 'CASH', // Default payment method
        status: invoice.status,
        notes: invoice.notes,
        isActive: invoice.isActive,
        createdAt: invoice.createdAt,
        updatedAt: invoice.updatedAt,
        createdBy: invoice.createdBy,
        saleItems: [], // InvoiceModel doesn't have items, so using empty list
      );

      // Show print preview
      await PdfInvoiceService.previewAndPrintInvoice(sale);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Print preview opened"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening print preview: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteInvoiceDialog(InvoiceModel invoice, InvoiceProvider provider, AppLocalizations l10n) {
    debugPrint('🔍 [InvoiceManagementWidget] Showing delete confirmation for invoice: ${invoice.invoiceNumber}');
    debugPrint('🔍 [InvoiceManagementWidget] Invoice ID: ${invoice.id}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Invoice"),
        content: Text('Are you sure you want to delete Invoice ${invoice.invoiceNumber}? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          PremiumButton(
            text: l10n.cancel ?? "Cancel",
            onPressed: () {
              debugPrint('🔍 [InvoiceManagementWidget] User cancelled delete for invoice: ${invoice.invoiceNumber}');
              Navigator.pop(context);
            },
            isOutlined: true,
            width: 100,
          ),
          PremiumButton(
            text: "Delete",
            onPressed: () async {
              debugPrint('🔍 [InvoiceManagementWidget] User confirmed delete for invoice: ${invoice.invoiceNumber}');
              Navigator.pop(context); // Close confirmation dialog
              
              try {
                debugPrint('🔍 [InvoiceManagementWidget] Calling provider.deleteInvoice for invoice: ${invoice.id}');
                final success = await provider.deleteInvoice(invoice.id);
                
                debugPrint('🔍 [InvoiceManagementWidget] Delete result: $success');
                
                if (success && mounted) {
                  debugPrint('✅ [InvoiceManagementWidget] Invoice deleted successfully');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invoice Deleted Successfully"), backgroundColor: Colors.green),
                  );
                } else if (mounted) {
                  debugPrint('❌ [InvoiceManagementWidget] Failed to delete invoice');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to delete invoice"), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                debugPrint('❌ [InvoiceManagementWidget] Exception during delete: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            backgroundColor: Colors.red,
            width: 100,
          ),
        ],
      ),
    );
  }

  void _generateInvoiceThermalPrint(InvoiceModel invoice, InvoiceProvider provider, AppLocalizations l10n) async {
    debugPrint('🔍 [InvoiceManagementWidget] Starting thermal print for invoice: ${invoice.invoiceNumber}');
    debugPrint('🔍 [InvoiceManagementWidget] Invoice ID: ${invoice.id}');
    debugPrint('🔍 [InvoiceManagementWidget] Invoice Status: ${invoice.status}');
    debugPrint('🔍 [InvoiceManagementWidget] Invoice Amount: PKR ${invoice.grandTotal.toStringAsFixed(2)}');
    
    try {
      debugPrint('🔍 [InvoiceManagementWidget] Calling provider.generateInvoiceThermalPrint...');
      final success = await provider.generateInvoiceThermalPrint(invoice.id);
      
      debugPrint('🔍 [InvoiceManagementWidget] Thermal print result: $success');
      
      if (success && mounted) {
        debugPrint('✅ [InvoiceManagementWidget] Thermal print data generated successfully');
        
        // Get thermal print data
        final thermalData = provider.thermalPrintData;
        if (thermalData != null) {
          _showThermalPrintDialog(thermalData, invoice.invoiceNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thermal print data generated but no data received"), backgroundColor: Colors.orange),
          );
        }
      } else if (mounted) {
        debugPrint('❌ [InvoiceManagementWidget] Thermal print generation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate thermal print"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceManagementWidget] Exception during thermal print: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating thermal print: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showThermalPrintDialog(Map<String, dynamic> thermalData, String invoiceNumber) {
    debugPrint('🔍 [InvoiceManagementWidget] Thermal data received: $thermalData');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thermal Print - $invoiceNumber"),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header
              Center(
                child: Column(
                  children: [
                    Text(thermalData['company']?['name'] ?? 'Al Noor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(thermalData['company']?['address'] ?? 'Your Company Address', style: const TextStyle(fontSize: 12)),
                    Text(thermalData['company']?['phone'] ?? '+92-XXX-XXXXXXX', style: const TextStyle(fontSize: 12)),
                    const Divider(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Invoice Info
              Text('Invoice #: ${thermalData['invoice']?['invoice_number'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Date: ${thermalData['invoice']?['issue_date'] ?? 'N/A'}'),
              Text('Customer: ${thermalData['invoice']?['customer_name'] ?? 'Walk-in Customer'}'),
              if ((thermalData['invoice']?['customer_phone'] ?? '').isNotEmpty)
                Text('Phone: ${thermalData['invoice']?['customer_phone']}'),
              const Divider(),
              
              // Items
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: thermalData['items']?.length ?? 0,
                  itemBuilder: (context, index) {
                    if (thermalData['items'] == null || index >= thermalData['items'].length) {
                      return const Text('No items found');
                    }
                    final item = thermalData['items'][index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item['name'] ?? 'N/A')),
                          Text('${item['quantity'] ?? 0}x'),
                          Text('PKR ${(item['total'] ?? 0.0).toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              
              // Totals
              Text('Subtotal: PKR ${(thermalData['totals']?['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
              Text('Tax: PKR ${(thermalData['totals']?['tax'] ?? 0.0).toStringAsFixed(2)}'),
              Text('Discount: PKR ${(thermalData['totals']?['discount'] ?? 0.0).toStringAsFixed(2)}'),
              Text('TOTAL: PKR ${(thermalData['totals']?['total'] ?? 0.0).toStringAsFixed(2)}', 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        actions: [
          PremiumButton(
            text: "Print",
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thermal printer integration coming soon!"), backgroundColor: Colors.blue),
              );
            },
            width: 100,
          ),
          PremiumButton(
            text: "Close",
            onPressed: () => Navigator.pop(context),
            isOutlined: true,
            width: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}