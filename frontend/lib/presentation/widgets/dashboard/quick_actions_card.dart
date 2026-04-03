import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  List<Map<String, dynamic>> getQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'title': l10n.newOrder,
        'subtitle': l10n.createOrder,
        'icon': Icons.add_shopping_cart_rounded,
        'color': Colors.green,
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
      },
      {
        'title': l10n.addProduct,
        'subtitle': l10n.manageInventory,
        'icon': Icons.inventory_2_rounded,
        'color': Colors.blue,
        'gradient': [const Color(0xFF2196F3), const Color(0xFF1976D2)],
      },
      {
        'title': l10n.payment,
        'subtitle': l10n.processPayment,
        'icon': Icons.payment_rounded,
        'color': Colors.purple,
        'gradient': [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      },
      {
        'title': l10n.reports,
        'subtitle': l10n.viewAnalytics,
        'icon': Icons.analytics_rounded,
        'color': Colors.orange,
        'gradient': [const Color(0xFFFF9800), const Color(0xFFF57C00)],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1.w,
            offset: Offset(0, 0.5.w),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(1.w),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: AppTheme.accentGold,
                  size: 2.5.sp,
                ),
              ),

              SizedBox(width: 1.5.w),

              Text(
                l10n.quickActions,
                style: TextStyle(
                  fontSize: 2.2.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 1.5.w,
              mainAxisSpacing: 1.5.h,
              childAspectRatio: 1.8,
            ),
            itemCount: getQuickActions(context).length,
            itemBuilder: (context, index) {
              final action = getQuickActions(context)[index];
              return _buildActionCard(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(1.5.w),
        child: Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: action['gradient'],
            ),
            borderRadius: BorderRadius.circular(1.5.w),
            boxShadow: [
              BoxShadow(
                color: action['color'].withOpacity(0.3),
                blurRadius: 1.w,
                offset: Offset(0, 0.5.w),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(0.8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1.w),
                ),
                child: Icon(action['icon'], color: Colors.white, size: 2.5.sp),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action['title'],
                    style: TextStyle(
                      fontSize: 1.8.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    action['subtitle'],
                    style: TextStyle(
                      fontSize: 1.4.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
