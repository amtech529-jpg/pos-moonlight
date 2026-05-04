import 'package:flutter/material.dart';
import 'package:frontend/src/models/dispatch/dispatch_form_model.dart';
import 'package:frontend/src/models/order/order_model.dart';
import 'package:frontend/src/providers/dispatch_provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:frontend/presentation/widgets/globals/text_field.dart';
import 'package:frontend/presentation/widgets/globals/keyboard_scrollable.dart';
import 'package:frontend/src/services/pdf_gate_pass_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddDispatchFormDialog extends StatefulWidget {
  const AddDispatchFormDialog({super.key});

  @override
  State<AddDispatchFormDialog> createState() => _AddDispatchFormDialogState();
}

class _AddDispatchFormDialogState extends State<AddDispatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderSearchController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _staffNameController = TextEditingController();
  
  OrderModel? _selectedOrder;
  bool _isSearching = false;
  List<OrderModel> _searchResults = [];

  // Editable Dates
  DateTime? _eventDate;
  DateTime? _dispatchDate;
  DateTime? _returnDate;

  @override
  void dispose() {
    _orderSearchController.dispose();
    _driverNameController.dispose();
    _vehicleNumberController.dispose();
    _staffNameController.dispose();
    super.dispose();
  }

  Future<void> _searchOrders(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.searchOrders(query, excludeDispatched: true);
    
    setState(() {
      _searchResults = orderProvider.orders;
      _isSearching = false;
    });
  }

  void _selectOrder(OrderModel order) {
    setState(() {
      _selectedOrder = order;
      _searchResults = [];
      _orderSearchController.text = order.orderNumber;
      
      // Initialize editable dates from order
      _eventDate = order.eventDate;
      _dispatchDate = order.dispatchDate;
      _returnDate = order.returnDate;
    });
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate;
    if (type == 'event') initialDate = _eventDate ?? DateTime.now();
    else if (type == 'dispatch') initialDate = _dispatchDate ?? DateTime.now();
    else initialDate = _returnDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBD0D1D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              secondary: Color(0xFFBD0D1D),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBD0D1D),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'event') _eventDate = picked;
        else if (type == 'dispatch') _dispatchDate = picked;
        else _returnDate = picked;
      });
    }
  }

  Future<void> _saveAndPrint() async {
    if (!_formKey.currentState!.validate() || _selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an order and fill all fields')),
      );
      return;
    }

    // Create a temporary order object with updated dates for PDF generation
    final updatedOrder = _selectedOrder!.copyWith(
      eventDate: _eventDate,
      dispatchDate: _dispatchDate,
      returnDate: _returnDate,
    );

    final dispatchForm = DispatchFormModel(
      id: '', // Backend will generate
      orderId: _selectedOrder!.id,
      driverName: _driverNameController.text,
      vehicleNumber: _vehicleNumberController.text,
      staffName: _staffNameController.text,
      createdAt: DateTime.now(),
      orderDetails: updatedOrder, // Pass updated order details
    );

    final provider = context.read<DispatchProvider>();
    final result = await provider.createDispatchForm(dispatchForm);

    if (result != null) {
      // Print the gate pass (ensure it uses the updated result which contains backend data)
      await PdfGatePassService.printGatePass(result.copyWith(orderDetails: updatedOrder));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate Pass saved and printed successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save Gate Pass')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 850,
        height: 700,
        child: Column(
          children: [
            // Header (fixed)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Gate Pass (Dispatch Form)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Scrollable Content
            Expanded(
              child: KeyboardScrollable(
                thumbVisibility: true,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Search Section
                      const Text('Search Order (ID or Customer)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        controller: _orderSearchController,
                        label: 'Search Order',
                        hint: 'Enter Order Number or Customer Name...',
                        prefixIcon: Icons.search,
                        onChanged: _searchOrders,
                      ),
                      
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final order = _searchResults[index];
                                return InkWell(
                                  onTap: () {
                                    _selectOrder(order);
                                    FocusScope.of(context).unfocus();
                                  },
                                  hoverColor: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFFBD0D1D).withOpacity(0.1),
                                          child: const Icon(Icons.receipt_long, color: Color(0xFFBD0D1D), size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order.orderNumber,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                order.customerName.isEmpty ? 'Unknown Customer' : order.customerName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF666666),
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      
                      if (_selectedOrder != null) ...[
                        const SizedBox(height: 24),
                        // Order Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFFBD0D1D).withOpacity(0.05), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBD0D1D).withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFFBD0D1D), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Customer: ${_selectedOrder!.customerName}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.celebration, color: Color(0xFFBD0D1D), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Event: ${_selectedOrder!.eventName}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFBD0D1D), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Location: ${_selectedOrder!.eventLocation}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Schedule Dates (Click to Edit)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildEditableDate('Dispatch Date', _dispatchDate, () => _selectDate(context, 'dispatch')),
                              _buildEditableDate('Event Date', _eventDate, () => _selectDate(context, 'event')),
                              _buildEditableDate('Return Date', _returnDate, () => _selectDate(context, 'return')),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text('Items List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _selectedOrder!.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.productName.isNotEmpty ? item.productName : (item.productDisplayInfo['name'] ?? 'Unknown Item'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBD0D1D).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        color: Color(0xFFBD0D1D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Dispatch Logistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: PremiumTextField(
                                controller: _driverNameController,
                                label: 'Driver Name',
                                prefixIcon: Icons.person,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: PremiumTextField(
                                controller: _vehicleNumberController,
                                label: 'Vehicle Number',
                                prefixIcon: Icons.directions_car,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PremiumTextField(
                          controller: _staffNameController,
                          label: 'Staff/Person Accompanying (Bnda)',
                          prefixIcon: Icons.group,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer (fixed)
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: Colors.grey, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveAndPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBD0D1D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.print, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Save & Print Gate Pass',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
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

  Widget _buildEditableDate(String label, DateTime? date, VoidCallback onTap) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Color(0xFFBD0D1D)),
                const SizedBox(width: 8),
                Text(
                  date != null ? dateFormat.format(date) : 'Select Date',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
