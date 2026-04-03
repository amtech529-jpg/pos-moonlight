import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';

class ProductOptionsMenu extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onCustomizeAndAdd;
  final VoidCallback? onCreateCustomOrder;
  final VoidCallback? onApplyDiscount;

  const ProductOptionsMenu({
    super.key,
    required this.product,
    this.onCustomizeAndAdd,
    this.onCreateCustomOrder,
    this.onApplyDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: context.smallPadding / 2),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(context.cardPadding / 2),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                    child: Icon(
                      Icons.checkroom_outlined,
                      color: Colors.grey[500],
                      size: context.iconSize('medium'),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoalGray,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PKR ${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryMaroon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Column(
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.add_shopping_cart_rounded,
                  title: l10n.addToCart,
                  subtitle: l10n.quickAddWithDefaultOptions,
                  color: AppTheme.primaryMaroon,
                  onTap: () {
                    Navigator.of(context).pop();
                    Provider.of<SalesProvider>(
                      context,
                      listen: false,
                    ).addToCartWithCustomization(
                      productId: product.id,
                      productName: product.name,
                      unitPrice: product.price,
                      quantity: 1,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite),
                            SizedBox(width: context.smallPadding),
                            Expanded(
                              child: Text(
                                '${product.name} ${l10n.addToCart}',
                                style: TextStyle(color: AppTheme.pureWhite),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                        ),
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.tune_rounded,
                  title: l10n.customizeAndAdd,
                  subtitle: l10n.setSizeQualityEmbroidery,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onCustomizeAndAdd != null) {
                      onCustomizeAndAdd!();
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.local_offer_rounded,
                  title: l10n.applyDiscount,
                  subtitle: l10n.applyDiscountBeforeAdding,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onApplyDiscount != null) {
                      onApplyDiscount!();
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.assignment_rounded,
                  title: l10n.createCustomOrder,
                  subtitle: l10n.scheduleDeliveryAndAdvance,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onCreateCustomOrder != null) {
                      onCreateCustomOrder!();
                    }
                  },
                ),
              ],
            ),

            SizedBox(height: context.cardPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.cardPadding / 2,
            vertical: context.cardPadding / 2,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.smallPadding / 1.5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Icon(icon, color: color, size: context.iconSize('medium')),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: context.iconSize('small'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
