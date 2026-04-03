"""
Simplified Dashboard Analytics View - Daily Order Count Only
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Count
from datetime import timedelta
import logging

# Import models
from sales.models import Sales, SaleItem
from orders.models import Order
from order_items.models import OrderItem

# Set up logger
logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_analytics(request):
    """
    Simplified Dashboard Analytics - Daily Order Count Only
    """
    try:
        logger.info("=== DASHBOARD ANALYTICS API CALLED ===")
        
        # Date ranges
        today = timezone.now().date()
        current_month_start = today.replace(day=1)
        last_month_end = current_month_start - timedelta(days=1)
        last_month_start = last_month_end.replace(day=1)
        
        logger.info(f"DEBUG: Date ranges - today: {today}, current_month_start: {current_month_start}, last_month_start: {last_month_start}")
        
        # =====================================================
        # COMBINED METRICS (SALES + ORDERS)
        # =====================================================
        
        # Current month metrics
        s_this = Sales.objects.filter(is_active=True, date_of_sale__gte=current_month_start).aggregate(total=Sum('grand_total'), count=Count('id'))
        o_this = Order.objects.filter(is_active=True, date_ordered__gte=current_month_start).aggregate(total=Sum('total_amount'), count=Count('id'))
        
        total_sales = (s_this['total'] or 0) + (o_this['total'] or 0)
        total_orders = (s_this['count'] or 0) + (o_this['count'] or 0)
        
        # Last month metrics
        s_last = Sales.objects.filter(is_active=True, date_of_sale__gte=last_month_start, date_of_sale__lte=last_month_end).aggregate(total=Sum('grand_total'), count=Count('id'))
        o_last = Order.objects.filter(is_active=True, date_ordered__gte=last_month_start, date_ordered__lte=last_month_end).aggregate(total=Sum('total_amount'), count=Count('id'))
        
        last_month_sales = (s_last['total'] or 0) + (o_last['total'] or 0)
        last_month_orders = (s_last['count'] or 0) + (o_last['count'] or 0)
        
        # Calculate trends
        def calculate_trend(current, previous):
            if not previous or previous == 0:
                return "+100%" if current > 0 else "0%"
            growth = ((float(current) - float(previous)) / float(previous)) * 100
            prefix = "+" if growth >= 0 else ""
            return f"{prefix}{growth:.1f}%"

        sales_trend = calculate_trend(total_sales, last_month_sales)
        orders_trend = calculate_trend(total_orders, last_month_orders)
        
        # Daily order count for the last 7 days (Combined)
        daily_orders = []
        for i in range(7):
            date = today - timedelta(days=6-i)
            s_count = Sales.objects.filter(is_active=True, date_of_sale__date=date).count()
            o_count = Order.objects.filter(is_active=True, date_ordered=date).count()
            
            daily_orders.append({
                'date': date.isoformat(),
                'day_name': date.strftime('%a'),
                'order_count': s_count + o_count,
            })
        
        # =====================================================
        # ADDITIONAL METRICS
        # =====================================================
        
        from customers.models import Customer
        total_customers = Customer.objects.filter(is_active=True).count()
        
        # Customer trend (new customers this month vs last month)
        this_month_new_customers = Customer.objects.filter(is_active=True, created_at__gte=current_month_start).count()
        last_month_new_customers = Customer.objects.filter(is_active=True, created_at__gte=last_month_start, created_at__lte=last_month_end).count()
        customers_trend = calculate_trend(this_month_new_customers, last_month_new_customers)

        # Latest customers
        latest_customers = Customer.objects.filter(is_active=True).order_by('-created_at')[:5]
        latest_customers_data = []
        for customer in latest_customers:
            latest_customers_data.append({
                'id': str(customer.id),
                'name': customer.name,
                'email': customer.email or '',
                'phone': customer.phone or '',
                'total_spent': float(customer.total_sales_amount),
                'total_orders': customer.total_sales_count,
                'created_at': customer.created_at.isoformat(),
            })
        
        from vendors.models import Vendor
        total_vendors = Vendor.objects.filter(is_active=True).count()
        
        from products.models import Product
        total_products = Product.objects.filter(is_active=True).count()
        low_stock_products = Product.objects.filter(is_active=True, quantity__lte=5).count()
        
        # Trending products (Combined SaleItem + OrderItem)
        from django.db.models import F
        
        sale_items = SaleItem.objects.filter(
            sale__is_active=True,
            sale__date_of_sale__gte=current_month_start
        ).values('product__name', 'product__id').annotate(
            qty=Sum('quantity'),
            rev=Sum('line_total')
        )
        
        order_items = OrderItem.objects.filter(
            is_active=True,
            order__is_active=True,
            order__date_ordered__gte=current_month_start
        ).values('product__name', 'product__id').annotate(
            qty=Sum('quantity'),
            rev=Sum('line_total')
        )
        
        # Combine in memory
        combined_products = {}
        for item in list(sale_items) + list(order_items):
            pid = str(item['product__id'])
            if pid not in combined_products:
                combined_products[pid] = {
                    'name': item['product__name'] or "Unknown",
                    'sales': 0,
                    'revenue': 0.0
                }
            combined_products[pid]['sales'] += item['qty'] or 0
            combined_products[pid]['revenue'] += float(item['rev'] or 0)
            
        trending_products_data = sorted(
            [{'id': k, **v} for k, v in combined_products.items()],
            key=lambda x: x['sales'],
            reverse=True
        )[:5]
        
        from expenses.models import Expense
        # ✅ Show ALL-TIME expenses (not just this month)
        total_expenses = Expense.objects.filter(
            is_active=True,
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        net_profit = float(total_sales) - float(total_expenses)
        profit_margin = (net_profit / float(total_sales) * 100) if float(total_sales) > 0 else 0
        
        # Return Metrics
        from returns.models import RentalReturn
        returns_stats = RentalReturn.objects.aggregate(
            total_damage=Sum('damage_charges'),
            total_recovered=Sum('damage_recovered')
        )
        total_damage = float(returns_stats['total_damage'] or 0)
        total_recovered = float(returns_stats['total_recovered'] or 0)
        
        # Sales overview breakdown
        sales_overview = {
            'this_month': float(total_sales),
            'orders_count': total_orders,
            'average_order_value': float(total_sales) / total_orders if total_orders > 0 else 0,
            'daily_average': float(total_sales) / 30,  # Assuming 30 days
        }
        
        logger.info(f"DEBUG: Additional metrics - customers: {total_customers}, vendors: {total_vendors}, products: {total_products}, expenses: {total_expenses}")
        logger.info(f"DEBUG: Latest customers: {len(latest_customers_data)}, Trending products: {len(trending_products_data)}")
        
        # =====================================================
        # RESPONSE DATA - ENHANCED
        # =====================================================
        
        response_data = {
            # Sales metrics
            'total_sales': float(total_sales),
            'total_orders': total_orders,
            'sales_trend': sales_trend,
            'orders_trend': orders_trend,
            
            # Daily order analytics
            'daily_orders': daily_orders,
            
            # Customer metrics
            'total_customers': total_customers,
            'customers_trend': customers_trend,
            'latest_customers': latest_customers_data,
            
            # Vendor metrics
            'total_vendors': total_vendors,
            
            # Product metrics
            'total_products': total_products,
            'low_stock_products': low_stock_products,
            'trending_products': trending_products_data,
            
            # Financial metrics
            'total_expenses': float(total_expenses),
            'total_revenue': float(total_sales),
            'total_damage': total_damage,
            'total_recovered': total_recovered,
            'net_profit': net_profit,
            'profit_margin': profit_margin,
            
            # Sales overview
            'sales_overview': sales_overview,
            
            # Basic info
            'current_month': current_month_start.isoformat(),
            'today': today.isoformat(),
        }
        
        logger.info("=== DASHBOARD ANALYTICS API SUCCESS ===")
        return Response({
            'success': True,
            'data': response_data
        })
        
    except Exception as e:
        logger.error(f"Dashboard analytics error: {e}")
        logger.error(f"Exception type: {type(e)}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        
        return Response({
            'success': False,
            'message': 'Failed to get dashboard analytics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def business_metrics(request):
    """Get business metrics list"""
    try:
        from .models import BusinessMetrics
        from .serializers import BusinessMetricSerializer
        
        metrics = BusinessMetrics.objects.all().order_by('-start_date')[:20]
        serializer = BusinessMetricSerializer(metrics, many=True)
        
        return Response({
            'success': True,
            'data': {
                'metrics': serializer.data,
                'pagination': {
                    'page': 1,
                    'page_size': 20,
                    'total_count': BusinessMetrics.objects.count(),
                    'total_pages': 1,
                    'has_next': False,
                    'has_previous': False
                }
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get business metrics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def realtime_analytics(request):
    """Get real-time analytics data"""
    try:
        from orders.models import Order
        
        now = timezone.now()
        today = now.date()
        
        # Today's sales
        today_sales = Sales.objects.filter(
            is_active=True,
            date_of_sale=today
        ).aggregate(
            total=Sum('grand_total'),
            count=Count('id')
        )
        
        # Today's orders
        today_orders = Order.objects.filter(
            is_active=True,
            order_date=today
        ).count()
        
        # Active sessions (customers who made purchases in last hour)
        one_hour_ago = now - timedelta(hours=1)
        active_sessions = Sales.objects.filter(
            is_active=True,
            created_at__gte=one_hour_ago
        ).values('customer').distinct().count()
        
        realtime_data = {
            'current_time': now.isoformat(),
            'today_date': today.isoformat(),
            'today_sales': float(today_sales['total'] or 0),
            'today_sales_count': today_sales['count'] or 0,
            'today_orders': today_orders,
            'active_sessions': active_sessions,
            'pending_orders': Order.objects.filter(
                is_active=True,
                status='PENDING'
            ).count(),
        }
        
        return Response({
            'success': True,
            'data': realtime_data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get real-time analytics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def top_customers(request):
    """Get top customers by spending (combining Sales and Orders)"""
    try:
        from customers.models import Customer
        from django.db.models import Sum, Count, Q

        customers = Customer.objects.filter(
            is_active=True
        ).annotate(
            sales_spent=Sum('sales__grand_total', filter=Q(sales__is_active=True)),
            orders_spent=Sum('orders__total_amount', filter=Q(orders__is_active=True)),
            sales_count=Count('sales', distinct=True, filter=Q(sales__is_active=True)),
            orders_count=Count('orders', distinct=True, filter=Q(orders__is_active=True))
        ).order_by('-orders_spent')[:20]

        data = []
        for c in customers:
            total_spent = float(c.sales_spent or 0) + float(c.orders_spent or 0)
            total_orders = (c.sales_count or 0) + (c.orders_count or 0)
            
            if total_spent == 0 and total_orders == 0:
                continue

            data.append({
                'id': str(c.id),
                'name': c.name,
                'phone': c.phone or '',
                'total_spent': total_spent,
                'total_orders': total_orders
            })

        return Response({'success': True, 'data': data})
    except Exception as e:
        import traceback
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def top_products(request):
    """Get most rented/sold items (from both Orders and Sales)"""
    try:
        from order_items.models import OrderItem
        from sales.models import SaleItem
        from django.db.models import Sum
        
        # Aggregate from Orders (Rentals)
        order_items = OrderItem.objects.filter(is_active=True).values(
            'product__name', 'product__category__name'
        ).annotate(
            total_qty=Sum('quantity'),
            total_rev=Sum('line_total')
        )
        
        # Aggregate from Sales (Direct sales/Walk-ins)
        sale_items = SaleItem.objects.filter(is_active=True).values(
            'product__name', 'product__category__name'
        ).annotate(
            total_qty=Sum('quantity'),
            total_rev=Sum('line_total')
        )
        
        # Combine results
        combined_data = {}
        
        for item in order_items:
            name = item['product__name'] or 'Unknown'
            cat = item['product__category__name'] or 'General'
            combined_data[name] = {
                'name': name,
                'category': cat,
                'quantity': item['total_qty'] or 0,
                'revenue': float(item['total_rev'] or 0)
            }
            
        for item in sale_items:
            name = item['product__name'] or 'Unknown'
            cat = item['product__category__name'] or 'General'
            if name in combined_data:
                combined_data[name]['quantity'] += item['total_qty'] or 0
                combined_data[name]['revenue'] += float(item['total_rev'] or 0)
            else:
                combined_data[name] = {
                    'name': name,
                    'category': cat,
                    'quantity': item['total_qty'] or 0,
                    'revenue': float(item['total_rev'] or 0)
                }
        
        # Sort and limit
        final_list = sorted(combined_data.values(), key=lambda x: x['quantity'], reverse=True)[:20]
            
        return Response({'success': True, 'data': final_list})
    except Exception as e:
        import traceback
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def revenue_report(request):
    """Get daily revenue for the last 30 days (combined Orders and Sales)"""
    try:
        from sales.models import Sales
        from orders.models import Order
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=30)
        
        daily_revenue = []
        for i in range(31):
            d = start_date + timedelta(days=i)
            
            # Sales revenue
            sales_total = Sales.objects.filter(
                is_active=True, 
                date_of_sale__date=d
            ).aggregate(total=Sum('grand_total'))['total'] or 0
            
            # Orders revenue (using total_amount or advance? Usually total_amount represents booked revenue)
            orders_total = Order.objects.filter(
                is_active=True,
                date_ordered=d
            ).aggregate(total=Sum('total_amount'))['total'] or 0
            
            daily_revenue.append({
                'date': d.isoformat(),
                'revenue': float(sales_total) + float(orders_total)
            })
            
        return Response({'success': True, 'data': daily_revenue})
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tool_usage_report(request):
    """Monthly usage, recent usage history, and re-order (purchase) history for consumable tools"""
    try:
        from order_items.models import OrderItem
        from purchases.models import PurchaseItem
        from django.db.models.functions import TruncMonth
        from django.db.models import Sum
        
        # Get filtering months from query param (default to 6)
        months_limit = int(request.query_params.get('months', 6))
        cutoff_date = timezone.now() - timedelta(days=months_limit * 30)

        # Usage trend (Monthly)
        usage = OrderItem.objects.filter(
            is_active=True,
            product__is_consumable=True,
            created_at__gte=cutoff_date
        ).annotate(
            month=TruncMonth('created_at')
        ).values('month').annotate(
            total_qty=Sum('quantity'),
            total_rev=Sum('line_total')
        ).order_by('month')
        
        # Recent usage history (from orders)
        history = OrderItem.objects.filter(
            is_active=True,
            product__is_consumable=True
        ).select_related('order', 'product').order_by('-created_at')[:20]
        
        # Re-order (Purchase) History
        purchase_history = PurchaseItem.objects.filter(
            product__is_consumable=True
        ).select_related('purchase', 'purchase__vendor', 'product').order_by('-purchase__purchase_date')[:20]

        usage_data = []
        for u in usage:
            if u['month']:
                usage_data.append({
                    'month': u['month'].strftime('%b'),
                    'quantity': u['total_qty'],
                    'revenue': float(u['total_rev'])
                })
            
        history_data = []
        for h in history:
            history_data.append({
                'date': h.created_at.strftime('%Y-%m-%d'),
                'item': h.product_name or (h.product.name if h.product else "Unknown"),
                'quantity': h.quantity,
                'status': h.order.get_status_display() if h.order else 'Used'
            })
            
        reorder_data = []
        for p in purchase_history:
            reorder_data.append({
                'date': p.purchase.purchase_date.strftime('%Y-%m-%d'),
                'item': p.product.name,
                'vendor': p.purchase.vendor.name,
                'quantity': float(p.quantity),
                'cost': float(p.total_cost)
            })

        return Response({
            'success': True, 
            'data': {
                'monthly_usage': usage_data,
                'recent_history': history_data,
                'reorder_history': reorder_data
            }
        })
    except Exception as e:
        import traceback
        logger.error(f"Tool usage report error: {str(e)}")
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def monthly_revenue_report(request):
    """Get aggregated monthly revenue for the last 12 months (Combined)"""
    try:
        from sales.models import Sales
        from orders.models import Order
        from django.db.models.functions import TruncMonth
        from django.db.models import Sum
        
        cutoff_date = timezone.now() - timedelta(days=365)
        
        # Sales monthly
        sales_monthly = Sales.objects.filter(
            is_active=True,
            date_of_sale__gte=cutoff_date
        ).annotate(
            month=TruncMonth('date_of_sale')
        ).values('month').annotate(
            total=Sum('grand_total')
        ).order_by('month')
        
        # Orders monthly
        orders_monthly = Order.objects.filter(
            is_active=True,
            date_ordered__gte=cutoff_date.date()
        ).annotate(
            month=TruncMonth('date_ordered')
        ).values('month').annotate(
            total=Sum('total_amount')
        ).order_by('month')
        
        # Combine
        monthly_data = {}
        
        for item in sales_monthly:
            if not item['month']: continue
            m_key = item['month'].strftime('%Y-%m')
            monthly_data[m_key] = {
                'month': item['month'].strftime('%b %Y'),
                'revenue': float(item['total'] or 0),
                'sales': float(item['total'] or 0),
                'rentals': 0.0
            }
            
        for item in orders_monthly:
            if not item['month']: continue
            m_key = item['month'].strftime('%Y-%m')
            if m_key in monthly_data:
                monthly_data[m_key]['revenue'] += float(item['total'] or 0)
                monthly_data[m_key]['rentals'] += float(item['total'] or 0)
            else:
                monthly_data[m_key] = {
                    'month': item['month'].strftime('%b %Y'),
                    'revenue': float(item['total'] or 0),
                    'sales': 0.0,
                    'rentals': float(item['total'] or 0)
                }
                
        # Sort by month key
        sorted_results = [monthly_data[k] for k in sorted(monthly_data.keys())]
        
        return Response({'success': True, 'data': sorted_results})
    except Exception as e:
        import traceback
        logger.error(f"Monthly revenue report error: {str(e)}")
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def business_performance(request):
    """Overall business performance analysis dashboard data"""
    try:
        from expenses.models import Expense
        from returns.models import RentalReturn
        from django.db.models import Sum
        
        # Life-time total revenue
        total_sales = Sales.objects.filter(is_active=True).aggregate(Sum('grand_total'))['grand_total__sum'] or 0
        total_orders = Order.objects.filter(is_active=True).aggregate(Sum('total_amount'))['total_amount__sum'] or 0
        total_rev = float(total_sales) + float(total_orders)
        
        # Life-time total expenses
        total_expenses = Expense.objects.filter(is_active=True).aggregate(Sum('amount'))['amount__sum'] or 0
        
        # Damage and Recovery
        returns_stats = RentalReturn.objects.aggregate(
            total_damage=Sum('damage_charges'),
            total_recovered=Sum('damage_recovered')
        )
        total_damage = float(returns_stats['total_damage'] or 0)
        total_recovered = float(returns_stats['total_recovered'] or 0)
        
        # Efficiency
        orders_count = Order.objects.filter(is_active=True).count()
        sales_count = Sales.objects.filter(is_active=True).count()
        total_transactions = orders_count + sales_count
        
        summary = {
            'total_revenue': total_rev,
            'total_expenses': float(total_expenses),
            'net_cash_flow': total_rev - float(total_expenses),
            'damage_loss': total_damage - total_recovered,
            'recovery_rate': round((total_recovered / total_damage * 100) if total_damage > 0 else 0, 1),
            'average_order_value': round(total_rev / total_transactions if total_transactions > 0 else 0, 0),
            'total_transactions': total_transactions
        }
        
        return Response({'success': True, 'data': summary})
    except Exception as e:
        import traceback
        logger.error(f"Business performance analysis error: {str(e)}")
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def reminders(request):
    """
    Get reminders for dashboard:
    - Dispatch reminders (expected_delivery_date)
    - Return reminders (return_date)
    - Upcoming events (event_date)
    - Dues reminders (Invoice due_date)
    """
    try:
        from orders.models import Order
        from sales.models import Invoice
        from django.db.models import Q
        
        today = timezone.now().date()
        next_3_days = today + timedelta(days=3)
        
        # 1. Dispatch Reminders
        dispatches = Order.objects.filter(
            is_active=True,
            status__in=['PENDING', 'CONFIRMED', 'READY'],
            expected_delivery_date__range=[today, next_3_days]
        ).order_by('expected_delivery_date')
        
        # 2. Return Reminders
        returns = Order.objects.filter(
            is_active=True,
            status='DELIVERED',
            return_date__range=[today, next_3_days]
        ).order_by('return_date')
        
        # 3. Upcoming Events
        events = Order.objects.filter(
            is_active=True,
            status__in=['PENDING', 'CONFIRMED', 'READY', 'DELIVERED'],
            event_date__range=[today, next_3_days]
        ).order_by('event_date')
        
        # 4. Dues Reminders
        dues = Invoice.objects.filter(
            is_active=True,
            status__in=['ISSUED', 'PARTIALLY_PAID', 'OVERDUE'],
            amount_due__gt=0,
            due_date__range=[today, next_3_days]
        ).order_by('due_date')
        
        def get_date(dt):
            if not dt: return None
            return dt.date() if hasattr(dt, 'date') else dt

        reminder_list = []

        for d in dispatches:
            reminder_list.append({
                'type': 'DISPATCH',
                'title': f"Dispatch: {d.customer_name}",
                'subtitle': f"Order for {d.event_name or 'unnamed event'}",
                'date': d.expected_delivery_date.isoformat(),
                'id': str(d.id),
                'priority': 'HIGH' if get_date(d.expected_delivery_date) == today else 'MEDIUM'
            })
            
        for r in returns:
            reminder_list.append({
                'type': 'RETURN',
                'title': f"Return: {r.customer_name}",
                'subtitle': f"Event: {r.event_name or 'N/A'}",
                'date': r.return_date.isoformat(),
                'id': str(r.id),
                'priority': 'HIGH' if get_date(r.return_date) == today else 'MEDIUM'
            })
            
        for e in events:
            reminder_list.append({
                'type': 'EVENT',
                'title': f"Event: {e.event_name}",
                'subtitle': f"Customer: {e.customer_name}",
                'date': e.event_date.isoformat(),
                'id': str(e.id),
                'priority': 'MEDIUM'
            })
            
        for d in dues:
            reminder_list.append({
                'type': 'DUE',
                'title': f"Due: {d.amount_due} PKR",
                'subtitle': f"Invoice: {d.invoice_number} - {d.sale.customer_name if d.sale else 'N/A'}",
                'date': d.due_date.isoformat(),
                'id': str(d.id),
                'priority': 'CRITICAL' if get_date(d.due_date) < today else 'HIGH'
            })
            
        # Sort all reminders by date
        reminder_list.sort(key=lambda x: x['date'])
            
        return Response({
            'success': True,
            'data': reminder_list
        })
    except Exception as e:
        import traceback
        logger.error(f"Reminders loading error: {str(e)}")
        return Response({'success': False, 'message': str(e), 'debug': traceback.format_exc()}, status=500)