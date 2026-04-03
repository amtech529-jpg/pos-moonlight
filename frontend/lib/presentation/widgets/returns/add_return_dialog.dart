import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/providers/rental_return_provider.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/services/order_service.dart';
import '../../../src/services/order_item_service.dart';
import '../../../src/models/order/order_api_responses.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';

class ReturnItemInput {
  final OrderItemModel originalItem;
  int returned;
  int damaged;
  int missing;
  double damageCharge;
  String conditionNotes;

  ReturnItemInput({
    required this.originalItem,
    this.returned = 0,
    this.damaged = 0,
    this.missing = 0,
    this.damageCharge = 0.0,
    this.conditionNotes = '',
  });

  int get totalAccounted => returned + damaged + missing;
  int get remaining => originalItem.quantity - totalAccounted;
}

class AddReturnDialog extends StatefulWidget {
  const AddReturnDialog({super.key});

  @override
  State<AddReturnDialog> createState() => _AddReturnDialogState();
}

class _AddReturnDialogState extends State<AddReturnDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final OrderService _orderService = OrderService();
  final OrderItemService _orderItemService = OrderItemService();

  // Controllers
  final _notesController = TextEditingController();

  // Form state
  Customer? _selectedCustomer;
  OrderModel? _selectedOrder;
  String _responsibility = 'NONE';
  List<OrderModel> _customerOrders = [];
  List<ReturnItemInput> _returnItems = [];
  bool _isLoadingOrders = false;
  bool _isLoadingItems = false;
  String? _itemLoadError;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _responsibilityChoices = ['NONE', 'CUSTOMER', 'INTERNAL'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _animationController.forward();
    
    // Load customers if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleCustomerChange(Customer? customer) async {
    setState(() {
      _selectedCustomer = customer;
      _selectedOrder = null;
      _returnItems = [];
      _customerOrders = [];
      _itemLoadError = null;
    });

    if (customer != null) {
      _loadCustomerOrders(customer.id);
    }
  }

  Future<void> _loadCustomerOrders(String customerId) async {
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      // Use OrderBaseParams to filter by customer
      // Note: We might need to adjust based on API capabilities.
      // Assuming getOrders supports customer_id filtering via params or we filter client side if not supported.
      // Based on OrderService analysis, it supports params with customerId.
      final response = await _orderService.getOrders(
        params: OrderListParams(
          customerId: customerId,
          pageSize: 100, // Fetch recent 100 orders
          sortBy: 'date_ordered',
          sortOrder: 'desc',
        )
      );

      if (response.success && response.data != null) {
        setState(() {
          // Only allow orders that have been DELIVERED to be processed for return.
          // Confirmed/Ready orders must be delivered first, or Cancelled if not going out.
          _customerOrders = response.data!.orders.where((o) => 
            o.status == OrderStatus.DELIVERED && 
            o.returnStatus != 'COMPLETE'
          ).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  void _handleOrderChange(OrderModel? order) {
    setState(() {
      _selectedOrder = order;
      _returnItems = [];
      _itemLoadError = null;
    });

    if (order != null) {
      _loadOrderItems(order.id);
    }
  }

  Future<void> _loadOrderItems(String orderId) async {
    setState(() {
      _isLoadingItems = true;
      _itemLoadError = null;
    });

    try {
      final response = await _orderItemService.getOrderItems(
        orderId: orderId,
        pageSize: 100,
      );

      if (response.success && response.data != null) {
        setState(() {
          _returnItems = response.data!.orderItems.map((item) {
            return ReturnItemInput(
              originalItem: item,
              returned: 0, // Default to 0 instead of item.quantity to prevent accidental double-returns
              damaged: 0,
              missing: 0,
            );
          }).toList();
        });
      } else {
        setState(() {
          _itemLoadError = response.message ?? 'Failed to load items';
        });
      }
    } catch (e) {
      setState(() {
        _itemLoadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedOrder == null) return;
      if (_returnItems.isEmpty) return;

      final provider = Provider.of<RentalReturnProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Validate items total accounted
      for (final item in _returnItems) {
        if (item.totalAccounted > item.originalItem.quantity) {
          _showErrorSnackbar('Total for ${item.originalItem.productName} (${item.totalAccounted}) exceeds items sent (${item.originalItem.quantity}). Please adjust Returned/Damaged/Missing counts.');
          return;
        }
      }

      // Prepare items data
      final itemsData = _returnItems.map((input) {
        return {
          'product': input.originalItem.productId,       // May be empty if API didn't return it
          'order_item_id': input.originalItem.id,         // Fallback 1: backend resolves product from this
          'product_name': input.originalItem.productName, // Fallback 2: backend looks up by name
          'qty_sent': input.originalItem.quantity,
          'qty_returned': input.returned,
          'qty_damaged': input.damaged,
          'qty_missing': input.missing,
          'damage_charge': input.damageCharge,
          'condition_notes': input.conditionNotes,
          'is_partner_item': input.originalItem.rentedFromPartner,
        };
      }).toList();
      
      // Calculate total damage charges
      final totalDamageCharges = _returnItems.fold(0.0, (sum, item) => sum + item.damageCharge);

      final success = await provider.createReturn(
        orderId: _selectedOrder!.id,
        responsibility: _responsibility,
        damageCharges: totalDamageCharges,
        notes: _notesController.text.trim(),
        items: itemsData,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          final errorMessage = (provider.error != null && provider.error!.isNotEmpty) 
              ? provider.error! 
              : 'Failed to create return record';
          _showErrorSnackbar(errorMessage);
        }
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Return processed successfully!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.shouldShowCompactLayout ? 95.w : context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: context.maxContentWidth,
                  maxHeight: 90.h,
                ),
                margin: context.pagePadding,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(l10n),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: EdgeInsets.all(context.cardPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSelectionSection(l10n),
                              if (_selectedOrder != null) ...[
                                SizedBox(height: context.cardPadding),
                                _buildItemsSection(l10n),
                                SizedBox(height: context.cardPadding),
                                _buildAdditionalInfoSection(l10n),
                              ],
                              const SizedBox(height: 100), // Added extra space for visibility
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                    _buildFooter(l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_return_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Text(
              'Process Return & Tally',
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.pureWhite,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _animationController.reverse().then((_) => Navigator.of(context).pop());
            },
            icon: Icon(Icons.close_rounded, color: AppTheme.pureWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<CustomerProvider>(
          builder: (context, provider, child) {
            return PremiumDropdownField<Customer>(
              label: 'Customer',
              hint: 'Select Customer',
              value: _selectedCustomer,
              items: provider.customers.map((c) => DropdownItem(
                value: c,
                label: c.name,
              )).toList(),
              onChanged: _handleCustomerChange,
              prefixIcon: Icons.person_outline,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        if (_isLoadingOrders)
          const Center(child: CircularProgressIndicator())
        else
          PremiumDropdownField<OrderModel>(
            label: 'Order',
            hint: _selectedCustomer == null ? 'Select Customer First' : 'Select Order',
            value: _selectedOrder,
            items: _customerOrders.map((o) => DropdownItem(
              value: o,
              label: '${o.orderNumber} - ${o.formattedDateOrdered} (Items: ${o.orderSummary['total_items'] ?? 'N/A'})',
            )).toList(),
            onChanged: _selectedCustomer == null ? null : _handleOrderChange,
            prefixIcon: Icons.shopping_bag_outlined,
            enabled: _selectedCustomer != null,
          ),
      ],
    );
  }

  Widget _buildItemsSection(AppLocalizations l10n) {
    if (_isLoadingItems) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_itemLoadError != null) {
      return Center(
        child: Text(
          _itemLoadError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_returnItems.isEmpty) {
      return const Center(child: Text("No items in this order."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tally Items',
          style: TextStyle(
            fontSize: context.subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoalGray,
          ),
        ),
        SizedBox(height: context.smallPadding),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _returnItems.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final item = _returnItems[index];
            return _buildItemRow(item);
          },
        ),
      ],
    );
  }

  Widget _buildItemRow(ReturnItemInput item) {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.originalItem.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: context.bodyFontSize,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sent: ${item.originalItem.quantity}',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.bold,
                    fontSize: context.captionFontSize,
                  ),
                ),
              ),
              if (item.originalItem.rentedFromPartner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Partner Item',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  label: 'Returned (واپس)',
                  fieldKey: '${item.originalItem.productId}_ret',
                  value: item.returned,
                  onChanged: (val) {
                    setState(() => item.returned = val);
                  },
                  max: item.originalItem.quantity,
                  icon: Icons.assignment_turned_in_outlined,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: _buildNumberInput(
                  label: 'Damaged (خراب)',
                  fieldKey: '${item.originalItem.productId}_dmg',
                  value: item.damaged,
                  onChanged: (val) {
                    setState(() => item.damaged = val);
                  },
                  isError: item.damaged > 0,
                  icon: Icons.report_problem_outlined,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: _buildNumberInput(
                  label: 'Missing (غائب)',
                  fieldKey: '${item.originalItem.productId}_mis',
                  value: item.missing,
                  onChanged: (val) {
                    setState(() => item.missing = val);
                  },
                  isError: item.missing > 0,
                  icon: Icons.help_outline_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (item.totalAccounted != item.originalItem.quantity)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                item.totalAccounted > item.originalItem.quantity 
                    ? ' Error: Total (${item.totalAccounted}) exceeds Sent (${item.originalItem.quantity})!'
                    : ' Warning: Accounted (${item.totalAccounted}) != Sent (${item.originalItem.quantity})',
                style: TextStyle(
                  color: item.totalAccounted > item.originalItem.quantity ? Colors.red : Colors.orange, 
                  fontSize: context.captionFontSize,
                  fontWeight: item.totalAccounted > item.originalItem.quantity ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          if (item.damaged > 0 || item.missing > 0) ...[
             SizedBox(height: context.smallPadding),
             Row(
               children: [
                 Expanded(
                   child: PremiumTextField(
                     label: 'Damage Charge (جرمانہ)',
                     initialValue: item.damageCharge > 0 ? item.damageCharge.toString() : '',
                     keyboardType: TextInputType.number,
                     prefixIcon: Icons.money_off,
                     onChanged: (val) {
                       item.damageCharge = double.tryParse(val) ?? 0.0;
                     },
                   ),
                 ),
                 SizedBox(width: context.smallPadding),
                 Expanded(
                   flex: 2,
                   child: PremiumTextField(
                     label: 'Condition Notes (تفصیل)',
                     initialValue: item.conditionNotes,
                     prefixIcon: Icons.note_alt_outlined,
                     onChanged: (val) {
                       item.conditionNotes = val;
                     },
                   ),
                 ),
               ],
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String fieldKey,
    required int value,
    required Function(int) onChanged,
    int? max,
    bool isError = false,
    IconData? icon,
    Color? color,
  }) {
    return PremiumTextField(
      label: label,
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      prefixIcon: icon,
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(0);
          return;
        }
        final parsed = int.tryParse(val);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
      validator: (val) {
        final parsed = int.tryParse(val ?? '');
        if (parsed == null || parsed < 0) return 'Invalid';
        if (max != null && parsed > max) return 'Max $max';
        return null;
      },
    );
  }

  Widget _buildAdditionalInfoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumDropdownField<String>(
          label: 'Responsibility (ذمہ داری)',
          hint: 'Select Responsibility',
          prefixIcon: Icons.person_pin_rounded,
          value: _responsibility,
          items: _responsibilityChoices.map((c) => DropdownItem(value: c, label: c)).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _responsibility = val);
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumTextField(
          label: 'Overall Notes (تفصیل)',
          controller: _notesController,
          prefixIcon: Icons.note_alt_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.borderRadius('large')),
          bottomRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              l10n.cancel,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(width: context.cardPadding),
          ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Generate Return (درج کریں)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
