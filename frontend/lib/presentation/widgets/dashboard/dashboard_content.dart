import 'package:flutter/material.dart';
import 'package:frontend/src/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/providers/dashboard_provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/models/order/order_model.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/customer/customer_screen.dart';
import '../../screens/vendor/vendor_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/invoices/invoice_management_screen.dart';
import '../../screens/labor/labor_screen.dart';
import '../../screens/order/order_screen.dart';
import '../../screens/payables/payables_screen.dart';
import '../../screens/product/product_screen.dart';
import '../../screens/purchases/purchases_screen.dart';
import '../../screens/quotations/quotations_screen.dart';
import '../../screens/ledger/ledger_module_screen.dart';
import '../../screens/returns/return_management_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/import_export_screen.dart';
import '../../screens/tools/tools_inventory_screen.dart';
import '../../screens/reports/reports_analytics_screen.dart';
import '../../screens/users/user_management_screen.dart';
import '../../screens/backup/backup_security_screen.dart';
import 'recent_orders_card.dart';
import 'dashboard_alerts_card.dart';

class DashboardContent extends StatelessWidget {
  final int selectedIndex;

  const DashboardContent({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return const PurchasesScreen();
      case 2:
        return const InventoryManagementScreen(); // Optimized and Track-wise inventory
      case 3:
        return const CategoryPage();
      case 4:
        return const QuotationsScreen();
      case 5:
        return const OrderPage();
      case 6:
        return const CustomerPage();
      case 7:
        return const VendorPage();
      case 8:
        return const InvoiceManagementScreen();
      case 9:
        return const PayablesPage();
      case 10:
        return const ReturnManagementScreen();
      case 11:
        return const LedgerModuleScreen();
      case 12:
        return const ExpensesPage();
      case 13:
        return const ToolsInventoryScreen();
      case 14:
        return const LaborPage(); // HR & Salary -> Labor
      case 15:
        return const ReportsAnalyticsScreen();
      case 16:
        return const UserManagementScreen();
      case 17:
        return const ImportExportScreen();
      case 18:
        return const BackupSecurityScreen();
      default:
        return _buildDashboard(context);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    return Consumer2<DashboardProvider, OrderProvider>(
      builder: (context, dashboardProvider, orderProvider, child) {
        final stats = dashboardProvider.dashboardStats;
        final orders = orderProvider.orders;

        return Container(
          color: Colors.transparent, // Inherit Screen's #CFBEBE
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Welcome back, here's what's happening today.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),

                // Stats Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Orders",
                        value: orderProvider.totalCount.toString(),
                        icon: Icons.shopping_cart_outlined,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Revenue",
                        value: "PKR ${dashboardProvider.totalRevenue.toStringAsFixed(0)}",
                        icon: Icons.bar_chart_rounded,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: "Active Rentals",
                        value: ((orderProvider.statistics?.statusBreakdown['confirmed'] ?? 0) + 
                                (orderProvider.statistics?.statusBreakdown['ready'] ?? 0) +
                                (orderProvider.statistics?.statusBreakdown['delivered'] ?? 0)).toString(),
                        icon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Customer",
                        value: dashboardProvider.totalCustomers.toString(),
                        icon: Icons.people_outline_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Financial Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Expenses",
                        value: "PKR ${dashboardProvider.totalExpenses.toStringAsFixed(0)}",
                        icon: Icons.money_off_csred_outlined,
                        iconColor: Colors.red[300],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: "Item Damages",
                        value: "PKR ${dashboardProvider.totalDamage.toStringAsFixed(0)}",
                        icon: Icons.report_problem_outlined,
                        iconColor: Colors.orange[300],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Recovered",
                        value: "PKR ${dashboardProvider.totalRecovered.toStringAsFixed(0)}",
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green[300],
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Spacer(), // Empty space to keep it symmetric or add more later
                  ],
                ),

                const SizedBox(height: 32),

                // Alerts & Reminders Section
                if (dashboardProvider.reminders.isNotEmpty) ...[
                  DashboardAlertsCard(reminders: dashboardProvider.reminders),
                  const SizedBox(height: 32),
                ],

                // Recent Orders Section
                const RecentOrdersCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                ),
              ),
              Icon(
                icon,
                color: iconColor ?? AppTheme.primaryMaroon,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
