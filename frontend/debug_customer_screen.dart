import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/src/providers/customer_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:sizer/sizer.dart';

class DebugCustomerScreen extends StatelessWidget {
  const DebugCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Customer Screen'),
        backgroundColor: AppTheme.primaryMaroon,
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Debug Info
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider State Debug:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Is Loading: ${provider.isLoading}'),
                    Text('Has Error: ${provider.hasError}'),
                    Text('Error Message: ${provider.errorMessage ?? "None"}'),
                    Text('Customers Count: ${provider.customers.length}'),
                    Text('Current Page: ${provider.currentPage}'),
                    SizedBox(height: 16),
                    
                    // Actions
                    ElevatedButton(
                      onPressed: () => provider.initialize(),
                      child: Text('Initialize Provider'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => provider.refreshCustomers(),
                      child: Text('Refresh Customers'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearAllFilters();
                        provider.searchCustomers('test');
                      },
                      child: Text('Search "test"'),
                    ),
                  ],
                ),
              ),
              
              // Customer List
              Expanded(
                child: provider.customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = provider.customers[index];
                          return ListTile(
                            title: Text(customer.name),
                            subtitle: Text(customer.email),
                            leading: CircleAvatar(
                              child: Text(customer.name[0].toUpperCase()),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
