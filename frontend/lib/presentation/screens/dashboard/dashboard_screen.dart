import 'package:flutter/material.dart';
import 'package:frontend/src/core/app_colors.dart';
// Import AuthProvider if not already imported
import 'package:frontend/src/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../src/providers/dashboard_provider.dart';
import '../../widgets/dashboard/dashboard_content.dart';
import '../../widgets/globals/sidebar.dart' as sidebar;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dashboardProvider = context.read<DashboardProvider>();
        dashboardProvider.setInstance(); // Set global instance
        dashboardProvider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Official pinkish/beige background
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          return Row(
            children: [
              // Sidebar
              sidebar.Sidebar(
                isExpanded: dashboardProvider.isSidebarExpanded,
                selectedIndex: dashboardProvider.selectedMenuIndex,
                onMenuSelected: (index) {
                  dashboardProvider.selectMenu(index);
                },
                onToggle: () {
                  dashboardProvider.toggleSidebar();
                },
              ),

              // Gap between Sidebar and Content
              const SizedBox(width: 10),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top Header
                    _buildHeader(context),

                    // Page Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: DashboardContent(
                          selectedIndex: dashboardProvider.selectedMenuIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDEDED), width: 1),
        ),
      ),
      child: Stack(
        children: [
          /* // Search Bar (Perfectly Centered)
          Center(
            child: Container(
              width: 400,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0x6BD9D9D9), // #D9D9D96B
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  return TextField(
                    onChanged: (value) => provider.updateSearchQuery(value),
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Color(0xFF8E8E8E),
                        size: 22,
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  );
                },
              ),
            ),
          ), */

          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.currentUser;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/moon.png', // Moon Logo
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user?.roleName ?? "Guest",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
