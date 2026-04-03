import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/models/customer/customer_model.dart';
import '../../../src/services/customer_service.dart';
import '../../../src/theme/app_theme.dart';

class QuickCustomerLookupWidget extends StatefulWidget {
  final Function(CustomerModel)? onCustomerSelected;
  final bool showCreateButton;
  final String? initialQuery;
  final bool autoFocus;

  const QuickCustomerLookupWidget({super.key, this.onCustomerSelected, this.showCreateButton = true, this.initialQuery, this.autoFocus = true});

  @override
  State<QuickCustomerLookupWidget> createState() => _QuickCustomerLookupWidgetState();
}

class _QuickCustomerLookupWidgetState extends State<QuickCustomerLookupWidget> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();

  List<CustomerModel> _searchResults = [];
  bool _isLoading = false;
  String? _lastError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _lastError = null;
      });
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final response = await _customerService.quickCustomerLookup(query: query, limit: 10, includeInactive: false);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _searchResults = response.data!;
          } else {
            _searchResults = [];
            _lastError = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastError = 'Search failed: $e';
        });
      }
    }
  }

  void _onCustomerSelected(CustomerModel customer) {
    widget.onCustomerSelected?.call(customer);
    // Clear search after selection
    _searchController.clear();
    setState(() {
      _searchResults.clear();
    });
  }

  void _showCreateCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateCustomerDialog(
        onCustomerCreated: (customer) {
          widget.onCustomerSelected?.call(customer);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Header
        Row(
          children: [
            Icon(Icons.person_search, color: AppTheme.primaryMaroon, size: 20),
            SizedBox(width: 8),
            Text(
              'Customer Lookup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Search Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: widget.autoFocus,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                              _lastError = null;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryMaroon, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            if (widget.showCreateButton) ...[
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateCustomerDialog,
                icon: Icon(Icons.person_add, size: 18),
                label: Text('New', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16),

        // Search Results
        if (_searchResults.isNotEmpty) ...[
          _buildSearchResults(),
        ] else if (_lastError != null) ...[
          _buildErrorDisplay(),
        ] else if (_searchController.text.isNotEmpty && !_isLoading) ...[
          _buildNoResultsDisplay(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Results Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryMaroon, size: 16),
                SizedBox(width: 8),
                Text(
                  'Found ${_searchResults.length} customer(s)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                ),
              ],
            ),
          ),

          // Results List
          ..._searchResults.map((customer) => _buildCustomerResult(customer)).toList(),
        ],
      ),
    );
  }

  Widget _buildCustomerResult(CustomerModel customer) {
    return InkWell(
      onTap: () => _onCustomerSelected(customer),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Customer Avatar
            CircleAvatar(
              backgroundColor: AppTheme.primaryMaroon.withOpacity(0.2),
              child: Text(
                customer.initials,
                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
            ),

            SizedBox(width: 16),

            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (customer.email.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(customer.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),

            // Customer Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(customer.status).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    customer.statusDisplay,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(customer.status)),
                  ),
                ),
                SizedBox(height: 4),
                if (customer.totalSalesCount > 0)
                  Text('${customer.totalSalesCount} sales', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(_lastError!, style: TextStyle(color: Colors.red[700], fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsDisplay() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No customers found',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text('Try a different search term or create a new customer', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VIP':
        return Colors.purple;
      case 'REGULAR':
        return Colors.green;
      case 'NEW':
        return Colors.blue;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// Simple customer creation dialog
class _CreateCustomerDialog extends StatefulWidget {
  final Function(CustomerModel) onCustomerCreated;

  const _CreateCustomerDialog({required this.onCustomerCreated});

  @override
  State<_CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<_CreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customerService = CustomerService();
      final response = await customerService.createCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (response.success && response.data != null) {
        widget.onCustomerCreated(response.data!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create customer: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Customer', style: TextStyle(fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCustomer,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text('Create'),
        ),
      ],
    );
  }
}
