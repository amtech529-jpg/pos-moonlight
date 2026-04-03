import 'package:flutter/material.dart';
import 'package:frontend/src/core/app_colors.dart';
import 'package:frontend/src/core/app_images.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../auth/logout_dialog.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final VoidCallback onToggle;
  final bool isExpanded;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.onToggle,
    required this.isExpanded,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Map<String, dynamic>> getMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      {
        'icon': Icons.dashboard_outlined,
        'activeIcon': Icons.dashboard,
        'title': l10n.dashboard,
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag,
        'title': "Purchase",
      },
      {
        'icon': Icons.inventory_2_outlined,
        'activeIcon': Icons.inventory_2,
        'title': "Inventory",
      },
      {
        'icon': Icons.description_outlined,
        'activeIcon': Icons.description,
        'title': "Quotation",
      },
      {
        'icon': Icons.event_note_outlined,
        'activeIcon': Icons.event_note,
        'title': "Order & Rental",
      },
      {
        'icon': Icons.people_outline_rounded,
        'activeIcon': Icons.people,
        'title': "Customer Management",
      },
      {
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long,
        'title': "Invoice & Payment",
      },
      {
        'icon': Icons.handshake_outlined,
        'activeIcon': Icons.handshake,
        'title': "Partner/Payables",
      },
      {
        'icon': Icons.assignment_return_outlined,
        'activeIcon': Icons.assignment_return,
        'title': "Return & Tally",
      },
      {
        'icon': Icons.account_balance_outlined,
        'activeIcon': Icons.account_balance,
        'title': "Ledger",
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'activeIcon': Icons.account_balance_wallet,
        'title': "Expense Management",
      },
      {
        'icon': Icons.build_outlined,
        'activeIcon': Icons.build,
        'title': "Tools & Consumables",
      },
      {
        'icon': Icons.badge_outlined,
        'activeIcon': Icons.badge,
        'title': "HR & Salary",
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart,
        'title': l10n.reportsAnalytics,
      },
      {
        'icon': Icons.manage_accounts_outlined,
        'activeIcon': Icons.manage_accounts,
        'title': l10n.userRoles,
      },
      {
        'icon': Icons.file_download_outlined,
        'activeIcon': Icons.file_download,
        'title': "Import/Export",
      },
      {
        'icon': Icons.security_outlined,
        'activeIcon': Icons.security,
        'title': "Backup",
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = getMenuItems(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Mapping sidebar titles to module names for permission check
    final moduleMapping = {
      "Dashboard": "Dashboard",
      "Purchase": "Purchase",
      "Inventory": "Inventory",
      "Quotation": "Quotation",
      "Order & Rental": "Order & Rental",
      "Customer Management": "Customer Management",
      "Invoice & Payment": "Invoice & Payment",
      "Partner/Payables": "Partner/Payables",
      "Return & Tally": "Return & Tally",
      "Ledger": "Ledger",
      "Expense Management": "Expense Management",
      "Tools & Consumables": "Tools & Consumables",
      "HR & Salary": "HR & Salary",
      "Reports & Analytics": "Reports", // Matching l10n name if possible
      "User Roles": "User Management", // Special case
      "Import/Export": "Import/Export",
      "Backup": "Backup",
    };

    return Container(
      width: widget.isExpanded ? 353 : 88,
      height: 100.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFE),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 4,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand Logo Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: widget.isExpanded
                ? Row(
                    children: [
                      Image.asset(AppImages.logo, height: 64, width: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Moon Light Events",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.0,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rent Management",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                                height: 1.0,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(AppImages.logo, height: 64, width: 64),
                    ),
                  ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderGray,
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = index == widget.selectedIndex;
                final title = item['title'].toString();
                
                // Permission Check
                if (user != null && !user.isSuperuser && user.roleName != 'Admin') {
                  // Special check for User Roles - usually only Admin
                  if (title.contains("User Roles")) return const SizedBox.shrink();
                  
                  final moduleName = moduleMapping[title] ?? title;
                  if (!user.hasPermission(moduleName)) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onMenuSelected(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isExpanded ? 12 : 0,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.grey.shade100
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: widget.isExpanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] : item['icon'],
                              color: Colors.black87,
                              size: 20,
                            ),
                            if (widget.isExpanded) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Profile & Toggle Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(top: BorderSide(color: AppColors.borderGray)),
            ),
            child: Column(
              children: [
                if (widget.isExpanded)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      return Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : "A",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? "Admin",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textBlack,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user?.email ?? "admin@moonlight.com",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const LogoutDialogWidget(
                            isExpanded: false,
                          ), // Small icon only here
                        ],
                      );
                    },
                  )
                else
                  const LogoutDialogWidget(isExpanded: false),

                const SizedBox(height: 16),

                InkWell(
                  onTap: widget.onToggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.borderGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isExpanded
                          ? Icons.keyboard_double_arrow_left
                          : Icons.keyboard_double_arrow_right,
                      color: AppColors.textGray,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
