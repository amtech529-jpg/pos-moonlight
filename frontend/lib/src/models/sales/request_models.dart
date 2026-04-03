import 'sale_model.dart';

/// Request model for creating a new sale
class CreateSaleRequest {
  final String? orderId;
  final String? customerId;
  final double overallDiscount;
  final TaxConfiguration taxConfiguration;
  final String paymentMethod;
  final double? amountPaid; 
  final Map<String, dynamic>? splitPaymentDetails;
  final String? notes;
  final List<CreateSaleItemRequest> saleItems;

  CreateSaleRequest({
    this.orderId,
    this.customerId,
    required this.overallDiscount,
    required this.taxConfiguration,
    required this.paymentMethod,
    required this.amountPaid,
    this.splitPaymentDetails,
    this.notes,
    required this.saleItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer': customerId,
      'overall_discount': overallDiscount.toString(),
      'tax_configuration': taxConfiguration.toJson(),
      'payment_method': paymentMethod,
      'amount_paid': amountPaid?.toString() ?? '0.0',
      // 🔥 FIX: Don't send null - send empty dict or omit the field
      if (splitPaymentDetails != null) 'split_payment_details': splitPaymentDetails,
      // 🔥 FIX: Don't send null - send empty string or omit the field  
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'sale_items': saleItems.map((item) => item.toJson()).toList(),
    };
  }
}

/// Request model for creating a sale item
class CreateSaleItemRequest {
  final String? orderItemId;
  final String productId;
  final double unitPrice;
  final int quantity;
  final double itemDiscount;
  final String? customizationNotes;

  CreateSaleItemRequest({
    this.orderItemId,
    required this.productId,
    required this.unitPrice,
    required this.quantity,
    required this.itemDiscount,
    this.customizationNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_item': orderItemId,
      'product': productId,
      'unit_price': unitPrice.toString(),
      'quantity': quantity,
      'item_discount': itemDiscount.toString(),
      'customization_notes': customizationNotes,
    };
  }
}

/// Request model for updating a sale
class UpdateSaleRequest {
  final double? overallDiscount;
  final TaxConfiguration? taxConfiguration;
  final String? paymentMethod;
  final Map<String, dynamic>? splitPaymentDetails;
  final String? notes;
  final String? status;

  UpdateSaleRequest({this.overallDiscount, this.taxConfiguration, this.paymentMethod, this.splitPaymentDetails, this.notes, this.status});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (overallDiscount != null) data['overall_discount'] = overallDiscount.toString();
    if (taxConfiguration != null) data['tax_configuration'] = taxConfiguration!.toJson();
    if (paymentMethod != null) data['payment_method'] = paymentMethod;
    if (splitPaymentDetails != null) data['split_payment_details'] = splitPaymentDetails;
    if (notes != null) data['notes'] = notes;
    if (status != null) data['status'] = status;
    return data;
  }
}

/// Request model for creating a sale from an order
class CreateSaleFromOrderRequest {
  final String orderId;
  final String paymentMethod;
  final double amountPaid;
  final double overallDiscount;
  final TaxConfiguration? taxConfiguration;
  final String? notes;
  final List<Map<String, dynamic>>? partialItems;

  CreateSaleFromOrderRequest({
    required this.orderId,
    required this.paymentMethod,
    required this.amountPaid,
    required this.overallDiscount,
    this.taxConfiguration,
    this.notes,
    this.partialItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid.toString(),
      'overall_discount': overallDiscount.toString(),
      'tax_configuration': taxConfiguration?.toJson(),
      'notes': notes,
      'partial_items': partialItems,
    };
  }
}

/// Request model for updating a sale item
class UpdateSaleItemRequest {
  final double? unitPrice;
  final int? quantity;
  final double? itemDiscount;
  final String? customizationNotes;

  UpdateSaleItemRequest({this.unitPrice, this.quantity, this.itemDiscount, this.customizationNotes});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (unitPrice != null) data['unit_price'] = unitPrice.toString();
    if (quantity != null) data['quantity'] = quantity;
    if (itemDiscount != null) data['item_discount'] = itemDiscount.toString();
    if (customizationNotes != null) data['customization_notes'] = customizationNotes;
    return data;
  }
}

/// Request model for adding payment to a sale
class AddPaymentRequest {
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;

  AddPaymentRequest({required this.amount, required this.paymentMethod, this.reference, this.notes});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'amount': amount.toString(), 'payment_method': paymentMethod};
    if (reference != null) data['reference'] = reference;
    if (notes != null) data['notes'] = notes;
    return data;
  }
}

/// Request model for bulk actions on sales
class BulkActionRequest {
  final List<String> saleIds;
  final String action;
  final Map<String, dynamic>? actionData;

  BulkActionRequest({required this.saleIds, required this.action, this.actionData});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'sale_ids': saleIds, 'action': action};
    if (actionData != null) data['action_data'] = actionData;
    return data;
  }
}