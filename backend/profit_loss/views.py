from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Sum, Count, Q, F, DecimalField
from django.utils import timezone
from django.core.exceptions import ValidationError
from decimal import Decimal
from datetime import date, timedelta
import calendar

from .models import ProfitLossRecord, ProfitLossCalculation
from .serializers import (
    ProfitLossRecordSerializer,
    ProfitLossCalculationSerializer,
    ProfitLossCalculationRequestSerializer,
    ProfitLossSummarySerializer,
    ProfitLossComparisonSerializer,
    ProductProfitabilitySerializer
)


class ProfitLossCalculationView(APIView):
    """View for calculating and retrieving profit and loss data"""
    
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Calculate profit and loss for a specific period"""
        serializer = ProfitLossCalculationRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Get calculation parameters
            start_date = serializer.validated_data['start_date']
            end_date = serializer.validated_data['end_date']
            period_type = serializer.validated_data['period_type']
            include_calculations = serializer.validated_data.get('include_calculations', True)
            calculation_notes = serializer.validated_data.get('calculation_notes', '')
            
            # Check if record already exists
            existing_record = ProfitLossRecord.objects.filter(
                period_type=period_type,
                start_date=start_date,
                end_date=end_date,
                is_active=True
            ).first()
            
            if existing_record:
                # Return existing record
                record_serializer = ProfitLossRecordSerializer(existing_record)
                return Response({
                    'message': 'Profit and loss record already exists for this period',
                    'record': record_serializer.data
                }, status=status.HTTP_200_OK)
            
            # Calculate profit and loss
            profit_loss_data = self._calculate_profit_loss(start_date, end_date)
            
            # Extract values from profit_loss_data
            total_sales_income = profit_loss_data['total_sales_income']
            total_cost_of_goods_sold = profit_loss_data['total_cost_of_goods_sold']
            total_labor_payments = profit_loss_data['total_labor_payments']
            total_vendor_payments = profit_loss_data['total_vendor_payments']
            total_expenses = profit_loss_data['total_expenses']
            total_zakat = profit_loss_data['total_zakat']
            total_expenses_calculated = total_expenses  # Assuming this is the correct value
            total_products_sold = profit_loss_data['total_products_sold']
            average_order_value = profit_loss_data['average_order_value']
            
            # Create profit loss record
            profit_loss_record = ProfitLossRecord.objects.create(
                period_type=period_type,
                start_date=start_date,
                end_date=end_date,
                total_sales_income=total_sales_income,
                total_cost_of_goods_sold=total_cost_of_goods_sold,
                total_labor_payments=total_labor_payments,
                total_vendor_payments=total_vendor_payments,
                total_expenses=total_expenses,
                total_zakat=total_zakat,
                total_expenses_calculated=total_expenses_calculated,
                total_products_sold=total_products_sold,
                average_order_value=average_order_value,
                calculation_notes=calculation_notes,
                created_by=request.user
            )
            
            # Create calculation records if requested
            if include_calculations:
                self._create_calculation_records(profit_loss_record, profit_loss_data)
            
            # Return the created record
            record_serializer = ProfitLossRecordSerializer(profit_loss_record)
            return Response({
                'message': 'Profit and loss calculation completed successfully',
                'record': record_serializer.data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'error': f'Error calculating profit and loss: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def _calculate_profit_loss(self, start_date, end_date):
        """Calculate profit and loss for the given period"""
        from sales.models import Sales
        from payments.models import Payment
        from expenses.models import Expense
        from zakats.models import Zakat
        
        # Calculate sales income
        sales_data = Sales.objects.filter(
            date_of_sale__date__range=[start_date, end_date],
            is_active=True
        ).aggregate(
            total_income=Sum('grand_total'),
            total_count=Count('id'),
            total_products=Sum('sale_items__quantity')
        )
        
        # Validate sales data - allow zero but not negative
        if sales_data['total_income'] is not None and sales_data['total_income'] < 0:
            raise ValidationError("Invalid sales income data detected. Please check sales records.")
        
        total_sales_income = sales_data['total_income'] or Decimal('0.00')
        total_sales_count = sales_data['total_count'] or 0
        total_products_sold = sales_data['total_products'] or 0
        
        # Calculate Cost of Goods Sold (COGS)
        from sales.models import SaleItem
        from django.db.models import F, Q
        try:
            cogs_data = SaleItem.objects.filter(
                sale__date_of_sale__date__range=[start_date, end_date],
                sale__is_active=True,
                is_active=True,
                product__cost_price__isnull=False,  # Only include products with cost prices
                product__cost_price__gt=0  # Only include products with positive cost prices
            ).select_related('product').aggregate(
                total_cost=Sum(
                    F('product__cost_price') * F('quantity'),
                    output_field=DecimalField(max_digits=15, decimal_places=2)
                )
            )
            total_cost_of_goods_sold = cogs_data['total_cost'] or Decimal('0.00')
        except Exception as e:
            # Log error but continue with zero COGS
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error calculating COGS: {str(e)}")
            total_cost_of_goods_sold = Decimal('0.00')
        
        # Log warning if products without cost prices are found
        products_without_cost = SaleItem.objects.filter(
            sale__date_of_sale__date__range=[start_date, end_date],
            sale__is_active=True,
            is_active=True
        ).filter(
            Q(product__cost_price__isnull=True) | Q(product__cost_price=0)
        ).count()
        
        if products_without_cost > 0:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(
                f"Found {products_without_cost} sale items without cost prices in period {start_date} to {end_date}. "
                "These items are excluded from COGS calculation."
            )
        
        # Calculate average order value - handle division by zero
        try:
            average_order_value = (
                total_sales_income / total_sales_count if total_sales_count > 0 
                else Decimal('0.00')
            )
            # Round to 2 decimal places and cap to prevent overflow
            average_order_value = average_order_value.quantize(Decimal('0.01'))
            average_order_value = min(average_order_value, Decimal('9999999999.99'))
        except (ZeroDivisionError, TypeError):
            average_order_value = Decimal('0.00')
        
        # Calculate labor payments
        labor_payments = Payment.objects.filter(
            date__range=[start_date, end_date],
            payer_type='LABOR',
            is_active=True
        ).aggregate(total=Sum('amount_paid'))
        total_labor_payments = labor_payments['total'] or Decimal('0.00')
        
        # Validate labor payments
        if total_labor_payments < 0:
            raise ValidationError("Labor payments cannot be negative. Please check payment records.")
        
        # Calculate vendor payments
        vendor_payments = Payment.objects.filter(
            date__range=[start_date, end_date],
            payer_type='VENDOR',
            is_active=True
        ).aggregate(total=Sum('amount_paid'))
        total_vendor_payments = vendor_payments['total'] or Decimal('0.00')
        
        # Validate vendor payments
        if total_vendor_payments < 0:
            raise ValidationError("Vendor payments cannot be negative. Please check payment records.")
        
        # Calculate other expenses
        expenses = Expense.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        ).aggregate(total=Sum('amount'))
        total_expenses = expenses['total'] or Decimal('0.00')
        
        # Validate expenses
        if total_expenses < 0:
            raise ValidationError("Expenses cannot be negative. Please check expense records.")
        
        # Calculate zakat
        zakat = Zakat.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        ).aggregate(total=Sum('amount'))
        total_zakat = zakat['total'] or Decimal('0.00')
        
        # Validate zakat
        if total_zakat < 0:
            raise ValidationError("Zakat amounts cannot be negative. Please check zakat records.")
        
        return {
            'total_sales_income': total_sales_income,
            'total_cost_of_goods_sold': total_cost_of_goods_sold,
            'total_labor_payments': total_labor_payments,
            'total_vendor_payments': total_vendor_payments,
            'total_expenses': total_expenses,
            'total_zakat': total_zakat,
            'total_products_sold': total_products_sold,
            'average_order_value': average_order_value,
            'source_records': {
                'sales_count': total_sales_count,
                'labor_payments_count': Payment.objects.filter(
                    date__range=[start_date, end_date],
                    payer_type='LABOR',
                    is_active=True
                ).count(),
                'vendor_payments_count': Payment.objects.filter(
                    date__range=[start_date, end_date],
                    payer_type='VENDOR',
                    is_active=True
                ).count(),
                'expenses_count': Expense.objects.filter(
                    date__range=[start_date, end_date],
                    is_active=True
                ).count(),
                'zakat_count': Zakat.objects.filter(
                    date__range=[start_date, end_date],
                    is_active=True
                ).count()
            }
        }
    
    def _create_calculation_records(self, profit_loss_record, profit_loss_data):
        """Create detailed calculation records"""
        from sales.models import Sales
        from payments.models import Payment
        from expenses.models import Expense
        from zakats.models import Zakat

        calculations = []
        
        # Sales income calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='SALES_INCOME',
            source_model='Sales',
            source_count=profit_loss_data['source_records']['sales_count'],
            source_total=profit_loss_data['total_sales_income'],
            calculation_details={
                'period_start': profit_loss_record.start_date.isoformat(),
                'period_end': profit_loss_record.end_date.isoformat(),
                'total_products_sold': profit_loss_data['total_products_sold'],
                'average_order_value': float(profit_loss_data['average_order_value'])
            },
            calculation_notes='Income from sales.grand_total'
        ))
        
        # Labor payments calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='LABOR_PAYMENTS',
            source_model='Payment',
            source_count=profit_loss_data['source_records']['labor_payments_count'],
            source_total=profit_loss_data['total_labor_payments'],
            calculation_details={
                'payer_type': 'LABOR',
                'payment_methods': list(Payment.objects.filter(
                    date__range=[profit_loss_record.start_date, profit_loss_record.end_date],
                    payer_type='LABOR',
                    is_active=True
                ).values_list('payment_method', flat=True).distinct())
            },
            calculation_notes='Payments to labor'
        ))
        
        # Vendor payments calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='VENDOR_PAYMENTS',
            source_model='Payment',
            source_count=profit_loss_data['source_records']['vendor_payments_count'],
            source_total=profit_loss_data['total_vendor_payments'],
            calculation_details={
                'payer_type': 'VENDOR',
                'payment_methods': list(Payment.objects.filter(
                    date__range=[profit_loss_record.start_date, profit_loss_record.end_date],
                    payer_type='VENDOR',
                    is_active=True
                ).values_list('payment_method', flat=True).distinct())
            },
            calculation_notes='Payments to vendors'
        ))
        
        # Expenses calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='EXPENSES',
            source_model='Expense',
            source_count=profit_loss_data['source_records']['expenses_count'],
            source_total=profit_loss_data['total_expenses'],
            calculation_details={
                'expense_categories': list(Expense.objects.filter(
                    date__range=[profit_loss_record.start_date, profit_loss_record.end_date],
                    is_active=True
                ).values_list('category', flat=True).distinct())
            },
            calculation_notes='Other business expenses'
        ))
        
        # Zakat calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='ZAKAT',
            source_model='Zakat',
            source_count=profit_loss_data['source_records']['zakat_count'],
            source_total=profit_loss_data['total_zakat'],
            calculation_details={
                'beneficiaries': list(Zakat.objects.filter(
                    date__range=[profit_loss_record.start_date, profit_loss_record.end_date],
                    is_active=True
                ).values_list('beneficiary_name', flat=True).distinct())
            },
            calculation_notes='Zakat payments'
        ))
        
        # Profit calculation
        calculations.append(ProfitLossCalculation(
            profit_loss_record=profit_loss_record,
            calculation_type='PROFIT_CALCULATION',
            source_model='Calculated',
            source_count=1,
            source_total=profit_loss_record.net_profit,
            calculation_details={
                'formula': 'Profit = Total Sales Income - (Labor Payments + Vendor Payments + Other Expenses + Zakat)',
                'calculation': {
                    'sales_income': float(profit_loss_data['total_sales_income']),
                    'total_expenses': float(profit_loss_data['total_labor_payments'] + 
                                         profit_loss_data['total_vendor_payments'] + 
                                         profit_loss_data['total_expenses'] + 
                                         profit_loss_data['total_zakat']),
                    'net_profit': float(profit_loss_record.net_profit),
                    'profit_margin': float(profit_loss_record.profit_margin_percentage)
                }
            },
            calculation_notes='Net profit calculation'
        ))
        
        # Bulk create all calculations
        ProfitLossCalculation.objects.bulk_create(calculations)


class ProfitLossRecordListView(generics.ListAPIView):
    """View for listing profit and loss records"""
    
    permission_classes = [IsAuthenticated]
    serializer_class = ProfitLossRecordSerializer
    queryset = ProfitLossRecord.objects.filter(is_active=True)
    
    def get_queryset(self):
        """Filter queryset based on query parameters"""
        queryset = super().get_queryset()
        
        # Filter by period type
        period_type = self.request.query_params.get('period_type')
        if period_type:
            queryset = queryset.filter(period_type=period_type)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        if start_date:
            queryset = queryset.filter(start_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(end_date__lte=end_date)
        
        # Filter by profitability
        is_profitable = self.request.query_params.get('is_profitable')
        if is_profitable is not None:
            if is_profitable.lower() == 'true':
                queryset = queryset.filter(net_profit__gt=0)
            else:
                queryset = queryset.filter(net_profit__lte=0)
        
        return queryset


class ProfitLossRecordDetailView(generics.RetrieveAPIView):
    """View for retrieving a specific profit and loss record"""
    
    permission_classes = [IsAuthenticated]
    serializer_class = ProfitLossRecordSerializer
    queryset = ProfitLossRecord.objects.filter(is_active=True)
    lookup_field = 'id'


class ProfitLossSummaryView(APIView):
    """View for getting profit and loss summary for different periods"""
    
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get profit and loss summary for different periods"""
        try:
            # Get period type from query params
            period_type = request.query_params.get('period_type', 'MONTHLY')
            
            if period_type == 'CURRENT_MONTH':
                summary = self._get_current_month_summary()
            elif period_type == 'CURRENT_YEAR':
                summary = self._get_current_year_summary()
            elif period_type == 'LAST_30_DAYS':
                summary = self._get_last_30_days_summary()
            elif period_type == 'LAST_90_DAYS':
                summary = self._get_last_90_days_summary()
            else:
                return Response({
                    'error': f'Unsupported period type: {period_type}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            serializer = ProfitLossSummarySerializer(summary)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f'Error getting summary: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def _get_current_month_summary(self):
        """Get summary for current month"""
        today = date.today()
        start_date = date(today.year, today.month, 1)
        end_date = date(today.year, today.month, calendar.monthrange(today.year, today.month)[1])
        
        return self._calculate_summary(start_date, end_date, 'MONTHLY')
    
    def _get_current_year_summary(self):
        """Get summary for current year"""
        today = date.today()
        start_date = date(today.year, 1, 1)
        end_date = date(today.year, 12, 31)
        
        return self._calculate_summary(start_date, end_date, 'YEARLY')
    
    def _get_last_30_days_summary(self):
        """Get summary for last 30 days"""
        end_date = date.today()
        start_date = end_date - timedelta(days=30)
        
        return self._calculate_summary(start_date, end_date, 'CUSTOM')
    
    def _get_last_90_days_summary(self):
        """Get summary for last 90 days"""
        end_date = date.today()
        start_date = end_date - timedelta(days=90)
        
        return self._calculate_summary(start_date, end_date, 'CUSTOM')
    
    def _calculate_summary(self, start_date, end_date, period_type):
        """Calculate summary for the given period"""
        from sales.models import Sales
        from payments.models import Payment
        from expenses.models import Expense
        from zakats.models import Zakat
        
        # Calculate sales income
        sales_data = Sales.objects.filter(
            date_of_sale__date__range=[start_date, end_date],
            is_active=True
        ).aggregate(
            total_income=Sum('grand_total'),
            total_count=Count('id'),
            total_products=Sum('sale_items__quantity')
        )
        
        total_sales_income = sales_data['total_income'] or Decimal('0.00')
        total_sales_count = sales_data['total_count'] or 0
        total_products_sold = sales_data['total_products'] or 0
        
        # Calculate average order value
        average_order_value = (
            total_sales_income / total_sales_count if total_sales_count > 0 
            else Decimal('0.00')
        )
        
        # Calculate expenses
        total_labor_payments = Payment.objects.filter(
            date__range=[start_date, end_date],
            payer_type='LABOR',
            is_active=True
        ).aggregate(total=Sum('amount_paid'))['total'] or Decimal('0.00')
        
        total_vendor_payments = Payment.objects.filter(
            date__range=[start_date, end_date],
            payer_type='VENDOR',
            is_active=True
        ).aggregate(total=Sum('amount_paid'))['total'] or Decimal('0.00')
        
        total_expenses = Expense.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        total_zakat = Zakat.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        # Calculate totals
        total_expenses_calculated = (
            total_labor_payments + total_vendor_payments + total_expenses + total_zakat
        )
        net_profit = total_sales_income - total_expenses_calculated
        profit_margin_percentage = (
            (net_profit / total_sales_income * 100) if total_sales_income > 0 
            else Decimal('0.00')
        )
        
        return {
            'period_info': {
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'period_type': period_type
            },
            'total_sales_income': total_sales_income,
            'total_products_sold': total_products_sold,
            'average_order_value': average_order_value,
            'total_labor_payments': total_labor_payments,
            'total_vendor_payments': total_vendor_payments,
            'total_expenses': total_expenses,
            'total_zakat': total_zakat,
            'total_expenses_calculated': total_expenses_calculated,
            'net_profit': net_profit,
            'profit_margin_percentage': profit_margin_percentage,
            'is_profitable': net_profit > 0,
            'formatted_total_sales_income': f"PKR {total_sales_income:,.2f}",
            'formatted_total_expenses': f"PKR {total_expenses_calculated:,.2f}",
            'formatted_net_profit': f"PKR {net_profit:,.2f}",
            'formatted_profit_margin': f"{profit_margin_percentage:.2f}%",
            'calculation_timestamp': timezone.now().isoformat(),
            'source_records_count': {
                'sales': total_sales_count,
                'labor_payments': Payment.objects.filter(
                    date__range=[start_date, end_date],
                    payer_type='LABOR',
                    is_active=True
                ).count(),
                'vendor_payments': Payment.objects.filter(
                    date__range=[start_date, end_date],
                    payer_type='VENDOR',
                    is_active=True
                ).count(),
                'expenses': Expense.objects.filter(
                    date__range=[start_date, end_date],
                    is_active=True
                ).count(),
                'zakat': Zakat.objects.filter(
                    date__range=[start_date, end_date],
                    is_active=True
                ).count()
            }
        }


class ProductProfitabilityView(APIView):
    """View for analyzing product-level profitability"""
    
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get product profitability analysis"""
        try:
            # Get period from query params
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            
            if not start_date or not end_date:
                # Default to current month
                today = date.today()
                start_date = date(today.year, today.month, 1)
                end_date = date(today.year, today.month, calendar.monthrange(today.year, today.month)[1])
            else:
                start_date = date.fromisoformat(start_date)
                end_date = date.fromisoformat(end_date)
            
            # Get product profitability data
            product_profitability = self._get_product_profitability(start_date, end_date)
            
            # Serialize and return
            serializer = ProductProfitabilitySerializer(product_profitability, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Product.DoesNotExist:
            return Response({
                'error': 'One or more products in this analysis was not found.'
            }, status=status.HTTP_404_NOT_FOUND)

        except Exception as e:
            return Response({
                'error': f'Error getting product profitability: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def _get_product_profitability(self, start_date, end_date):
        """Get profitability data for all products in the period"""
        from sales.models import SaleItem
        from products.models import Product
        
        # Get all products with sales in the period
        products_with_sales = SaleItem.objects.filter(
            sale__date_of_sale__date__range=[start_date, end_date],
            sale__is_active=True,
            is_active=True
        ).values('product').distinct()
        
        product_profitability = []
        
        for product_data in products_with_sales:
            product_id = product_data['product']
            product = Product.objects.get(id=product_id)
            
            # Get sales data for this product
            sale_items = SaleItem.objects.filter(
                product=product,
                sale__date_of_sale__date__range=[start_date, end_date],
                sale__is_active=True,
                is_active=True
            )
            
            # Calculate metrics
            units_sold = sale_items.aggregate(total=Sum('quantity'))['total'] or 0
            total_revenue = sale_items.aggregate(total=Sum('line_total'))['total'] or Decimal('0.00')
            average_sale_price = (
                total_revenue / units_sold if units_sold > 0 
                else Decimal('0.00')
            )
            
            # Calculate cost and profit
            cost_price = product.cost_price or Decimal('0.00')
            total_cost = cost_price * units_sold
            gross_profit = total_revenue - total_cost
            profit_margin = (
                (gross_profit / total_revenue * 100) if total_revenue > 0 
                else Decimal('0.00')
            )
            
            product_profitability.append({
                'product_id': product.id,
                'product_name': product.name,
                'product_category': product.category.name if product.category else 'Uncategorized',
                'units_sold': units_sold,
                'total_revenue': total_revenue,
                'average_sale_price': average_sale_price,
                'cost_price': cost_price,
                'total_cost': total_cost,
                'gross_profit': gross_profit,
                'profit_margin': profit_margin,
                'formatted_total_revenue': f"PKR {total_revenue:,.2f}",
                'formatted_gross_profit': f"PKR {gross_profit:,.2f}",
                'formatted_profit_margin': f"{profit_margin:.2f}%",
                'is_profitable': gross_profit > 0,
                'profitability_rank': 0  # Will be set after sorting
            })
        
        # Sort by profitability and assign ranks
        product_profitability.sort(key=lambda x: x['gross_profit'], reverse=True)
        for i, product in enumerate(product_profitability):
            product['profitability_rank'] = i + 1
        
        return product_profitability


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profit_loss_dashboard(request):
    """Get comprehensive profit and loss dashboard data"""
    try:
        # Get current month summary
        today = date.today()
        current_month_start = date(today.year, today.month, 1)
        current_month_end = date(today.year, today.month, calendar.monthrange(today.year, today.month)[1])
        
        # Get previous month for comparison
        if today.month == 1:
            prev_month_start = date(today.year - 1, 12, 1)
            prev_month_end = date(today.year - 1, 12, 31)
        else:
            prev_month_start = date(today.year, today.month - 1, 1)
            prev_month_end = date(today.year, today.month - 1, calendar.monthrange(today.year, today.month - 1)[1])
        
        # Calculate current month data
        current_month_data = ProfitLossCalculationView()._calculate_profit_loss(
            current_month_start, current_month_end
        )
        
        # Calculate previous month data
        prev_month_data = ProfitLossCalculationView()._calculate_profit_loss(
            prev_month_start, prev_month_end
        )
        
        # Calculate growth percentages
        sales_growth = _calculate_growth_percentage(
            current_month_data['total_sales_income'],
            prev_month_data['total_sales_income']
        )
        
        expense_growth = _calculate_growth_percentage(
            current_month_data['total_labor_payments'] + 
            current_month_data['total_vendor_payments'] + 
            current_month_data['total_expenses'] + 
            current_month_data['total_zakat'],
            prev_month_data['total_labor_payments'] + 
            prev_month_data['total_vendor_payments'] + 
            prev_month_data['total_expenses'] + 
            prev_month_data['total_zakat']
        )
        
        # Calculate current month profit
        current_total_expenses = (
            current_month_data['total_labor_payments'] + 
            current_month_data['total_vendor_payments'] + 
            current_month_data['total_expenses'] + 
            current_month_data['total_zakat']
        )
        current_net_profit = current_month_data['total_sales_income'] - current_total_expenses
        
        # Calculate previous month profit
        prev_total_expenses = (
            prev_month_data['total_labor_payments'] + 
            prev_month_data['total_vendor_payments'] + 
            prev_month_data['total_expenses'] + 
            prev_month_data['total_zakat']
        )
        prev_net_profit = prev_month_data['total_sales_income'] - prev_total_expenses
        
        profit_growth = _calculate_growth_percentage(current_net_profit, prev_net_profit)
        
        # Determine trends
        sales_trend = _determine_trend(sales_growth)
        profit_trend = _determine_trend(profit_growth)
        
        dashboard_data = {
            'current_month': {
                'period': f"{current_month_start.strftime('%B %Y')}",
                'sales_income': float(current_month_data['total_sales_income']),
                'total_expenses': float(current_total_expenses),
                'net_profit': float(current_net_profit),
                'products_sold': current_month_data['total_products_sold'],
                'orders_count': current_month_data['source_records']['sales_count']
            },
            'previous_month': {
                'period': f"{prev_month_start.strftime('%B %Y')}",
                'sales_income': float(prev_month_data['total_sales_income']),
                'total_expenses': float(prev_total_expenses),
                'net_profit': float(prev_net_profit),
                'products_sold': prev_month_data['total_products_sold'],
                'orders_count': prev_month_data['source_records']['sales_count']
            },
            'growth_metrics': {
                'sales_growth': float(sales_growth),
                'expense_growth': float(expense_growth),
                'profit_growth': float(profit_growth)
            },
            'trends': {
                'sales_trend': sales_trend,
                'profit_trend': profit_trend
            },
            'expense_breakdown': {
                'labor_payments': float(current_month_data['total_labor_payments']),
                'vendor_payments': float(current_month_data['total_vendor_payments']),
                'other_expenses': float(current_month_data['total_expenses']),
                'zakat': float(current_month_data['total_zakat'])
            }
        }
        
        return Response(dashboard_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Error getting dashboard data: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _calculate_growth_percentage(current_value, previous_value):
    """Calculate growth percentage between two values"""
    if previous_value == 0:
        return Decimal('100.00') if current_value > 0 else Decimal('0.00')
    
    growth = ((current_value - previous_value) / previous_value) * 100
    return growth


def _determine_trend(growth_percentage):
    """Determine trend based on growth percentage"""
    if growth_percentage > 5:
        return 'increasing'
    elif growth_percentage < -5:
        return 'decreasing'
    else:
        return 'stable'
