import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import 'payment_confirmation_dialog.dart';

class PaymentWorkflowStatus extends StatefulWidget {
  final String saleId;
  final String invoiceNumber;
  final String customerName;
  final double grandTotal;
  final double amountPaid;
  final String currentStatus;
  final VoidCallback? onStatusUpdated;

  const PaymentWorkflowStatus({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.customerName,
    required this.grandTotal,
    required this.amountPaid,
    required this.currentStatus,
    this.onStatusUpdated,
  });

  @override
  State<PaymentWorkflowStatus> createState() => _PaymentWorkflowStatusState();
}

class _PaymentWorkflowStatusState extends State<PaymentWorkflowStatus> {
  Map<String, dynamic>? _workflowSummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkflowSummary();
  }

  Future<void> _loadWorkflowSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      final summary = await provider.getPaymentWorkflowSummary(widget.saleId);

      if (mounted) {
        setState(() {
          _workflowSummary = summary;
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

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentConfirmationDialog(
        saleId: widget.saleId,
        invoiceNumber: widget.invoiceNumber,
        customerName: widget.customerName,
        grandTotal: widget.grandTotal,
        amountPaid: widget.amountPaid,
        currentStatus: widget.currentStatus,
        onPaymentConfirmed: (success) {
          if (success) {
            _loadWorkflowSummary();
            widget.onStatusUpdated?.call();
          }
        },
      ),
    );
  }

  void _showStatusUpdateDialog() {
    final l10n = AppLocalizations.of(context)!;
    if (_workflowSummary == null) return;

    final availableActions = Provider.of<SalesProvider>(context, listen: false).getAvailablePaymentActions(_workflowSummary!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateSaleStatus, style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectActionToPerform),
            const SizedBox(height: 16),
            ...availableActions.map(
                  (action) => ListTile(
                leading: _getActionIcon(action),
                title: Text(_getActionTitle(action)),
                subtitle: Text(_getActionDescription(action)),
                onTap: () {
                  Navigator.of(context).pop();
                  _performAction(action);
                },
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))],
      ),
    );
  }

  Icon _getActionIcon(String action) {
    switch (action) {
      case 'add_payment':
        return const Icon(Icons.payment, color: AppTheme.primaryMaroon);
      case 'mark_delivered':
        return const Icon(Icons.local_shipping, color: Colors.green);
      case 'cancel_sale':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'return_sale':
        return const Icon(Icons.undo, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _getActionTitle(String action) {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'add_payment':
        return l10n.addPayment;
      case 'mark_delivered':
        return l10n.markAsDelivered;
      case 'cancel_sale':
        return l10n.cancelSale;
      case 'return_sale':
        return l10n.returnSale;
      default:
        return l10n.unknownAction;
    }
  }

  String _getActionDescription(String action) {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'add_payment':
        return l10n.processAdditionalPayment;
      case 'mark_delivered':
        return l10n.markSaleAsDelivered;
      case 'cancel_sale':
        return l10n.cancelSaleAndRestoreInventory;
      case 'return_sale':
        return l10n.processReturnForDeliveredSale;
      default:
        return l10n.noDescriptionAvailable;
    }
  }

  Future<void> _performAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<SalesProvider>(context, listen: false);

    try {
      bool success = false;

      switch (action) {
        case 'add_payment':
          _showPaymentConfirmationDialog();
          return;
        case 'mark_delivered':
          success = await provider.updateSaleStatusWithPayment(widget.saleId, 'DELIVERED', notes: l10n.markedAsDelivered);
          break;
        case 'cancel_sale':
          success = await provider.updateSaleStatusWithPayment(widget.saleId, 'CANCELLED', notes: l10n.saleCancelled);
          break;
        case 'return_sale':
          success = await provider.updateSaleStatusWithPayment(widget.saleId, 'RETURNED', notes: l10n.saleReturned);
          break;
      }

      if (success) {
        await _loadWorkflowSummary();
        widget.onStatusUpdated?.call();
      }
    } catch (e) {
      // Error handling is done in the provider
    }
  }

  Widget _buildProgressIndicator() {
    if (_workflowSummary == null) return const SizedBox.shrink();

    final progress = Provider.of<SalesProvider>(context, listen: false).getPaymentWorkflowProgress(_workflowSummary!);
    final isComplete = Provider.of<SalesProvider>(context, listen: false).isPaymentWorkflowComplete(_workflowSummary!);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(isComplete ? Colors.green : AppTheme.primaryMaroon),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isComplete ? Colors.green : AppTheme.primaryMaroon),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final l10n = AppLocalizations.of(context)!;
    if (_workflowSummary == null) return const SizedBox.shrink();

    final currentStep = _workflowSummary!['current_workflow_step'] as String? ?? '';

    Color chipColor;
    String chipText;

    switch (currentStep) {
      case 'awaiting_payment':
        chipColor = Colors.red;
        chipText = l10n.awaitingPayment;
        break;
      case 'partial_payment':
        chipColor = Colors.orange;
        chipText = l10n.partialPayment;
        break;
      case 'payment_complete':
        chipColor = Colors.green;
        chipText = l10n.paymentComplete;
        break;
      default:
        chipColor = Colors.grey;
        chipText = l10n.unknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        chipText,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: chipColor),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    if (_workflowSummary == null) return const SizedBox.shrink();

    final availableActions = Provider.of<SalesProvider>(context, listen: false).getAvailablePaymentActions(_workflowSummary!);

    if (availableActions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (availableActions.contains('add_payment'))
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _showPaymentConfirmationDialog,
              icon: const Icon(Icons.payment, size: 16),
              label: Text(l10n.payment, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 28),
              ),
            ),
          ),
        if (availableActions.length > 1)
          IconButton(
            onPressed: _showStatusUpdateDialog,
            icon: const Icon(Icons.more_vert, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.grey[700]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 120,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProgressIndicator(),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusChip()),
            ],
          ),
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }
}
