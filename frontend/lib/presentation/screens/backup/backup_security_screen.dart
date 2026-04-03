import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../src/config/api_config.dart';
import 'dart:io';

class BackupSecurityScreen extends StatefulWidget {
  const BackupSecurityScreen({super.key});

  @override
  State<BackupSecurityScreen> createState() => _BackupSecurityScreenState();
}

class _BackupSecurityScreenState extends State<BackupSecurityScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = false;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/backup/list/');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _backups = List<Map<String, dynamic>>.from(response.data['backups'] ?? []);
        });
      }
    } catch (e) {
      _showError('Failed to load backups: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup({List<String>? modules}) async {
    setState(() => _isLoading = true);
    try {
      String url = '${ApiConfig.baseUrl}/backup/create/';
      if (modules != null && modules.isNotEmpty) {
        url += '?modules=${modules.join(',')}';
      }

      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200) {
        // Save file
        String fileName = 'backup_';
        if (modules != null && modules.isNotEmpty) {
          fileName += '${modules.join('_')}_';
        } else {
          fileName += 'full_';
        }
        fileName += '${DateTime.now().toString().replaceAll(':', '-').split('.')[0]}.json';

        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(response.data);
          _showSuccess('Backup created and saved successfully');
          _loadBackups();
        }
      }
    } catch (e) {
      _showError('Failed to create backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBackupOptionsDialog() {
    final Map<String, String> availableModules = {
      'sales,sale_items,payments': 'Invoices & Financials',
      'labors,advance_payments': 'Employees & HR Records',
      'products,categories': 'Inventory & Categories',
      'customers': 'Customer Directory',
      'purchases': 'Purchase Management',
      'orders,order_items': 'Orders & Rental History',
      'expenses': 'Expense Management',
    };
    List<String> selectedModules = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                    Icon(Icons.backup_outlined, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Backup Options', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Full System Backup', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Text('Recommended for complete security', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
                      leading: const Icon(Icons.all_inclusive, color: Colors.blue),
                      onTap: () {
                        Navigator.pop(context);
                        _createBackup();
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Selective Module Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                      ),
                    ),
                    ...availableModules.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 14)),
                        value: selectedModules.contains(entry.key),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedModules.add(entry.key);
                            } else {
                              selectedModules.remove(entry.key);
                            }
                          });
                        },
                        activeColor: AppTheme.primaryMaroon,
                        dense: true,
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createBackup();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                  child: const Text(
                    'Full Backup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedModules.isEmpty 
                    ? null 
                    : () {
                        Navigator.pop(context);
                        _createBackup(modules: selectedModules);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                  ),
                  child: const Text(
                    'Backup Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, 
                      fontSize: 13
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
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
                Text('Confirm Restore', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: Text(
            'This will replace all current data with the backup. Are you sure?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Restore',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          final file = File(result.files.single.path!);
          final formData = FormData.fromMap({
            'backup_file': await MultipartFile.fromFile(file.path),
          });

          final response = await _dio.post(
            '${ApiConfig.baseUrl}/backup/restore/',
            data: formData,
          );

          if (response.statusCode == 200 && response.data['success']) {
            _showSuccess('Database restored successfully');
          } else {
            _showError(response.data['message'] ?? 'Restore failed');
          }
        } catch (e) {
          _showError('Failed to restore backup: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50), // Dark Blue Header
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Delete Backup', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: Text(
          'Delete backup file: $filename?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _dio.delete('${ApiConfig.baseUrl}/backup/delete/$filename/');
        if (response.statusCode == 200) {
          _showSuccess('Backup deleted successfully');
          _loadBackups();
        }
      } catch (e) {
        _showError('Failed to delete backup: $e');
      }
    }
  }

  Future<void> _downloadExistingBackup(String filename) async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/backup/download/$filename/',
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Download Backup',
          fileName: filename,
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(response.data);
          _showSuccess('Backup downloaded successfully');
        }
      }
    } catch (e) {
      _showError('Failed to download backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildBackupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Backup & Security",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        SizedBox(height: 4),
        Text(
          "Manage database backups and restore points",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: "Create Backup",
            subtitle: "Download current database",
            icon: Icons.backup,
            color: AppTheme.primaryMaroon,
            onTap: _isLoading ? null : _showBackupOptionsDialog,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildActionCard(
            title: "Restore Backup",
            subtitle: "Upload and restore from file",
            icon: Icons.restore,
            color: Colors.orange,
            onTap: _isLoading ? null : _restoreBackup,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildActionCard(
            title: "Refresh List",
            subtitle: "Reload backup files",
            icon: Icons.refresh,
            color: Colors.blue,
            onTap: _isLoading ? null : _loadBackups,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Available Backups",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_backups.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text(
                  "No backups available",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backups.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final backup = _backups[index];
                final String fileName = backup['filename'] ?? '';
                final isFull = fileName.contains('full');
                
                String displayTitle = "System Backup";
                if (!isFull) {
                  // Extract modules from backup_mod1_mod2_timestamp.json
                  try {
                    final parts = fileName.split('_');
                    if (parts.length > 2) {
                      displayTitle = "Partial: ${parts[1].toUpperCase()}...";
                    }
                  } catch (e) {
                    displayTitle = "Selective Backup";
                  }
                } else {
                  displayTitle = "Full System Backup";
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFull ? Icons.storage : Icons.snippet_folder, 
                      color: isFull ? Colors.blue : Colors.orange
                    ),
                  ),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${(backup['size'] / 1024).toStringAsFixed(2)} KB • Created: ${backup['created_at']?.toString().split('T')[0] ?? ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_for_offline, color: AppTheme.primaryMaroon),
                        onPressed: () => _downloadExistingBackup(fileName),
                        tooltip: 'Download File',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteBackup(fileName),
                        tooltip: 'Delete Backup',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
