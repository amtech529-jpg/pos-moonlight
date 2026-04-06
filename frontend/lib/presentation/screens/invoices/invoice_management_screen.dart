import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../widgets/sales/view_invoice_dialog.dart';
import '../../widgets/sales/edit_invoice_dialog.dart';
import '../../widgets/sales/create_invoice_dialog.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit global pinkish/beige background
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: 24),

            // Stats row (Total Invoice & Total Received)
            _buildSummaryCards(),

            const SizedBox(height: 24),

            // Search Bar Section
            _buildSearchSection(),

            const SizedBox(height: 24),

            // Invoice Table
            _buildInvoiceTable(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        double totalInvoiced = 0;
        double totalPaid = 0;
        double totalDue = 0;

        for (var inv in provider.invoices) {
          if (inv.status == 'CANCELLED') continue;

          totalInvoiced += inv.totalAmount;
          totalPaid += inv.amountPaid;

          // Only add to Pending Due if status is not terminal
          final upperStatus = inv.status.toUpperCase();
          if (upperStatus != 'CLOSED' &&
              upperStatus != 'WRITTEN_OFF' &&
              upperStatus != 'CANCELLED' && 
              upperStatus != 'PAID') {
            totalDue += inv.amountDue;
          }
        }

        return Row(
          children: [
            Expanded(child: _buildSummaryCard("Total Invoiced", "Rs. ${totalInvoiced.toStringAsFixed(0)}")),
            const SizedBox(width: 24),
            Expanded(child: _buildSummaryCard("Total Paid", "Rs. ${totalPaid.toStringAsFixed(0)}")),
            const SizedBox(width: 24),
            Expanded(child: _buildSummaryCard("Pending Due", "Rs. ${totalDue.toStringAsFixed(0)}")),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Invoice & Payments",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Manage all your Invoice & Payments",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
             showDialog(
               context: context,
               builder: (context) => const CreateInvoiceDialog(),
             );
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            "Add Invoice",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B61FF), // Premium purple for action
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }


  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
               onChanged: (value) => context.read<InvoiceProvider>().setFilters(search: value),
              decoration: InputDecoration(
                filled: true,
                fillColor: _searchFocusNode.hasFocus
                    ? const Color(0xFFD9D9D9).withOpacity(0.7)
                    : const Color(0xFFE8E8E8),
                hintText: "Search Invoice # or Customer...",
                hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8E8E8E),
                  size: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTable() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
           return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (provider.filteredInvoices.isEmpty) {
           return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("No invoices found"),
          ));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    // Table Header strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text("#Invoice", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                          Expanded(flex: 3, child: Text("Customer", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                          Expanded(flex: 2, child: Text("Total", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Paid", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Due", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                          Expanded(flex: 5, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Table Rows
                     ...provider.filteredInvoices.map((invoice) {
                        final statusColor = invoice.statusColor;
                        return _buildInvoiceRow(context, invoice, statusColor);
                      }),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildInvoiceRow(BuildContext context, InvoiceModel invoice, Color statusColor) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    // First try using the explicit customerId, else try via orderId.
    String? customerId = invoice.customerId;
    if (customerId == null && invoice.orderId != null) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final matchingOrder = orderProvider.allOrders.where((o) => o.id == invoice.orderId).firstOrNull;
      if (matchingOrder != null) {
        customerId = matchingOrder.customerId;
      }
    }
    
    final customer = customerProvider.allCustomers.where((c) => c.id == customerId).firstOrNull;
    final displayName = customer?.orderDisplayName ?? (invoice.customerName ?? 'Unknown');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(flex: 3, child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF333333)), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text("Rs. ${invoice.grandTotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text("Rs. ${invoice.amountPaid.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.green), textAlign: TextAlign.center)),
          Expanded(
            flex: 2, 
            child: Text(
              "Rs. ${(['PAID', 'CLOSED', 'WRITTEN_OFF', 'CANCELLED'].contains(invoice.status.toUpperCase())) ? '0' : invoice.amountDue.toStringAsFixed(0)}", 
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 12, 
                color: (['PAID', 'CLOSED', 'WRITTEN_OFF', 'CANCELLED'].contains(invoice.status.toUpperCase())) ? Colors.grey : (invoice.amountDue > 0 ? Colors.red : Colors.grey)
              ), 
              textAlign: TextAlign.center
            )
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    invoice.statusDisplay,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (invoice.amountDue > 0 && invoice.status.toUpperCase() != 'PARTIALLY_PAID' && invoice.status.toUpperCase() != 'WRITTEN_OFF' && invoice.status.toUpperCase() != 'CLOSED' && invoice.status.toUpperCase() != 'PAID')
                  _buildActionButton(
                    icon: Icons.add_card_rounded,
                    color: Colors.green,
                    tooltip: "Quick Pay",
                    onTap: () => _handleEditInvoice(context, invoice), 
                  ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.edit_note_rounded,
                  color: Colors.blue,
                  tooltip: "Edit",
                  onTap: () => _handleEditInvoice(context, invoice),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.visibility_rounded,
                  color: Colors.teal,
                  tooltip: "View",
                  onTap: () => _handleViewInvoice(context, invoice),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.delete_forever_rounded,
                  color: Colors.red,
                  tooltip: "Delete",
                  onTap: () => _handleDeleteInvoice(context, invoice),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? "",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }


  void _handleEditInvoice(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => EditInvoiceDialog(invoice: invoice),
    );
  }

  void _handleViewInvoice(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => ViewInvoiceDialog(invoice: invoice),
    );
  }

  void _handleDeleteInvoice(BuildContext context, InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: const Text(
          'Delete Invoice',
          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
              style: const TextStyle(color: Color(0xFF444444), fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<InvoiceProvider>().deleteInvoice(invoice.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
