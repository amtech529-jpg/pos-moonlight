import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/providers/inventory_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class RealTimeInventoryWidget extends StatefulWidget {
  final List<String> productIds;
  final VoidCallback? onStockUpdated;
  final bool showAlerts;
  final bool showStockInfo;

  const RealTimeInventoryWidget({super.key, required this.productIds, this.onStockUpdated, this.showAlerts = true, this.showStockInfo = true});

  @override
  State<RealTimeInventoryWidget> createState() => _RealTimeInventoryWidgetState();
}

class _RealTimeInventoryWidgetState extends State<RealTimeInventoryWidget> {
  @override
  void initState() {
    super.initState();
    // Load initial stock data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productIds.isNotEmpty) {
        context.read<InventoryProvider>().checkStockAvailability(widget.productIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(inventoryProvider, l10n),

              SizedBox(height: 16),

              // Stock Information
              if (widget.showStockInfo) ...[_buildStockInfo(inventoryProvider, l10n), SizedBox(height: 16)],

              // Low Stock Alerts
              if (widget.showAlerts) ...[_buildLowStockAlerts(inventoryProvider, l10n), SizedBox(height: 16)],

              // Action Buttons
              _buildActionButtons(inventoryProvider, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(InventoryProvider provider, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: AppTheme.primaryMaroon, size: 24),
            SizedBox(width: 12),
            Text(
              l10n.realTimeInventory,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
            ),
          ],
        ),
        Row(
          children: [
            if (provider.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)),
              ),
            SizedBox(width: 12),
            IconButton(
              onPressed: () => _refreshInventory(provider),
              icon: Icon(Icons.refresh, color: AppTheme.primaryMaroon),
              tooltip: l10n.refreshInventory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockInfo(InventoryProvider provider, AppLocalizations l10n) {
    if (provider.stockInfo.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: Text(l10n.noStockInformationAvailable, style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stockInformation, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 12),
        ...provider.stockInfo.map((stock) => _buildStockItem(stock, l10n)).toList(),
      ],
    );
  }

  Widget _buildStockItem(Map<String, dynamic> stock, AppLocalizations l10n) {
    final productName = stock['product_name'] as String? ?? l10n.unknownProduct;
    final availableQuantity = stock['available_quantity'] as int? ?? 0;
    final stockStatus = stock['stock_status'] as String? ?? 'UNKNOWN';
    final lowStockWarning = stock['low_stock_warning'] as bool? ?? false;
    final outOfStock = stock['out_of_stock'] as bool? ?? false;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (outOfStock) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = l10n.outOfStock;
    } else if (lowStockWarning) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = l10n.lowStock;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = l10n.inStock;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${l10n.available}: $availableQuantity', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlerts(InventoryProvider provider, AppLocalizations l10n) {
    if (provider.lowStockAlerts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.allProductsHaveSufficientStock,
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              l10n.lowStockAlerts,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange[700]),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${provider.getLowStockAlertCount()}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...provider.lowStockAlerts.map((alert) => _buildAlertItem(alert, l10n)).toList(),
      ],
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert, AppLocalizations l10n) {
    final productName = alert['product_name'] as String? ?? l10n.unknownProduct;
    final currentQuantity = alert['current_quantity'] as int? ?? 0;
    final alertLevel = alert['alert_level'] as String? ?? 'WARNING';
    final categoryName = alert['category_name'] as String? ?? l10n.uncategorized;

    Color alertColor;
    IconData alertIcon;
    String alertLevelText;

    switch (alertLevel) {
      case 'CRITICAL':
        alertColor = Colors.red;
        alertIcon = Icons.error;
        alertLevelText = l10n.critical;
        break;
      case 'WARNING':
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        alertLevelText = l10n.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
        alertLevelText = l10n.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alertIcon, color: alertColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${l10n.category}: $categoryName', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  '${l10n.currentStock}: $currentQuantity',
                  style: TextStyle(fontSize: 12, color: alertColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: alertColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              alertLevelText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: alertColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(InventoryProvider provider, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: provider.isLoading ? null : () => _refreshInventory(provider),
            icon: Icon(Icons.refresh, size: 18),
            label: Text(l10n.refreshStock, style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: provider.isLoading ? null : () => _showLowStockAlerts(provider),
            icon: Icon(Icons.warning, size: 18),
            label: Text(l10n.viewAlerts, style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryMaroon,
              side: BorderSide(color: AppTheme.primaryMaroon),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _refreshInventory(InventoryProvider provider) {
    if (widget.productIds.isNotEmpty) {
      provider.checkStockAvailability(widget.productIds);
    }
    provider.getLowStockAlerts();
    widget.onStockUpdated?.call();
  }

  void _showLowStockAlerts(InventoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text(l10n.lowStockAlerts, style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.lowStockAlerts.isEmpty)
                Text(l10n.noLowStockAlertsAtThisTime, style: TextStyle(color: Colors.grey[600]))
              else
                ...provider.lowStockAlerts.map((alert) => _buildAlertItem(alert, l10n)).toList(),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
      ),
    );
  }
}
