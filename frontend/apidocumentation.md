# Django POS System - Complete API Documentation

## Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [Categories APIs](#categories-apis)
3. [Products APIs](#products-apis)
4. [Customers APIs](#customers-apis)
5. [Vendors APIs](#vendors-apis)
6. [Labors APIs](#labors-apis)
7. [Advance Payments APIs](#advance-payments-apis)
8. [Orders APIs](#orders-apis)
9. [Sales APIs](#sales-apis)
10. [Payments APIs](#payments-apis)
11. [Payables APIs](#payables-apis)
12. [Receivables APIs](#receivables-apis)
13. [Expenses APIs](#expenses-apis)
14. [Zakats APIs](#zakats-apis)
15. [Profit & Loss APIs](#profit--loss-apis)
16. [Analytics/Dashboard APIs](#analyticsdashboard-apis)
17. [Purchases APIs](#purchases-apis)

---

## Authentication APIs

### Base Path: `/api/v1/`

#### 1. Register User
- **Endpoint:** `POST /api/v1/auth/register/`
- **Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe"
    },
    "token": "abc123token..."
  }
}
```

#### 2. Login User
- **Endpoint:** `POST /api/v1/auth/login/`
- **Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "abc123token...",
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com"
    }
  }
}
```

#### 3. Logout User
- **Endpoint:** `POST /api/v1/auth/logout/`
- **Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### 4. Get User Profile
- **Endpoint:** `GET /api/v1/auth/profile/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

#### 5. Update User Profile
- **Endpoint:** `PUT/PATCH /api/v1/auth/profile/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

#### 6. Change Password
- **Endpoint:** `POST /api/v1/auth/change-password/`
- **Response:**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## Categories APIs

### Base Path: `/api/v1/categories/`

#### 1. List Categories
- **Endpoint:** `GET /api/v1/categories/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid",
        "name": "Electronics",
        "description": "Electronic items",
        "is_active": true,
        "created_at": "2024-01-01T10:00:00Z",
        "updated_at": "2024-01-01T10:00:00Z",
        "created_by": "admin@example.com"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 50,
      "total_pages": 3,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Category
- **Endpoint:** `POST /api/v1/categories/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Category created successfully",
  "data": {
    "id": "uuid",
    "name": "Electronics",
    "description": "Electronic items",
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z"
  }
}
```

#### 3. Get Category Details
- **Endpoint:** `GET /api/v1/categories/{category_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Electronics",
    "description": "Electronic items",
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T10:00:00Z",
    "created_by": "admin@example.com"
  }
}
```

#### 4. Update Category
- **Endpoint:** `PUT/PATCH /api/v1/categories/{category_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Category updated successfully",
  "data": {
    "id": "uuid",
    "name": "Electronics Updated",
    "description": "Updated description"
  }
}
```

#### 5. Delete Category (Hard)
- **Endpoint:** `DELETE /api/v1/categories/{category_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Category deleted successfully"
}
```

#### 6. Soft Delete Category
- **Endpoint:** `POST /api/v1/categories/{category_id}/soft-delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Category soft deleted successfully"
}
```

#### 7. Restore Category
- **Endpoint:** `POST /api/v1/categories/{category_id}/restore/`
- **Response:**
```json
{
  "success": true,
  "message": "Category restored successfully"
}
```

---

## Products APIs

### Base Path: `/api/v1/products/`

#### 1. List Products
- **Endpoint:** `GET /api/v1/products/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": "uuid",
        "name": "Laptop",
        "detail": "Dell Laptop",
        "price": 50000.00,
        "cost_price": 45000.00,
        "quantity": 10,
        "category_id": "uuid",
        "category_name": "Electronics",
        "stock_status": "IN_STOCK",
        "stock_status_display": "In Stock",
        "total_value": 500000.00,
        "is_active": true,
        "created_at": "2024-01-01T10:00:00Z",
        "updated_at": "2024-01-01T10:00:00Z",
        "created_by": "admin",
        "created_by_id": 1,
        "created_by_email": "admin@example.com"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "search": "",
      "category": null,
      "stock_status": null,
      "min_price": null,
      "max_price": null
    }
  }
}
```

#### 2. Create Product
- **Endpoint:** `POST /api/v1/products/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "id": "uuid",
    "name": "Laptop",
    "detail": "Dell Laptop",
    "price": 50000.00,
    "cost_price": 45000.00,
    "quantity": 10,
    "category_id": "uuid",
    "category_name": "Electronics"
  }
}
```

#### 3. Get Product Details
- **Endpoint:** `GET /api/v1/products/{product_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Laptop",
    "detail": "Dell Laptop",
    "price": 50000.00,
    "cost_price": 45000.00,
    "quantity": 10,
    "category_id": "uuid",
    "category_name": "Electronics",
    "stock_status": "IN_STOCK",
    "total_value": 500000.00,
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z"
  }
}
```

#### 4. Update Product
- **Endpoint:** `PUT/PATCH /api/v1/products/{product_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Product updated successfully",
  "data": {
    "id": "uuid",
    "name": "Laptop Updated",
    "price": 52000.00
  }
}
```

#### 5. Delete Product
- **Endpoint:** `DELETE /api/v1/products/{product_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Product deleted successfully"
}
```

---

## Customers APIs

### Base Path: `/api/v1/customers/`

#### 1. List Customers
- **Endpoint:** `GET /api/v1/customers/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": "uuid",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+923001234567",
        "address": "123 Main St",
        "city": "Rawalpindi",
        "country": "Pakistan",
        "customer_type": "WHOLESALE",
        "status": "ACTIVE",
        "is_verified": true,
        "last_order_date": "2024-01-15",
        "total_orders": 5,
        "total_spent": 250000.00,
        "is_active": true,
        "created_at": "2024-01-01T10:00:00Z",
        "updated_at": "2024-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 150,
      "total_pages": 8,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "search": "",
      "customer_type": null,
      "status": null,
      "city": null
    }
  }
}
```

#### 2. Create Customer
- **Endpoint:** `POST /api/v1/customers/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+923001234567",
    "customer_type": "WHOLESALE"
  }
}
```

#### 3. Get Customer Details
- **Endpoint:** `GET /api/v1/customers/{customer_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+923001234567",
    "address": "123 Main St",
    "city": "Rawalpindi",
    "country": "Pakistan",
    "customer_type": "WHOLESALE",
    "status": "ACTIVE",
    "total_orders": 5,
    "total_spent": 250000.00
  }
}
```

#### 4. Update Customer
- **Endpoint:** `PUT/PATCH /api/v1/customers/{customer_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Customer updated successfully",
  "data": {
    "id": "uuid",
    "name": "John Doe Updated",
    "phone": "+923009999999"
  }
}
```

#### 5. Delete Customer
- **Endpoint:** `DELETE /api/v1/customers/{customer_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Customer 'John Doe' deleted successfully"
}
```

#### 6. Customer Statistics
- **Endpoint:** `GET /api/v1/customers/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_customers": 150,
    "active_customers": 120,
    "inactive_customers": 30,
    "wholesale_customers": 80,
    "retail_customers": 70,
    "verified_customers": 100,
    "new_this_month": 15
  }
}
```

---

## Vendors APIs

### Base Path: `/api/v1/vendors/`

#### 1. List Vendors
- **Endpoint:** `GET /api/v1/vendors/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "vendors": [
      {
        "id": "uuid",
        "name": "ABC Suppliers",
        "business_name": "ABC Trading Co.",
        "phone": "+923001234567",
        "email": "abc@example.com",
        "address": "456 Market St",
        "city": "Rawalpindi",
        "area": "Saddar",
        "is_active": true,
        "created_at": "2024-01-01T10:00:00Z",
        "updated_at": "2024-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 80,
      "total_pages": 4,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "search": "",
      "city": null,
      "area": null
    }
  }
}
```

#### 2. Create Vendor
- **Endpoint:** `POST /api/v1/vendors/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Vendor created successfully",
  "data": {
    "id": "uuid",
    "name": "ABC Suppliers",
    "business_name": "ABC Trading Co.",
    "phone": "+923001234567",
    "city": "Rawalpindi"
  }
}
```

#### 3. Get Vendor Details
- **Endpoint:** `GET /api/v1/vendors/{vendor_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "ABC Suppliers",
    "business_name": "ABC Trading Co.",
    "phone": "+923001234567",
    "email": "abc@example.com",
    "address": "456 Market St",
    "city": "Rawalpindi",
    "area": "Saddar",
    "is_active": true
  }
}
```

#### 4. Update Vendor
- **Endpoint:** `PUT/PATCH /api/v1/vendors/{vendor_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Vendor updated successfully",
  "data": {
    "id": "uuid",
    "name": "ABC Suppliers Updated"
  }
}
```

#### 5. Delete Vendor
- **Endpoint:** `DELETE /api/v1/vendors/{vendor_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Vendor deleted successfully"
}
```

#### 6. Vendor Statistics
- **Endpoint:** `GET /api/v1/vendors/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_vendors": 80,
    "active_vendors": 70,
    "inactive_vendors": 10,
    "new_this_month": 5,
    "cities_count": 10,
    "areas_count": 25
  }
}
```

#### 7. Vendor Transactions
- **Endpoint:** `GET /api/v1/vendors/{vendor_id}/transactions/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "vendor_id": "uuid",
    "vendor_name": "ABC Suppliers",
    "transactions": [
      {
        "id": "uuid",
        "amount_paid": 50000.00,
        "date": "2024-01-15",
        "payment_method": "BANK_TRANSFER",
        "description": "Payment for order #123"
      }
    ],
    "summary": {
      "totalTransactions": 10,
      "totalAmount": 500000.00,
      "pendingAmount": 50000.00,
      "paidAmount": 450000.00,
      "lastTransactionDate": "2024-01-15"
    },
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 10,
      "total_pages": 1
    }
  }
}
```

#### 8. Search Vendors
- **Endpoint:** `GET /api/v1/vendors/search/?q=ABC`
- **Response:**
```json
{
  "success": true,
  "data": {
    "vendors": [...],
    "pagination": {...},
    "search_query": "ABC"
  }
}
```

#### 9. Vendors by City
- **Endpoint:** `GET /api/v1/vendors/city/{city_name}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "vendors": [...],
    "pagination": {...},
    "city": "Rawalpindi",
    "total_vendors_in_city": 25
  }
}
```

---

## Labors APIs

### Base Path: `/api/v1/labors/`

#### 1. List Labors
- **Endpoint:** `GET /api/v1/labors/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "labors": [
      {
        "id": "uuid",
        "name": "Ali Khan",
        "phone_number": "+923001234567",
        "designation": "Carpenter",
        "salary": 30000.00,
        "age": 30,
        "gender": "MALE",
        "caste": "Punjabi",
        "city": "Rawalpindi",
        "area": "Saddar",
        "joining_date": "2024-01-01",
        "work_experience_days": 365,
        "work_experience_years": 1.0,
        "is_active": true,
        "created_at": "2024-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 50,
      "total_pages": 3,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "search": "",
      "designation": null,
      "city": null,
      "min_salary": null,
      "max_salary": null
    }
  }
}
```

#### 2. Create Labor
- **Endpoint:** `POST /api/v1/labors/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Labor created successfully",
  "data": {
    "id": "uuid",
    "name": "Ali Khan",
    "phone_number": "+923001234567",
    "designation": "Carpenter",
    "salary": 30000.00
  }
}
```

#### 3. Get Labor Details
- **Endpoint:** `GET /api/v1/labors/{labor_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Ali Khan",
    "phone_number": "+923001234567",
    "designation": "Carpenter",
    "salary": 30000.00,
    "age": 30,
    "gender": "MALE",
    "city": "Rawalpindi",
    "joining_date": "2024-01-01",
    "advance_payments_count": 5,
    "total_advance_amount": 15000.00,
    "remaining_monthly_salary": 15000.00
  }
}
```

#### 4. Update Labor
- **Endpoint:** `PUT/PATCH /api/v1/labors/{labor_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Labor updated successfully",
  "data": {
    "id": "uuid",
    "name": "Ali Khan Updated",
    "salary": 32000.00
  }
}
```

#### 5. Delete Labor
- **Endpoint:** `DELETE /api/v1/labors/{labor_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Labor deleted successfully"
}
```

#### 6. Labor Statistics
- **Endpoint:** `GET /api/v1/labors/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_labors": 50,
    "active_labors": 45,
    "inactive_labors": 5,
    "total_monthly_salary": 1500000.00,
    "average_salary": 30000.00,
    "designations_count": 10,
    "cities_count": 8
  }
}
```

---

## Advance Payments APIs

### Base Path: `/api/v1/advance-payments/`

#### 1. List Advance Payments
- **Endpoint:** `GET /api/v1/advance-payments/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "advance_payments": [
      {
        "id": "uuid",
        "labor_name": "Ali Khan",
        "labor_phone": "+923001234567",
        "labor_role": "Carpenter",
        "amount": 5000.00,
        "formatted_amount": "5,000.00 PKR",
        "description": "Advance for month",
        "date": "2024-01-15",
        "time": "10:30:00",
        "receipt_image_path": "/media/receipts/receipt.jpg",
        "remaining_salary": 25000.00,
        "total_salary": 30000.00,
        "advance_percentage": 16.67,
        "is_recent": true,
        "is_today": false,
        "has_receipt": true,
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "search": "",
      "labor_name": null,
      "date_from": null,
      "date_to": null,
      "has_receipt": null
    }
  }
}
```

#### 2. Create Advance Payment
- **Endpoint:** `POST /api/v1/advance-payments/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Advance payment created successfully",
  "data": {
    "id": "uuid",
    "labor_name": "Ali Khan",
    "amount": 5000.00,
    "date": "2024-01-15",
    "remaining_salary": 25000.00
  }
}
```

#### 3. Get Advance Payment Details
- **Endpoint:** `GET /api/v1/advance-payments/{payment_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "labor_id": "uuid",
    "labor_name": "Ali Khan",
    "labor_phone": "+923001234567",
    "labor_role": "Carpenter",
    "amount": 5000.00,
    "description": "Advance for month",
    "date": "2024-01-15",
    "time": "10:30:00",
    "labor_details": {
      "id": "uuid",
      "name": "Ali Khan",
      "designation": "Carpenter",
      "current_salary": 30000.00
    }
  }
}
```

#### 4. Update Advance Payment
- **Endpoint:** `PUT/PATCH /api/v1/advance-payments/{payment_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Advance payment updated successfully",
  "data": {
    "id": "uuid",
    "amount": 6000.00,
    "description": "Updated description"
  }
}
```

#### 5. Delete Advance Payment
- **Endpoint:** `DELETE /api/v1/advance-payments/{payment_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Advance payment deleted successfully"
}
```

#### 6. Advance Payment Statistics
- **Endpoint:** `GET /api/v1/advance-payments/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_payments": 100,
    "total_amount": 500000.00,
    "today_payments": 5,
    "today_amount": 25000.00,
    "this_month_payments": 30,
    "this_month_amount": 150000.00,
    "amount_statistics": {
      "min_amount": 1000.00,
      "max_amount": 10000.00,
      "avg_amount": 5000.00
    },
    "top_labor_recipients": [
      {
        "labor_name": "Ali Khan",
        "total_advances": 25000.00,
        "payment_count": 5
      }
    ],
    "payments_with_receipts": 80,
    "payments_without_receipts": 20
  }
}
```

#### 7. Today's Payments
- **Endpoint:** `GET /api/v1/advance-payments/today/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "advance_payments": [...],
    "pagination": {...},
    "date": "2024-01-21",
    "summary": {
      "count": 5,
      "total_amount": 25000.00
    }
  }
}
```

#### 8. Recent Payments
- **Endpoint:** `GET /api/v1/advance-payments/recent/?days=7`
- **Response:**
```json
{
  "success": true,
  "data": {
    "advance_payments": [...],
    "pagination": {...},
    "days": 7,
    "description": "Advance payments from last 7 days"
  }
}
```

---

## Orders APIs

### Base Path: `/api/v1/orders/`

#### 1. List Orders
- **Endpoint:** `GET /api/v1/orders/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": "uuid",
        "order_number": "ORD-2024-001",
        "customer_id": "uuid",
        "customer_name": "John Doe",
        "customer_phone": "+923001234567",
        "date_ordered": "2024-01-15",
        "expected_delivery_date": "2024-01-20",
        "actual_delivery_date": null,
        "status": "PENDING",
        "status_display": "Pending",
        "payment_status": "UNPAID",
        "total_amount": 100000.00,
        "advance_payment": 20000.00,
        "remaining_amount": 80000.00,
        "is_fully_paid": false,
        "is_overdue": false,
        "days_until_delivery": 5,
        "items_count": 3,
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 200,
      "total_pages": 10,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {
      "status": null,
      "payment_status": null,
      "date_from": null,
      "date_to": null
    }
  }
}
```

#### 2. Create Order
- **Endpoint:** `POST /api/v1/orders/create/`
- **Request Body:**
```json
{
  "customer": "uuid",
  "date_ordered": "2024-01-15",
  "expected_delivery_date": "2024-01-20",
  "status": "PENDING",
  "advance_payment": 20000.00,
  "items": [
    {
      "product": "uuid",
      "quantity": 5,
      "unit_price": 10000.00
    }
  ]
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": "uuid",
    "order_number": "ORD-2024-001",
    "customer_name": "John Doe",
    "total_amount": 100000.00,
    "status": "PENDING"
  }
}
```

#### 3. Get Order Details
- **Endpoint:** `GET /api/v1/orders/{order_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "order_number": "ORD-2024-001",
    "customer": {
      "id": "uuid",
      "name": "John Doe",
      "phone": "+923001234567"
    },
    "date_ordered": "2024-01-15",
    "expected_delivery_date": "2024-01-20",
    "status": "PENDING",
    "total_amount": 100000.00,
    "advance_payment": 20000.00,
    "remaining_amount": 80000.00,
    "items": [
      {
        "id": "uuid",
        "product_name": "Laptop",
        "quantity": 5,
        "unit_price": 10000.00,
        "subtotal": 50000.00
      }
    ]
  }
}
```

#### 4. Update Order
- **Endpoint:** `PUT/PATCH /api/v1/orders/{order_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Order updated successfully",
  "data": {
    "id": "uuid",
    "status": "CONFIRMED",
    "total_amount": 105000.00
  }
}
```

#### 5. Delete Order
- **Endpoint:** `DELETE /api/v1/orders/{order_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Order deleted successfully"
}
```

#### 6. Order Statistics
- **Endpoint:** `GET /api/v1/orders/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_orders": 200,
    "pending_orders": 50,
    "confirmed_orders": 100,
    "delivered_orders": 40,
    "cancelled_orders": 10,
    "total_revenue": 10000000.00,
    "pending_revenue": 2000000.00,
    "overdue_orders": 5
  }
}
```

---

## Sales APIs

### Base Path: `/api/v1/sales/`

#### 1. List Sales
- **Endpoint:** `GET /api/v1/sales/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "sales": [
      {
        "id": "uuid",
        "sale_number": "SALE-2024-001",
        "customer_id": "uuid",
        "customer_name": "John Doe",
        "date_of_sale": "2024-01-15",
        "total_amount": 50000.00,
        "discount": 5000.00,
        "tax": 2250.00,
        "grand_total": 47250.00,
        "payment_method": "CASH",
        "payment_status": "PAID",
        "status": "COMPLETED",
        "items_count": 3,
        "is_active": true,
        "created_at": "2024-01-15T14:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 500,
      "total_pages": 25,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Sale
- **Endpoint:** `POST /api/v1/sales/create/`
- **Request Body:**
```json
{
  "customer": "uuid",  // Optional for wholesale
  "date_of_sale": "2024-01-15",
  "payment_method": "CASH",
  "discount": 5000.00,
  "tax": 2250.00,
  "sale_items": [
    {
      "product": "uuid",
      "quantity": 2,
      "unit_price": 25000.00
    }
  ]
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Sale created successfully",
  "data": {
    "id": "uuid",
    "sale_number": "SALE-2024-001",
    "grand_total": 47250.00,
    "payment_status": "PAID"
  }
}
```

#### 3. Get Sale Details
- **Endpoint:** `GET /api/v1/sales/{sale_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "sale_number": "SALE-2024-001",
    "customer": {
      "id": "uuid",
      "name": "John Doe",
      "phone": "+923001234567"
    },
    "date_of_sale": "2024-01-15",
    "total_amount": 50000.00,
    "discount": 5000.00,
    "tax": 2250.00,
    "grand_total": 47250.00,
    "payment_method": "CASH",
    "sale_items": [
      {
        "id": "uuid",
        "product_name": "Product A",
        "quantity": 2,
        "unit_price": 25000.00,
        "subtotal": 50000.00
      }
    ]
  }
}
```

#### 4. Update Sale
- **Endpoint:** `PUT/PATCH /api/v1/sales/{sale_id}/update/`
- **Response:**
```json
{
  "success": true,
  "message": "Sale updated successfully",
  "data": {
    "id": "uuid",
    "grand_total": 48000.00
  }
}
```

#### 5. Delete Sale
- **Endpoint:** `DELETE /api/v1/sales/{sale_id}/delete/`
- **Response:**
```json
{
  "success": true,
  "message": "Sale deleted successfully"
}
```

#### 6. Sales Statistics
- **Endpoint:** `GET /api/v1/sales/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_sales": 500,
    "total_revenue": 25000000.00,
    "today_sales": 10,
    "today_revenue": 500000.00,
    "this_month_sales": 150,
    "this_month_revenue": 7500000.00,
    "average_sale_value": 50000.00,
    "payment_methods_breakdown": {
      "CASH": 300,
      "BANK_TRANSFER": 150,
      "CHEQUE": 50
    }
  }
}
```

---

## Payments APIs

### Base Path: `/api/v1/payments/`

#### 1. List Payments
- **Endpoint:** `GET /api/v1/payments/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "payments": [
      {
        "id": "uuid",
        "payer_type": "VENDOR",
        "payer_name": "ABC Suppliers",
        "amount_paid": 50000.00,
        "payment_method": "BANK_TRANSFER",
        "date": "2024-01-15",
        "description": "Payment for materials",
        "receipt_image_path": "/media/receipts/receipt.jpg",
        "is_final_payment": false,
        "has_receipt": true,
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 300,
      "total_pages": 15,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Payment
- **Endpoint:** `POST /api/v1/payments/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Payment created successfully",
  "data": {
    "id": "uuid",
    "payer_type": "VENDOR",
    "amount_paid": 50000.00,
    "payment_method": "BANK_TRANSFER",
    "date": "2024-01-15"
  }
}
```

#### 3. Get Payment Details
- **Endpoint:** `GET /api/v1/payments/{payment_id}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "payer_type": "VENDOR",
    "vendor_details": {
      "id": "uuid",
      "name": "ABC Suppliers",
      "phone": "+923001234567"
    },
    "amount_paid": 50000.00,
    "payment_method": "BANK_TRANSFER",
    "date": "2024-01-15",
    "description": "Payment for materials"
  }
}
```

#### 4. Payment Statistics
- **Endpoint:** `GET /api/v1/payments/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_payments": 300,
    "total_amount": 15000000.00,
    "vendor_payments": 200,
    "vendor_payments_amount": 10000000.00,
    "labor_payments": 100,
    "labor_payments_amount": 5000000.00,
    "this_month_payments": 50,
    "this_month_amount": 2500000.00
  }
}
```

---

## Payables APIs

### Base Path: `/api/v1/payables/`

#### 1. List Payables
- **Endpoint:** `GET /api/v1/payables/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "payables": [
      {
        "id": "uuid",
        "creditor_name": "ABC Suppliers",
        "vendor_id": "uuid",
        "amount_due": 100000.00,
        "amount_paid": 50000.00,
        "remaining_balance": 50000.00,
        "due_date": "2024-02-15",
        "status": "PARTIAL",
        "is_overdue": false,
        "days_until_due": 25,
        "priority": "MEDIUM",
        "description": "Materials purchase",
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Payable
- **Endpoint:** `POST /api/v1/payables/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Payable created successfully",
  "data": {
    "id": "uuid",
    "creditor_name": "ABC Suppliers",
    "amount_due": 100000.00,
    "due_date": "2024-02-15"
  }
}
```

#### 3. Add Payment to Payable
- **Endpoint:** `POST /api/v1/payables/{payable_id}/payment/`
- **Response:**
```json
{
  "success": true,
  "message": "Payment added successfully",
  "data": {
    "payable_id": "uuid",
    "amount_paid": 50000.00,
    "remaining_balance": 50000.00,
    "status": "PARTIAL"
  }
}
```

#### 4. Payable Statistics
- **Endpoint:** `GET /api/v1/payables/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_payables": 100,
    "total_due": 5000000.00,
    "total_paid": 2000000.00,
    "total_remaining": 3000000.00,
    "overdue_payables": 10,
    "overdue_amount": 500000.00,
    "due_soon_payables": 15,
    "due_soon_amount": 750000.00
  }
}
```

#### 5. Overdue Payables
- **Endpoint:** `GET /api/v1/payables/overdue/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "payables": [...],
    "pagination": {...},
    "total_overdue_amount": 500000.00
  }
}
```

---

## Receivables APIs

### Base Path: `/api/v1/receivables/`

#### 1. List Receivables
- **Endpoint:** `GET /api/v1/receivables/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "receivables": [
      {
        "id": "uuid",
        "debtor_name": "John Doe",
        "customer_id": "uuid",
        "amount_due": 75000.00,
        "amount_received": 25000.00,
        "remaining_balance": 50000.00,
        "due_date": "2024-02-20",
        "status": "PARTIAL",
        "is_overdue": false,
        "days_until_due": 30,
        "description": "Order payment",
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 150,
      "total_pages": 8,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Receivable
- **Endpoint:** `POST /api/v1/receivables/create/`
- **Response:**
```json
{
  "success": true,
  "message": "Receivable created successfully",
  "data": {
    "id": "uuid",
    "debtor_name": "John Doe",
    "amount_due": 75000.00,
    "due_date": "2024-02-20"
  }
}
```

#### 3. Record Payment for Receivable
- **Endpoint:** `POST /api/v1/receivables/{receivable_id}/record-payment/`
- **Response:**
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": {
    "receivable_id": "uuid",
    "amount_received": 25000.00,
    "remaining_balance": 50000.00,
    "status": "PARTIAL"
  }
}
```

#### 4. Receivables Summary
- **Endpoint:** `GET /api/v1/receivables/summary/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_receivables": 150,
    "total_due": 7500000.00,
    "total_received": 3000000.00,
    "total_remaining": 4500000.00,
    "overdue_receivables": 20,
    "overdue_amount": 1000000.00
  }
}
```

---

## Expenses APIs

### Base Path: `/api/v1/expenses/`

#### 1. List Expenses
- **Endpoint:** `GET /api/v1/expenses/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "expenses": [
      {
        "id": "uuid",
        "authority": "Transport",
        "category": "OPERATIONAL",
        "amount": 15000.00,
        "date": "2024-01-15",
        "description": "Delivery charges",
        "receipt_image_path": "/media/receipts/expense.jpg",
        "has_receipt": true,
        "is_recurring": false,
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 200,
      "total_pages": 10,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Expense
- **Endpoint:** `POST /api/v1/expenses/`
- **Response:**
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": "uuid",
    "authority": "Transport",
    "category": "OPERATIONAL",
    "amount": 15000.00,
    "date": "2024-01-15"
  }
}
```

#### 3. Expense Statistics
- **Endpoint:** `GET /api/v1/expenses/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_expenses": 200,
    "total_amount": 3000000.00,
    "today_expenses": 5,
    "today_amount": 75000.00,
    "this_month_expenses": 50,
    "this_month_amount": 750000.00,
    "category_breakdown": {
      "OPERATIONAL": 1500000.00,
      "ADMINISTRATIVE": 800000.00,
      "MAINTENANCE": 700000.00
    }
  }
}
```

#### 4. Monthly Summary
- **Endpoint:** `GET /api/v1/expenses/monthly-summary/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "month": "January 2024",
    "total_expenses": 50,
    "total_amount": 750000.00,
    "daily_breakdown": [
      {
        "date": "2024-01-01",
        "count": 3,
        "amount": 45000.00
      }
    ]
  }
}
```

---

## Zakats APIs

### Base Path: `/api/v1/zakats/`

#### 1. List Zakats
- **Endpoint:** `GET /api/v1/zakats/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "zakats": [
      {
        "id": "uuid",
        "beneficiary_name": "Masjid",
        "authority": "Islamic Center",
        "amount": 50000.00,
        "date": "2024-01-15",
        "description": "Monthly zakat",
        "receipt_image_path": "/media/receipts/zakat.jpg",
        "has_receipt": true,
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 50,
      "total_pages": 3,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Create Zakat
- **Endpoint:** `POST /api/v1/zakats/`
- **Response:**
```json
{
  "success": true,
  "message": "Zakat created successfully",
  "data": {
    "id": "uuid",
    "beneficiary_name": "Masjid",
    "amount": 50000.00,
    "date": "2024-01-15"
  }
}
```

#### 3. Zakat Statistics
- **Endpoint:** `GET /api/v1/zakats/statistics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "total_zakats": 50,
    "total_amount": 2500000.00,
    "this_month_zakats": 5,
    "this_month_amount": 250000.00,
    "this_year_zakats": 50,
    "this_year_amount": 2500000.00,
    "top_beneficiaries": [
      {
        "beneficiary_name": "Masjid",
        "count": 12,
        "total_amount": 600000.00
      }
    ]
  }
}
```

---

## Profit & Loss APIs

### Base Path: `/api/v1/profit-loss/`

#### 1. Calculate P&L
- **Endpoint:** `POST /api/v1/profit-loss/calculate/`
- **Request Body:**
```json
{
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "period_type": "MONTHLY",
  "include_calculations": true
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Profit and loss calculated successfully",
  "data": {
    "id": "uuid",
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "period_type": "MONTHLY",
    "period_display": "January 2024",
    "total_sales_income": 10000000.00,
    "cost_of_goods_sold": 6000000.00,
    "gross_profit": 4000000.00,
    "gross_profit_margin": 40.00,
    "labor_payments": 500000.00,
    "vendor_payments": 1500000.00,
    "other_expenses": 300000.00,
    "zakat": 100000.00,
    "total_expenses": 2400000.00,
    "net_profit": 1600000.00,
    "net_profit_margin": 16.00,
    "profitability_status": "PROFITABLE",
    "profitability_status_display": "Profitable",
    "sales_count": 150,
    "labor_payments_count": 50,
    "vendor_payments_count": 30,
    "expenses_count": 20,
    "zakat_count": 5
  }
}
```

#### 2. Get P&L Summary
- **Endpoint:** `GET /api/v1/profit-loss/summary/?period_type=CURRENT_MONTH`
- **Response:**
```json
{
  "success": true,
  "data": {
    "period": "Current Month",
    "gross_profit": 4000000.00,
    "net_profit": 1600000.00,
    "gross_profit_margin": 40.00,
    "net_profit_margin": 16.00,
    "total_sales": 10000000.00,
    "total_expenses": 2400000.00
  }
}
```

#### 3. Product Profitability
- **Endpoint:** `GET /api/v1/profit-loss/product-profitability/?start_date=2024-01-01&end_date=2024-01-31`
- **Response:**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "product_id": "uuid",
        "product_name": "Laptop",
        "total_revenue": 2500000.00,
        "total_cost": 1800000.00,
        "gross_profit": 700000.00,
        "profit_margin": 28.00,
        "units_sold": 50
      }
    ],
    "period": {
      "start_date": "2024-01-01",
      "end_date": "2024-01-31"
    }
  }
}
```

---

## Analytics/Dashboard APIs

### Base Path: `/api/v1/analytics/`

#### 1. Dashboard Analytics
- **Endpoint:** `GET /api/v1/analytics/dashboard/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "revenue_metrics": {
      "total_revenue": 25000000.00,
      "this_month_revenue": 7500000.00,
      "last_month_revenue": 6500000.00,
      "revenue_growth": 15.38
    },
    "sales_metrics": {
      "total_sales": 500,
      "this_month_sales": 150,
      "today_sales": 10,
      "this_month_sales_count": 150,
      "recent_sales_count": 35
    },
    "order_metrics": {
      "total_orders": 300,
      "pending_orders": 50,
      "recent_orders_count": 20
    },
    "customer_metrics": {
      "total_customers": 250,
      "active_customers": 180
    },
    "vendor_metrics": {
      "total_vendors": 80,
      "active_vendors": 65
    },
    "product_metrics": {
      "total_products": 500,
      "low_stock_products": 25,
      "out_of_stock_products": 5
    },
    "labor_metrics": {
      "total_labors": 50,
      "active_labors": 45
    },
    "payment_metrics": {
      "total_payments": 300,
      "vendor_payments": 200,
      "labor_payments": 100
    },
    "expense_metrics": {
      "total_expenses": 3000000.00,
      "this_month_expenses": 750000.00
    },
    "profit_metrics": {
      "gross_profit": 10000000.00,
      "net_profit": 6000000.00,
      "profit_margin": 24.00
    }
  }
}
```

#### 2. Business Metrics
- **Endpoint:** `GET /api/v1/analytics/business-metrics/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "key_metrics": {
      "total_revenue": 25000000.00,
      "total_orders": 300,
      "average_order_value": 83333.33,
      "customer_acquisition_rate": 15.5,
      "inventory_turnover": 4.2
    },
    "trends": {
      "revenue_trend": "increasing",
      "order_trend": "stable",
      "customer_trend": "increasing"
    }
  }
}
```

---

## Purchases APIs

### Base Path: `/api/v1/purchases/`

#### 1. List Purchases
- **Endpoint:** `GET /api/v1/purchases/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "purchases": [
      {
        "id": "uuid",
        "vendor_id": "uuid",
        "vendor_name": "ABC Suppliers",
        "product_id": "uuid",
        "product_name": "Raw Material",
        "quantity": 100,
        "unit_price": 500.00,
        "total_amount": 50000.00,
        "purchase_date": "2024-01-15",
        "is_active": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "page_size": 20,
      "total_count": 200,
      "total_pages": 10,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### 2. Get Purchase Details
- **Endpoint:** `GET /api/v1/purchases/{pk}/`
- **Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "vendor": {
      "id": "uuid",
      "name": "ABC Suppliers",
      "phone": "+923001234567"
    },
    "product": {
      "id": "uuid",
      "name": "Raw Material"
    },
    "quantity": 100,
    "unit_price": 500.00,
    "total_amount": 50000.00,
    "purchase_date": "2024-01-15"
  }
}
```

---

## Common Response Patterns

### Success Response Structure
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response Structure
```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field_name": "Error details"
  }
}
```

### Pagination Structure
```json
{
  "pagination": {
    "current_page": 1,
    "page_size": 20,
    "total_count": 100,
    "total_pages": 5,
    "has_next": true,
    "has_previous": false
  }
}
```

---

## HTTP Status Codes Used

- `200 OK` - Successful GET, PUT, PATCH requests
- `201 Created` - Successful POST requests (resource created)
- `204 No Content` - Successful DELETE requests
- `400 Bad Request` - Validation errors, invalid data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server errors

---

## Authentication

All API endpoints (except login/register) require authentication using Token-based authentication:

**Header:**
```
Authorization: Token abc123token...
```

---

## Notes

1. **UUIDs**: All entity IDs are UUIDs (not integers)
2. **Dates**: Date format is `YYYY-MM-DD`
3. **DateTimes**: DateTime format is ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)
4. **Decimals**: All monetary values are returned as numbers with 2 decimal places
5. **Pagination**: Default page size is 20, maximum is 100
6. **Filtering**: Most list endpoints support query parameters for filtering
7. **Sorting**: Most list endpoints support `sort_by` and `sort_order` parameters
8. **Search**: Most list endpoints support `search` or `q` parameter for full-text search

---

## Common Query Parameters

- `page` - Page number (default: 1)
- `page_size` - Items per page (default: 20, max: 100)
- `search` or `q` - Search query
- `sort_by` - Field to sort by
- `sort_order` - `asc` or `desc` (default: `desc`)
- `date_from` - Filter by date range start
- `date_to` - Filter by date range end
- `is_active` - Filter by active status

---

This documentation covers all major API endpoints in your Django POS system. Each endpoint follows consistent patterns for requests and responses, making it easier to integrate with your Flutter frontend.