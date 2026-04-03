import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String name;
  final String detail;
  final double price;
  final double? costPrice; // Added cost price field
  final String? color;
  final String? fabric;
  final List<String>? pieces;
  final int quantity;
  final int quantityAvailable;
  final int? dateAvailableQuantity; // Added for date-wise availability check
  final int quantityReserved;
  final int quantityDamaged;
  final String? serialNumber;
  final String? warehouseLocation;
  final String pricingType;
  final bool isRental;
  final bool isConsumable;
  final String? categoryId;
  final String? categoryName;
  final String stockStatus;
  final String stockStatusDisplay;
  final double totalValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final int? createdById;
  final String? createdByEmail;
  final String? barcode;
  final String? sku;
  final int minStockThreshold;
  final int totalSold;
  final double monthlyRevenue;

  const ProductModel({
    required this.id,
    required this.name,
    required this.detail,
    required this.price,
    this.costPrice,
    this.color,
    this.fabric,
    this.pieces,
    required this.quantity,
    this.quantityAvailable = 0,
    this.dateAvailableQuantity, // Added
    this.quantityReserved = 0,
    this.quantityDamaged = 0,
    this.serialNumber,
    this.warehouseLocation,
    this.pricingType = 'PER_DAY',
    this.isRental = true,
    this.isConsumable = false,
    this.categoryId,
    this.categoryName,
    required this.stockStatus,
    required this.stockStatusDisplay,
    required this.totalValue,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdById,
    this.createdByEmail,
    this.barcode,
    this.sku,
    this.minStockThreshold = 5,
    this.totalSold = 0,
    this.monthlyRevenue = 0.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      detail: json['detail'] as String? ?? '',
      // Handle price as string or number
      price: _parseDouble(json['price']),
      costPrice: json['cost_price'] != null
          ? _parseDouble(json['cost_price'])
          : null, // Parse cost price
      color: json['color'] as String?,
      fabric: json['fabric'] as String?,
      pieces: json['pieces'] != null ? _parsePieces(json['pieces']) : null,
      quantity: json['quantity'] as int? ?? 0,
      quantityAvailable: json['quantity_available'] as int? ?? 0,
      dateAvailableQuantity: json['date_available_quantity'] as int?, // Added
      quantityReserved: json['quantity_reserved'] as int? ?? 0,
      quantityDamaged: json['quantity_damaged'] as int? ?? 0,
      serialNumber: json['serial_number'] as String?,
      warehouseLocation: json['warehouse_location'] as String?,
      pricingType: json['pricing_type'] as String? ?? 'PER_DAY',
      isRental: json['is_rental'] as bool? ?? true,
      isConsumable: json['is_consumable'] as bool? ?? false,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      stockStatus: json['stock_status'] as String? ?? 'UNKNOWN',
      stockStatusDisplay: json['stock_status_display'] as String? ?? 'Unknown',
      totalValue: _parseDouble(json['total_value']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdById: json['created_by_id'] as int?,
      createdByEmail: json['created_by_email'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      minStockThreshold: json['min_stock_threshold'] as int? ?? 5,
      totalSold: json['total_sold'] as int? ?? 0,
      monthlyRevenue: _parseDouble(json['monthly_revenue']),
    );
  }

  // Helper method to parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse pieces - handle both array and string
  static List<String> _parsePieces(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      // If it's a string, split by comma and clean up
      if (value.isEmpty) return [];
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'detail': detail,
      'price': price,
      'cost_price': costPrice, // Include cost price in JSON
      'color': color,
      'fabric': fabric,
      'pieces': pieces,
      'quantity': quantity,
      'quantity_available': quantityAvailable,
      'date_available_quantity': dateAvailableQuantity, // Added
      'quantity_reserved': quantityReserved,
      'quantity_damaged': quantityDamaged,
      'serial_number': serialNumber,
      'warehouse_location': warehouseLocation,
      'pricing_type': pricingType,
      'is_rental': isRental,
      'is_consumable': isConsumable,
      'category_id': categoryId,
      'category_name': categoryName,
      'stock_status': stockStatus,
      'stock_status_display': stockStatusDisplay,
      'total_value': totalValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_by_id': createdById,
      'created_by_email': createdByEmail,
      'barcode': barcode,
      'sku': sku,
      'min_stock_threshold': minStockThreshold,
    };
  }

  // Helper getters
  String get formattedPrice => 'PKR ${price.toStringAsFixed(0)}';
  String get formattedCostPrice =>
      costPrice != null ? 'PKR ${costPrice!.toStringAsFixed(0)}' : 'Not Set';
  String get formattedTotalValue => 'PKR ${totalValue.toStringAsFixed(0)}';

  // Barcode and SKU helpers
  String get displayBarcode => barcode ?? 'No Barcode';
  String get displaySku => sku ?? 'No SKU';
  bool get hasBarcode => barcode != null && barcode!.isNotEmpty;
  bool get hasSku => sku != null && sku!.isNotEmpty;

  // Check if cost price is set
  bool get hasCostPrice => costPrice != null && costPrice! > 0;

  // Profit margin calculations
  double? get profitMargin {
    if (costPrice == null || costPrice == 0) return null;
    return ((price - costPrice!) / price) * 100;
  }

  String get formattedProfitMargin {
    final margin = profitMargin;
    if (margin == null) return 'N/A';
    return '${margin.toStringAsFixed(1)}%';
  }

  double? get profitAmount {
    if (costPrice == null) return null;
    return price - costPrice!;
  }

  String get formattedProfitAmount {
    final profit = profitAmount;
    if (profit == null) return 'N/A';
    return 'PKR ${profit.toStringAsFixed(0)}';
  }

  bool get isOutOfStock => stockStatus == 'OUT_OF_STOCK';
  bool get isLowStock => stockStatus == 'LOW_STOCK';
  bool get isMediumStock => stockStatus == 'MEDIUM_STOCK';
  bool get isHighStock => stockStatus == 'HIGH_STOCK';

  Color get stockStatusColor {
    switch (stockStatus) {
      case 'OUT_OF_STOCK':
        return Colors.red;
      case 'LOW_STOCK':
        return Colors.orange;
      case 'MEDIUM_STOCK':
        return Colors.yellow[700]!;
      case 'HIGH_STOCK':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get stockStatusText => stockStatusDisplay;
  String get piecesText => pieces?.join(', ') ?? '';

  bool get isHardware => isRental || isConsumable;
  String get displayPricingType =>
      pricingType == 'PER_DAY' ? 'Per Day' : 'Per Event';

  // Copy with method for updates
  ProductModel copyWith({
    String? id,
    String? name,
    String? detail,
    double? price,
    double? costPrice, // Added cost price parameter
    String? color,
    String? fabric,
    List<String>? pieces,
    int? quantity,
    int? quantityAvailable,
    int? dateAvailableQuantity, // Added
    int? quantityReserved,
    int? quantityDamaged,
    String? serialNumber,
    String? warehouseLocation,
    String? pricingType,
    bool? isRental,
    bool? isConsumable,
    String? categoryId,
    String? categoryName,
    String? stockStatus,
    String? stockStatusDisplay,
    double? totalValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? createdById,
    String? createdByEmail,
    String? barcode,
    String? sku,
    int? minStockThreshold,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      color: color ?? this.color,
      fabric: fabric ?? this.fabric,
      pieces: pieces ?? this.pieces,
      quantity: quantity ?? this.quantity,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      dateAvailableQuantity: dateAvailableQuantity ?? this.dateAvailableQuantity, // Added
      quantityReserved: quantityReserved ?? this.quantityReserved,
      quantityDamaged: quantityDamaged ?? this.quantityDamaged,
      serialNumber: serialNumber ?? this.serialNumber,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      pricingType: pricingType ?? this.pricingType,
      isRental: isRental ?? this.isRental,
      isConsumable: isConsumable ?? this.isConsumable,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stockStatus: stockStatus ?? this.stockStatus,
      stockStatusDisplay: stockStatusDisplay ?? this.stockStatusDisplay,
      totalValue: totalValue ?? this.totalValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product(id: $id, name: $name, quantity: $quantity)';
}

// Product API Response Models
class ProductsListResponse {
  final List<ProductModel> products;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  ProductsListResponse({
    required this.products,
    required this.pagination,
    this.filtersApplied,
  });

  factory ProductsListResponse.fromJson(Map<String, dynamic> json) {
    return ProductsListResponse(
      products: (json['products'] as List? ?? [])
          .map((productJson) => ProductModel.fromJson(productJson))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters_applied': filtersApplied,
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
      currentPage: json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
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
}

class ProductCreateRequest {
  final String name;
  final String detail;
  final double price;
  final double? costPrice; // Added cost price field
  final String? color;
  final String? fabric;
  final List<String>? pieces;
  final int quantity;
  final String category; // Category UUID
  final String? serialNumber;
  final String? warehouseLocation;
  final String? pricingType;
  final bool? isRental;
  final bool? isConsumable;
  final String? barcode;
  final String? sku;
  final int? minStockThreshold;

  ProductCreateRequest({
    required this.name,
    required this.detail,
    required this.price,
    this.costPrice,
    this.color,
    this.fabric,
    this.pieces,
    required this.quantity,
    required this.category,
    this.serialNumber,
    this.warehouseLocation,
    this.pricingType,
    this.isRental,
    this.isConsumable,
    this.barcode,
    this.sku,
    this.minStockThreshold,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'detail': detail,
      'price': price,
      'quantity': quantity,
      'category': category,
    };

    if (costPrice != null) data['cost_price'] = costPrice;
    if (color != null) data['color'] = color;
    if (fabric != null) data['fabric'] = fabric;
    if (pieces != null) data['pieces'] = pieces;
    if (serialNumber != null) data['serial_number'] = serialNumber;
    if (warehouseLocation != null) data['warehouse_location'] = warehouseLocation;
    if (pricingType != null) data['pricing_type'] = pricingType;
    if (isRental != null) data['is_rental'] = isRental;
    if (isConsumable != null) data['is_consumable'] = isConsumable;
    if (barcode != null) data['barcode'] = barcode;
    if (sku != null) data['sku'] = sku;
    if (minStockThreshold != null) data['min_stock_threshold'] = minStockThreshold;

    return data;
  }
}

class ProductUpdateRequest {
  final String? name;
  final String? detail;
  final double? price;
  final double? costPrice; // Added cost price field
  final String? color;
  final String? fabric;
  final List<String>? pieces;
  final int? quantity;
  final String? category; // Category UUID
  final String? serialNumber;
  final String? warehouseLocation;
  final String? pricingType;
  final bool? isRental;
  final bool? isConsumable;
  final int? minStockThreshold;

  ProductUpdateRequest({
    this.name,
    this.detail,
    this.price,
    this.costPrice,
    this.color,
    this.fabric,
    this.pieces,
    this.quantity,
    this.category,
    this.serialNumber,
    this.warehouseLocation,
    this.pricingType,
    this.isRental,
    this.isConsumable,
    this.minStockThreshold,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (detail != null) data['detail'] = detail;
    if (price != null) data['price'] = price;
    if (costPrice != null) data['cost_price'] = costPrice; // Include cost price
    if (color != null) data['color'] = color;
    if (fabric != null) data['fabric'] = fabric;
    if (pieces != null) data['pieces'] = pieces;
    if (quantity != null) data['quantity'] = quantity;
    if (category != null) data['category'] = category;
    if (serialNumber != null) data['serial_number'] = serialNumber;
    if (warehouseLocation != null)
      data['warehouse_location'] = warehouseLocation;
    if (pricingType != null) data['pricing_type'] = pricingType;
    if (isRental != null) data['is_rental'] = isRental;
    if (isConsumable != null) data['is_consumable'] = isConsumable;
    if (minStockThreshold != null) data['min_stock_threshold'] = minStockThreshold;
    return data;
  }
}

class ProductFilters {
  final String? search;
  final String? categoryId;
  final String? color;
  final String? fabric;
  final String? stockLevel;
  final double? minPrice;
  final double? maxPrice;
  final String? barcode;
  final String? sku;
  final bool? isRental; // Added isRental
  final bool? isConsumable; // Added isConsumable
  final bool? showInactive; // Added showInactive
  final DateTime? startDate; // Added for date-wise check
  final DateTime? endDate; // Added for date-wise check
  final String sortBy;
  final String sortOrder;

  const ProductFilters({
    this.search,
    this.categoryId,
    this.color,
    this.fabric,
    this.stockLevel,
    this.minPrice,
    this.maxPrice,
    this.barcode,
    this.sku,
    this.isRental, // Added parameter
    this.isConsumable, // Added parameter
    this.showInactive, // Added parameter
    this.startDate, // Added
    this.endDate, // Added
    this.sortBy = 'name',
    this.sortOrder = 'asc',
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (categoryId != null && categoryId!.isNotEmpty)
      params['category_id'] = categoryId!;
    if (color != null && color!.isNotEmpty) params['color'] = color!;
    if (fabric != null && fabric!.isNotEmpty) params['fabric'] = fabric!;
    if (stockLevel != null && stockLevel!.isNotEmpty)
      params['stock_level'] = stockLevel!;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (barcode != null && barcode!.isNotEmpty) params['barcode'] = barcode!;
    if (sku != null && sku!.isNotEmpty) params['sku'] = sku!;
    if (isRental != null) params['is_rental'] = isRental.toString(); // Added parameter
    if (isConsumable != null) params['is_consumable'] = isConsumable.toString(); // Added parameter
    if (showInactive != null) params['show_inactive'] = showInactive.toString(); // Added parameter
    if (startDate != null) params['start_date'] = startDate!.toIso8601String().split('T')[0];
    if (endDate != null) params['end_date'] = endDate!.toIso8601String().split('T')[0];
    params['sort_by'] = sortBy;
    params['sort_order'] = sortOrder;

    return params;
  }

  ProductFilters copyWith({
    String? search,
    String? categoryId,
    String? color,
    String? fabric,
    String? stockLevel,
    double? minPrice,
    double? maxPrice,
    String? barcode,
    String? sku,
    bool? isRental, // Added parameter
    bool? isConsumable, // Added parameter
    bool? showInactive, // Added parameter
    DateTime? startDate, // Added
    DateTime? endDate, // Added
    String? sortBy,
    String? sortOrder,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      fabric: fabric ?? this.fabric,
      stockLevel: stockLevel ?? this.stockLevel,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isRental: isRental ?? this.isRental, // Added parameter
      isConsumable: isConsumable ?? this.isConsumable, // Added parameter
      showInactive: showInactive ?? this.showInactive, // Added parameter
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ProductStatistics {
  final int totalProducts;
  final double totalInventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final List<CategoryStats> categoryBreakdown;
  final StockStatusSummary stockStatusSummary;

  const ProductStatistics({
    required this.totalProducts,
    required this.totalInventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categoryBreakdown,
    required this.stockStatusSummary,
  });

  factory ProductStatistics.fromJson(Map<String, dynamic> json) {
    return ProductStatistics(
      totalProducts: json['total_products'] as int? ?? 0,
      totalInventoryValue: ProductModel._parseDouble(
        json['total_inventory_value'],
      ),
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      outOfStockCount: json['out_of_stock_count'] as int? ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List? ?? [])
          .map((item) => CategoryStats.fromJson(item))
          .toList(),
      stockStatusSummary: StockStatusSummary.fromJson(
        json['stock_status_summary'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'total_inventory_value': totalInventoryValue,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'category_breakdown': categoryBreakdown
          .map((item) => item.toJson())
          .toList(),
      'stock_status_summary': stockStatusSummary.toJson(),
    };
  }
}

class CategoryStats {
  final String categoryName;
  final int count;
  final int totalQuantity;
  final double? totalValue;

  const CategoryStats({
    required this.categoryName,
    required this.count,
    required this.totalQuantity,
    this.totalValue,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      categoryName: json['category__name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalQuantity: json['total_quantity'] as int? ?? 0,
      totalValue: ProductModel._parseDouble(json['total_value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category__name': categoryName,
      'count': count,
      'total_quantity': totalQuantity,
      'total_value': totalValue,
    };
  }
}

class StockStatusSummary {
  final int inStock;
  final int mediumStock;
  final int lowStock;
  final int outOfStock;

  const StockStatusSummary({
    required this.inStock,
    required this.mediumStock,
    required this.lowStock,
    required this.outOfStock,
  });

  factory StockStatusSummary.fromJson(Map<String, dynamic> json) {
    return StockStatusSummary(
      inStock: json['in_stock'] as int? ?? 0,
      mediumStock: json['medium_stock'] as int? ?? 0,
      lowStock: json['low_stock'] as int? ?? 0,
      outOfStock: json['out_of_stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in_stock': inStock,
      'medium_stock': mediumStock,
      'low_stock': lowStock,
      'out_of_stock': outOfStock,
    };
  }
}
