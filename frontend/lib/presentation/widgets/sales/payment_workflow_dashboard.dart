import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';

class PaymentWorkflowDashboard extends StatefulWidget {
  final VoidCallback? onRefresh;

  const PaymentWorkflowDashboard({super.key, this.onRefresh});

  @override
  State<PaymentWorkflowDashboard> createState() => _PaymentWorkflowDashboardState();
}

class _PaymentWorkflowDashboardState extends State<PaymentWorkflowDashboard> {
  bool _isLoading = false;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _dashboardData = {
            'total_sales': 156,
            'pending_payments': 23,
            'partial_payments': 12,
            'completed_payments': 121,
            'total_revenue': 2450000.0,
            'collected_revenue': 1980000.0,
            'pending_revenue': 470000.0,
            'payment_completion_rate': 80.8,
            'average_payment_time': 3.2,
            'recent_workflow_activities': [
              {
                'type': 'payment',
                'description': 'Payment received for INV-2025-0001',
                'amount': 45000.0,
                'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
                'status': 'completed',
              },
              {
                'type': 'status_update',
                'description': 'Sale INV-2025-0002 marked as delivered',
                'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
                'status': 'completed',
              },
              {
                'type': 'payment',
                'description': 'Partial payment for INV-2025-0003',
                'amount': 25000.0,
                'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
                'status': 'partial',
              },
            ],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.paymentWorkflowDashboard,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
              IconButton(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh, color: AppTheme.primaryMaroon),
                tooltip: l10n.refreshDashboard,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)))
          else if (_dashboardData != null)
            Column(
              children: [
                _buildKeyMetricsRow(),
                const SizedBox(height: 24),
                _buildPaymentProgressChart(),
                const SizedBox(height: 24),
                _buildRecentActivities(),
              ],
            )
          else
            Center(
              child: Text(l10n.noDataAvailable, style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsRow() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: l10n.totalSales,
            value: _dashboardData!['total_sales'].toString(),
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: l10n.pendingPayments,
            value: _dashboardData!['pending_payments'].toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: l10n.completed,
            value: _dashboardData!['completed_payments'].toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: l10n.completionRate,
            value: '${_dashboardData!['payment_completion_rate'].toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: AppTheme.primaryMaroon,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressChart() {
    final l10n = AppLocalizations.of(context)!;
    final totalRevenue = _dashboardData!['total_revenue'] as double;
    final collectedRevenue = _dashboardData!['collected_revenue'] as double;
    final pendingRevenue = _dashboardData!['pending_revenue'] as double;
    final completionRate = _dashboardData!['payment_completion_rate'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.creamWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentProgressOverview,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.paymentCompletion, style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${completionRate.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                minHeight: 10,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRevenueItem(
                  label: l10n.collected,
                  amount: collectedRevenue,
                  color: Colors.green,
                  percentage: (collectedRevenue / totalRevenue) * 100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRevenueItem(
                  label: l10n.pending,
                  amount: pendingRevenue,
                  color: Colors.orange,
                  percentage: (pendingRevenue / totalRevenue) * 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem({required String label, required double amount, required Color color, required double percentage}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ),
          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final l10n = AppLocalizations.of(context)!;
    final activities = _dashboardData!['recent_workflow_activities'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.creamWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentWorkflowActivities,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
          ),
          const SizedBox(height: 16),
          ...activities.map((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final description = activity['description'] as String;
    final timestamp = activity['timestamp'] as DateTime;
    final status = activity['status'] as String;
    final amount = activity['amount'] as double?;

    IconData icon;
    Color color;

    switch (type) {
      case 'payment':
        icon = Icons.payment;
        color = status == 'completed' ? Colors.green : Colors.orange;
        break;
      case 'status_update':
        icon = Icons.update;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                if (amount != null)
                  Text(
                    'PKR ${amount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: AppTheme.primaryMaroon, fontWeight: FontWeight.w600),
                  ),
                Text(_formatTimestamp(timestamp), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return l10n.daysAgo(difference.inDays);
    }
  }
}
