import 'role_model.dart';

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final int? roleId;
  final String? roleName;
  final List<PermissionModel> permissions;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.roleId,
    this.roleName,
    this.permissions = const [],
    this.isActive = true,
    this.isSuperuser = false,
    this.dateJoined,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var list = json['permissions'] as List? ?? [];
    List<PermissionModel> permissionsList = list.map((i) => PermissionModel.fromJson(i)).toList();

    return UserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleId: json['role_id'] as int?,
      roleName: json['role_name'] as String?,
      permissions: permissionsList,
      isActive: json['is_active'] as bool? ?? true,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role_id': roleId,
      'role_name': roleName,
      'permissions': permissions.map((e) => e.toJson()).toList(),
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    int? roleId,
    String? roleName,
    List<PermissionModel>? permissions,
    bool? isActive,
    bool? isSuperuser,
    DateTime? dateJoined,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool hasPermission(String moduleName) {
    if (isSuperuser || roleName == 'Admin') return true;
    return permissions.any((p) => p.moduleName == moduleName && p.canView);
  }

  bool canPerform(String moduleName, String action) {
    if (isSuperuser || roleName == 'Admin') return true;
    final perm = permissions.firstWhere(
      (p) => p.moduleName == moduleName,
      orElse: () => PermissionModel(moduleName: moduleName),
    );
    switch (action.toLowerCase()) {
      case 'view': return perm.canView;
      case 'add': return perm.canAdd;
      case 'edit': return perm.canEdit;
      case 'delete': return perm.canDelete;
      default: return false;
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, roleName: $roleName, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.roleId == roleId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, fullName, email, roleId, roleName, isActive);
  }
}