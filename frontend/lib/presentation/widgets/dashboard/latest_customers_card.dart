import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class LatestCustomersCard extends StatelessWidget {
  final Map<String, dynamic> analytics;
  
  const LatestCustomersCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    // Get real latest customers data from analytics
    final latestCustomers = analytics['latest_customers'] as List<dynamic>? ?? [];
    
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: context.formFieldSpacing),
          _buildCustomersList(context, latestCustomers.cast<Map<String, dynamic>>()),
          SizedBox(height: context.formFieldSpacing),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            Icons.people_rounded,
            color: Colors.indigo,
            size: context.iconSize('medium'),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest Customers',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'Recently registered customers',
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            color: Colors.indigo,
            size: context.iconSize('small'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersList(BuildContext context, List<Map<String, dynamic>> customers) {
    return Column(
      children: customers.map((customer) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.smallPadding / 2),
          child: _buildCustomerItem(context, customer),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerItem(BuildContext context, Map<String, dynamic> customer) {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: context.isTablet ? 25 : 20,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: Text(
              customer['avatar'] as String? ?? 'CU',
              style: TextStyle(
                fontSize: context.isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
          ),
          SizedBox(width: context.cardPadding),
          // Customer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'] as String? ?? 'Unknown Customer',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  customer['email'] as String? ?? 'No email',
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatLastOrderDate(customer['last_order_date'] as String?),
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${(customer['total_spent'] as num?)?.toDouble() ?? 0.0}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding / 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: context.captionFontSize - 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_rounded,
            color: AppTheme.primaryMaroon,
            size: context.iconSize('small'),
          ),
          SizedBox(width: 8),
          Text(
            'View All Customers',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastOrderDate(String? lastOrderDate) {
    if (lastOrderDate == null) return 'No orders';
    
    try {
      final date = DateTime.parse(lastOrderDate);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${(difference.inDays / 30).floor()} months ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
