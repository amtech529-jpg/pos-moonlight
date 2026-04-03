import 'package:flutter/material.dart';
import 'package:frontend/src/core/app_images.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onAddNew;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final int notificationCount;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.onAddNew,
    this.searchController,
    this.onSearchChanged,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFE),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        children: [
          /* // Search Field
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0x6BD9D9D9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ), */
          const Spacer(),
          const SizedBox(width: 24),

          // Logo and Admin Section
          Row(
            children: [
              Image.asset(
                AppImages.logo,
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
