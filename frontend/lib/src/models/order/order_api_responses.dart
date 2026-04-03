import 'order_model.dart';
import 'order_item_model.dart';

// Utility class for order status conversion
class OrderStatusConverter {
  // Convert frontend status to backend format
  static String toBackend(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'PENDING';
      case 'CONFIRMED':
        return 'CONFIRMED';
      case 'READY':
        return 'READY';
      case 'DELIVERED':
        return 'DELIVERED';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  // Convert backend status to frontend format
  static String toFrontend(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'PENDING';
      case 'CONFIRMED':
        return 'CONFIRMED';
      case 'READY':
        return 'READY';
      case 'DELIVERED':
        return 'DELIVERED';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }
}

// Pagination Info
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationInfo({
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

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

// Order List Response
class OrdersListResponse {
  final List<OrderModel> orders;
  final PaginationInfo pagination;

  const OrdersListResponse({required this.orders, required this.pagination});

  factory OrdersListResponse.fromJson(Map<String, dynamic> json) {
    return OrdersListResponse(
      orders: (json['orders'] as List<dynamic>? ?? []).map((orderJson) => OrderModel.fromJson(orderJson as Map<String, dynamic>)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'orders': orders.map((order) => order.toJson()).toList(), 'pagination': pagination.toJson()};
  }
}

// Order Item List Response
class OrderItemsListResponse {
  final List<OrderItemModel> orderItems;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;
  final String? searchQuery;
  final String? orderId;
  final String? productId;

  const OrderItemsListResponse({
    required this.orderItems,
    required this.pagination,
    this.filtersApplied,
    this.searchQuery,
    this.orderId,
    this.productId,
  });

  factory OrderItemsListResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemsListResponse(
      orderItems: (json['order_items'] as List<dynamic>? ?? []).map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_items': orderItems.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters_applied': filtersApplied,
      'search_query': searchQuery,
      'order_id': orderId,
      'product_id': productId,
    };
  }
}

// Order Statistics Response
class OrderStatisticsResponse {
  final int totalOrders;
  final Map<String, int> statusBreakdown;
  final Map<String, dynamic> financialSummary;
  final Map<String, dynamic> paymentSummary;
  final Map<String, dynamic> deliverySummary;
  final Map<String, dynamic> recentActivity;

  const OrderStatisticsResponse({
    required this.totalOrders,
    required this.statusBreakdown,
    required this.financialSummary,
    required this.paymentSummary,
    required this.deliverySummary,
    required this.recentActivity,
  });

  factory OrderStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatisticsResponse(
      totalOrders: json['total_orders'] as int? ?? 0,
      statusBreakdown: Map<String, int>.from(json['status_breakdown'] as Map<String, dynamic>? ?? {}),
      financialSummary: Map<String, dynamic>.from(json['financial_summary'] as Map<String, dynamic>? ?? {}),
      paymentSummary: Map<String, dynamic>.from(json['payment_summary'] as Map<String, dynamic>? ?? {}),
      deliverySummary: Map<String, dynamic>.from(json['delivery_summary'] as Map<String, dynamic>? ?? {}),
      recentActivity: Map<String, dynamic>.from(json['recent_activity'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'status_breakdown': statusBreakdown,
      'financial_summary': financialSummary,
      'payment_summary': paymentSummary,
      'delivery_summary': deliverySummary,
      'recent_activity': recentActivity,
    };
  }
}

// Order Item Statistics Response
class OrderItemStatisticsResponse {
  final int totalOrderItems;
  final int activeOrderItems;
  final int inactiveOrderItems;
  final int itemsWithCustomization;
  final double totalValue;
  final int totalQuantity;
  final Map<String, int> itemsByStatus;
  final Map<String, double> valueByProduct;
  final Map<String, int> quantityByProduct;

  const OrderItemStatisticsResponse({
    required this.totalOrderItems,
    required this.activeOrderItems,
    required this.inactiveOrderItems,
    required this.itemsWithCustomization,
    required this.totalValue,
    required this.totalQuantity,
    required this.itemsByStatus,
    required this.valueByProduct,
    required this.quantityByProduct,
  });

  factory OrderItemStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemStatisticsResponse(
      totalOrderItems: json['total_order_items'] as int? ?? 0,
      activeOrderItems: json['active_order_items'] as int? ?? 0,
      inactiveOrderItems: json['inactive_order_items'] as int? ?? 0,
      itemsWithCustomization: json['items_with_customization'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: json['total_quantity'] as int? ?? 0,
      itemsByStatus: Map<String, int>.from(json['items_by_status'] as Map? ?? {}),
      valueByProduct: Map<String, double>.from(
        (json['value_by_product'] as Map?)?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      ),
      quantityByProduct: Map<String, int>.from(json['quantity_by_product'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_order_items': totalOrderItems,
      'active_order_items': activeOrderItems,
      'inactive_order_items': inactiveOrderItems,
      'items_with_customization': itemsWithCustomization,
      'total_value': totalValue,
      'total_quantity': totalQuantity,
      'items_by_status': itemsByStatus,
      'value_by_product': valueByProduct,
      'quantity_by_product': quantityByProduct,
    };
  }
}

// Order Create Request
class OrderCreateRequest {
  final String customer;
  final List<OrderItemModel> items;
  final double advancePayment;
  final DateTime? dateOrdered;
  final DateTime? expectedDeliveryDate;
  final String? eventName;
  final String? eventLocation;
  final DateTime? eventDate;
  final DateTime? returnDate;
  final String description;
  final String status;

  const OrderCreateRequest({
    required this.customer,
    required this.items,
    required this.advancePayment,
    this.dateOrdered,
    this.expectedDeliveryDate,
    this.eventName,
    this.eventLocation,
    this.eventDate,
    this.returnDate,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      'items': items.map((item) => item.toJson()).toList(),
      'advance_payment': advancePayment,
      'date_ordered': dateOrdered?.toIso8601String().split('T')[0],
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String().split('T')[0],
      'event_name': eventName,
      'event_location': eventLocation,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'description': description,
      'status': OrderStatusConverter.toBackend(status),
    };
  }
}

// Order Update Request
class OrderUpdateRequest {
  final double advancePayment;
  final DateTime? expectedDeliveryDate;
  final String description;
  final String status;

  const OrderUpdateRequest({required this.advancePayment, this.expectedDeliveryDate, required this.description, required this.status});

  Map<String, dynamic> toJson() {
    return {
      'advance_payment': advancePayment,
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'description': description,
      'status': OrderStatusConverter.toBackend(status), // Convert to proper backend format
    };
  }
}

// Order Item Create Request
class OrderItemCreateRequest {
  final String order;
  final String product;
  final int quantity;
  final double unitPrice;
  final String customizationNotes;

  const OrderItemCreateRequest({
    required this.order,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.customizationNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'product': product,
      'quantity': quantity,
      'unit_price': unitPrice,
      'customization_notes': customizationNotes,
      'notes': customizationNotes,
      'description': customizationNotes,
      'comment': customizationNotes,
      'remarks': customizationNotes,
    };
  }
}

// Order Item Update Request
class OrderItemUpdateRequest {
  final int quantity;
  final double unitPrice;
  final String customizationNotes;

  const OrderItemUpdateRequest({required this.quantity, required this.unitPrice, required this.customizationNotes});

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unit_price': unitPrice,
      'customization_notes': customizationNotes,
      'notes': customizationNotes,
      'description': customizationNotes,
      'comment': customizationNotes,
      'remarks': customizationNotes,
    };
  }
}

// Order Payment Request
class OrderPaymentRequest {
  final double amount;

  const OrderPaymentRequest({required this.amount});

  Map<String, dynamic> toJson() {
    return {'amount': amount};
  }
}

// Order Status Update Request
class OrderStatusUpdateRequest {
  final String status;
  final String? notes;

  const OrderStatusUpdateRequest({required this.status, this.notes});

  Map<String, dynamic> toJson() {
    return {'status': OrderStatusConverter.toBackend(status), if (notes != null) 'notes': notes}; // Convert to proper backend format
  }
}

// Order Search Parameters
class OrderListParams {
  final int page;
  final int pageSize;
  final bool showInactive;
  final String? search;
  final String? customerId;
  final String? status;
  final String? paymentStatus;
  final String? deliveryStatus;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minValue;
  final double? maxValue;
  final String? sortBy;
  final String? sortOrder;

  const OrderListParams({
    this.page = 1,
    this.pageSize = 20,
    this.showInactive = false,
    this.search,
    this.customerId,
    this.status,
    this.paymentStatus,
    this.deliveryStatus,
    this.dateFrom,
    this.dateTo,
    this.minValue,
    this.maxValue,
    this.sortBy = 'date_ordered',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString(), 'show_inactive': showInactive.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (customerId != null && customerId!.isNotEmpty) {
      params['customer_id'] = customerId;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (paymentStatus != null && paymentStatus!.isNotEmpty) {
      params['payment_status'] = paymentStatus;
    }
    if (deliveryStatus != null && deliveryStatus!.isNotEmpty) {
      params['delivery_status'] = deliveryStatus;
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (minValue != null) {
      params['min_value'] = minValue.toString();
    }
    if (maxValue != null) {
      params['max_value'] = maxValue.toString();
    }
    if (sortBy != null) {
      params['sort_by'] = sortBy;
    }
    if (sortOrder != null) {
      params['sort_order'] = sortOrder;
    }

    return params;
  }
}

// Order Item Search Parameters
class OrderItemListParams {
  final int page;
  final int pageSize;
  final bool showInactive;
  final String? search;
  final String? orderId;
  final String? productId;
  final bool? hasCustomization;
  final int? minQuantity;
  final int? maxQuantity;
  final double? minPrice;
  final double? maxPrice;

  const OrderItemListParams({
    this.page = 1,
    this.pageSize = 20,
    this.showInactive = false,
    this.search,
    this.orderId,
    this.productId,
    this.hasCustomization,
    this.minQuantity,
    this.maxQuantity,
    this.minPrice,
    this.maxPrice,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString(), 'show_inactive': showInactive.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (orderId != null && orderId!.isNotEmpty) {
      params['order_id'] = orderId;
    }
    if (productId != null && productId!.isNotEmpty) {
      params['product_id'] = productId;
    }
    if (hasCustomization != null) {
      params['has_customization'] = hasCustomization.toString();
    }
    if (minQuantity != null) {
      params['min_quantity'] = minQuantity.toString();
    }
    if (maxQuantity != null) {
      params['max_quantity'] = maxQuantity.toString();
    }
    if (minPrice != null) {
      params['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice.toString();
    }

    return params;
  }
}
