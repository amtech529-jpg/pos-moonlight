from rest_framework import viewsets, status, decorators
from rest_framework.response import Response
from .models import Quotation, QuotationItem
from .serializers import QuotationSerializer, CreateQuotationSerializer, UpdateQuotationSerializer
from orders.models import Order
from order_items.models import OrderItem
from customers.models import Customer
from django.utils import timezone
from datetime import timedelta
import uuid

class QuotationViewSet(viewsets.ModelViewSet):
    queryset = Quotation.objects.filter(is_active=True)
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CreateQuotationSerializer
        elif self.action in ['update', 'partial_update']:
            return UpdateQuotationSerializer
        return QuotationSerializer

    @decorators.action(detail=True, methods=['post'])
    def convert_to_order(self, request, pk=None):
        """Convert an approved quotation into a live order"""
        quotation = self.get_object()
        
        if quotation.status == 'CONVERTED':
            return Response({'error': 'Quotation already converted to order'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # 1. Handle Customer
            customer = quotation.customer
            if not customer:
                 # Check if customer exists by phone number to avoid duplicates
                 if quotation.customer_phone:
                     existing = Customer.objects.filter(phone=quotation.customer_phone, is_active=True).first()
                     if existing:
                         customer = existing
                     else:
                         # Create new customer
                         customer = Customer.objects.create(
                             name=quotation.customer_name,
                             phone=quotation.customer_phone,
                             created_by=request.user
                         )
                 else:
                     # No phone, create with name only (or handle error?)
                     # For now, let's allow creating customer with just name
                     customer = Customer.objects.create(
                         name=quotation.customer_name,
                         created_by=request.user
                     )
            
            # 2. Calculate return date based on manual field or max days fallback
            return_date = quotation.return_date
            if not return_date and quotation.event_date:
                max_days = 1
                if quotation.items.exists():
                    max_days = max(item.days for item in quotation.items.all())
                return_date = quotation.event_date + timedelta(days=max_days)


            # 2.5 Stock Check (Date-aware)
            for q_item in quotation.items.all():
                if q_item.product and not q_item.rented_from_partner: # Only check internal stock if NOT a partner item
                    available_for_dates = q_item.product.get_available_quantity_for_dates(
                        start_date=quotation.event_date,
                        end_date=return_date or quotation.event_date
                    )
                    if available_for_dates < q_item.quantity:
                        return Response({
                            'error': f'Insufficient internal stock for "{q_item.product.name}" on requested dates ({quotation.event_date} to {return_date or quotation.event_date}). Please mark it as "Rented from Partner" or reduce quantity. Available: {available_for_dates}, Requested: {q_item.quantity}'
                        }, status=status.HTTP_400_BAD_REQUEST)

            # 3. Create Order
            order = Order.objects.create(
                customer=customer,
                customer_name=customer.name,
                customer_phone=customer.phone or "",
                customer_email=customer.email or "",
                total_amount=quotation.final_amount,
                advance_payment=0, # Initially 0, can be updated later
                event_name=quotation.event_name,
                event_location=quotation.event_location,
                event_date=quotation.event_date,
                return_date=return_date,
                description=f"Generated from Quotation {quotation.quotation_number}. {quotation.special_notes or ''}",
                status='PENDING', # Default starting status
                created_by=request.user,
                date_ordered=timezone.now().date()
            )

            # 4. Create Order Items
            for q_item in quotation.items.all():
                from order_items.models import OrderItem
                OrderItem.objects.create(
                    order=order,
                    product=q_item.product, # Can be None
                    product_name=q_item.product_name or (q_item.product.name if q_item.product else "Unknown Item"),
                    quantity=q_item.quantity,
                    rate=q_item.rate,
                    days=q_item.days,
                    pricing_type=q_item.pricing_type,
                    line_total=q_item.total,
                    customization_notes=f"From Quote Item {q_item.id}",
                    # Mapping partner fields
                    rented_from_partner=q_item.rented_from_partner,
                    partner=q_item.partner,
                    partner_rate=q_item.partner_rate
                )

            # 5. Update Quotation Status
            quotation.status = 'CONVERTED'
            quotation.save()
            
            # Recalculate order totals just to be safe
            order.calculate_totals()

            return Response({
                'message': 'Quotation converted to order successfully',
                'order_id': order.id
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
