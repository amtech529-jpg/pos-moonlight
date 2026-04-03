import 'category_model.dart';

class CategoriesListResponse {
  final List<CategoryModel> categories;
  final PaginationInfo pagination;

  CategoriesListResponse({
    required this.categories,
    required this.pagination,
  });

  factory CategoriesListResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesListResponse(
      categories: (json['categories'] as List)
          .map((categoryJson) => CategoryModel.fromJson(categoryJson))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] as int,
      pageSize: json['page_size'] as int,
      totalCount: json['total_count'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrevious: json['has_previous'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'page_size': pageSize,
      'total_count': totalCount,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

class CategoryCreateRequest {
  final String name;
  final String description;

  CategoryCreateRequest({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class CategoryUpdateRequest {
  final String name;
  final String description;

  CategoryUpdateRequest({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class CategoryListParams {
  final int page;
  final int pageSize;
  final String? search;
  final bool showInactive;

  CategoryListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.showInactive = false,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'show_inactive': showInactive.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }

    return params;
  }

  CategoryListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
  }) {
    return CategoryListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      showInactive: showInactive ?? this.showInactive,
    );
  }

  @override
  String toString() {
    return 'CategoryListParams(page: $page, pageSize: $pageSize, search: $search, showInactive: $showInactive)';
  }
}