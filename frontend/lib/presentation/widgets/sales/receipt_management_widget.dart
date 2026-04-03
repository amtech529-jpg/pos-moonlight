import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/services/receipt_service.dart';
import 'create_simple_receipt_dialog.dart';
import 'view_receipt_dialog.dart';
import 'edit_receipt_dialog.dart';

class ReceiptManagementWidget extends StatefulWidget {
  const ReceiptManagementWidget({super.key});

  @override
  State<ReceiptManagementWidget> createState() => _ReceiptManagementWidgetState();
}

class _ReceiptManagementWidgetState extends State<ReceiptManagementWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load both receipts and sales
      context.read<ReceiptProvider>().initialize();
      context.read<SalesProvider>().loadAllSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // --- Filters ---
          _buildFilters(),

          // --- List ---
          Expanded(child: _buildReceiptsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSimpleReceiptDialog(context),
        tooltip: l10n.createReceipt,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filters, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.search,
                      hintText: 'Search by invoice number or customer...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => context.read<ReceiptProvider>().setFilters(search: value),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Dropdown
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus.isEmpty ? null : _selectedStatus,
                    decoration: InputDecoration(
                      labelText: l10n.status,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem(value: '', child: Text(l10n.allStatuses)),
                      DropdownMenuItem(value: 'GENERATED', child: Text(l10n.generated)),
                      DropdownMenuItem(value: 'SENT', child: Text(l10n.sent)),
                      DropdownMenuItem(value: 'VIEWED', child: Text(l10n.viewed)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value ?? '';
                      });
                      context.read<ReceiptProvider>().setFilters(status: value);
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Clear Filters
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedStatus = '';
                    });
                    context.read<ReceiptProvider>().clearFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: Text(l10n.clearFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<SalesProvider, ReceiptProvider>(
      builder: (context, salesProvider, receiptProvider, child) {
        if (salesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (salesProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(l10n.error(salesProvider.errorMessage!)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => salesProvider.loadSales(refresh: true),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        // Filter sales based on search
        List<SaleModel> filteredSales = salesProvider.sales.where((sale) {
          if (_searchController.text.isNotEmpty) {
            final searchLower = _searchController.text.toLowerCase();
            return sale.invoiceNumber.toLowerCase().contains(searchLower) ||
                   sale.customerName.toLowerCase().contains(searchLower);
          }
          return true;
        }).toList();

        if (filteredSales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No Sales Found', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('No sales found in the system', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => salesProvider.loadSales(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filteredSales.length,
            itemBuilder: (context, index) {
              final sale = filteredSales[index];
              final hasReceipt = receiptProvider.receipts.any((receipt) => receipt.saleId == sale.id);
              
              return _buildSaleCard(sale, hasReceipt, receiptProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildSaleCard(SaleModel sale, bool hasReceipt, ReceiptProvider receiptProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: hasReceipt ? Colors.green : Colors.blue,
          child: Icon(
            hasReceipt ? Icons.receipt : Icons.receipt_long,
            color: Colors.white,
          ),
        ),
        title: Text(
          sale.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sale.customerName),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${l10n.date}: ${sale.dateOfSale.toString().split('T')[0]}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  '${l10n.total}: PKR ${sale.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReceipt ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasReceipt ? 'Receipt' : 'Invoice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleSaleAction(value, sale, receiptProvider),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.view),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      const Icon(Icons.print, size: 16),
                      const SizedBox(width: 8),
                      Text('Print'),
                    ],
                  ),
                ),
                if (!hasReceipt)
                  PopupMenuItem(
                    value: 'create_receipt',
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.createReceipt),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSaleAction(String action, SaleModel sale, ReceiptProvider receiptProvider) {
    switch (action) {
      case 'view':
        _viewSaleReceipt(sale);
        break;
      case 'print':
        _printSaleReceipt(sale);
        break;
      case 'create_receipt':
        _createReceiptForSale(sale);
        break;
    }
  }

  void _viewSaleReceipt(SaleModel sale) {
    // Show receipt details in a dialog
    showDialog(
      context: context,
      builder: (context) => ViewReceiptDialog(sale: sale),
    );
  }

  void _printSaleReceipt(SaleModel sale) async {
    try {
      // Show loading state
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating receipt for printing...')),
        );
      }

      // Use SalesProvider to generate and print the receipt (same as ViewReceiptDialog)
      final salesProvider = context.read<SalesProvider>();
      final success = await salesProvider.generateReceiptPdf(sale.id);
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt sent to printer successfully!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to print receipt')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing receipt: $e')),
        );
      }
    }
  }

  void _createReceiptForSale(SaleModel sale) {
    // Show create receipt dialog with pre-selected sale
    showDialog(
      context: context,
      builder: (context) => CreateSimpleReceiptDialog(
        initialSaleId: sale.id,
        isViewOnly: false,
      ),
    );
  }

  Widget _buildReceiptCard(ReceiptModel receipt, ReceiptProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(receipt.status),
          child: Icon(_getStatusIcon(receipt.status), color: Colors.white),
        ),
        title: Text(
            receipt.receiptNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${l10n.customer}: ${receipt.customerName}'),
            Text(
              '${l10n.amount}: ${receipt.formattedPaymentAmount}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text('${l10n.status}: ${receipt.statusDisplay}'),
                const SizedBox(width: 8),
                Text('|  ${l10n.generated}: ${receipt.formattedGeneratedDate}'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReceiptAction(value, receipt, provider),
          itemBuilder: (context) => _buildReceiptActionMenu(receipt),
        ),
        onTap: () => _showReceiptDetails(receipt, provider),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'GENERATED': return Colors.blue;
      case 'SENT': return Colors.orange;
      case 'VIEWED': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'GENERATED': return Icons.receipt;
      case 'SENT': return Icons.send;
      case 'VIEWED': return Icons.visibility;
      default: return Icons.help_outline;
    }
  }

  List<PopupMenuEntry<String>> _buildReceiptActionMenu(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;

    return [
      PopupMenuItem(
        value: 'view',
        child: Row(children: [const Icon(Icons.visibility, color: Colors.blue), const SizedBox(width: 8), Text(l10n.view)]),
      ),
      if (receipt.pdfFile != null)
        PopupMenuItem(
          value: 'download_pdf',
          child: Row(children: [const Icon(Icons.picture_as_pdf, color: Colors.green), const SizedBox(width: 8), Text('Download PDF')]),
        ),
      PopupMenuItem(
        value: 'edit',
        child: Row(children: [const Icon(Icons.edit, color: Colors.orange), const SizedBox(width: 8), Text(l10n.edit)]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'delete',
        child: Row(children: [const Icon(Icons.delete, color: Colors.red), const SizedBox(width: 8), Text(l10n.delete)]),
      ),
    ];
  }

  void _handleReceiptAction(String action, ReceiptModel receipt, ReceiptProvider provider) {
    switch (action) {
      case 'view':
        _showReceiptDetails(receipt, provider);
        break;
      case 'download_pdf':
        _downloadReceiptPdf(receipt);
        break;
      case 'edit':
        _showEditReceiptDialog(receipt, provider);
        break;
      case 'delete':
        _showDeleteReceiptDialog(receipt, provider);
        break;
    }
  }

  void _showCreateSimpleReceiptDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const CreateSimpleReceiptDialog());
  }

  void _downloadReceiptPdf(ReceiptModel receipt) {
    if (receipt.pdfFile != null) {
      // Show dialog with PDF URL
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.picture_as_pdf, color: Colors.green, size: 48),
          title: const Text('Receipt PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PDF generated successfully!'),
              const SizedBox(height: 8),
              Text('Available at:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                receipt.pdfFile!,
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.info_outline, color: Colors.orange, size: 48),
          title: const Text('PDF Not Available'),
          content: const Text('PDF not available for this receipt. Please generate the PDF first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showReceiptDetails(ReceiptModel receipt, ReceiptProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.receiptDetails(receipt.receiptNumber)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(l10n.receiptNumber, receipt.receiptNumber),
                _buildDetailRow(l10n.amount, receipt.formattedPaymentAmount),
                _buildDetailRow(l10n.status, receipt.statusDisplay),
                _buildDetailRow(l10n.generatedAt, receipt.formattedGeneratedDate),
                const Divider(),
                if (receipt.customerName.isNotEmpty)
                  _buildDetailRow(l10n.customer, receipt.customerName),
                if (receipt.notes?.isNotEmpty == true)
                  _buildDetailRow(l10n.notes, receipt.notes!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          )
        ],
      ),
    );
  }

  void _showEditReceiptDialog(ReceiptModel receipt, ReceiptProvider provider) {
    showDialog(
      context: context,
      builder: (context) => EditReceiptDialog(receipt: receipt),
    );
  }

  void _showDeleteReceiptDialog(ReceiptModel receipt, ReceiptProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReceipt(receipt.receiptNumber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.areYouSureDeleteReceipt),
            const SizedBox(height: 8),
            Text(
              '${l10n.amount}: ${receipt.formattedPaymentAmount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.thisActionCannotBeUndone, style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.deleteReceipt(receipt.id);
              if (success && mounted) {
                _showSuccessDialog(l10n.receiptDeletedSuccessfully);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
            width: 140,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}