class RoleModel {
  final int id;
  final String name;
  final String? description;
  final List<PermissionModel> permissions;

  RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    var list = json['permissions'] as List? ?? [];
    List<PermissionModel> permissionsList = list.map((i) => PermissionModel.fromJson(i)).toList();

    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      permissions: permissionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PermissionModel {
  final int? id;
  final String moduleName;
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  PermissionModel({
    this.id,
    required this.moduleName,
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] as int?,
      moduleName: json['module_name'] as String,
      canView: json['can_view'] as bool? ?? false,
      canAdd: json['can_add'] as bool? ?? false,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_name': moduleName,
      'can_view': canView,
      'can_add': canAdd,
      'can_edit': canEdit,
      'can_delete': canDelete,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionModel &&
        other.moduleName == moduleName &&
        other.canView == canView &&
        other.canAdd == canAdd &&
        other.canEdit == canEdit &&
        other.canDelete == canDelete;
  }

  @override
  int get hashCode => Object.hash(moduleName, canView, canAdd, canEdit, canDelete);
}
