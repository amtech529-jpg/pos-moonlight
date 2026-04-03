from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import models
from django.shortcuts import get_object_or_404
import logging

logger = logging.getLogger(__name__)

from .models import RentalReturn, RentalReturnItem, DamageRecovery
from .serializers import (
    RentalReturnSerializer,
    CreateRentalReturnSerializer,
    TallyReturnSerializer,
    AddDamageRecoverySerializer,
    RestoreStockSerializer,
)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_returns(request):
    """List rental returns with optional filters"""
    returns = RentalReturn.objects.select_related('order').prefetch_related('items', 'recoveries')
    
    # Filters
    status_filter = request.query_params.get('status')
    if status_filter:
        returns = returns.filter(status=status_filter.upper())
    
    search = request.query_params.get('search')
    if search:
        returns = returns.filter(
            models.Q(order__customer_name__icontains=search) |
            models.Q(notes__icontains=search) |
            models.Q(items__product__name__icontains=search)
        ).distinct()
    
    start_date_str = request.query_params.get('start_date')
    end_date_str = request.query_params.get('end_date')
    if start_date_str and end_date_str:
        from django.utils.dateparse import parse_datetime
        sd = parse_datetime(start_date_str)
        ed = parse_datetime(end_date_str)
        if sd and ed:
            returns = returns.filter(return_date__date__range=[sd.date(), ed.date()])
        else:
            # Fallback if parsing fails
            try:
                returns = returns.filter(return_date__date__range=[start_date_str[:10], end_date_str[:10]])
            except:
                pass
    
    serializer = RentalReturnSerializer(returns, many=True)
    return Response({
        'count': returns.count(),
        'results': serializer.data
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_return(request):
    """Create a new rental return with items"""
    logger.warning(f"DEBUG: create_return data: {request.data}")
    serializer = CreateRentalReturnSerializer(
        data=request.data, context={'request': request}
    )
    if serializer.is_valid():
        rental_return = serializer.save()
        return Response(
            RentalReturnSerializer(rental_return).data,
            status=status.HTTP_201_CREATED
        )
    logger.warning(f"DEBUG: create_return errors: {serializer.errors}")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_return(request, return_id):
    """Get a specific rental return detail"""
    rental_return = get_object_or_404(RentalReturn, id=return_id)
    serializer = RentalReturnSerializer(rental_return)
    return Response(serializer.data)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def tally_return(request, return_id):
    """Tally items — update returned/damaged/missing counts"""
    rental_return = get_object_or_404(RentalReturn, id=return_id)
    
    serializer = TallyReturnSerializer(
        data=request.data, context={'request': request}
    )
    if serializer.is_valid():
        updated_return = serializer.update(rental_return, serializer.validated_data)
        return Response(RentalReturnSerializer(updated_return).data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_stock(request, return_id):
    """Restore owned inventory stock from returned items"""
    rental_return = get_object_or_404(RentalReturn, id=return_id)
    
    serializer = RestoreStockSerializer(data=request.data)
    if serializer.is_valid():
        try:
            rental_return.restore_stock(user=request.user)
            return Response({
                'detail': 'Stock restored successfully',
                'return': RentalReturnSerializer(rental_return).data
            })
        except Exception as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_damage_recovery(request, return_id):
    """Record a damage recovery action (deduction, payment, write-off)"""
    rental_return = get_object_or_404(RentalReturn, id=return_id)
    
    serializer = AddDamageRecoverySerializer(
        data=request.data,
        context={'rental_return': rental_return, 'request': request}
    )
    if serializer.is_valid():
        recovery = serializer.save()
        # Refresh the return to get updated totals
        rental_return.refresh_from_db()
        return Response({
            'detail': 'Damage recovery recorded successfully',
            'return': RentalReturnSerializer(rental_return).data
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def return_statistics(request):
    """Get return & tally statistics"""
    stats = RentalReturn.get_statistics()
    return Response(stats)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_return(request, return_id):
    """Delete a rental return (only if stock not restored)"""
    rental_return = get_object_or_404(RentalReturn, id=return_id)
    
    if rental_return.is_stock_restored:
        return Response(
            {'detail': 'Cannot delete return after stock has been restored'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    rental_return.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
