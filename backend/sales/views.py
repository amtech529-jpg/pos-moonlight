from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, Sum, Count
from django.http import HttpResponse
from decimal import Decimal
from .models import Sales, SaleItem
from .serializers import (
    SalesSerializer, SalesCreateSerializer, SalesUpdateSerializer, SalesListSerializer,
    SaleItemSerializer, SaleItemCreateSerializer, SaleItemUpdateSerializer, SaleItemListSerializer,
    SalesPaymentSerializer, SalesStatusUpdateSerializer, SalesBulkActionSerializer,
    SalesStatisticsSerializer, OrderToSaleConversionSerializer
)
from customers.models import Customer
from products.models import Product
from orders.models import Order
from order_items.models import OrderItem
from .models import Invoice, Receipt
from payments.models import Payment
from .serializers import (
    InvoiceCreateSerializer, InvoiceSerializer, InvoiceUpdateSerializer, InvoiceListSerializer,
    ReceiptCreateSerializer, ReceiptSerializer, ReceiptUpdateSerializer, ReceiptListSerializer,
    TaxRateSerializer
)
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)


# Function-based views for Sales

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_sales(request):
    """List all sales with filtering, search, and pagination"""
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))

        # Search and filter parameters
        search = request.GET.get('search', '').strip()
        status_filter = request.GET.get('status', '').strip()
        customer_id = request.GET.get('customer_id', '').strip()
        payment_method = request.GET.get('payment_method', '').strip()
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()

        # Base queryset
        if show_inactive:
            sales = Sales.objects.all()
        else:
            sales = Sales.objects.active()

        # Apply filters
        if search:
            sales = sales.search(search)

        if status_filter:
            sales = sales.by_status(status_filter)

        if customer_id:
            sales = sales.by_customer(customer_id)

        if payment_method:
            sales = sales.by_payment_method(payment_method)

        if date_from and date_to:
            sales = sales.by_date_range(date_from, date_to)

        # Pagination
        start = (page - 1) * page_size
        end = start + page_size
        total_count = sales.count()

        sales_page = sales[start:end]
        serializer = SalesListSerializer(sales_page, many=True)

        return Response({
            'success': True,
            'data': serializer.data,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to list sales.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_sale(request):
    """Create a new sale"""
    logger.info(f"📥 Received sale creation request from user: {request.user}")
    logger.info(f"📦 Request data: {request.data}")

    # ✅ Pass request in context
    serializer = SalesCreateSerializer(data=request.data, context={'request': request})

    if serializer.is_valid():
        logger.info(f"✅ Serializer validation passed")
        logger.info(f"📋 Validated data: {serializer.validated_data}")

        try:
            with transaction.atomic():
                logger.info(f"🔄 Starting transaction for sale creation")
                # ✅ Don't pass created_by here - serializer gets it from context
                sale = serializer.save()
                logger.info(f"✅ Sale created with ID: {sale.id}")

                return Response({
                    'success': True,
                    'message': 'Sale created successfully.',
                    'data': SalesSerializer(sale).data
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.error(f"❌ Error creating sale: {str(e)}", exc_info=True)
            return Response({
                'success': False,
                'message': 'Failed to create sale.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    else:
        logger.error(f"❌ Serializer validation failed: {serializer.errors}")
        return Response({
            'success': False,
            'message': 'Sale creation failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_sale(request, sale_id):
    """Get sale details with items"""
    try:
        sale = Sales.objects.get(id=sale_id, is_active=True)
        serializer = SalesSerializer(sale)

        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)

    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve sale.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_sale(request, sale_id):
    """Update sale details"""
    try:
        sale = Sales.objects.get(id=sale_id, is_active=True)

        if request.method == 'PUT':
            serializer = SalesUpdateSerializer(sale, data=request.data)
        else:
            serializer = SalesUpdateSerializer(sale, data=request.data, partial=True)

        if serializer.is_valid():
            with transaction.atomic():
                updated_sale = serializer.save()

                return Response({
                    'success': True,
                    'message': 'Sale updated successfully.',
                    'data': SalesSerializer(updated_sale).data
                }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Sale update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update sale.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_sale(request, sale_id):
    """Soft delete sale"""
    try:
        sale = Sales.objects.get(id=sale_id, is_active=True)
        sale.is_active = False
        sale.save()

        return Response({
            'success': True,
            'message': 'Sale deleted successfully.'
        }, status=status.HTTP_200_OK)

    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete sale.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_payment(request, sale_id):
    """Record payment for a sale"""
    try:
        sale = Sales.objects.get(id=sale_id, is_active=True)
        serializer = SalesPaymentSerializer(data=request.data)

        if serializer.is_valid():
            payment_data = serializer.validated_data

            amount = payment_data.get('amount')
            method = payment_data['payment_method']

            with transaction.atomic():
                # Update payment details on Sales
                sale.payment_method = method
                if amount:
                    sale.amount_paid += amount

                if method == 'SPLIT':
                    sale.split_payment_details = payment_data.get('split_payment_details', {})

                sale.update_payment_status()
                sale.save()

                # ✅ CREATE PAYMENT RECORD
                if amount:
                    Payment.objects.create(
                        entity_id=str(sale.id),
                        entity_type='sale',
                        amount=amount,
                        payment_method=method,
                        created_by=request.user,
                        status='COMPLETED',
                        transaction_date=timezone.now()
                    )

                return Response({
                    'success': True,
                    'message': 'Payment recorded successfully.',
                    'data': SalesSerializer(sale).data
                }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Payment recording failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to record payment.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_status(request, sale_id):
    """Update sale status"""
    try:
        sale = Sales.objects.get(id=sale_id, is_active=True)
        serializer = SalesStatusUpdateSerializer(data=request.data)

        if serializer.is_valid():
            new_status = serializer.validated_data['status']

            with transaction.atomic():
                sale.status = new_status
                sale.save()

                return Response({
                    'success': True,
                    'message': f'Sale status updated to {new_status}.',
                    'data': SalesSerializer(sale).data
                }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Status update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update status.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_sales_history(request, customer_id):
    """Get sales history for a specific customer"""
    try:
        customer = Customer.objects.get(id=customer_id, is_active=True)
        sales = Sales.objects.by_customer(customer_id).active()

        serializer = SalesListSerializer(sales, many=True)

        return Response({
            'success': True,
            'data': {
                'customer': {
                    'id': customer.id,
                    'name': customer.name,
                    'phone': customer.phone
                },
                'sales': serializer.data,
                'total_sales': sales.count(),
                'total_revenue': sales.aggregate(total=Sum('grand_total'))['total'] or Decimal('0.00')
            }
        }, status=status.HTTP_200_OK)

    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve customer sales history.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_action_sales(request):
    """Perform bulk actions on sales"""
    serializer = SalesBulkActionSerializer(data=request.data)

    if serializer.is_valid():
        try:
            action = serializer.validated_data['action']
            sale_ids = serializer.validated_data['sale_ids']

            with transaction.atomic():
                sales = Sales.objects.filter(id__in=sale_ids, is_active=True)
                updated_count = 0

                if action == 'activate':
                    updated_count = sales.update(is_active=True)
                elif action == 'deactivate':
                    updated_count = sales.update(is_active=False)
                elif action == 'confirm':
                    updated_count = sales.filter(status='DRAFT').update(status='CONFIRMED')
                elif action == 'invoice':
                    updated_count = sales.filter(status='CONFIRMED').update(status='INVOICED')
                elif action == 'mark_paid':
                    updated_count = sales.filter(status='INVOICED').update(status='PAID')
                elif action == 'deliver':
                    updated_count = sales.filter(status='PAID').update(status='DELIVERED')
                elif action == 'cancel':
                    updated_count = sales.filter(status__in=['DRAFT', 'CONFIRMED', 'INVOICED']).update(status='CANCELLED')
                elif action == 'return':
                    updated_count = sales.filter(status='DELIVERED').update(status='RETURNED')
                elif action == 'recalculate':
                    for sale in sales:
                        sale.recalculate_totals()
                    updated_count = len(sales)

                return Response({
                    'success': True,
                    'message': f'Bulk action "{action}" completed successfully on {updated_count} sales.',
                    'updated_count': updated_count
                }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to perform bulk action.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({
        'success': False,
        'message': 'Bulk action failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sales_statistics(request):
    """Get sales statistics and analytics"""
    try:
        # Get date range parameters
        days = int(request.GET.get('days', 30))

        # Calculate statistics
        recent_sales = Sales.objects.recent(days)
        total_sales = recent_sales.count()
        total_revenue = recent_sales.aggregate(total=Sum('grand_total'))['total'] or Decimal('0.00')
        total_items = recent_sales.aggregate(total=Sum('total_items'))['total'] or 0
        average_sale_value = total_revenue / total_sales if total_sales > 0 else Decimal('0.00')

        # Payment completion rate
        paid_sales = recent_sales.filter(is_fully_paid=True).count()
        payment_completion_rate = (paid_sales / total_sales * 100) if total_sales > 0 else 0

        # Top products
        top_products = SaleItem.objects.filter(
            sale__in=recent_sales
        ).values('product_name').annotate(
            total_quantity=Sum('quantity'),
            total_revenue=Sum('line_total')
        ).order_by('-total_revenue')[:10]

        # Top customers
        top_customers = recent_sales.values('customer_name').annotate(
            total_sales=Count('id'),
            total_revenue=Sum('grand_total')
        ).order_by('-total_revenue')[:10]

        # Monthly trends (simplified)
        monthly_trends = recent_sales.extra(
            select={'month': "EXTRACT(month FROM date_of_sale)"}
        ).values('month').annotate(
            sales_count=Count('id'),
            revenue=Sum('grand_total')
        ).order_by('month')

        data = {
            'total_sales': total_sales,
            'total_revenue': total_revenue,
            'total_items_sold': total_items,
            'average_sale_value': average_sale_value,
            'payment_completion_rate': payment_completion_rate,
            'top_products': list(top_products),
            'top_customers': list(top_customers),
            'monthly_trends': list(monthly_trends)
        }

        serializer = SalesStatisticsSerializer(data)

        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve sales statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_from_order(request):
    """Create sale from existing order"""
    serializer = OrderToSaleConversionSerializer(data=request.data)

    if serializer.is_valid():
        try:
            with transaction.atomic():
                order_id = serializer.validated_data['order_id']
                order = Order.objects.get(id=order_id)

                # Create sale
                sale_data = {
                    'order_id': order,
                    'customer': order.customer,
                    'overall_discount': serializer.validated_data['overall_discount'],
                    'gst_percentage': serializer.validated_data['gst_percentage'],
                    'amount_paid': serializer.validated_data['amount_paid'],
                    'payment_method': serializer.validated_data['payment_method'],
                    'split_payment_details': serializer.validated_data.get('split_payment_details', {}),
                    'notes': serializer.validated_data.get('notes', ''),
                    'status': 'CONFIRMED',
                    'created_by': request.user
                }

                sale = Sales.objects.create(**sale_data)

                # Create sale items from order items
                partial_items = serializer.validated_data.get('partial_items', [])

                if partial_items:
                    # Partial conversion
                    for item_data in partial_items:
                        order_item_id = item_data.get('order_item_id')
                        quantity_to_sell = item_data.get('quantity_to_sell', 1)

                        try:
                            order_item = OrderItem.objects.get(id=order_item_id, order=order)

                            if quantity_to_sell <= order_item.quantity:
                                    SaleItem.objects.create(
                                        sale=sale,
                                        order_item=order_item.id, # This field is UUIDField in SaleItem
                                        product=order_item.product,
                                        unit_price=order_item.rate * order_item.days, # SaleItem unit_price is total per item for the rental period
                                        quantity=quantity_to_sell,
                                        customization_notes=order_item.customization_notes
                                    )
                        except OrderItem.DoesNotExist:
                            continue
                else:
                    # Full conversion
                    for order_item in order.order_items.all():
                        SaleItem.objects.create(
                            sale=sale,
                            order_item=order_item.id,
                            product=order_item.product,
                            unit_price=order_item.rate * order_item.days,
                            quantity=order_item.quantity,
                            customization_notes=order_item.customization_notes
                        )

                # Recalculate totals
                sale.recalculate_totals()

                return Response({
                    'success': True,
                    'message': 'Sale created from order successfully.',
                    'data': SalesSerializer(sale).data
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create sale from order.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({
        'success': False,
        'message': 'Order to sale conversion failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


# Sale Items views

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_sale_items(request):
    """List sale items with filtering"""
    try:
        sale_id = request.GET.get('sale_id', '').strip()
        product_id = request.GET.get('product_id', '').strip()

        sale_items = SaleItem.objects.active()

        if sale_id:
            sale_items = sale_items.by_sale(sale_id)

        if product_id:
            sale_items = sale_items.by_product(product_id)

        serializer = SaleItemListSerializer(sale_items, many=True)

        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to list sale items.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_sale_item(request):
    """Create a new sale item"""
    serializer = SaleItemCreateSerializer(data=request.data)

    if serializer.is_valid():
        try:
            with transaction.atomic():
                sale_item = serializer.save()

                # Recalculate sale totals
                sale_item.sale.recalculate_totals()

                return Response({
                    'success': True,
                    'message': 'Sale item created successfully.',
                    'data': SaleItemSerializer(sale_item).data
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create sale item.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({
        'success': False,
        'message': 'Sale item creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_sale_item(request, item_id):
    """Update sale item"""
    try:
        sale_item = SaleItem.objects.get(id=item_id, is_active=True)

        if request.method == 'PUT':
            serializer = SaleItemUpdateSerializer(sale_item, data=request.data)
        else:
            serializer = SaleItemUpdateSerializer(sale_item, data=request.data, partial=True)

        if serializer.is_valid():
            with transaction.atomic():
                updated_item = serializer.save()

                # Recalculate sale totals
                updated_item.sale.recalculate_totals()

                return Response({
                    'success': True,
                    'message': 'Sale item updated successfully.',
                    'data': SaleItemSerializer(updated_item).data
                }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Sale item update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except SaleItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale item not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update sale item.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_sale_item(request, item_id):
    """Delete sale item"""
    try:
        sale_item = SaleItem.objects.get(id=item_id, is_active=True)

        with transaction.atomic():
            sale_item.is_active = False
            sale_item.save()

            # Recalculate sale totals
            sale_item.sale.recalculate_totals()

            return Response({
                'success': True,
                'message': 'Sale item deleted successfully.'
            }, status=status.HTTP_200_OK)

    except SaleItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale item not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete sale item.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_invoice(request):
    """Create a new invoice for a sale"""
    serializer = InvoiceCreateSerializer(data=request.data, context={'request': request})

    if serializer.is_valid():
        try:
            with transaction.atomic():
                invoice = serializer.save()

                # Update sale status to INVOICED if it's not already invoiced
                sale = invoice.sale
                if sale.status not in ['INVOICED', 'CANCELLED']:
                    sale.status = 'INVOICED'
                    sale.save(update_fields=['status', 'updated_at'])

                return Response({
                    'success': True,
                    'message': 'Invoice created successfully',
                    'data': InvoiceSerializer(invoice).data
                }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create invoice',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({
        'success': False,
        'message': 'Invalid invoice data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_invoice(request, invoice_id):
    """Get invoice details"""
    try:
        invoice = Invoice.objects.get(id=invoice_id, is_active=True)
        serializer = InvoiceSerializer(invoice)

        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get invoice',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_invoice(request, invoice_id):
    """Update invoice details"""
    try:
        invoice = Invoice.objects.get(id=invoice_id, is_active=True)
        serializer = InvoiceUpdateSerializer(invoice, data=request.data, partial=True)

        if serializer.is_valid():
            invoice = serializer.save()
            return Response({
                'success': True,
                'message': 'Invoice updated successfully',
                'data': InvoiceSerializer(invoice).data
            }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Invalid invoice data',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update invoice',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_invoices(request):
    """List all invoices with filtering and pagination"""
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))

        # Filter parameters
        search = request.GET.get('search', '').strip()
        status_filter = request.GET.get('status', '').strip()
        customer_id = request.GET.get('customer_id', '').strip()
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()
        overdue_only = request.GET.get('overdue_only', 'false').lower() == 'true'

        # Base queryset
        if show_inactive:
            invoices = Invoice.objects.all()
        else:
            invoices = Invoice.objects.filter(is_active=True)

        # Apply filters
        if search:
            invoices = invoices.filter(
                Q(invoice_number__icontains=search) |
                Q(sale__customer_name__icontains=search) |
                Q(sale__customer_phone__icontains=search) |
                Q(order__customer_name__icontains=search) |
                Q(order__customer_phone__icontains=search)
            )
        if status_filter:
            invoices = invoices.filter(status=status_filter.upper())

        if customer_id:
            invoices = invoices.filter(
                Q(sale__customer_id=customer_id) |
                Q(order__customer_id=customer_id)
            )

        if date_from and date_to:
            invoices = invoices.filter(issue_date__date__range=[date_from, date_to])

        if overdue_only:
            invoices = invoices.filter(due_date__lt=timezone.now().date(), status__in=['DRAFT', 'ISSUED', 'SENT'])

        # Pagination
        start = (page - 1) * page_size
        end = start + page_size
        total_count = invoices.count()

        invoices_page = invoices[start:end]
        serializer = InvoiceListSerializer(invoices_page, many=True)

        return Response({
            'success': True,
            'data': serializer.data,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to list invoices',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_invoice_pdf(request, invoice_id):
    """Generate PDF for invoice"""
    try:
        from reportlab.lib.pagesizes import letter, A4
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import inch
        from reportlab.lib import colors
        from reportlab.pdfgen import canvas
        from django.conf import settings
        import os
        from io import BytesIO

        invoice = get_object_or_404(Invoice, id=invoice_id, is_active=True)

        # Create PDF buffer
        buffer = BytesIO()

        # Create PDF document
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        story = []

        # Get styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            spaceAfter=30,
            alignment=1,  # Center alignment
        )

        # Add title
        story.append(Paragraph(f"INVOICE #{invoice.invoice_number}", title_style))
        story.append(Spacer(1, 20))

        # Company and customer info
        due_date_str = invoice.due_date.strftime("%B %d, %Y") if invoice.due_date else "N/A"
        company_info = [
            ['Company: Moon Light Events', f'Invoice Date: {invoice.issue_date.strftime("%B %d, %Y")}'],
            ['Address: Karachi, Pakistan', f'Due Date: {due_date_str}'],
            ['Phone: +92-XXX-XXXXXXX', f'Status: {invoice.status}'],
        ]

        company_table = Table(company_info, colWidths=[3*inch, 3*inch])
        company_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', 10),
            ('BOTTOMPADDING', 6, 6, 6),
        ]))
        story.append(company_table)
        story.append(Spacer(1, 20))

        # Customer details
        customer = None
        if invoice.sale and invoice.sale.customer:
            customer = invoice.sale.customer
        elif invoice.order and invoice.order.customer:
            customer = invoice.order.customer

        if customer:
            customer_info = [
                ['Customer Information:'],
                ['Name:', customer.name],
                ['Phone:', customer.phone or 'N/A'],
                ['Email:', customer.email or 'N/A'],
                ['Address:', customer.address or 'N/A'],
            ]

            customer_table = Table(customer_info, colWidths=[1.5*inch, 4.5*inch])
            customer_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                ('FONTSIZE', 10),
                ('BOTTOMPADDING', 6, 6, 6),
                ('BACKGROUND', (0, 0), (0, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (0, 0), colors.whitesmoke),
            ]))
            story.append(customer_table)
            story.append(Spacer(1, 20))

        # Invoice items
        items_data = [['Item', 'Description', 'Qty', 'Unit Price', 'Total']]
        has_items = False

        if invoice.sale and invoice.sale.sale_items.exists():
            has_items = True
            for item in invoice.sale.sale_items.all():
                items_data.append([
                    item.product.name if item.product else 'N/A',
                    item.product.description[:50] + '...' if item.product and item.product.description and len(item.product.description) > 50 else (item.product.description if item.product else 'N/A'),
                    str(item.quantity),
                    f"PKR {item.unit_price:.2f}",
                    f"PKR {(item.quantity * item.unit_price):.2f}",
                ])
        elif invoice.order and invoice.order.order_items.exists():
            has_items = True
            for item in invoice.order.order_items.filter(is_active=True):
                items_data.append([
                    item.product.name if item.product else 'N/A',
                    item.product.description[:50] + '...' if item.product and item.product.description and len(item.product.description) > 50 else (item.product.description if item.product else 'N/A'),
                    str(item.quantity),
                    f"PKR {item.unit_price:.2f}",
                    f"PKR {(item.quantity * item.unit_price):.2f}",
                ])

        if has_items:
            items_table = Table(items_data, colWidths=[1.5*inch, 2*inch, 0.8*inch, 1.2*inch, 1.2*inch])
            items_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', 10),
                ('BOTTOMPADDING', 6, 6, 6),
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ]))
            story.append(items_table)
            story.append(Spacer(1, 20))

        # Totals
        subtotal = Decimal('0.00')
        tax = Decimal('0.00')
        discount = Decimal('0.00')
        grand_total = invoice.total_amount

        if invoice.sale:
            subtotal = invoice.sale.subtotal
            tax = invoice.sale.tax_amount
            discount = invoice.sale.overall_discount
            grand_total = invoice.sale.grand_total
        elif invoice.order:
            subtotal = invoice.order.total_amount
            # For orders, we might not have explicit tax/discount fields in the same way
            grand_total = invoice.order.total_amount

        totals_data = [
            ['Subtotal:', f"PKR {subtotal:.2f}"],
            ['Tax:', f"PKR {tax:.2f}"],
            ['Discount:', f"PKR {discount:.2f}"],
            ['Total:', f"PKR {grand_total:.2f}"],
            ['Paid Amount:', f"PKR {invoice.amount_paid:.2f}"],
            ['Due Amount:', f"PKR {invoice.amount_due:.2f}"],
        ]

        totals_table = Table(totals_data, colWidths=[1*inch, 1.5*inch])
        totals_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', 10),
            ('BOTTOMPADDING', 6, 6, 6),
            ('FONTNAME', (0, -1), (1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, -1), (1, -1), 12),
        ]))
        story.append(totals_table)

        # Build PDF
        doc.build(story)

        # Get PDF content
        pdf_content = buffer.getvalue()
        buffer.close()

        # Save PDF to file
        filename = f"invoice_{invoice.invoice_number}_{invoice.issue_date.strftime('%Y%m%d')}.pdf"
        filepath = os.path.join(settings.MEDIA_ROOT, 'invoices', filename)

        # Ensure directory exists
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'wb') as f:
            f.write(pdf_content)

        # Update invoice with PDF file
        from django.core.files.base import ContentFile
        invoice.pdf_file.save(filename, ContentFile(pdf_content), save=True)
        invoice.status = 'ISSUED'
        invoice.save(update_fields=['status', 'updated_at', 'pdf_file'])

        return HttpResponse(
            pdf_content,
            content_type='application/pdf'
        )

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate invoice PDF',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_invoice(request, invoice_id):
    """Delete an invoice"""
    try:
        invoice = get_object_or_404(Invoice, id=invoice_id, is_active=True)
        
        # Soft delete by setting is_active to False
        invoice.is_active = False
        invoice.save(update_fields=['is_active', 'updated_at'])
        
        logger.info(f"Invoice {invoice.invoice_number} deleted by user {request.user}")
        
        return Response({
            'success': True,
            'message': 'Invoice deleted successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error deleting invoice {invoice_id}: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to delete invoice',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_invoice_thermal_print(request, invoice_id):
    """Generate thermal print data for invoice"""
    try:
        from django.conf import settings
        import json

        invoice = get_object_or_404(Invoice, id=invoice_id, is_active=True)
        
        # Create thermal print data structure
        thermal_data = {
            'type': 'thermal_print',
            'invoice': {
                'invoice_number': invoice.invoice_number,
                'issue_date': invoice.issue_date.strftime("%Y-%m-%d %H:%M"),
                'due_date': invoice.due_date.strftime("%Y-%m-%d") if invoice.due_date else None,
                'status': invoice.status,
                'customer_name': invoice.sale.customer_name if invoice.sale else 'Walk-in Customer',
                'customer_phone': invoice.sale.customer_phone if invoice.sale else '',
            },
            'company': {
                'name': 'Moon Light Events',
                'address': 'Karachi, Pakistan',
                'phone': '+92-XXX-XXXXXXX',
            },
            'items': [],
            'totals': {
                'subtotal': float(invoice.total_amount),
                'tax': float(invoice.sale.tax_amount) if invoice.sale else 0.0,
                'discount': float(invoice.sale.overall_discount) if invoice.sale else 0.0,
                'total': float(invoice.total_amount),
                'amount_paid': float(invoice.amount_paid),
                'amount_due': float(invoice.amount_due),
            }
        }
        
        # Add items
        if invoice.sale and invoice.sale.sale_items.exists():
            for item in invoice.sale.sale_items.all():
                thermal_data['items'].append({
                    'name': item.product.name if item.product else 'N/A',
                    'quantity': int(item.quantity),
                    'unit_price': float(item.unit_price),
                    'total': float(item.quantity * item.unit_price),
                })
        
        logger.info(f"Thermal print data generated for invoice {invoice.invoice_number}")
        
        return Response({
            'success': True,
            'message': 'Thermal print data generated successfully',
            'data': thermal_data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error generating thermal print data for invoice {invoice_id}: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to generate thermal print data',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ===== RECEIPT MANAGEMENT =====

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_simple_receipt(request):
    """Create a simple receipt directly from sale (no separate payment record needed)"""
    from decimal import Decimal
    import uuid
    
    sale_id = request.data.get('sale')
    notes = request.data.get('notes', 'Receipt generated for paid sale')
    
    if not sale_id:
        return Response({
            'success': False,
            'message': 'Sale ID is required',
            'errors': {'sale': ['This field is required.']}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Get sale
        sale = Sales.objects.get(id=sale_id, is_active=True)
        
        # Check if sale has payment
        if sale.amount_paid <= 0:
            return Response({
                'success': False,
                'message': 'Cannot create receipt for unpaid sale',
                'errors': {'sale': ['This sale has no payment recorded.']}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if receipt already exists
        existing_receipt = Receipt.objects.filter(sale=sale, is_active=True).first()
        if existing_receipt:
            return Response({
                'success': False,
                'message': 'Receipt already exists for this sale',
                'errors': {'sale': ['Receipt already generated for this sale.']}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create a mock payment for receipt compatibility
        mock_payment_id = str(uuid.uuid4())
        
        # Create receipt
        receipt = Receipt.objects.create(
            id=uuid.uuid4(),
            sale=sale,
            payment=None,  # No payment required for simple receipts
            receipt_number=f"REC-{timezone.now().strftime('%Y-%m')}-{str(uuid.uuid4())[:8].upper()}",
            generated_at=timezone.now(),
            status='GENERATED',
            notes=notes
        )
        
        return Response({
            'success': True,
            'message': 'Simple receipt created successfully',
            'data': ReceiptSerializer(receipt).data
        }, status=status.HTTP_201_CREATED)
        
    except Sales.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale not found',
            'errors': {'sale': ['Invalid sale ID.']}
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to create simple receipt',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_receipt(request):
    """Create a new receipt for a payment"""
    serializer = ReceiptCreateSerializer(data=request.data, context={'request': request})

    if serializer.is_valid():
        try:
            with transaction.atomic():
                receipt = serializer.save()

                return Response({
                    'success': True,
                    'message': 'Receipt created successfully',
                    'data': ReceiptSerializer(receipt).data
                }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create receipt',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({
        'success': False,
        'message': 'Invalid receipt data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_receipt(request, receipt_id):
    """Get receipt details"""
    try:
        receipt = get_object_or_404(Receipt, id=receipt_id, is_active=True)
        serializer = ReceiptSerializer(receipt)

        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get receipt',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_receipt(request, receipt_id):
    """Update receipt details"""
    try:
        receipt = get_object_or_404(Receipt, id=receipt_id, is_active=True)
        serializer = ReceiptUpdateSerializer(receipt, data=request.data, partial=True)

        if serializer.is_valid():
            receipt = serializer.save()
            return Response({
                'success': True,
                'message': 'Receipt updated successfully',
                'data': ReceiptSerializer(receipt).data
            }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'message': 'Invalid receipt data',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update receipt',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_receipts(request):
    """List all receipts with filtering and pagination"""
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))

        # Filter parameters
        sale_id = request.GET.get('sale_id', '').strip()
        payment_id = request.GET.get('payment_id', '').strip()
        status_filter = request.GET.get('status', '').strip()
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()

        # Base queryset
        if show_inactive:
            receipts = Receipt.objects.all()
        else:
            receipts = Receipt.objects.filter(is_active=True)

        # Apply filters
        if sale_id:
            receipts = receipts.filter(sale_id=sale_id)

        if payment_id:
            receipts = receipts.filter(payment_id=payment_id)

        if status_filter:
            receipts = receipts.filter(status=status_filter.upper())

        if date_from and date_to:
            receipts = receipts.filter(generated_at__date__range=[date_from, date_to])

        # Pagination
        start = (page - 1) * page_size
        end = start + page_size
        total_count = receipts.count()

        receipts_page = receipts[start:end]
        serializer = ReceiptListSerializer(receipts_page, many=True)

        return Response({
            'success': True,
            'data': serializer.data,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_count,
                'total_pages': (total_count + page_size - 1) // page_size
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to list receipts',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_receipt_pdf(request, receipt_id):
    """Generate PDF for receipt in thermal receipt format (80mm width)"""
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.lib.units import mm
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib import colors
        from reportlab.pdfgen import canvas
        from django.conf import settings
        import os
        from io import BytesIO

        receipt = get_object_or_404(Receipt, id=receipt_id, is_active=True)
        
        # Create PDF buffer
        buffer = BytesIO()
        
        # Custom page size for thermal receipt (80mm width, 300mm height)
        page_width = 80 * mm
        page_height = 300 * mm
        
        # Create PDF document with custom page size
        doc = SimpleDocTemplate(
            buffer,
            pagesize=(page_width, page_height),
            leftMargin=3*mm,
            rightMargin=3*mm,
            topMargin=5*mm,
            bottomMargin=5*mm
        )
        story = []
        
        # Get styles
        styles = getSampleStyleSheet()
        
        # Shop header styles
        shop_name_style = ParagraphStyle(
            'ShopName',
            parent=styles['Normal'],
            fontSize=16,
            fontName='Helvetica-Bold',
            alignment=1,  # Center alignment
            spaceAfter=2*mm,
            textColor=colors.black
        )
        
        shop_tagline_style = ParagraphStyle(
            'ShopTagline',
            parent=styles['Normal'],
            fontSize=9,
            fontName='Helvetica',
            alignment=1,
            spaceAfter=3*mm,
            textColor=colors.grey
        )
        
        normal_center_style = ParagraphStyle(
            'NormalCenter',
            parent=styles['Normal'],
            fontSize=8,
            fontName='Helvetica',
            alignment=1,
            spaceAfter=1*mm
        )
        
        normal_left_style = ParagraphStyle(
            'NormalLeft',
            parent=styles['Normal'],
            fontSize=8,
            fontName='Helvetica',
            alignment=0,  # Left alignment
            spaceAfter=1*mm
        )
        
        # Add shop header
        story.append(Paragraph("★★ MOON LIGHT EVENTS ★★", shop_name_style))
        story.append(Paragraph("Events & Rentals", shop_tagline_style))
        story.append(Paragraph("Karachi, Pakistan", normal_center_style))
        story.append(Paragraph("Phone: +92-XXX-XXXXXXX", normal_center_style))
        
        # Separator
        story.append(Spacer(1, 2*mm))
        separator_data = [['=' * 30]]
        separator_table = Table(separator_data, colWidths=[page_width - 6*mm])
        separator_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ]))
        story.append(separator_table)
        story.append(Spacer(1, 2*mm))
        
        # Receipt info
        current_time = receipt.generated_at
        story.append(Paragraph(f"Receipt #: {receipt.receipt_number}", normal_center_style))
        story.append(Paragraph(f"Date: {current_time.strftime('%d-%b-%Y')}", normal_center_style))
        story.append(Paragraph(f"Time: {current_time.strftime('%I:%M %p')}", normal_center_style))
        story.append(Paragraph(f"Invoice: {receipt.sale.invoice_number if receipt.sale else 'N/A'}", normal_center_style))
        
        # Customer info
        if receipt.sale and receipt.sale.customer:
            customer = receipt.sale.customer
            story.append(Spacer(1, 2*mm))
            story.append(Paragraph(f"Customer: {customer.name}", normal_left_style))
            if customer.phone:
                story.append(Paragraph(f"Phone: {customer.phone}", normal_left_style))
        
        # Separator
        story.append(Spacer(1, 2*mm))
        separator_data = [['-' * 30]]
        separator_table = Table(separator_data, colWidths=[page_width - 6*mm])
        separator_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 6),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ]))
        story.append(separator_table)
        
        # Table header
        story.append(Spacer(1, 2*mm))
        header_data = [
            ['Item', 'Qty', 'Price', 'Total'],
        ]
        
        header_table = Table(header_data, colWidths=[30*mm, 8*mm, 14*mm, 14*mm])
        header_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 7),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BACKGROUND', (0, 0), (-1, -1), colors.lightgrey),
        ]))
        story.append(header_table)
        
        # Add sale items
        if receipt.sale:
            sale = receipt.sale
            sale_items = sale.sale_items.all() if hasattr(sale, 'sale_items') else []
            
            items_data = []
            total_quantity = 0
            total_amount = 0.0
            
            for item in sale_items:
                product_name = item.product.name if item.product else 'Unknown Product'
                quantity = float(item.quantity) if item.quantity else 0
                unit_price = float(item.unit_price) if item.unit_price else 0
                item_total = quantity * unit_price
                
                # Truncate long product names
                display_name = product_name[:25] + "..." if len(product_name) > 25 else product_name
                
                items_data.append([
                    display_name,
                    f"{quantity:.0f}",
                    f"{unit_price:.0f}",
                    f"{item_total:.0f}"
                ])
                
                total_quantity += quantity
                total_amount += item_total
            
            # Items table
            if items_data:
                items_table = Table(items_data, colWidths=[30*mm, 8*mm, 14*mm, 14*mm])
                items_table.setStyle(TableStyle([
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                    ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 0), (-1, -1), 7),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
                    ('TOPPADDING', (0, 0), (-1, -1), 1),
                ]))
                story.append(items_table)
        
        # Separator
        story.append(Spacer(1, 2*mm))
        separator_data = [['-' * 30]]
        separator_table = Table(separator_data, colWidths=[page_width - 6*mm])
        separator_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 6),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ]))
        story.append(separator_table)
        
        # Totals section
        story.append(Spacer(1, 2*mm))
        
        # Calculate totals
        grand_total = float(receipt.sale.grand_total) if receipt.sale and receipt.sale.grand_total else 0.0
        amount_paid = float(receipt.sale.amount_paid) if receipt.sale and receipt.sale.amount_paid else 0.0
        
        # For receipt, show the actual amount paid
        receipt_amount = float(receipt.payment_amount) if hasattr(receipt, 'payment_amount') else amount_paid
        balance = float(receipt.sale.remaining_amount) if receipt.sale else 0.0
        
        # Summary table
        summary_data = [
            ['Subtotal:', f"PKR {total_amount:.2f}"],
            ['Tax (0%):', 'PKR 0.00'],
            ['Grand Total:', f"PKR {grand_total:.2f}"],
            ['Paid Amount:', f"PKR {amount_paid:.2f}"],
            ['Balance Due:', f"PKR {balance:.2f}"],
        ]
        
        summary_table = Table(summary_data, colWidths=[30*mm, 30*mm])
        summary_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
            ('TOPPADDING', (0, 0), (-1, -1), 1),
        ]))
        story.append(summary_table)
        
        # Payment method
        if receipt.sale:
            payment_method = receipt.sale.payment_method_display if hasattr(receipt.sale, 'payment_method_display') else receipt.sale.payment_method
            story.append(Spacer(1, 2*mm))
            payment_data = [['Payment Method:', payment_method]]
            payment_table = Table(payment_data, colWidths=[30*mm, 30*mm])
            payment_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
                ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
                ('TOPPADDING', (0, 0), (-1, -1), 1),
            ]))
            story.append(payment_table)
        
        # Separator
        story.append(Spacer(1, 3*mm))
        separator_data = [['=' * 30]]
        separator_table = Table(separator_data, colWidths=[page_width - 6*mm])
        separator_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ]))
        story.append(separator_table)
        
        # Footer
        story.append(Spacer(1, 3*mm))
        footer_style = ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=7,
            fontName='Helvetica',
            alignment=1,
            spaceAfter=1*mm
        )
        story.append(Paragraph("Thank You!", footer_style))
        story.append(Paragraph("Please Visit Again", footer_style))
        story.append(Spacer(1, 2*mm))
        story.append(Paragraph("Software: POS System", footer_style))
        story.append(Paragraph(f"Printed: {current_time.strftime('%d/%m/%Y %I:%M %p')}", footer_style))
        
        # Build PDF
        doc.build(story)
        
        # Get PDF content
        pdf_content = buffer.getvalue()
        buffer.close()
        
        # Save PDF to file
        filename = f"receipt_{receipt.receipt_number}_{receipt.generated_at.strftime('%Y%m%d_%H%M')}.pdf"
        filepath = os.path.join(settings.MEDIA_ROOT, 'receipts', filename)
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        with open(filepath, 'wb') as f:
            f.write(pdf_content)
        
        # Update receipt with PDF file
        from django.core.files.base import ContentFile
        receipt.pdf_file.save(filename, ContentFile(pdf_content), save=True)
        receipt.status = 'GENERATED'
        receipt.save(update_fields=['status', 'updated_at', 'pdf_file'])
        
        return Response({
            'success': True,
            'message': 'Receipt PDF generated successfully',
            'data': {
                'receipt_id': str(receipt.id),
                'status': receipt.status,
                'pdf_url': receipt.pdf_file.url if receipt.pdf_file else None,
                'filename': filename
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate receipt PDF',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_sale_receipt_pdf(request, sale_id):
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.units import mm
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
        from reportlab.lib import colors
        from io import BytesIO

        sale = get_object_or_404(Sales, id=sale_id)

        # 1. Define Page Size: 80mm standard width for thermal printers.
        # Height: 297mm (A4 height), usually thermal printers cut automatically after content.
        # Margins: 2mm to maximize print area.
        width = 80 * mm
        height = 297 * mm

        buffer = BytesIO()

        # Setup Document with narrow margins
        doc = SimpleDocTemplate(
            buffer,
            pagesize=(width, height),
            rightMargin=2*mm,
            leftMargin=2*mm,
            topMargin=5*mm,
            bottomMargin=5*mm
        )

        story = []
        styles = getSampleStyleSheet()

        # 2. Custom Styles for POS
        style_center = ParagraphStyle(name='Center', parent=styles['Normal'], alignment=TA_CENTER, fontSize=8, leading=10)
        style_left = ParagraphStyle(name='Left', parent=styles['Normal'], alignment=TA_LEFT, fontSize=8, leading=10)
        style_bold_left = ParagraphStyle(name='BoldLeft', parent=styles['Normal'], alignment=TA_LEFT, fontSize=8, leading=10, fontName='Helvetica-Bold')
        style_bold_center = ParagraphStyle(name='BoldCenter', parent=styles['Normal'], alignment=TA_CENTER, fontSize=9, leading=11, fontName='Helvetica-Bold')
        style_title = ParagraphStyle(name='Title', parent=styles['Normal'], alignment=TA_CENTER, fontSize=12, leading=14, fontName='Helvetica-Bold')

        # 3. Enhanced Header Section
        story.append(Paragraph("🌙 MOON LIGHT EVENTS", style_title))
        story.append(Paragraph("📍 123 Market Street, City Name", style_center))
        story.append(Paragraph("📞 +92 300 1234567", style_center))
        story.append(Paragraph("🌐 www.alnoorfabrics.com", style_center))
        story.append(Spacer(1, 3*mm))

        # Separator Line
        story.append(Paragraph("=" * 48, style_center))

        # 4. Receipt Info Section
        story.append(Paragraph(f"🧾 INVOICE #: {sale.invoice_number}", style_bold_left))
        story.append(Paragraph(f"📅 Date: {sale.date_of_sale.strftime('%d-%m-%Y %H:%M')}", style_left))
        if sale.customer:
            story.append(Paragraph(f"👤 Customer: {sale.customer.name}", style_left))
        else:
            story.append(Paragraph("👤 Customer: Walk-in Customer", style_left))
        
        # Payment method
        payment_method_display = sale.get_payment_method_display()
        story.append(Paragraph(f"💳 Payment: {payment_method_display}", style_left))

        story.append(Paragraph("=" * 48, style_center))
        story.append(Spacer(1, 2*mm))

        # 5. Enhanced Items Table Section
        story.append(Paragraph("📋 ORDER DETAILS", style_bold_center))
        story.append(Spacer(1, 1*mm))
        
        # Columns: Item (Name wraps), Qty, Price, Total
        # Widths: Total ~76mm (80mm - 4mm margins)
        # Item: 35mm, Qty: 8mm, Price: 15mm, Total: 18mm
        col_widths = [35*mm, 8*mm, 15*mm, 18*mm]

        headers = ["🛍️ Item", "Qty", "Rate", "Total"]
        data = [headers]

        total_qty = 0
        for item in sale.sale_items.all():
            product_name = item.product.name if item.product else item.product_name
            # Item Name in Paragraph to allow wrapping
            p_name_para = Paragraph(product_name, style_left)

            row = [
                p_name_para,
                f"{item.quantity}",
                f"{int(item.unit_price)}",
                f"{int(item.line_total)}"
            ]
            data.append(row)
            total_qty += item.quantity

        t = Table(data, colWidths=col_widths)
        t.setStyle(TableStyle([
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'), # Header Bold
            ('FONTSIZE', (0,0), (-1,-1), 8),
            ('ALIGN', (1,0), (-1,-1), 'RIGHT'), # Numbers Right Aligned
            ('ALIGN', (0,0), (0,-1), 'LEFT'),   # Item Name Left Aligned
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('LINEBELOW', (0,0), (-1,0), 0.5, colors.black), # Line below header
            ('LINEABOVE', (0,0), (-1,0), 0.5, colors.black), # Line above header
            ('BOTTOMPADDING', (0,0), (-1,0), 3),
            ('TOPPADDING', (0,0), (-1,-1), 2),
            ('BACKGROUND', (0,0), (-1,0), colors.lightgrey), # Header background
        ]))
        story.append(t)

        story.append(Paragraph("=" * 48, style_center))
        story.append(Spacer(1, 2*mm))

        # 6. Enhanced Totals Section
        story.append(Paragraph("💰 PAYMENT SUMMARY", style_bold_center))
        story.append(Spacer(1, 1*mm))

        # Calculate change/remaining based on model fields
        # Assuming change_amount exists, else 0
        change = getattr(sale, 'change_amount', 0)

        t_totals_data = [
            ["📦 Total Items:", f"{total_qty}"],
            ["💵 Subtotal:", f"PKR {int(sale.subtotal)}"],
        ]

        if sale.overall_discount > 0:
            t_totals_data.append(["🎉 Discount:", f"-PKR {int(sale.overall_discount)}"])

        if sale.tax_amount > 0:
            t_totals_data.append(["📈 Tax:", f"PKR {int(sale.tax_amount)}"])

        t_totals_data.append(["💎 GRAND TOTAL:", f"PKR {int(sale.grand_total)}"])
        t_totals_data.append(["💸 Amount Paid:", f"PKR {int(sale.amount_paid)}"])
        t_totals_data.append(["⚖️ Remaining:", f"PKR {int(sale.remaining_amount)}"])

        if change > 0:
            t_totals_data.append(["🔄 Change:", f"PKR {int(change)}"])

        t_totals = Table(t_totals_data, colWidths=[45*mm, 30*mm])

        # Apply styles to totals table
        t_totals.setStyle(TableStyle([
            ('FONTNAME', (0,0), (-1,-1), 'Helvetica'),
            ('FONTSIZE', (0,0), (-1,-1), 8),
            ('ALIGN', (0,0), (0,-1), 'LEFT'),
            ('ALIGN', (1,0), (1,-1), 'RIGHT'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ]))

        # Find index of GRAND TOTAL to bold it specifically
        grand_total_idx = -1
        for i, row in enumerate(t_totals_data):
            if "GRAND TOTAL" in row[0]:
                grand_total_idx = i
                break

        if grand_total_idx != -1:
            t_totals.setStyle(TableStyle([
                ('FONTNAME', (0, grand_total_idx), (-1, grand_total_idx), 'Helvetica-Bold'),
                ('FONTSIZE', (0, grand_total_idx), (-1, grand_total_idx), 10),
                ('LINEABOVE', (0, grand_total_idx), (-1, grand_total_idx), 0.5, colors.black),
                ('LINEBELOW', (0, grand_total_idx), (-1, grand_total_idx), 0.5, colors.black),
                ('BACKGROUND', (0, grand_total_idx), (-1, grand_total_idx), colors.lightgrey),
            ]))

        story.append(t_totals)

        story.append(Paragraph("=" * 48, style_center))
        story.append(Spacer(1, 3*mm))

        # 7. Enhanced Footer Section
        story.append(Paragraph("⚠️  No Return / Exchange without receipt", style_center))
        story.append(Paragraph("🙏 Thank you for choosing Moon Light Events!", style_bold_center))
        story.append(Spacer(1, 2*mm))
        story.append(Paragraph("📱 Visit us again!", style_center))
        story.append(Spacer(1, 2*mm))
        story.append(Paragraph("💻 Powered by: HH Tech Hub", style_center))
        story.append(Spacer(1, 2*mm))
        story.append(Paragraph("🌟 Quality Fabric, Trusted Service", style_center))

        doc.build(story)
        pdf_content = buffer.getvalue()
        buffer.close()

        response = HttpResponse(pdf_content, content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="receipt_{sale.invoice_number}.pdf"'
        return response

    except Exception as e:
        logger.error(f"Error generating sale receipt: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to generate receipt',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_sale_thermal_print(request, sale_id):
    """Generate thermal print data for sale"""
    try:
        from django.conf import settings
        import json

        sale = get_object_or_404(Sales, id=sale_id, is_active=True)
        
        # Create thermal print data structure
        thermal_data = {
            'type': 'thermal_print',
            'sale': {
                'invoice_number': sale.invoice_number,
                'date_of_sale': sale.date_of_sale.strftime("%Y-%m-%d %H:%M"),
                'customer_name': sale.customer_name,
                'customer_phone': sale.customer_phone,
                'subtotal': float(sale.subtotal),
                'overall_discount': float(sale.overall_discount),
                'tax_amount': float(sale.tax_amount),
                'grand_total': float(sale.grand_total),
                'amount_paid': float(sale.amount_paid),
                'remaining_amount': float(sale.remaining_amount),
                'payment_method': sale.payment_method,
                'status': sale.status,
            },
            'items': [],
            'company': {
                'name': getattr(settings, 'COMPANY_NAME', 'Moon Light Events'),
                'address': getattr(settings, 'COMPANY_ADDRESS', 'Karachi, Pakistan'),
                'phone': getattr(settings, 'COMPANY_PHONE', '+92-XXX-XXXXXXX'),
                'email': getattr(settings, 'COMPANY_EMAIL', 'info@moonlightevents.com'),
            }
        }
        
        # Add items
        if sale.sale_items.exists():
            for item in sale.sale_items.all():
                thermal_data['items'].append({
                    'name': item.product.name if item.product else 'N/A',
                    'quantity': int(item.quantity),
                    'unit_price': float(item.unit_price),
                    'item_discount': float(item.item_discount),
                    'total': float(item.line_total),
                })
        
        logger.info(f"Thermal print data generated for sale {sale.invoice_number}")
        
        return Response({
            'success': True,
            'message': 'Thermal print data generated successfully',
            'data': thermal_data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error generating thermal print data for sale {sale_id}: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to generate thermal print data',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ===== INVOICE GENERATION & PAYMENT =====

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_invoice_from_order(request):
    """
    Generate an invoice from an existing order.
    
    Body: {"order_id": "uuid"}
    """
    from .invoice_service import generate_invoice_from_order as gen_invoice
    
    order_id = request.data.get('order_id')
    if not order_id:
        return Response({
            'success': False,
            'message': 'order_id is required.',
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        order = Order.objects.get(id=order_id, is_active=True)
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
        }, status=status.HTTP_404_NOT_FOUND)
    
    try:
        invoice = gen_invoice(order, created_by=request.user)
        return Response({
            'success': True,
            'message': f'Invoice {invoice.invoice_number} generated successfully.',
            'data': InvoiceSerializer(invoice).data,
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Failed to generate invoice from order {order_id}: {str(e)}")
        return Response({
            'success': False,
            'message': f'Failed to generate invoice: {str(e)}',
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def apply_invoice_payment(request, invoice_id):
    """
    Apply a payment to an invoice.
    
    Body: {
        "amount": 5000.00,
        "payment_method": "CASH",
        "reference": "optional reference"
    }
    """
    from .invoice_service import apply_payment_to_invoice
    from decimal import Decimal
    
    try:
        invoice = Invoice.objects.get(id=invoice_id, is_active=True)
    except Invoice.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Invoice not found.',
        }, status=status.HTTP_404_NOT_FOUND)
    
    amount = request.data.get('amount')
    if not amount:
        return Response({
            'success': False,
            'message': 'amount is required.',
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        amount = Decimal(str(amount))
        payment, updated_invoice = apply_payment_to_invoice(
            invoice=invoice,
            payment_amount=amount,
            payment_method=request.data.get('payment_method', 'CASH'),
            reference=request.data.get('reference', ''),
            created_by=request.user,
        )
        
        return Response({
            'success': True,
            'message': f'Payment of PKR {amount} applied to invoice {invoice.invoice_number}.',
            'data': {
                'invoice': InvoiceSerializer(updated_invoice).data,
                'payment_id': str(payment.id),
            }
        }, status=status.HTTP_200_OK)
    
    except ValueError as e:
        return Response({
            'success': False,
            'message': str(e),
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error(f"Failed to apply payment to invoice {invoice_id}: {str(e)}")
        return Response({
            'success': False,
            'message': f'Failed to apply payment: {str(e)}',
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def write_off_invoice(request, invoice_id):
    """
    Write off remaining balance on an invoice for closure.
    
    Body: {
        "amount": 150.00,  // optional, defaults to full remaining balance
        "reason": "Small balance write-off"
    }
    """
    from .invoice_service import write_off_invoice_balance
    from decimal import Decimal
    
    try:
        invoice = Invoice.objects.get(id=invoice_id, is_active=True)
    except Invoice.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Invoice not found.',
        }, status=status.HTTP_404_NOT_FOUND)
    
    try:
        amount = request.data.get('amount')
        if amount:
            amount = Decimal(str(amount))
        
        reason = request.data.get('reason', '')
        
        updated_invoice = write_off_invoice_balance(
            invoice=invoice,
            amount=amount,
            reason=reason,
            created_by=request.user,
        )
        
        return Response({
            'success': True,
            'message': f'Write-off applied to invoice {invoice.invoice_number}.',
            'data': InvoiceSerializer(updated_invoice).data,
        }, status=status.HTTP_200_OK)
    
    except ValueError as e:
        return Response({
            'success': False,
            'message': str(e),
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error(f"Failed to write off invoice {invoice_id}: {str(e)}")
        return Response({
            'success': False,
            'message': f'Failed to write off: {str(e)}',
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def invoice_ledger(request):
    """
    Get invoice ledger summary, optionally filtered by customer.
    
    Query params: ?customer_id=uuid
    """
    from .invoice_service import get_invoice_ledger
    
    customer_id = request.query_params.get('customer_id')
    start_date = request.query_params.get('start_date')
    end_date = request.query_params.get('end_date')
    
    try:
        ledger = get_invoice_ledger(
            customer_id=customer_id,
            start_date=start_date,
            end_date=end_date
        )
        
        # Convert Decimal values for JSON serialization
        totals = {k: float(v) for k, v in ledger['totals'].items()}
        
        return Response({
            'success': True,
            'data': {
                'totals': totals,
                'total_overdue': float(ledger['total_overdue']),
                'ledger_count': ledger['ledger_count'],
                'ledger_entries': ledger['ledger_entries'],
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Failed to get invoice ledger: {str(e)}")
        return Response({
            'success': False,
            'message': f'Failed to get ledger: {str(e)}',
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_tax_rates(request):
    """List all tax rates with filtering, search, and pagination"""
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        search = request.GET.get('search', '').strip()
        tax_type = request.GET.get('tax_type', '').strip()

        # Base queryset
        if show_inactive:
            tax_rates = TaxRate.objects.all()
        else:
            tax_rates = TaxRate.objects.filter(is_active=True)

        # Apply filters
        if search:
            # Note: We need Q for complex lookups
            from django.db.models import Q
            tax_rates = tax_rates.filter(Q(name__icontains=search) | Q(description__icontains=search))

        if tax_type:
            tax_rates = tax_rates.filter(tax_type=tax_type)

        # Pagination
        start = (page - 1) * page_size
        end = start + page_size
        total_count = tax_rates.count()

        tax_rates_page = tax_rates[start:end]
        serializer = TaxRateSerializer(tax_rates_page, many=True)

        return Response({
            'success': True,
            'data': {
                'tax_rates': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end < total_count,
                    'has_previous': start > 0
                }
            }
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error listing tax rates: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to list tax rates.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_active_tax_rates(request):
    """Get all currently effective tax rates"""
    try:
        # Use simple filter instead of complex logic for now
        # Only get those marked as active
        tax_rates = TaxRate.objects.filter(is_active=True)
        
        # Filter by currently effective if property logic is needed, 
        # but for API, we can just return all active ones and let frontend decide or handle it here
        active_rates = [rate for rate in tax_rates if rate.is_currently_effective]
        
        serializer = TaxRateSerializer(active_rates, many=True)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error getting active tax rates: {str(e)}")
        return Response({
            'success': False,
            'message': 'Failed to get active tax rates.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_tax_rate(request):
    """Create a new tax rate"""
    serializer = TaxRateSerializer(data=request.data)
    if serializer.is_valid():
        try:
            tax_rate = serializer.save()
            return Response({
                'success': True,
                'message': 'Tax rate created successfully.',
                'data': TaxRateSerializer(tax_rate).data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create tax rate.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    return Response({
        'success': False,
        'message': 'Validation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'PATCH', 'DELETE'])
@permission_classes([IsAuthenticated])
def tax_rate_detail(request, pk):
    """CRUD operations for a specific tax rate"""
    try:
        tax_rate = TaxRate.objects.get(pk=pk)
    except TaxRate.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Tax rate not found.'
        }, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = TaxRateSerializer(tax_rate)
        return Response({
            'success': True,
            'data': serializer.data
        })

    elif request.method in ['PUT', 'PATCH']:
        partial = request.method == 'PATCH'
        serializer = TaxRateSerializer(tax_rate, data=request.data, partial=partial)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Tax rate updated successfully.',
                'data': serializer.data
            })
        return Response({
            'success': False,
            'message': 'Update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        # Soft delete
        tax_rate.is_active = False
        tax_rate.save()
        return Response({
            'success': True,
            'message': 'Tax rate deactivated successfully.'
        }, status=status.HTTP_200_OK)