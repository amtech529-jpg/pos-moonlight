import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:frontend/src/providers/auth_provider.dart';
import 'package:frontend/src/providers/quotation_provider.dart';
import 'package:frontend/src/providers/product_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/quotations/add_quotation_dialog.dart';
import 'package:frontend/presentation/widgets/quotations/edit_quotation_dialog.dart';
import 'package:frontend/presentation/widgets/quotations/delete_quotation_dialog.dart';
import 'package:frontend/src/models/quotation/quotation_model.dart';
import 'package:frontend/src/services/pdf_quotation_service.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Fetch data
    Future.microtask(() => context.read<QuotationProvider>().initialize());
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
      backgroundColor: Colors.transparent,
      body: Consumer<QuotationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.quotations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalValue = provider.quotations.fold(0.0, (sum, q) => sum + q.finalAmount);
          final pendingCount = provider.quotations.where((q) => q.status == 'PENDING').length;
          final acceptedCount = provider.quotations.where((q) => q.status == 'ACCEPTED').length;

          final authProvider = Provider.of<AuthProvider>(context);
          final currentUser = authProvider.currentUser;
          final bool canAdd = currentUser?.canPerform('Quotation', 'add') ?? true;
          final bool canEdit = currentUser?.canPerform('Quotation', 'edit') ?? true;
          final bool canDelete = currentUser?.canPerform('Quotation', 'delete') ?? true;
          final bool canAddOrder = currentUser?.canPerform('Order & Rental', 'add') ?? true;

          return RefreshIndicator(
            onRefresh: () => provider.initialize(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(canAdd),
                  const SizedBox(height: 18),
                  _buildStatsRow(provider.quotations.length.toString(), pendingCount.toString(), acceptedCount.toString(), totalValue),
                  const SizedBox(height: 24),
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildQuotationsTable(provider.quotations, canEdit, canDelete, canAddOrder),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool canAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quotations",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            SizedBox(height: 2),
            Text(
              "Manage and Track quotations for events",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
            ),
          ],
        ),
        if (canAdd)
          ElevatedButton.icon(
            onPressed: () => _showAddQuotationDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("New Quote", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF222222),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
      ],
    );
  }

  void _showAddQuotationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddQuotationDialog(),
    );
  }

  void _showEditQuotationDialog(QuotationModel quotation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditQuotationDialog(quotation: quotation),
    );
  }

  void _showDeleteQuotationDialog(QuotationModel quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteQuotationDialog(quotation: quotation),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
      if (success && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quotation deleted successfully")));
      }
    }
  }

  Widget _buildStatsRow(String total, String pending, String accepted, double totalValue) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard("Total Quotations", total, Colors.black)),
        const SizedBox(width: 20),
        Expanded(child: _buildSummaryCard("Pending", pending, Colors.orange)),
        const SizedBox(width: 20),
        Expanded(child: _buildSummaryCard("Accepted", accepted, const Color(0xFF2ECC71))),
        const SizedBox(width: 20),
        Expanded(child: _buildSummaryCard("Total Value", "Rs. ${totalValue.toStringAsFixed(0)}", AppTheme.primaryMaroon)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF999999), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: TextField(
          focusNode: _searchFocusNode,
          controller: _searchController,
          onChanged: (v) => context.read<QuotationProvider>().searchQuotations(v),
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _searchFocusNode.hasFocus ? const Color(0xFFD9D9D9).withOpacity(0.7) : const Color(0xFFE8E8E8),
            hintText: "Search Quotations by Event or Customer...",
            hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E8E), size: 22),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationsTable(List<QuotationModel> quotations, bool canEdit, bool canDelete, bool canAddOrder) {
    final filtered = quotations;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Expanded(flex: 1, child: Text("Quotation ID", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
              SizedBox(width: 24),
              Expanded(flex: 3, child: Text("Clients", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
              Expanded(flex: 1, child: Text("Value", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
              Expanded(flex: 1, child: Text("Days Left", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
              Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
              Expanded(flex: 2, child: Text("Action", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("No quotations found.", style: TextStyle(color: Colors.grey)),
          )
        else ...[
          ...filtered.map((q) => _buildTableRow(q, canEdit, canDelete, canAddOrder)).toList(),
          if (context.watch<QuotationProvider>().hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: context.watch<QuotationProvider>().isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => context.read<QuotationProvider>().loadMore(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Load More Quotations"),
                    ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTableRow(QuotationModel quotation, bool canEdit, bool canDelete, bool canAddOrder) {
    Color statusColor = const Color(0xFFFE813E); // Brand Orange for PENDING
    Color textOnStatus = Colors.white;
    double opacity = 0.94;

    if (quotation.status == 'ACCEPTED') {
      statusColor = const Color(0xFF2ECC71);
      textOnStatus = Colors.white;
      opacity = 0.94;
    } else if (quotation.status == 'CONVERTED') {
      statusColor = Colors.purple;
      textOnStatus = Colors.white;
      opacity = 0.94;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text(quotation.quotationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quotation.eventName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(quotation.customerName,
                    style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Text("Rs. ${quotation.finalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          Expanded(
              flex: 1,
              child: Text(
                  "${quotation.validUntil.difference(DateTime.now()).inDays} Days",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(quotation.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textOnStatus, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (canEdit)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _showEditQuotationDialog(quotation),
                    tooltip: 'Edit',
                  ),
                if (quotation.status != 'CONVERTED' && canAddOrder)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 20, color: Colors.green),
                    onPressed: () => _showConvertToOrderDialog(quotation),
                    tooltip: 'Convert to Order',
                  ),
                if (canDelete)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    onPressed: () => _showDeleteQuotationDialog(quotation),
                    tooltip: 'Delete',
                  ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.print_outlined, size: 20, color: Colors.black),
                  onPressed: () => PdfQuotationService.printQuotation(quotation),
                  tooltip: 'Print Quotation',
                ),
                if (!canEdit && !canDelete && (!canAddOrder || quotation.status == 'CONVERTED'))
                  const Text("View-only",
                      style: TextStyle(
                          fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConvertToOrderDialog(QuotationModel quotation) async {
    final productProvider = context.read<ProductProvider>();
      final List<String> stockWarnings = [];
      
      for (var item in quotation.items) {
        if (item.product != null) {
          try {
            final p = productProvider.products.firstWhere((p) => p.id == item.product);
            // Use dateAvailableQuantity if available (range from event_date to return_date)
            final availableCount = p.dateAvailableQuantity ?? p.quantityAvailable;
            if (item.quantity > availableCount) {
              stockWarnings.add("• ${p.name}: Requested ${item.quantity}, but only $availableCount in stock for these dates.");
            }
          } catch (_) {}
        }
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                stockWarnings.isEmpty ? Icons.shopping_cart_checkout : Icons.warning_amber_rounded, 
                color: stockWarnings.isEmpty ? Colors.green : Colors.orange, 
                size: 28
              ),
              const SizedBox(width: 12),
              const Text('Convert to Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to convert quotation ${quotation.quotationNumber} to an order?',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                if (stockWarnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Stock Alerts:",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ...stockWarnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(w, style: TextStyle(color: Colors.orange[900], fontSize: 12)),
                        )),
                        const SizedBox(height: 8),
                        const Text(
                          "Converting will proceed even with low stock. You can purchase more later.",
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: stockWarnings.isEmpty ? const Color(0xFF7B61FF) : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: Text(
                stockWarnings.isEmpty ? 'CONVERT' : 'PROCEED ANYWAY', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final result = await context.read<QuotationProvider>().convertToOrder(quotation.id);
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Quotation converted to order successfully"))
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<QuotationProvider>().error ?? "Failed to convert"))
          );
        }
      }
    }
}
