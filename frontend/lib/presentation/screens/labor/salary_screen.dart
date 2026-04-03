
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/models/labor/salary_slip_model.dart';
import '../../../src/services/labor/labor_service.dart';
import '../../../src/services/labor/salary_slip_pdf_service.dart';
import '../../../src/utils/debug_helper.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final LaborService _laborService = LaborService();
  bool _isLoading = false;
  List<SalarySlip> _slips = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _statusFilter; // 'PENDING', 'PAID', null (All)

  double _totalGross = 0;
  double _totalPaid = 0;
  double _totalPending = 0;
  double _totalDeductions = 0;

  @override
  void initState() {
    super.initState();
    _loadSlips();
  }

  void _calculateTotals() {
    _totalGross = 0;
    _totalPaid = 0;
    _totalPending = 0;
    _totalDeductions = 0;
    for (var slip in _slips) {
      _totalGross += slip.baseSalary + slip.bonuses;
      _totalDeductions += slip.totalAdvances + slip.deductions;
      if (slip.status == 'PAID') {
        _totalPaid += slip.netSalary;
      } else {
        _totalPending += slip.netSalary;
      }
    }
  }

  Future<void> _loadSlips() async {
    setState(() => _isLoading = true);
    try {
      final response = await _laborService.getSalarySlips(
        month: _selectedMonth,
        year: _selectedYear,
        status: _statusFilter,
      );
      
      DebugHelper.printInfo('SalaryScreen', 'Load Slips: month=$_selectedMonth, year=$_selectedYear, success=${response.success}, count=${response.data?.slips.length}');

      if (response.success && response.data != null) {
        setState(() {
          _slips = response.data!.slips;
          _calculateTotals();
        });
      } else {
        DebugHelper.printError('SalaryScreen', 'Failed: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load slips')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSlips({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _laborService.generateSalarySlips(
        month: _selectedMonth,
        year: _selectedYear,
        force: force,
      );
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated ${response.data?.length ?? 0} slips')),
        );
        _loadSlips();
      } else if (response.message?.contains('already exist') == true) {
         // Show confirmation dialog for force regeneration
        bool confirm = await showDialog(
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
                  response.message ?? 'Slips already exist for this period.',
                  style: TextStyle(
                    fontSize: 15, 
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Regenerating will replace all existing pending slips. This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 13, 
                    color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.7), 
                    fontStyle: FontStyle.italic
                  ),
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
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[700], 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )
                )
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )
                )
              ),
            ],
          )
        ) ?? false;
        
        if (confirm) {
           await _generateSlips(force: true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaid(SalarySlip slip) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Confirm Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: Text(
          'Are you sure you want to mark the salary of ${slip.laborName} as PAID for ${DateFormat('MMMM yyyy').format(DateTime(slip.year, slip.month))}?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel', 
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[700], 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBD0D1D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final response = await _laborService.updateSalarySlipStatus(
        slipId: slip.id,
        status: 'PAID',
      );
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as PAID')),
        );
        _loadSlips();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed')),
        );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('HR & Salary', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('HR & Salary', 'edit') ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Management'),
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlips,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsRow(),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterDropdown<int>(
                  label: 'Month',
                  value: _selectedMonth,
                  items: List.generate(12, (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(DateFormat('MMMM').format(DateTime(2000, index + 1))),
                  )), 
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _loadSlips();
                    }
                  }
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<int>(
                  label: 'Year',
                  value: _selectedYear,
                  items: List.generate(5, (index) => DropdownMenuItem(
                    value: DateTime.now().year - 2 + index,
                    child: Text('${DateTime.now().year - 2 + index}'),
                  )), 
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadSlips();
                    }
                  }
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  label: 'Status',
                  value: _statusFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Status")),
                    const DropdownMenuItem(value: "PENDING", child: Text("Pending")),
                    const DropdownMenuItem(value: "PAID", child: Text("Paid")),
                  ], 
                  onChanged: (val) {
                    setState(() => _statusFilter = val);
                    _loadSlips();
                  }
                ),
                const Spacer(),
                if (canAdd)
                  ElevatedButton.icon(
                    onPressed: () => _generateSlips(),
                    icon: const Icon(Icons.flash_on, size: 20),
                    label: const Text('Run New Payroll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _slips.isEmpty 
                ? const Center(child: Text('No salary slips found for this period.'))
                : ListView.builder(
                    itemCount: _slips.length,
                    itemBuilder: (context, index) {
                      final slip = _slips[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(
                              slip.laborName.isNotEmpty ? slip.laborName.substring(0, 1).toUpperCase() : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            slip.laborName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Net Salary: ${NumberFormat.currency(symbol: 'PKR ').format(slip.netSalary)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: slip.status == 'PAID' ? Colors.green[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: slip.status == 'PAID' ? Colors.green[200]! : Colors.orange[200]!,
                                  ),
                                ),
                                child: Text(
                                  slip.status,
                                  style: TextStyle(
                                    color: slip.status == 'PAID' ? Colors.green[700] : Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.print_outlined),
                                color: Colors.blue[700],
                                tooltip: 'Print Slip',
                                onPressed: () => SalarySlipPdfService.previewAndPrintSlip(slip),
                              ),
                              if (slip.status != 'PAID' && canEdit)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  color: Colors.green[700],
                                  tooltip: 'Mark as Paid',
                                  onPressed: () => _markAsPaid(slip),
                                ),
                            ],
                          ),
                          onTap: () {
                             showDialog(
                               context: context, 
                               builder: (context) => AlertDialog(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                 titlePadding: EdgeInsets.zero,
                                 title: Container(
                                   padding: const EdgeInsets.all(16),
                                   decoration: const BoxDecoration(
                                     color: Color(0xFF2C3E50),
                                     borderRadius: BorderRadius.only(
                                       topLeft: Radius.circular(16),
                                       topRight: Radius.circular(16),
                                     ),
                                   ),
                                   child: Row(
                                     children: [
                                       const Icon(Icons.receipt_long, color: Colors.white),
                                       const SizedBox(width: 12),
                                       const Text('Payslip Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                     ],
                                   ),
                                 ),
                                 content: Container(
                                   width: 400,
                                   child: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       _buildDetailRow('Employee Name', slip.laborName, isBold: true),
                                       _buildDetailRow('Designation', slip.laborDesignation),
                                       _buildDetailRow('Reference #', slip.referenceNumber ?? 'N/A'),
                                       _buildDetailRow('Month/Year', '${DateFormat('MMMM').format(DateTime(2000, slip.month))} ${slip.year}'),
                                       const Divider(height: 24),
                                       const Text('EARNINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                       const SizedBox(height: 8),
                                       _buildDetailRow('Base Salary', NumberFormat.currency(symbol: 'Rs ').format(slip.baseSalary)),
                                       _buildDetailRow('Bonuses/Incentives', NumberFormat.currency(symbol: 'Rs ').format(slip.bonuses)),
                                       const SizedBox(height: 12),
                                       const Text('DEDUCTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                       const SizedBox(height: 8),
                                       _buildDetailRow('Monthly Advances', '- ${NumberFormat.currency(symbol: 'Rs ').format(slip.totalAdvances)}'),
                                       _buildDetailRow('Other Deductions', '- ${NumberFormat.currency(symbol: 'Rs ').format(slip.deductions)}'),
                                       const Divider(height: 32),
                                       Container(
                                         padding: const EdgeInsets.all(12),
                                         decoration: BoxDecoration(
                                           color: Colors.blue[50],
                                           borderRadius: BorderRadius.circular(8),
                                         ),
                                         child: Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           children: [
                                             const Text('NET SALARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                             Text(
                                               NumberFormat.currency(symbol: 'Rs ').format(slip.netSalary),
                                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2980B9)),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.pop(context), 
                                     child: Text(
                                        'Close', 
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.white70 
                                              : Colors.black87, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        )
                                      )
                                   ),
                                   ElevatedButton.icon(
                                     onPressed: () {
                                       Navigator.pop(context);
                                       SalarySlipPdfService.previewAndPrintSlip(slip);
                                     },
                                     icon: const Icon(Icons.print, size: 18, color: Colors.white),
                                     label: const Text(
                                       'Print Now',
                                       style: TextStyle(
                                         color: Colors.white,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 16,
                                       ),
                                     ),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: const Color(0xFF2C3E50),
                                       foregroundColor: Colors.white,
                                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                     ),
                                   ),
                                 ],
                               ),
                             );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? (isBold ? Colors.black : Colors.grey[800]),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildSummaryCard("Total Gross", _totalGross, Icons.payments_outlined, Colors.blue),
          const SizedBox(width: 12),
          _buildSummaryCard("To Be Paid", _totalPending, Icons.pending_actions, Colors.orange),
          const SizedBox(width: 12),
          _buildSummaryCard("Paid Salary", _totalPaid, Icons.check_circle_outline, Colors.green),
          const SizedBox(width: 12),
          _buildSummaryCard("Deductions", _totalDeductions, Icons.money_off_csred_outlined, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat.currency(symbol: 'PKR', decimalDigits: 0).format(amount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ),
    );
  }
}

