import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/user_provider.dart';
import '../../../src/models/user_model.dart';
import '../../../src/models/role_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool isApprovalWorkflowEnabled = true;
  RoleModel? selectedRoleForMatrix;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      provider.fetchUsers();
      provider.fetchRoles().then((_) {
        if (provider.roles.isNotEmpty) {
          setState(() {
            selectedRoleForMatrix = provider.roles.first;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    
    // Safety check for view permission
    if (currentUser != null && currentUser.roleName != 'Admin') {
      if (!currentUser.hasPermission('User Management')) {
        return const Center(child: Text("You do not have permission to access User Management", style: TextStyle(color: Colors.black, fontSize: 18)));
      }
    }

    debugPrint('DEBUG: Building UserManagementScreen. Users count: ${userProvider.users.length}, isLoading: ${userProvider.isLoading}');
    
    return Container(
      color: const Color(0xFFF5E9E9),
      padding: const EdgeInsets.all(24.0),
      child: userProvider.isLoading && userProvider.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserManagementSection(context, l10n, userProvider, currentUser),
                  if (currentUser?.roleName == 'Admin') ...[
                    const SizedBox(height: 24),
                    _buildPermissionMatrixSection(context, l10n, userProvider),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildUserManagementSection(BuildContext context, AppLocalizations l10n, UserProvider userProvider, UserModel? currentUser) {
    final bool canAdd = currentUser?.canPerform('User Management', 'add') ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.userManagement,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (canAdd)
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context, l10n, userProvider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add User"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUserTable(l10n, userProvider.users, currentUser),
        ],
      ),
    );
  }

  Widget _buildUserTable(AppLocalizations l10n, List<UserModel> users, UserModel? currentUser) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: _headerText(l10n.userName)),
              Expanded(child: _headerText(l10n.email)),
              Expanded(child: _headerText(l10n.role)),
              Expanded(child: _headerText(l10n.status)),
              Expanded(child: _headerText("Action")),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No users found"),
          )
        else
          ...users.map((user) => _buildUserRow(user, Provider.of<UserProvider>(context, listen: false), currentUser)).toList(),
      ],
    );
  }

  Widget _headerText(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A), // Explicit charcoal black
        fontSize: 12,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildUserRow(UserModel user, UserProvider provider, UserModel? currentUser) {
    debugPrint('ROW_DATA: ${user.fullName} | ${user.email} | ${user.roleName}');
    final bool canEdit = currentUser?.canPerform('User Management', 'edit') ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("NAME", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  user.fullName.isEmpty ? "[EMPTY NAME]" : user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("EMAIL", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  user.email.isEmpty ? "[EMPTY EMAIL]" : user.email,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ROLE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBD0D1D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.roleName ?? 'NO ROLE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBD0D1D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStatusBadge(user.isActive ? 'Active' : 'Inactive')),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: canEdit 
                ? ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(context, AppLocalizations.of(context)!, provider, user),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPermissionMatrixSection(BuildContext context, AppLocalizations l10n, UserProvider userProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.rolePermissionMatrix,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (userProvider.roles.isNotEmpty)
                DropdownButton<RoleModel>(
                  value: selectedRoleForMatrix ?? userProvider.roles.first,
                  items: userProvider.roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name),
                    );
                  }).toList(),
                  onChanged: (role) {
                    setState(() {
                      selectedRoleForMatrix = role;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _headerText(l10n.module)),
                Expanded(child: _headerText(l10n.view)),
                Expanded(child: _headerText(l10n.add)),
                Expanded(child: _headerText(l10n.edit)),
                Expanded(child: _headerText(l10n.delete)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (selectedRoleForMatrix != null)
            ...selectedRoleForMatrix!.permissions.map((perm) => _buildPermissionRow(perm.moduleName, perm, userProvider)).toList(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.approvalWorkflow,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Switch(
                value: isApprovalWorkflowEnabled,
                onChanged: (value) {
                  setState(() {
                    isApprovalWorkflowEnabled = value;
                  });
                },
                activeColor: const Color(0xFF00B894),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String moduleName, PermissionModel perm, UserProvider userProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              moduleName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: _buildCheckbox(perm.canView, (val) => _updatePerm(perm, 'view', val, userProvider))),
          Expanded(child: _buildCheckbox(perm.canAdd, (val) => _updatePerm(perm, 'add', val, userProvider))),
          Expanded(child: _buildCheckbox(perm.canEdit, (val) => _updatePerm(perm, 'edit', val, userProvider))),
          Expanded(child: _buildCheckbox(perm.canDelete, (val) => _updatePerm(perm, 'delete', val, userProvider))),
        ],
      ),
    );
  }

  void _updatePerm(PermissionModel perm, String type, bool value, UserProvider provider) {
    // Implement update logic locally then call API
    if (selectedRoleForMatrix == null) return;
    
    final updatedPerms = selectedRoleForMatrix!.permissions.map((p) {
      if (p.moduleName == perm.moduleName) {
        return PermissionModel(
          moduleName: p.moduleName,
          canView: type == 'view' ? value : p.canView,
          canAdd: type == 'add' ? value : p.canAdd,
          canEdit: type == 'edit' ? value : p.canEdit,
          canDelete: type == 'delete' ? value : p.canDelete,
        );
      }
      return p;
    }).toList();

    provider.updateRolePermissions(selectedRoleForMatrix!.id, updatedPerms.map((e) => e.toJson()).toList()).then((success) {
      if (success) {
        setState(() {
          selectedRoleForMatrix = provider.roles.firstWhere((r) => r.id == selectedRoleForMatrix!.id);
        });
      }
    });
  }

  Widget _buildCheckbox(bool isChecked, Function(bool) onChanged) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Checkbox(
        value: isChecked,
        onChanged: (val) => onChanged(val ?? false),
        activeColor: AppTheme.accentGold,
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, AppLocalizations l10n, UserProvider provider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPassVisible = false;
    int? selectedRoleId;
    
    // Auto-fetch roles if empty
    if (provider.roles.isEmpty && !provider.isLoading) {
      provider.fetchRoles();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "Create New User",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Full Name", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Enter full name (e.g. Ali Ahmed)",
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7B61FF), size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Email Address", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Enter email (e.g. user@example.com)",
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7B61FF), size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Password", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPassVisible,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Enter secure password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7B61FF), size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(isPassVisible ? Icons.visibility : Icons.visibility_off, color: Colors.blue, size: 20),
                            onPressed: () => setDialogState(() => isPassVisible = !isPassVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Select User Role", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      // Use provider.roles directly, but need a way to rebuild when provider changes
                      // Since this is inside a StatefulBuilder, we should wrap the dropdown in a Consumer
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          if (userProvider.isLoading && userProvider.roles.isEmpty) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ));
                          }
                          
                          if (userProvider.roles.isEmpty) {
                            return TextButton.icon(
                              onPressed: () => userProvider.fetchRoles(),
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry loading roles"),
                            );
                          }

                          // Set initial value if not set
                          selectedRoleId ??= userProvider.roles.first.id;

                          return DropdownButtonFormField<int>(
                            value: selectedRoleId,
                            items: userProvider.roles.map((role) {
                              return DropdownMenuItem<int>(
                                value: role.id,
                                child: Text(role.name, style: const TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedRoleId = val;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF7B61FF), size: 20),
                              filled: true,
                              fillColor: Colors.grey[50],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            dropdownColor: Colors.white,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty || selectedRoleId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
                      return;
                    }
                    
                    final payload = {
                      'full_name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': passwordController.text,
                      'password_confirm': passwordController.text,
                      'role_id': selectedRoleId,
                      'agreed_to_terms': true,
                    };
                    
                    final success = await provider.createUser(payload);
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? "Failed to create user"))
                      );
                    }
                  },
                  child: const Text("ADD USER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, AppLocalizations l10n, UserProvider provider, UserModel user) {
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final newPasswordController = TextEditingController();
    bool isPassVisible = false;
    int? selectedRoleId = user.roleId ?? (provider.roles.isNotEmpty ? provider.roles.first.id : 1);
    bool isActive = user.isActive;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "Edit User",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Full Name", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7B61FF), size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Email Address", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7B61FF), size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Select User Role", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        items: provider.roles.map((role) {
                          return DropdownMenuItem<int>(
                            value: role.id,
                            child: Text(role.name, style: const TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedRoleId = val;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      // Password Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_reset, color: Colors.blue, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  "Set New Password",
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Text("(optional)", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newPasswordController,
                              obscureText: !isPassVisible,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "Leave empty to keep current password",
                                hintStyle: const TextStyle(fontSize: 12),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue, size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPassVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () => setDialogState(() => isPassVisible = !isPassVisible),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Account Status", 
                                  style: TextStyle(
                                    color: isActive ? Colors.green[800] : Colors.red[800], 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                                Text(
                                  isActive ? "User can login" : "User is blocked",
                                  style: TextStyle(color: isActive ? Colors.green[600] : Colors.red[600], fontSize: 12),
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (val) {
                                setDialogState(() {
                                  isActive = val;
                                });
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedRoleId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
                      return;
                    }

                    final payload = <String, dynamic>{
                      'full_name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'role_id': selectedRoleId,
                      'is_active': isActive,
                    };
                    // Only send password if user typed one
                    final pwd = newPasswordController.text.trim();
                    if (pwd.isNotEmpty) {
                      payload['new_password'] = pwd;
                    }
                    
                    final success = await provider.updateUser(user.id, payload);
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? "Update failed"))
                      );
                    }
                  },
                  child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
