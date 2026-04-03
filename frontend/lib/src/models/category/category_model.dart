class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByEmail;
  final int? createdById;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdByEmail,
    this.createdById,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] as String;
    final createdAt = DateTime.parse(createdAtStr);

    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : createdAt, // Use createdAt as fallback if updated_at is missing
      createdByEmail: json['created_by_email'] as String?,
      createdById: json['created_by_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdByEmail,
      'created_by_id': createdById,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByEmail,
    int? createdById,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdById: createdById ?? this.createdById,
    );
  }

  // Formatted date for display
  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get formattedUpdatedAt {
    return '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
  }

  // Relative date (e.g., "Today", "Yesterday", "2 days ago")
  String get relativeCreatedAt {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final categoryDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final difference = today.difference(categoryDate).inDays;

    return _getRelativeDateString(difference);
  }

  String get relativeUpdatedAt {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final categoryDate = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
    final difference = today.difference(categoryDate).inDays;

    return _getRelativeDateString(difference);
  }

  String _getRelativeDateString(int difference) {
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, description: $description, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, createdByEmail: $createdByEmail, createdById: $createdById)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdByEmail == createdByEmail &&
        other.createdById == createdById;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      isActive,
      createdAt,
      updatedAt,
      createdByEmail,
      createdById,
    );
  }
}