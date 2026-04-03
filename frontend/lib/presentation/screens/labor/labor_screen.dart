import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import 'salary_screen.dart';
import '../../widgets/labor/add_labor_dialog.dart';
import '../../widgets/labor/labor_filter_dialog.dart';
import '../../widgets/labor/edit_labor_dialog.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/services/labor/labor_service.dart';
import '../../../src/services/labor/salary_slip_pdf_service.dart';
import '../../../src/utils/debug_helper.dart';

class LaborPage extends StatefulWidget {
  const LaborPage({super.key});

  @override
  State<LaborPage> createState() => _LaborPageState();
}

class _LaborPageState extends State<LaborPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LaborProvider>();
      provider.refreshLabors();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _processSalaries() async {
    final now = DateTime.now();
    final laborService = LaborService();
    
    setState(() => _isLoading = true); // Need to add _isLoading to state if not there
    
    try {
      final response = await laborService.generateSalarySlips(
        month: now.month,
        year: now.year,
      );
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Generated ${response.data?.length ?? 0} salary slips for ${DateFormat('MMMM yyyy').format(now)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (response.message?.contains('already exist') == true) {
        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              title: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFBD0D1D), // primaryMaroon
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Regenerate Slips?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.message ?? 'Salaries already processed for this period.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Regenerating will replace all existing pending slips. This action cannot be undone.',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD0D1D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Regenerate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
          
          if (confirm == true) {
            final retryResponse = await laborService.generateSalarySlips(
              month: now.month,
              year: now.year,
              force: true,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(retryResponse.success 
                    ? 'Regenerated ${retryResponse.data?.length ?? 0} salary slips' 
                    : 'Failed to regenerate: ${retryResponse.message}'),
                  backgroundColor: retryResponse.success ? Colors.green : Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Failed to process salaries'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printEmployeeSlip(LaborModel labor) async {
    final laborService = LaborService();
    
    setState(() => _isLoading = true);
    
    try {
      // Get slips for this labor, order by year/month desc
      final response = await laborService.getSalarySlips(
        laborId: labor.id,
        page: 1,
        pageSize: 1,
      );
      
      DebugHelper.printInfo('LaborScreen', 'Print Slip: laborId=${labor.id}, success=${response.success}, count=${response.data?.slips.length}');

      if (response.success && response.data != null && response.data!.slips.isNotEmpty) {
        await SalarySlipPdfService.previewAndPrintSlip(response.data!.slips.first);
      } else {
        if (mounted) {
          DebugHelper.printError('LaborScreen', 'No slip found for labor: ${labor.name}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No salary slips found for this employee. Process salaries first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing slip: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E9E7), // Matched with the creamy background
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Employee Management",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Manage and track all employee details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddLaborDialog(),
                    ).then((_) {
                      final provider = context.read<LaborProvider>();
                      provider.refreshLabors();
                      provider.loadStatistics();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "+ Add Now",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stats row (4 cards as per screenshot)
            Consumer<LaborProvider>(
              builder: (context, provider, child) {
                final stats = provider.statistics;
                return Row(
                  children: [
                    _buildSummaryCard("Total Employees", "${stats?.totalLabors ?? 0}"),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      "Total Salary Budget", 
                      "Rs. ${NumberFormat('#,##0').format(stats?.salaryStatistics.totalSalaryCost ?? 0.0)}", 
                      count: "${stats?.totalLabors ?? 0}",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalaryScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Active Employees", "${stats?.activeLabors ?? 0}"),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Inactive Employees", "${stats?.inactiveLabors ?? 0}"),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),

            // Action Row: Search, Filter, Add Employee
            Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 87,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
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
                              hintText: "Search employee id or name",
                              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (value) => context.read<LaborProvider>().searchLabors(value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Filter Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EnhancedLaborFilterDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 87,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.filter_list_rounded, color: Colors.black, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Filter",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Add Employee Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddLaborDialog(),
                      ).then((_) {
                        final provider = context.read<LaborProvider>();
                        provider.refreshLabors();
                        provider.loadStatistics();
                      });
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 87,
                      width: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C), // Emerald/Green color from screenshot
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "+ Add Employee",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Employee Table
            Consumer<LaborProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
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
                          Expanded(flex: 2, child: Text("Emp ID", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Role", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Salary", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Advances", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Balance", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("City", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)))),
                          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Action", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF888888)), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.labors.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text("No employees found")),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: provider.labors.length,
                        itemBuilder: (context, index) {
                          final labor = provider.labors[index];
                          return _buildEmployeeRow(
                            context,
                            labor,
                          );
                        },
                      ),
                  ],
                );
              }
            ),

            const SizedBox(height: 32),

            // Bottom Buttons
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _processSalaries,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : const Color(0xFF1ABC9C),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1ABC9C).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isLoading ? "Processing..." : "Run Monthly Payroll",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalaryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBD0D1D), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: Color(0xFFBD0D1D), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            "View Payroll History",
                            style: TextStyle(
                              color: Color(0xFFBD0D1D),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, {String? count, VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: onTap != null ? Border.all(color: const Color(0xFFBD0D1D).withOpacity(0.3), width: 1.5) : null,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF999999),
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        count,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildEmployeeRow(BuildContext context, LaborModel labor) {
    final statusColor = labor.isActive ? const Color(0xFF2ECC71) : const Color(0xFFFF9F43);
    final status = labor.isActive ? "Active" : "Inactive";
    final id = "Emp-${labor.id.substring(0, 4)}";
    final name = labor.name;
    final role = labor.designation;
    final salary = NumberFormat('#,##0').format(labor.salary);
    final city = labor.city;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black))),
          Expanded(flex: 2, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black))),
          Expanded(flex: 2, child: Text(role, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF444444)))),
          Expanded(flex: 2, child: Text(salary, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black))),
          Expanded(
            flex: 2, 
            child: Text(
              NumberFormat('#,##0').format(labor.totalAdvancesAmount ?? 0), 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 14, 
                color: Colors.orange[800]
              )
            )
          ),
          Expanded(
            flex: 2, 
            child: Text(
              NumberFormat('#,##0').format(labor.remainingMonthlySalary), 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 14, 
                color: labor.remainingMonthlySalary < labor.salary ? Colors.red[700] : Colors.green[700]
              )
            )
          ),
          Expanded(flex: 2, child: Text(city, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF444444)))),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
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
                        builder: (context) => EnhancedEditLaborDialog(labor: labor),
                      ).then((_) => context.read<LaborProvider>().refreshLabors());
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text("Edit", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _printEmployeeSlip(labor),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text("Print", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFE74C3C))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
