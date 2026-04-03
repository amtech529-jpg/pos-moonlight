import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class ExistingOrdersDialog extends StatefulWidget {
  final ProductModel product;

  const ExistingOrdersDialog({super.key, required this.product});

  @override
  State<ExistingOrdersDialog> createState() => _ExistingOrdersDialogState();
}

class _ExistingOrdersDialogState extends State<ExistingOrdersDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existingOrders = _getExistingOrdersForProduct();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: 90.w,
            small: 80.w,
            medium: 70.w,
            large: 60.w,
            ultrawide: 50.w,
          ),
          maxHeight: 80.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: context.shadowBlur('heavy'),
              offset: Offset(0, context.cardPadding),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.borderRadius('large')),
                  topRight: Radius.circular(context.borderRadius('large')),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: AppTheme.pureWhite,
                      size: context.iconSize('large'),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.existingOrders,
                          style: TextStyle(
                            fontSize: context.headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            color: AppTheme.pureWhite.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      child: Container(
                        padding: EdgeInsets.all(context.smallPadding),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppTheme.pureWhite,
                          size: context.iconSize('medium'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.cardPadding),
                child: Column(children: existingOrders.map((order) => _buildOrderCard(order)).toList()),
              ),
            ),

            Container(
              padding: EdgeInsets.all(context.cardPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _showNewOrderDialog();
                          },
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: context.cardPadding / 1.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.blue, size: context.iconSize('medium')),
                                SizedBox(width: context.smallPadding),
                                Text(
                                  l10n.createNewOrder,
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  order['id'],
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: _getOrderStatusColor(order['status']),
                  ),
                ),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customerName'],
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                    Text(
                      order['phone'],
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  _getLocalizedStatus(order['status'], l10n),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: _getOrderStatusColor(order['status']),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderDate,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                  Text(
                    order['orderDate'],
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deliveryDate,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                  Text(
                    order['deliveryDate'],
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.amount,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                  Text(
                    'PKR ${order['amount']}',
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (order['notes'] != null && order['notes'].isNotEmpty) ...[
            SizedBox(height: context.smallPadding),
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_outlined, size: context.iconSize('small'), color: Colors.blue[700]),
                  SizedBox(width: context.smallPadding / 2),
                  Expanded(
                    child: Text(
                      order['notes'],
                      style: TextStyle(fontSize: context.captionFontSize, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _addToExistingOrder(order),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: context.smallPadding),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: context.iconSize('small'), color: Colors.blue),
                          SizedBox(width: context.smallPadding / 2),
                          Text(
                            l10n.addToOrder,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.smallPadding),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _viewOrderDetails(order),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  child: Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: context.iconSize('small'),
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pendingStatus;
      case 'in progress':
        return l10n.inProgressStatus;
      case 'completed':
        return l10n.completedStatus;
      case 'delivered':
        return l10n.deliveredStatus;
      case 'cancelled':
        return l10n.cancelledStatus;
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getExistingOrdersForProduct() {
    return [
      {
        'id': 'ORD001',
        'customerName': 'Aisha Khan',
        'phone': '+923001234567',
        'status': 'In Progress',
        'orderDate': '15 Jul 2024',
        'deliveryDate': '15 Aug 2024',
        'amount': '85000',
        'notes': 'Bridal dress with heavy embroidery work - custom measurements required',
      },
      {
        'id': 'ORD004',
        'customerName': 'Zara Sheikh',
        'phone': '+923007777777',
        'status': 'Pending',
        'orderDate': '27 Jul 2024',
        'deliveryDate': '25 Aug 2024',
        'amount': '120000',
        'notes': 'Complete wedding collection with accessories',
      },
    ];
  }

  void _addToExistingOrder(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.productAddedToOrder(widget.product.name, order['id'])),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    // Navigate to order details page
  }

  void _showNewOrderDialog() {
    // Show create new order dialog
  }
}
