from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, Sum, Count
from decimal import Decimal

from .models import Return, ReturnItem, Refund, Sales, SaleItem
from .return_serializers import (
    ReturnSerializer, ReturnCreateSerializer, ReturnUpdateSerializer, ReturnListSerializer,
    ReturnItemSerializer, RefundSerializer, RefundCreateSerializer, RefundUpdateSerializer, RefundListSerializer
)


class ReturnListView(generics.ListCreateAPIView):
    """List and create returns"""
    permission_classes = [IsAuthenticated]
    serializer_class = ReturnListSerializer
    
    def get_queryset(self):
        """Filter returns based on query parameters"""
        queryset = Return.objects.filter(is_active=True).select_related(
            'sale', 'customer', 'approved_by', 'processed_by', 'created_by'
        ).prefetch_related('return_items')
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter.upper())
        
        # Filter by customer
        customer_id = self.request.query_params.get('customer_id')
        if customer_id:
            queryset = queryset.filter(customer_id=customer_id)
        
        # Filter by sale
        sale_id = self.request.query_params.get('sale_id')
        if sale_id:
            queryset = queryset.filter(sale_id=sale_id)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            queryset = queryset.filter(return_date__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(return_date__date__lte=date_to)
        
        # Filter by reason
        reason = self.request.query_params.get('reason')
        if reason:
            queryset = queryset.filter(reason=reason.upper())
        
        return queryset.order_by('-return_date')
    
    def get_serializer_class(self):
        """Use different serializer for create vs list"""
        if self.request.method == 'POST':
            return ReturnCreateSerializer
        return ReturnListSerializer
    
    def create(self, request, *args, **kwargs):
        """Create return and return complete data"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return_obj = serializer.save(created_by=request.user)
        
        # Return the complete return data using ReturnListSerializer
        response_serializer = ReturnListSerializer(return_obj)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class ReturnDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete return"""
    permission_classes = [IsAuthenticated]
    queryset = Return.objects.filter(is_active=True).select_related(
        'sale', 'customer', 'approved_by', 'processed_by', 'created_by'
    ).prefetch_related('return_items')
    serializer_class = ReturnSerializer
    
    def get_serializer_class(self):
        """Use different serializer for update vs retrieve"""
        if self.request.method in ['PUT', 'PATCH']:
            return ReturnUpdateSerializer
        return ReturnSerializer
    
    def perform_update(self, serializer):
        """Set updated_by user"""
        serializer.save()
    
    def perform_destroy(self, instance):
        """Soft delete return"""
        instance.is_active = False
        instance.save()


class ReturnItemListView(generics.ListAPIView):
    """List return items for a specific return"""
    permission_classes = [IsAuthenticated]
    serializer_class = ReturnItemSerializer
    
    def get_queryset(self):
        """Get return items for specific return"""
        return_id = self.kwargs.get('pk')
        return ReturnItem.objects.filter(
            return_request_id=return_id, 
            is_active=True
        ).select_related('product', 'sale_item')


class ReturnApprovalView(generics.UpdateAPIView):
    """Approve or reject a return"""
    permission_classes = [IsAuthenticated]
    queryset = Return.objects.filter(is_active=True)
    serializer_class = ReturnSerializer
    
    def update(self, request, *args, **kwargs):
        """Handle return approval/rejection"""
        return_request = self.get_object()
        action = request.data.get('action')
        reason = request.data.get('reason')
        
        if action == 'approve':
            try:
                return_request.approve(request.user)
                return Response({
                    'message': 'Return approved successfully',
                    'status': return_request.status
                }, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        elif action == 'reject':
            try:
                return_request.reject(request.user, reason)
                return Response({
                    'message': 'Return rejected successfully',
                    'status': return_request.status
                }, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        elif action == 'cancel':
            try:
                return_request.cancel(request.user, reason)
                return Response({
                    'message': 'Return cancelled successfully',
                    'status': return_request.status
                }, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({
                    'error': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
        
        else:
            return Response({
                'error': 'Invalid action. Must be approve, reject, or cancel.'
            }, status=status.HTTP_400_BAD_REQUEST)


class ReturnProcessingView(generics.UpdateAPIView):
    """Process a return (mark as processed)"""
    permission_classes = [IsAuthenticated]
    queryset = Return.objects.filter(is_active=True)
    serializer_class = ReturnSerializer
    
    def update(self, request, *args, **kwargs):
        """Process the return"""
        return_request = self.get_object()
        refund_amount = request.data.get('refund_amount')
        refund_method = request.data.get('refund_method')
        
        try:
            return_request.process(request.user, refund_amount, refund_method)
            return Response({
                'message': 'Return processed successfully',
                'status': return_request.status,
                'refund_amount': return_request.refund_amount,
                'refund_method': return_request.refund_method
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class RefundListView(generics.ListCreateAPIView):
    """List and create refunds"""
    permission_classes = [IsAuthenticated]
    serializer_class = RefundListSerializer
    
    def get_queryset(self):
        """Filter refunds based on query parameters"""
        try:
            print(f"🔍 [RefundListView] Getting queryset...")
            queryset = Refund.objects.filter(is_active=True).select_related(
                'return_request', 'return_request__sale', 'return_request__customer',
                'processed_by', 'created_by'
            )
            print(f"🔍 [RefundListView] Base queryset count: {queryset.count()}")
            
            # Filter by status
            status_filter = self.request.query_params.get('status')
            if status_filter:
                queryset = queryset.filter(status=status_filter.upper())
            
            # Filter by return request
            return_id = self.request.query_params.get('return_id')
            if return_id:
                queryset = queryset.filter(return_request_id=return_id)
            
            # Filter by method
            method = self.request.query_params.get('method')
            if method:
                queryset = queryset.filter(method=method.upper())
            
            # Filter by date range
            date_from = self.request.query_params.get('date_from')
            date_to = self.request.query_params.get('date_to')
            if date_from:
                queryset = queryset.filter(created_at__date__gte=date_from)
            if date_to:
                queryset = queryset.filter(created_at__date__lte=date_to)
            
            result = queryset.order_by('-created_at')
            print(f"🔍 [RefundListView] Final queryset count: {result.count()}")
            return result
        except Exception as e:
            print(f"❌ [RefundListView] Error in get_queryset: {e}")
            import traceback
            traceback.print_exc()
            return Refund.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to add error handling"""
        try:
            print(f"🔍 [RefundListView] List method called")
            response = super().list(request, *args, **kwargs)
            print(f"✅ [RefundListView] List successful: {len(response.data.get('results', []))} items")
            print(f"🔍 [RefundListView] Response data: {response.data}")
            return response
        except Exception as e:
            print(f"❌ [RefundListView] Error in list: {e}")
            import traceback
            traceback.print_exc()
            from rest_framework.response import Response
            return Response({
                'success': False,
                'message': f'Error loading refunds: {str(e)}',
                'results': []
            }, status=200)  # Return 200 instead of 500 to prevent UI breaking
    
    def get_serializer_class(self):
        """Use different serializer for create vs list"""
        if self.request.method == 'POST':
            return RefundCreateSerializer
        return RefundListSerializer
    
    def perform_create(self, serializer):
        """Set created_by user"""
        serializer.save(created_by=self.request.user)


class RefundDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete refund"""
    permission_classes = [IsAuthenticated]
    queryset = Refund.objects.filter(is_active=True).select_related(
        'return_request', 'return_request__sale', 'return_request__customer',
        'processed_by', 'created_by'
    )
    serializer_class = RefundSerializer
    
    def get_serializer_class(self):
        """Use different serializer for update vs retrieve"""
        if self.request.method in ['PUT', 'PATCH']:
            return RefundUpdateSerializer
        return RefundSerializer
    
    def perform_update(self, serializer):
        """Set updated_by user"""
        serializer.save()
    
    def perform_destroy(self, instance):
        """Soft delete refund"""
        instance.is_active = False
        instance.save()


class RefundProcessingView(generics.UpdateAPIView):
    """Process a refund (mark as processed)"""
    permission_classes = [IsAuthenticated]
    queryset = Refund.objects.filter(is_active=True)
    serializer_class = RefundSerializer
    
    def update(self, request, *args, **kwargs):
        """Process the refund"""
        refund = self.get_object()
        reference_number = request.data.get('reference_number')
        
        try:
            refund.process(request.user, reference_number)
            return Response({
                'message': 'Refund processed successfully',
                'status': refund.status,
                'reference_number': refund.reference_number
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class RefundFailureView(generics.UpdateAPIView):
    """Mark a refund as failed"""
    permission_classes = [IsAuthenticated]
    queryset = Refund.objects.filter(is_active=True)
    serializer_class = RefundSerializer
    
    def update(self, request, *args, **kwargs):
        """Mark refund as failed"""
        refund = self.get_object()
        reason = request.data.get('reason')
        
        try:
            refund.fail(request.user, reason)
            return Response({
                'message': 'Refund marked as failed',
                'status': refund.status
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class RefundCancellationView(generics.UpdateAPIView):
    """Cancel a refund"""
    permission_classes = [IsAuthenticated]
    queryset = Refund.objects.filter(is_active=True)
    serializer_class = RefundSerializer
    
    def update(self, request, *args, **kwargs):
        """Cancel the refund"""
        refund = self.get_object()
        reason = request.data.get('reason')
        
        try:
            refund.cancel(request.user, reason)
            return Response({
                'message': 'Refund cancelled successfully',
                'status': refund.status
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def return_statistics(request):
    """Get return statistics"""
    try:
        # Total returns
        total_returns = Return.objects.filter(is_active=True).count()
        
        # Returns by status
        status_counts = Return.objects.filter(is_active=True).values('status').annotate(
            count=Count('id')
        )
        
        # Total return amount
        total_return_amount = Return.objects.filter(is_active=True).aggregate(
            total=Sum('refund_amount')
        )['total'] or Decimal('0.00')
        
        # Total refund amount
        total_refund_amount = Refund.objects.filter(
            is_active=True, 
            status='PROCESSED'
        ).aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        # Returns by reason
        reason_counts = Return.objects.filter(is_active=True).values('reason').annotate(
            count=Count('id')
        )
        
        # Recent returns (last 30 days)
        from django.utils import timezone
        from datetime import timedelta
        thirty_days_ago = timezone.now() - timedelta(days=30)
        recent_returns = Return.objects.filter(
            is_active=True,
            return_date__gte=thirty_days_ago
        ).count()
        
        return Response({
            'total_returns': total_returns,
            'status_distribution': list(status_counts),
            'total_return_amount': total_return_amount,
            'total_refund_amount': total_refund_amount,
            'reason_distribution': list(reason_counts),
            'recent_returns': recent_returns
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_return_history(request, customer_id):
    """Get return history for a specific customer"""
    try:
        returns = Return.objects.filter(
            customer_id=customer_id,
            is_active=True
        ).select_related('sale').order_by('-return_date')
        
        serializer = ReturnListSerializer(returns, many=True)
        
        # Calculate customer return statistics
        total_returns = returns.count()
        total_return_amount = returns.aggregate(
            total=Sum('refund_amount')
        )['total'] or Decimal('0.00')
        
        return Response({
            'returns': serializer.data,
            'statistics': {
                'total_returns': total_returns,
                'total_return_amount': total_return_amount
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sale_return_details(request, sale_id):
    """Get return details for a specific sale"""
    try:
        returns = Return.objects.filter(
            sale_id=sale_id,
            is_active=True
        ).select_related('customer').prefetch_related('return_items')
        
        if not returns.exists():
            return Response({
                'message': 'No returns found for this sale'
            }, status=status.HTTP_404_NOT_FOUND)
        
        serializer = ReturnSerializer(returns, many=True)
        
        return Response({
            'returns': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
