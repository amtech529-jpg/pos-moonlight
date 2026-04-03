import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class TrendingProductsCard extends StatelessWidget {
  final Map<String, dynamic> analytics;
  
  const TrendingProductsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    // Get real trending products data from analytics
    final trendingProducts = analytics['trending_products'] as List<dynamic>? ?? [];
    
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
          _buildProductsList(context, trendingProducts.cast<Map<String, dynamic>>()),
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
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: context.iconSize('medium'),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending Products',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'Best selling items this week',
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
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: Colors.orange,
            size: context.iconSize('small'),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context, List<Map<String, dynamic>> products) {
    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < products.length - 1 ? context.smallPadding : 0),
          child: _buildProductItem(context, product),
        );
      }).toList(),
    );
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final stockLevel = (product['stock'] as num?)?.toInt() ?? 0;
    final stockStatus = stockLevel < 20 
        ? 'Low Stock' 
        : stockLevel < 50 
            ? 'Medium Stock' 
            : 'Good Stock';
    final stockColor = stockLevel < 20 
        ? Colors.red 
        : stockLevel < 50 
            ? Colors.orange 
            : Colors.green;
    
    // Calculate trend (mock for now, can be enhanced later)
    final trendPercentage = 15.0; // Mock trend
    final isTrendingUp = trendPercentage > 0;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Product Image/Emoji
          Container(
            width: context.isTablet ? 50 : 40,
            height: context.isTablet ? 50 : 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Center(
              child: Text(
                _getProductEmoji(product['name'] as String? ?? ''),
                style: TextStyle(
                  fontSize: context.isTablet ? 20 : 16,
                ),
              ),
            ),
          ),
          SizedBox(width: context.cardPadding),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String? ?? 'Unknown Product',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  product['category'] as String? ?? 'Uncategorized',
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.smallPadding / 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        stockStatus,
                        style: TextStyle(
                          fontSize: context.captionFontSize - 2,
                          fontWeight: FontWeight.w600,
                          color: stockColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$stockLevel units',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sales & Trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(product['sales'] as num?)?.toInt() ?? 0} sold',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PKR ${(product['revenue'] as num?)?.toDouble() ?? 0.0}',
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.green,
                    size: 14,
                  ),
                  SizedBox(width: 2),
                  Text(
                    '+${trendPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProductEmoji(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('phone') || name.contains('mobile')) return '📱';
    if (name.contains('laptop') || name.contains('computer')) return '💻';
    if (name.contains('headphone') || name.contains('ear')) return '🎧';
    if (name.contains('watch')) return '⌚';
    if (name.contains('cable') || name.contains('charger')) return '🔌';
    if (name.contains('mouse')) return '🖱️';
    if (name.contains('keyboard')) return '⌨️';
    if (name.contains('speaker')) return '🔊';
    if (name.contains('camera')) return '📷';
    return '📦'; // Default package emoji
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: Colors.orange,
            size: context.iconSize('small'),
          ),
          SizedBox(width: 8),
          Text(
            'View All Products',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
