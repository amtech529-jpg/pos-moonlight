import 'package:frontend/src/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../src/models/expenses/expenses_model.dart';
import '../../../src/providers/expenses_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/expenses/add_expense_dialog.dart';
import '../../widgets/expenses/edit_expense_dialog.dart';
import '../../widgets/expenses/delete_expense_dialog.dart';
import '../../widgets/expenses/view_expense_dialog.dart';


class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpensesProvider>();
      provider.loadExpenseRecords();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Expense Management', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Expense Management', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('Expense Management', 'delete') ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9E7), // Matches the creamy background in screenshot
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
              "Expense Management",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your Expense Management",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),

            // Stats row (3 cards as per screenshot)
            // Stats row (3 cards as per screenshot)
            Consumer<ExpensesProvider>(
              builder: (context, provider, child) {
                final stats = provider.statistics;
                final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
                
                // Calculate values based on available data or use mock logic if strict adherence to screenshot is needed
                // Assuming:
                // Daily Expenses = Total Expenses (or filtered by 'Daily' if category exists)
                // Monthly Fixed = Filtered by 'Fixed'
                // Salary Deductibles = Filtered by 'isSalaryDeductible'
                
                // For now, mapping general stats to these cards:
                return Row(
                  children: [
                    Expanded(child: _buildSummaryCard(
                      "Total Expenses", 
                      currencyFormat.format(stats?.totalAmount ?? 0)
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSummaryCard(
                      "This Month", 
                      currencyFormat.format(stats?.currentMonthAmount ?? 0)
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSummaryCard(
                      "Total Count", 
                      "${stats?.totalExpenses ?? 0}"
                    )),

                  ],
                );
              },
            ),


            const SizedBox(height: 48),

            // Search Bar & Add Button Section
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            controller: _searchController,
                            cursorColor: Colors.black,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 15, color: Colors.black),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _searchFocusNode.hasFocus 
                                  ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                                  : const Color(0xFFE8E8E8),
                              hintText: "Search by Category or Description...",
                              hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E8E), size: 22),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (value) => context.read<ExpensesProvider>().searchExpenses(value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (canAdd)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddExpenseDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      "Add Expense",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF679DAA),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 80), // Fixed size to match search bar
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 48),

            // Expenses Table
            _buildExpensesTable(canEdit, canDelete),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExpensesTable(bool canEdit, bool canDelete) {
    return Column(
      children: [
        // Table Header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)))),
              Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)))),
              Expanded(flex: 3, child: Text("Description", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)))),
              Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)))),
              Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Rows
        Consumer<ExpensesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF679DAA))),
              );
            }

            if (provider.expenses.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    "No expenses found",
                    style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.expenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildExpenseRow(provider.expenses[index], canEdit, canDelete);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpenseRow(Expense expense, bool canEdit, bool canDelete) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(expense.formattedDate, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black))),
          Expanded(flex: 2, child: Text(expense.category ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xFF444444)))),
          Expanded(flex: 3, child: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black))),
          Expanded(flex: 2, child: Text(currencyFormat.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                       showDialog(
                        context: context,
                        builder: (context) => ViewExpenseDetailsDialog(expense: expense),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(Icons.visibility_outlined, size: 18, color: Colors.black),
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditExpenseDialog(expense: expense),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                           context: context,
                           builder: (context) => DeleteExpenseDialog(expense: expense),
                         );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          "Delete",
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ),
                  ),
                ],
                if (!canEdit && !canDelete)
                   const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text("View-only", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

