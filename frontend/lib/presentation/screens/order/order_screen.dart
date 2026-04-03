import 'package:frontend/src/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/models/order/order_model.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import '../../widgets/order/add_order_dialog.dart';
import '../../widgets/order/view_order_dialog.dart';
import '../../widgets/order/edit_order_dialog.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showAddOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddOrderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Order & Rental', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Order & Rental', 'edit') ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit global pinkish/beige background
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(context, canAdd),
            const SizedBox(height: 24),

            // Search Bar Section (Standardized White Outer Container)
            _buildSearchSection(),
            const SizedBox(height: 24),

            // Orders & Rental Table
            _buildOrdersTable(canEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canAdd) {
    bool isWide = MediaQuery.of(context).size.width > 700;
    
    final headerContent = [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Orders", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
            SizedBox(height: 2),
            Text("Manage your customer orders", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF666666))),
          ],
        ),
        if (!isWide) const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.read<OrderProvider>().refreshData(),
              icon: const Icon(Icons.refresh, color: AppTheme.primaryMaroon),
              tooltip: "Refresh Orders",
            ),
            const SizedBox(width: 12),
            if (canAdd) _buildAddOrderButton(),
          ],
        ),
    ];

    return isWide 
        ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: headerContent)
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: headerContent);
  }

  Widget _buildAddOrderButton() {
    return ElevatedButton(
      onPressed: _showAddOrderDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF222222),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: const Text(
        "+ New Order",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
              onChanged: (value) => context.read<OrderProvider>().searchOrders(value),
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: _searchFocusNode.hasFocus
                    ? const Color(0xFFD9D9D9).withOpacity(0.7)
                    : const Color(0xFFE8E8E8),
                hintText: "Search Inventory...",
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

  Widget _buildOrdersTable(bool canEdit) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFFE74C3C)),
            ),
          );
        }

        if (provider.errorMessage != null && provider.orders.isEmpty) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.errorMessage!),
                TextButton(
                  onPressed: () => provider.refreshData(),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        final orders = provider.orders;

        if (orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No orders found."),
            ),
          );
        }

        return Column(
          children: [
            // Table Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text("Quote ID", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                  Expanded(flex: 2, child: Text("Client", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                  Expanded(flex: 1, child: Text("Items", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                  Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                  Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)))),
                  Expanded(flex: 1, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF666666)), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Dynamic Data Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length + (provider.paginationInfo?.hasNext ?? false ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == orders.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: provider.isLoading 
                          ? const CircularProgressIndicator(color: Color(0xFFE74C3C))
                          : ElevatedButton(
                              onPressed: () => provider.loadNextPage(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF222222),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Load More Orders"),
                            ),
                      ),
                    );
                  }
                  
                  final order = orders[index];
                  return _buildOrderRow(
                    context,
                    order,
                    order.orderSummary['total_items']?.toString() ?? "0",
                    _getStatusColor(order.status),
                    canEdit,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return const Color(0xFFFF9F43);
      case OrderStatus.CONFIRMED:
      case OrderStatus.READY:
      case OrderStatus.DELIVERED:
      case OrderStatus.RETURNED:
        return const Color(0xFF2ECC71);
      case OrderStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderRow(BuildContext context, OrderModel order, String itemsCount, Color statusColor, bool canEdit) {
    final String id = order.id.substring(0, 8).toUpperCase();
    final String client = order.customerName;
    final String amount = "PKR ${order.totalAmount.toStringAsFixed(0)}";
    final String date = order.dateOrdered.toString().split(' ')[0];
    final String status = order.status.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Expanded(flex: 2, child: Text(client, style: const TextStyle(color: Color(0xFF666666), fontSize: 14))),
          Expanded(flex: 1, child: Text(itemsCount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF666666)))),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canEdit)
                  InkWell(
                    onTap: () => _editOrder(context, order),
                    child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black)),
                  ),
                if (canEdit) const SizedBox(width: 14),
                InkWell(
                  onTap: () => _viewOrder(context, order),
                  child: const Text("View", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFE74C3C))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => ViewOrderDialog(order: order),
    );
  }

  void _editOrder(BuildContext context, OrderModel order) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditOrderDialog(order: order),
    );

    if (result == true) {
      // Refresh list if updated
      context.read<OrderProvider>().refreshData();
    }
  }
}
