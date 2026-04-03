# Sales App

## Overview
The Sales app manages complete sales transactions including invoice generation, customer billing, payment processing, and order fulfillment.

## Features
- **Complete Sales Management**: From draft to delivery
- **Order Conversion**: Convert existing orders to sales
- **Payment Tracking**: Multiple payment methods including split payments
- **Tax Calculations**: Pakistani GST (17% default) with configurable rates
- **Invoice Generation**: Automatic sequential numbering
- **Inventory Integration**: Real-time stock updates
- **Customer Analytics**: Sales history and performance tracking

## Models
- **Sales**: Main sales transaction model
- **SaleItem**: Individual line items within sales

## API Endpoints
- `/api/v1/sales/` - Sales management
- `/api/v1/sale-items/` - Sale items management
- `/api/v1/sales/create-from-order/` - Convert orders to sales

## Key Workflows
1. **Direct Sale Creation**: Create sales for walk-in customers
2. **Order Conversion**: Convert completed orders to sales
3. **Payment Processing**: Handle various payment methods
4. **Status Management**: Track sale lifecycle

## Integration
- Seamlessly integrates with existing Customer, Product, Order, and OrderItem systems
- Enhances customer analytics with sales performance data
- Provides product sales metrics and inventory tracking
- Supports order-to-sale conversion workflow
