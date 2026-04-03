from rest_framework import serializers
from .models import Payment
from labors.models import Labor
from vendors.models import Vendor
from orders.models import Order
from sales.models import Sales
from datetime import datetime


class PaymentSerializer(serializers.ModelSerializer):
    """Serializer for Payment model"""
    
    # Custom fields for better frontend compatibility
    time = serializers.SerializerMethodField()
    date = serializers.DateField(format='%Y-%m-%d')
    payment_month = serializers.DateField(format='%Y-%m-%d')
    created_at = serializers.DateTimeField(format='%Y-%m-%dT%H:%M:%S')
    updated_at = serializers.DateTimeField(format='%Y-%m-%dT%H:%M:%S')
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    labor_name = serializers.CharField(read_only=True)
    labor_phone = serializers.CharField(read_only=True)
    labor_role = serializers.CharField(read_only=True)
    formatted_amount = serializers.CharField(read_only=True)
    net_amount = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    payment_period_display = serializers.CharField(read_only=True)
    has_receipt = serializers.BooleanField(read_only=True)
    
    # 🆕 PAYABLE INFO - Enhanced field
    payable_info = serializers.SerializerMethodField()
    
    class Meta:
        model = Payment
        fields = [
            'id', 'labor', 'vendor', 'order', 'sale', 'payer_type', 'payer_id',
            'labor_name', 'labor_phone', 'labor_role', 'amount_paid', 'bonus',
            'deduction', 'payment_month', 'is_final_payment', 'payment_method',
            'description', 'date', 'time', 'receipt_image_path', 'is_active',
            'created_at', 'updated_at', 'created_by', 'created_by_id',
            'formatted_amount', 'net_amount', 'payment_period_display', 'has_receipt',
            'payable', 'payable_info'  # 🆕 Added payable fields
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_time(self, obj):
        """Format time as ISO string for frontend compatibility"""
        if obj.time:
            from django.utils import timezone
            today = timezone.now().date()
            full_datetime = timezone.make_aware(
                datetime.combine(today, obj.time)
            )
            return full_datetime.isoformat()
        return None
    
    def get_payable_info(self, obj):
        """
        Get detailed payable information if payment is linked to a payable
        🆕 NEW METHOD
        """
        if not hasattr(obj, 'payable') or not obj.payable:
            return None
        
        payable = obj.payable
        return {
            'id': str(payable.id),
            'creditor_name': payable.creditor_name,
            'creditor_phone': payable.creditor_phone,
            'amount_borrowed': float(payable.amount_borrowed),
            'amount_paid': float(payable.amount_paid),
            'balance_remaining': float(payable.balance_remaining),
            'payment_percentage': float(payable.payment_percentage),
            'is_fully_paid': payable.is_fully_paid,
            'status': payable.status,
            'priority': payable.priority,
            'expected_repayment_date': payable.expected_repayment_date.strftime('%Y-%m-%d') if payable.expected_repayment_date else None,
            'days_until_due': payable.days_until_due,
            'is_overdue': payable.is_overdue,
            'repayment_status': payable.repayment_status
        }
    
    def validate(self, data):
        """Validate payment data"""
        # Check that at least one entity is specified
        if not any([data.get('labor'), data.get('vendor'), data.get('order'), data.get('sale')]):
            raise serializers.ValidationError(
                "At least one entity (labor, vendor, order, or sale) must be specified."
            )
        
        # Validate amount
        if data.get('amount_paid', 0) <= 0:
            raise serializers.ValidationError(
                {'amount_paid': 'Amount paid must be greater than zero.'}
            )
        
        # Validate bonus and deduction
        if data.get('bonus', 0) < 0:
            raise serializers.ValidationError(
                {'bonus': 'Bonus cannot be negative.'}
            )
        
        if data.get('deduction', 0) < 0:
            raise serializers.ValidationError(
                {'deduction': 'Deduction cannot be negative.'}
            )
        
        # 🆕 Validate payable if specified
        payable = data.get('payable')
        vendor = data.get('vendor')
        
        if payable:
            # Ensure payable belongs to the vendor
            if vendor and payable.vendor != vendor:
                raise serializers.ValidationError(
                    {'payable': 'Payable does not belong to the specified vendor.'}
                )
            
            # Warn if payable is fully paid
            if payable.is_fully_paid:
                raise serializers.ValidationError(
                    {'payable': 'Cannot add payment to a fully paid payable.'}
                )
            
            # Warn if payment exceeds remaining balance
            amount = data.get('amount_paid', 0)
            if amount > payable.balance_remaining:
                raise serializers.ValidationError(
                    {'amount_paid': f'Payment amount ({amount}) exceeds payable remaining balance ({payable.balance_remaining}).'}
                )
        
        return data
    
    def validate_labor(self, value):
        """Validate labor if specified"""
        if value and not value.is_active:
            raise serializers.ValidationError(
                "Cannot make payment to inactive labor."
            )
        return value
    
    def validate_vendor(self, value):
        """Validate vendor if specified"""
        if value and not value.is_active:
            raise serializers.ValidationError(
                "Cannot make payment to inactive vendor."
            )
        return value
    
    def validate_order(self, value):
        """Validate order if specified"""
        if value and not value.is_active:
            raise serializers.ValidationError(
                "Cannot make payment for inactive order."
            )
        return value
    
    def validate_sale(self, value):
        """Validate sale if specified"""
        if value and not value.is_active:
            raise serializers.ValidationError(
                "Cannot make payment for inactive sale."
            )
        return value


class PaymentCreateSerializer(PaymentSerializer):
    """Serializer for creating payments with additional validation"""
    
    # 🆕 Make payable optional but available
    payable = serializers.UUIDField(
        required=False,
        allow_null=True,
        write_only=True,
        help_text="Optional: Specify which payable to reduce. If not specified, will auto-link to most recent pending payable for vendor."
    )
    
    # Override time field to make it writable for creation
    time = serializers.TimeField(required=True, help_text="Time of payment")
    
    class Meta(PaymentSerializer.Meta):
        fields = (
            'labor', 'vendor', 'order', 'sale',
            'amount_paid', 'bonus', 'deduction',
            'payment_month', 'is_final_payment',
            'payment_method', 'description',
            'date', 'time', 'receipt_image_path',
            'payable'  # 🆕 Added payable field
        )
    
    def create(self, validated_data):
        """Create payment with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        
        # 🆕 Handle payable UUID conversion
        payable_id = validated_data.pop('payable', None)
        if payable_id:
            from payables.models import Payable
            try:
                payable = Payable.objects.get(id=payable_id)
                validated_data['payable'] = payable
            except Payable.DoesNotExist:
                raise serializers.ValidationError(
                    {'payable': f'Payable with ID {payable_id} does not exist.'}
                )
        
        return super().create(validated_data)


class PaymentListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing payments"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    formatted_amount = serializers.CharField(read_only=True)
    net_amount = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    payment_period_display = serializers.CharField(read_only=True)
    vendor_name = serializers.SerializerMethodField()
    has_receipt = serializers.BooleanField(read_only=True)
    
    # 🆕 Quick payable status indicator
    payable_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Payment
        fields = (
            'id',
            'labor',
            'vendor',
            'order',
            'sale',
            'labor_name',
            'labor_phone',
            'labor_role',
            'vendor_name',
            'payer_type',
            'payer_id',
            'amount_paid',
            'bonus',
            'deduction',
            'net_amount',
            'formatted_amount',
            'payment_month',
            'payment_period_display',
            'is_final_payment',
            'payment_method',
            'description',
            'date',
            'time',
            'receipt_image_path',
            'has_receipt',
            'is_active',
            'created_at',
            'created_by_email',
            'payable_status'  # 🆕 Added
        )
    
    def get_vendor_name(self, obj):
        """Get vendor name if available"""
        if obj.vendor:
            return obj.vendor.business_name
        return None
    
    def get_payable_status(self, obj):
        """
        Get quick payable status for list view
        🆕 NEW METHOD
        """
        if not hasattr(obj, 'payable') or not obj.payable:
            return None
        
        payable = obj.payable
        return {
            'id': str(payable.id),
            'creditor_name': payable.creditor_name,
            'balance_remaining': float(payable.balance_remaining),
            'is_fully_paid': payable.is_fully_paid,
            'status': payable.status
        }


class PaymentUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating payments"""
    
    # 🆕 Allow updating payable link
    payable = serializers.UUIDField(
        required=False,
        allow_null=True,
        write_only=True,
        help_text="Update which payable this payment is linked to"
    )
    
    class Meta:
        model = Payment
        fields = (
            'amount_paid', 'bonus', 'deduction',
            'payment_month', 'is_final_payment',
            'payment_method', 'description',
            'date', 'time', 'receipt_image_path',
            'payable'  # 🆕 Added
        )
    
    def validate_amount_paid(self, value):
        """Validate amount paid"""
        if value <= 0:
            raise serializers.ValidationError(
                "Amount paid must be greater than zero."
            )
        return value
    
    def update(self, instance, validated_data):
        """
        Update payment
        🆕 Handle payable re-linking
        """
        # Handle payable UUID conversion
        payable_id = validated_data.pop('payable', None)
        if payable_id is not None:
            from payables.models import Payable
            if payable_id:
                try:
                    payable = Payable.objects.get(id=payable_id)
                    validated_data['payable'] = payable
                except Payable.DoesNotExist:
                    raise serializers.ValidationError(
                        {'payable': f'Payable with ID {payable_id} does not exist.'}
                    )
            else:
                validated_data['payable'] = None
        
        return super().update(instance, validated_data)


class PaymentDetailSerializer(PaymentSerializer):
    """Detailed serializer for payment information"""
    
    labor_details = serializers.SerializerMethodField()
    vendor_details = serializers.SerializerMethodField()
    order_details = serializers.SerializerMethodField()
    sale_details = serializers.SerializerMethodField()
    
    # 🆕 Enhanced payable details for detail view
    payable_details = serializers.SerializerMethodField()
    
    class Meta(PaymentSerializer.Meta):
        fields = PaymentSerializer.Meta.fields + [
            'labor_details', 'vendor_details', 'order_details', 'sale_details',
            'payable_details'  # 🆕 Added
        ]
    
    def get_labor_details(self, obj):
        """Get labor details if available"""
        if obj.labor:
            return {
                'id': str(obj.labor.id),
                'name': obj.labor.name,
                'phone': obj.labor.phone_number,
                'designation': obj.labor.designation,
                'city': obj.labor.city,
                'area': obj.labor.area
            }
        return None
    
    def get_vendor_details(self, obj):
        """Get vendor details if available"""
        if obj.vendor:
            return {
                'id': str(obj.vendor.id),
                'name': obj.vendor.name,
                'business_name': obj.vendor.business_name,
                'phone': obj.vendor.phone,
                'city': obj.vendor.city,
                'area': obj.vendor.area,
                'cnic': obj.vendor.cnic
            }
        return None
    
    def get_order_details(self, obj):
        """Get order details if available"""
        if obj.order:
            return {
                'id': str(obj.order.id),
                'customer_name': obj.order.customer_name,
                'total_amount': float(obj.order.total_amount),
                'status': obj.order.status,
                'date_ordered': obj.order.date_ordered.strftime('%Y-%m-%d') if obj.order.date_ordered else None
            }
        return None
    
    def get_sale_details(self, obj):
        """Get sale details if available"""
        if obj.sale:
            return {
                'id': str(obj.sale.id),
                'invoice_number': obj.sale.invoice_number,
                'customer_name': obj.sale.customer_name,
                'grand_total': float(obj.sale.grand_total),
                'status': obj.sale.status,
                'date_of_sale': obj.sale.date_of_sale.strftime('%Y-%m-%d') if obj.sale.date_of_sale else None
            }
        return None
    
    def get_payable_details(self, obj):
        """
        Get comprehensive payable details for detail view
        🆕 NEW METHOD - More detailed than payable_info
        """
        if not hasattr(obj, 'payable') or not obj.payable:
            return None
        
        payable = obj.payable
        
        # Get payment history for this payable
        payment_history = []
        if hasattr(payable, 'linked_payments'):
            for payment in payable.linked_payments.all().order_by('-date')[:5]:
                payment_history.append({
                    'id': str(payment.id),
                    'amount': float(payment.amount_paid),
                    'date': payment.date.strftime('%Y-%m-%d'),
                    'payment_method': payment.payment_method
                })
        
        return {
            'id': str(payable.id),
            'creditor_name': payable.creditor_name,
            'creditor_phone': payable.creditor_phone,
            'creditor_email': payable.creditor_email or '',
            'amount_borrowed': float(payable.amount_borrowed),
            'amount_paid': float(payable.amount_paid),
            'balance_remaining': float(payable.balance_remaining),
            'payment_percentage': float(payable.payment_percentage),
            'is_fully_paid': payable.is_fully_paid,
            'status': payable.status,
            'priority': payable.priority,
            'reason_or_item': payable.reason_or_item,
            'date_borrowed': payable.date_borrowed.strftime('%Y-%m-%d'),
            'expected_repayment_date': payable.expected_repayment_date.strftime('%Y-%m-%d') if payable.expected_repayment_date else None,
            'days_since_borrowed': payable.days_since_borrowed,
            'days_until_due': payable.days_until_due,
            'is_overdue': payable.is_overdue,
            'repayment_status': payable.repayment_status,
            'priority_color': payable.priority_color,
            'status_color': payable.status_color,
            'notes': payable.notes or '',
            'payment_history': payment_history  # 🆕 Recent payment history
        }


# 🆕 NEW SERIALIZER: For vendor payment summary
class VendorPaymentSummarySerializer(serializers.Serializer):
    """
    Serializer for vendor payment summary including payables
    🆕 COMPLETELY NEW
    """
    vendor_id = serializers.UUIDField()
    vendor_name = serializers.CharField()
    vendor_business_name = serializers.CharField()
    total_payments = serializers.IntegerField()
    total_amount_paid = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_payables = serializers.IntegerField()
    total_payable_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_outstanding = serializers.DecimalField(max_digits=15, decimal_places=2)
    last_payment_date = serializers.DateField(allow_null=True)
    payment_methods_used = serializers.ListField(child=serializers.CharField())


# 🆕 NEW SERIALIZER: For payable-payment linking
class PayablePaymentLinkSerializer(serializers.Serializer):
    """
    Serializer for explicitly linking payment to payable
    🆕 COMPLETELY NEW
    """
    payment_id = serializers.UUIDField(help_text="Payment ID to link")
    payable_id = serializers.UUIDField(help_text="Payable ID to link to")
    
    def validate(self, data):
        """Validate that both payment and payable exist and are compatible"""
        from payables.models import Payable
        
        try:
            payment = Payment.objects.get(id=data['payment_id'])
            payable = Payable.objects.get(id=data['payable_id'])
        except Payment.DoesNotExist:
            raise serializers.ValidationError({'payment_id': 'Payment not found.'})
        except Payable.DoesNotExist:
            raise serializers.ValidationError({'payable_id': 'Payable not found.'})
        
        # Validate payment is for vendor
        if payment.payer_type != 'VENDOR' or not payment.vendor:
            raise serializers.ValidationError(
                {'payment_id': 'Payment must be a vendor payment.'}
            )
        
        # Validate payable belongs to same vendor
        if payable.vendor != payment.vendor:
            raise serializers.ValidationError(
                {'payable_id': 'Payable does not belong to the payment vendor.'}
            )
        
        # Validate payable is not fully paid
        if payable.is_fully_paid:
            raise serializers.ValidationError(
                {'payable_id': 'Payable is already fully paid.'}
            )
        
        data['payment'] = payment
        data['payable'] = payable
        
        return data