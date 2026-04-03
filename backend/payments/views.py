from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Sum, Q
from .models import Payment
from .serializers import (
    PaymentSerializer,
    PaymentCreateSerializer,
    PaymentListSerializer,
    PaymentUpdateSerializer,
    PaymentDetailSerializer
)
from django.utils import timezone


# Function-based views (following your module pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_payments(request):
    """
    List all active payments with pagination and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)  # Max 100 items per page
        page = int(request.GET.get('page', 1))
        
        # Filter payments
        if show_inactive:
            payments = Payment.objects.all()
        else:
            payments = Payment.active_payments()
        
        # Apply filters
        payer_type = request.GET.get('payer_type', '').strip()
        if payer_type:
            payments = payments.filter(payer_type__iexact=payer_type)
        
        payment_method = request.GET.get('payment_method', '').strip()
        if payment_method:
            payments = payments.filter(payment_method__iexact=payment_method)
        
        labor_id = request.GET.get('labor_id', '').strip()
        if labor_id:
            payments = payments.filter(labor_id=labor_id)
        
        vendor_id = request.GET.get('vendor_id', '').strip()
        if vendor_id:
            payments = payments.filter(vendor_id=vendor_id)
        
        order_id = request.GET.get('order_id', '').strip()
        if order_id:
            payments = payments.filter(order_id=order_id)
        
        sale_id = request.GET.get('sale_id', '').strip()
        if sale_id:
            payments = payments.filter(sale_id=sale_id)
        
        is_final = request.GET.get('is_final_payment', '').strip()
        if is_final:
            if is_final.lower() == 'true':
                payments = payments.filter(is_final_payment=True)
            elif is_final.lower() == 'false':
                payments = payments.filter(is_final_payment=False)
        
        # Date range filter
        start_date = request.GET.get('start_date', '').strip()
        end_date = request.GET.get('end_date', '').strip()
        if start_date and end_date:
            payments = payments.filter(date__range=[start_date, end_date])
        
        # Amount range filter
        min_amount = request.GET.get('min_amount', '').strip()
        max_amount = request.GET.get('max_amount', '').strip()
        if min_amount:
            try:
                payments = payments.filter(amount_paid__gte=float(min_amount))
            except ValueError:
                pass
        if max_amount:
            try:
                payments = payments.filter(amount_paid__lte=float(max_amount))
            except ValueError:
                pass
        
        # Apply search filter if provided
        search = request.GET.get('search', '').strip()
        if search:
            payments = payments.search(search)
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                }
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_payment(request):
    """
    Create a new payment
    """
    serializer = PaymentCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                payment = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Payment created successfully.',
                    'data': PaymentSerializer(payment).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Payment creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Payment creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payment(request, payment_id):
    """
    Retrieve a specific payment by ID
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        serializer = PaymentDetailSerializer(payment)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_payment(request, payment_id):
    """
    Update a payment
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        
        serializer = PaymentUpdateSerializer(
            payment,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    payment = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Payment updated successfully.',
                        'data': PaymentSerializer(payment).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Payment update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Payment update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Payment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': 'Payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_payment(request, payment_id):
    """
    Hard delete a payment (permanently remove from database)
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        
        # Store payment info for response message
        payment_info = f"{payment.labor_name or payment.vendor} - {payment.formatted_amount}"
        
        # Permanently delete the payment
        payment.delete()
        
        return Response({
            'success': True,
            'message': f'Payment "{payment_info}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Payment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': 'Payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_payment(request, payment_id):
    """
    Soft delete a payment (set is_active=False)
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        
        if not payment.is_active:
            return Response({
                'success': False,
                'message': 'Payment is already inactive.',
                'errors': {'detail': 'This payment has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payment.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Payment soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Payment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': 'Payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_payment(request, payment_id):
    """
    Restore a soft-deleted payment (set is_active=True)
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        
        if payment.is_active:
            return Response({
                'success': False,
                'message': 'Payment is already active.',
                'errors': {'detail': 'This payment is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payment.restore()
        
        return Response({
            'success': True,
            'message': 'Payment restored successfully.',
            'data': PaymentSerializer(payment).data
        }, status=status.HTTP_200_OK)
        
    except Payment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': 'Payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payment_statistics(request):
    """
    Get comprehensive payment statistics
    """
    try:
        stats = Payment.get_statistics()
        
        return Response({
            'success': True,
            'data': stats
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve payment statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_as_final_payment(request, payment_id):
    """
    Mark payment as final payment
    """
    try:
        payment = Payment.objects.get(id=payment_id)
        
        if payment.is_final_payment:
            return Response({
                'success': False,
                'message': 'Payment is already marked as final.',
                'errors': {'detail': 'This payment is already marked as final payment.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payment.mark_as_final()
        
        return Response({
            'success': True,
            'message': 'Payment marked as final payment successfully.',
            'data': PaymentSerializer(payment).data
        }, status=status.HTTP_200_OK)
        
    except Payment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Payment not found.',
            'errors': {'detail': 'Payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to mark payment as final.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Additional view functions for the new endpoints

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_payments(request):
    """Search payments by query"""
    try:
        query = request.GET.get('q', '').strip()
        if not query:
            return Response({
                'success': False,
                'message': 'Search query is required.',
                'errors': {'query': 'Search query parameter is required.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payments = Payment.objects.search(query)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments matching "{query}"',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Search failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_labor(request, labor_id):
    """Get payments for a specific labor"""
    try:
        payments = Payment.objects.by_labor(labor_id)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments for labor',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by labor.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_vendor(request, vendor_id):
    """Get payments for a specific vendor"""
    try:
        payments = Payment.objects.by_vendor(vendor_id)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments for vendor',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by vendor.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_order(request, order_id):
    """Get payments for a specific order"""
    try:
        payments = Payment.objects.by_order(order_id)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments for order',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by order.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_sale(request, sale_id):
    """Get payments for a specific sale"""
    try:
        payments = Payment.objects.by_sale(sale_id)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments for sale',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by sale.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_date_range(request):
    """Get payments within a date range"""
    try:
        start_date = request.GET.get('start_date')
        end_date = request.GET.get('end_date')
        
        if not start_date or not end_date:
            return Response({
                'success': False,
                'message': 'Both start_date and end_date are required.',
                'errors': {'date_range': 'start_date and end_date parameters are required.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payments = Payment.objects.by_date_range(start_date, end_date)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments in date range',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by date range.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_by_method(request, method):
    """Get payments by payment method"""
    try:
        payments = Payment.objects.by_payment_method(method.upper())
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments with method {method}',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments by method.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_with_receipts(request):
    """Get payments that have receipt images"""
    try:
        payments = Payment.objects.with_receipts()
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments with receipts',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments with receipts.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_payments_without_receipts(request):
    """Get payments without receipt images"""
    try:
        payments = Payment.objects.without_receipts()
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments without receipts',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get payments without receipts.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_recent_payments(request):
    """Get recent payments (last 30 days)"""
    try:
        days = int(request.GET.get('days', 30))
        payments = Payment.objects.recent(days)
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} recent payments',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get recent payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_today_payments(request):
    """Get today's payments"""
    try:
        payments = Payment.objects.today()
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments today',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get today\'s payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_this_month_payments(request):
    """Get this month's payments"""
    try:
        payments = Payment.objects.this_month()
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments this month',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get this month\'s payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_this_year_payments(request):
    """Get this year's payments"""
    try:
        payments = Payment.objects.this_year()
        serializer = PaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'message': f'Found {payments.count()} payments this year',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get this year\'s payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Class-based views (DRF standard approach)

class PaymentListCreateAPIView(generics.ListCreateAPIView):
    """Class-based view for listing and creating payments"""
    
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get queryset based on parameters"""
        show_inactive = self.request.GET.get('show_inactive', 'false').lower() == 'true'
        queryset = Payment.objects.all() if show_inactive else Payment.active_payments()
        
        # Apply filters
        payer_type = self.request.GET.get('payer_type', '').strip()
        if payer_type:
            queryset = queryset.filter(payer_type__iexact=payer_type)
        
        payment_method = self.request.GET.get('payment_method', '').strip()
        if payment_method:
            queryset = queryset.filter(payment_method__iexact=payment_method)
        
        search = self.request.GET.get('search', '').strip()
        if search:
            queryset = queryset.search(search)
        
        return queryset.order_by('-date', '-time')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.request.method == 'POST':
            return PaymentCreateSerializer
        return PaymentListSerializer
    
    def create(self, request, *args, **kwargs):
        """Custom create method with consistent response format"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payment = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Payment created successfully.',
            'data': PaymentSerializer(payment).data
        }, status=status.HTTP_201_CREATED)


class PaymentRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Class-based view for retrieving, updating, and deleting payments"""
    
    queryset = Payment.objects.all()
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    lookup_url_kwarg = 'payment_id'
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.request.method in ['PUT', 'PATCH']:
            return PaymentUpdateSerializer
        return PaymentDetailSerializer
    
    def update(self, request, *args, **kwargs):
        """Custom update method with consistent response format"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        payment = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Payment updated successfully.',
            'data': PaymentSerializer(payment).data
        }, status=status.HTTP_200_OK)
    
    def destroy(self, request, *args, **kwargs):
        """Custom delete method for hard deletion"""
        instance = self.get_object()
        payment_info = f"{instance.labor_name or instance.vendor} - {instance.formatted_amount}"
        
        # Permanently delete
        instance.delete()
        
        return Response({
            'success': True,
            'message': f'Payment "{payment_info}" deleted permanently.'
        }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def process_payment(request):
    """
    Process payment for a sale
    """
    try:
        sale_id = request.data.get('sale_id')
        amount = request.data.get('amount')
        payment_method = request.data.get('payment_method')
        currency = request.data.get('currency', 'PKR')
        reference = request.data.get('reference')
        notes = request.data.get('notes')
        metadata = request.data.get('metadata', {})
        
        if not all([sale_id, amount, payment_method]):
            return Response({
                'success': False,
                'message': 'Missing required fields: sale_id, amount, payment_method'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate amount
        try:
            amount = float(amount)
            if amount <= 0:
                return Response({
                    'success': False,
                    'message': 'Amount must be greater than zero'
                }, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, TypeError):
            return Response({
                'success': False,
                'message': 'Invalid amount format'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create payment record
        from sales.models import Sales
        try:
            sale = Sales.objects.get(id=sale_id, is_active=True)
        except Sales.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Sale not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Create payment
        payment = Payment.objects.create(
            sale=sale,
            payer_type='CUSTOMER',
            payer_id=sale.customer.id,
            amount_paid=amount,
            payment_month=timezone.now().date(),
            payment_method=payment_method.upper(),
            description=notes or f'Payment for sale {sale.invoice_number}',
            date=timezone.now().date(),
            time=timezone.now().time(),
            created_by=request.user
        )
        
        # Update sale payment status
        sale.amount_paid += amount
        sale.remaining_amount = max(0, sale.grand_total - sale.amount_paid)
        sale.is_fully_paid = sale.remaining_amount == 0
        sale.save()
        
        return Response({
            'success': True,
            'message': 'Payment processed successfully',
            'data': {
                'payment_id': str(payment.id),
                'sale_id': str(sale.id),
                'amount_paid': float(amount),
                'remaining_amount': float(sale.remaining_amount),
                'is_fully_paid': sale.is_fully_paid,
                'reference': reference,
                'metadata': metadata
            }
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to process payment: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def process_split_payment(request):
    """
    Process split payment for a sale
    """
    try:
        sale_id = request.data.get('sale_id')
        split_details = request.data.get('split_details', [])
        currency = request.data.get('currency', 'PKR')
        reference = request.data.get('reference')
        notes = request.data.get('notes')
        
        if not sale_id or not split_details:
            return Response({
                'success': False,
                'message': 'Missing required fields: sale_id, split_details'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate split details
        total_amount = 0
        for split in split_details:
            if not all(k in split for k in ['amount', 'payment_method']):
                return Response({
                    'success': False,
                    'message': 'Each split must have amount and payment_method'
                }, status=status.HTTP_400_BAD_REQUEST)
            try:
                amount = float(split['amount'])
                if amount <= 0:
                    return Response({
                        'success': False,
                        'message': 'Split amounts must be greater than zero'
                    }, status=status.HTTP_400_BAD_REQUEST)
                total_amount += amount
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid amount format in split details'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get sale
        from sales.models import Sales
        try:
            sale = Sales.objects.get(id=sale_id, is_active=True)
        except Sales.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Sale not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Validate total amount
        if abs(total_amount - float(sale.grand_total)) > 0.01:  # Allow small rounding differences
            return Response({
                'success': False,
                'message': f'Split total ({total_amount}) must equal sale total ({sale.grand_total})'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create payments for each split
        created_payments = []
        for split in split_details:
            payment = Payment.objects.create(
                sale=sale,
                payer_type='CUSTOMER',
                payer_id=sale.customer.id,
                amount_paid=split['amount'],
                payment_month=timezone.now().date(),
                payment_method=split['payment_method'].upper(),
                description=notes or f'Split payment for sale {sale.invoice_number}',
                date=timezone.now().date(),
                time=timezone.now().time(),
                created_by=request.user
            )
            created_payments.append({
                'payment_id': str(payment.id),
                'amount': split['amount'],
                'payment_method': split['payment_method']
            })
        
        # Update sale payment status
        sale.amount_paid = total_amount
        sale.remaining_amount = 0
        sale.is_fully_paid = True
        sale.payment_method = 'SPLIT'
        sale.save()
        
        return Response({
            'success': True,
            'message': 'Split payment processed successfully',
            'data': {
                'sale_id': str(sale.id),
                'total_amount': total_amount,
                'payments': created_payments,
                'reference': reference,
                'metadata': {'currency': currency}
            }
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to process split payment: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
