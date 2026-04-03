import 'package:flutter/material.dart';
import 'package:frontend/src/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/providers/dashboard_provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/models/order/order_model.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import '../../screens/customer/customer_screen.dart';
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
        return const QuotationsScreen();
      case 4:
        return const OrderPage();
      case 5:
        return const CustomerPage();
      case 6:
        return const InvoiceManagementScreen();
      case 7:
        return const PayablesPage();
      case 8:
        return const ReturnManagementScreen();
      case 9:
        return const LedgerModuleScreen();
      case 10:
        return const ExpensesPage();
      case 11:
        return const ToolsInventoryScreen();
      case 12:
        return const LaborPage(); // HR & Salary -> Labor
      case 13:
        return const ReportsAnalyticsScreen();
      case 14:
        return const UserManagementScreen();
      case 15:
        return const ImportExportScreen();
      case 16:
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
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            color: iconColor ?? const Color(0xFFCCCCCC),
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '$title Page',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature is currently under development.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Provider.of<DashboardProvider>(
                  context,
                  listen: false,
                ).selectMenu(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
