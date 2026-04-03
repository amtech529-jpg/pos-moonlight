from rest_framework import serializers
from django.db.models import Q, Sum
from datetime import date, datetime
from decimal import Decimal
from .models import AdvancePayment
from labors.models import Labor


class AdvancePaymentSerializer(serializers.ModelSerializer):
    """Complete serializer for AdvancePayment model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Labor relationship
    labor_id = serializers.UUIDField(source='labor.id', read_only=True)
    
    # Computed fields
    display_name = serializers.CharField(read_only=True)
    formatted_amount = serializers.CharField(read_only=True)
    payment_datetime = serializers.DateTimeField(read_only=True)
    is_recent = serializers.BooleanField(read_only=True)
    is_today = serializers.BooleanField(read_only=True)
    has_receipt = serializers.BooleanField(read_only=True)
    receipt_url = serializers.CharField(read_only=True)
    advance_percentage = serializers.FloatField(read_only=True)
    
    # Labor advance summary
    total_labor_advances = serializers.SerializerMethodField()
    labor_advance_count = serializers.SerializerMethodField()
    
    class Meta:
        model = AdvancePayment
        fields = (
            'id',
            'labor_id',
            'labor_name',
            'labor_phone',
            'labor_role',
            'amount',
            'description',
            'date',
            'time',
            'receipt_image_path',
            'remaining_salary',
            'total_salary',
            'display_name',
            'formatted_amount',
            'payment_datetime',
            'is_recent',
            'is_today',
            'has_receipt',
            'receipt_url',
            'advance_percentage',
            'total_labor_advances',
            'labor_advance_count',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'labor_id', 'labor_name', 'labor_phone', 'labor_role',
            'remaining_salary', 'total_salary', 'display_name', 'formatted_amount',
            'payment_datetime', 'is_recent', 'is_today', 'has_receipt', 'receipt_url',
            'advance_percentage', 'total_labor_advances', 'labor_advance_count',
            'created_at', 'updated_at', 'created_by', 'created_by_id'
        )
    
    def get_total_labor_advances(self, obj):
        """Get total advances for this labor in current month"""
        return AdvancePayment.objects.filter(
            labor=obj.labor,
            date__year=obj.date.year,
            date__month=obj.date.month,
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or 0.00
    
    def get_labor_advance_count(self, obj):
        """Get total advance count for this labor"""
        return AdvancePayment.objects.filter(
            labor=obj.labor,
            is_active=True
        ).count()


class AdvancePaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating advance payments"""
    
    labor = serializers.UUIDField(write_only=True)
    
    class Meta:
        model = AdvancePayment
        fields = (
            'labor',
            'amount',
            'description',
            'date',
            'time',
            'receipt_image_path'
        )
    
    def validate_labor(self, value):
        """Validate labor exists and is active"""
        try:
            labor = Labor.objects.get(id=value, is_active=True)
            return labor
        except Labor.DoesNotExist:
            raise serializers.ValidationError("Labor not found or inactive.")
    
    def validate_amount(self, value):
        """Validate amount"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero.")
        if value > 1000000:
            raise serializers.ValidationError("Amount cannot exceed 10,00,000 PKR.")
        return value
    
    def validate_date(self, value):
        """Validate payment date"""
        from datetime import timedelta
        max_future_date = date.today() + timedelta(days=365)
        if value > max_future_date:
            raise serializers.ValidationError("Payment date cannot be more than 1 year in the future.")
        return value
    
    def validate_description(self, value):
        """Clean description"""
        if value:
            return value.strip()
        return value
    
    def validate(self, data):
        """Cross-field validation"""
        labor = data.get('labor')
        amount = data.get('amount')
        payment_date = data.get('date', date.today())
        
        # Set default time if not provided
        if 'time' not in data or not data.get('time'):
            from datetime import datetime
            data['time'] = datetime.now().time()
        
        if labor and amount:
            # Check if advance exceeds monthly salary
            if amount > labor.salary:
                raise serializers.ValidationError({
                    'amount': f'Advance amount cannot exceed monthly salary of {labor.salary} PKR.'
                })
            
            # Check total advances for current month
            total_month_advances = AdvancePayment.objects.filter(
                labor=labor,
                date__year=payment_date.year,
                date__month=payment_date.month,
                is_active=True
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
            
            if (total_month_advances + amount) > labor.salary:
                remaining = labor.salary - total_month_advances
                raise serializers.ValidationError({
                    'amount': f'Total monthly advances cannot exceed salary. '
                             f'Remaining amount: {remaining} PKR.'
                })
        
        return data
    
    def create(self, validated_data):
        """Create advance payment with requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class AdvancePaymentUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating advance payments"""
    
    class Meta:
        model = AdvancePayment
        fields = (
            'amount',
            'description',
            'date',
            'time',
            'receipt_image_path'
        )
    
    def validate_amount(self, value):
        """Validate amount"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero.")
        if value > 1000000:
            raise serializers.ValidationError("Amount cannot exceed 10,00,000 PKR.")
        return value
    
    def validate_date(self, value):
        """Validate payment date"""
        from datetime import timedelta
        max_future_date = date.today() + timedelta(days=365)
        if value > max_future_date:
            raise serializers.ValidationError("Payment date cannot be more than 1 year in the future.")
        return value
    
    def validate_description(self, value):
        """Clean description"""
        if value:
            return value.strip()
        return value
    
    def validate(self, data):
        """Cross-field validation for updates"""
        if self.instance:
            labor = self.instance.labor
            amount = data.get('amount', self.instance.amount)
            payment_date = data.get('date', self.instance.date)
            
            # Set default time if not provided
            if 'time' not in data or not data.get('time'):
                from datetime import datetime
                if not self.instance.time:
                    data['time'] = datetime.now().time()
            
            # Check if advance exceeds monthly salary
            if amount > labor.salary:
                raise serializers.ValidationError({
                    'amount': f'Advance amount cannot exceed monthly salary of {labor.salary} PKR.'
                })
            
            # Check total advances for month (excluding current record)
            total_month_advances = AdvancePayment.objects.filter(
                labor=labor,
                date__year=payment_date.year,
                date__month=payment_date.month,
                is_active=True
            ).exclude(id=self.instance.id).aggregate(
                total=Sum('amount')
            )['total'] or Decimal('0.00')
            
            if (total_month_advances + amount) > labor.salary:
                remaining = labor.salary - total_month_advances
                raise serializers.ValidationError({
                    'amount': f'Total monthly advances cannot exceed salary. '
                             f'Remaining amount: {remaining} PKR.'
                })
        
        return data


class AdvancePaymentListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing advance payments"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    display_name = serializers.CharField(read_only=True)
    formatted_amount = serializers.CharField(read_only=True)
    is_recent = serializers.BooleanField(read_only=True)
    is_today = serializers.BooleanField(read_only=True)
    has_receipt = serializers.BooleanField(read_only=True)
    advance_percentage = serializers.FloatField(read_only=True)
    
    class Meta:
        model = AdvancePayment
        fields = (
            'id',
            'labor_name',
            'labor_phone',
            'labor_role',
            'amount',
            'formatted_amount',
            'description',
            'date',
            'time',
            'receipt_image_path',
            'remaining_salary',
            'total_salary',
            'display_name',
            'is_recent',
            'is_today',
            'has_receipt',
            'advance_percentage',
            'is_active',
            'created_at',
            'created_by_email'
        )


class AdvancePaymentDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single advance payment view"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    labor_id = serializers.UUIDField(source='labor.id', read_only=True)
    display_name = serializers.CharField(read_only=True)
    formatted_amount = serializers.CharField(read_only=True)
    payment_datetime = serializers.DateTimeField(read_only=True)
    is_recent = serializers.BooleanField(read_only=True)
    is_today = serializers.BooleanField(read_only=True)
    has_receipt = serializers.BooleanField(read_only=True)
    receipt_url = serializers.CharField(read_only=True)
    advance_percentage = serializers.FloatField(read_only=True)
    
    # Labor details
    labor_details = serializers.SerializerMethodField()
    
    class Meta:
        model = AdvancePayment
        fields = (
            'id',
            'labor_id',
            'labor_name',
            'labor_phone',
            'labor_role',
            'amount',
            'description',
            'date',
            'time',
            'receipt_image_path',
            'remaining_salary',
            'total_salary',
            'display_name',
            'formatted_amount',
            'payment_datetime',
            'is_recent',
            'is_today',
            'has_receipt',
            'receipt_url',
            'advance_percentage',
            'labor_details',
            'is_active',
            'created_at',
            'updated_at',
            'created_by'
        )
    
    def get_labor_details(self, obj):
        """Get additional labor details"""
        if obj.labor:
            return {
                'id': str(obj.labor.id),
                'name': obj.labor.name,
                'designation': obj.labor.designation,
                'city': obj.labor.city,
                'area': obj.labor.area,
                'current_salary': str(obj.labor.salary),
                'is_active': obj.labor.is_active
            }
        return None


class AdvancePaymentStatsSerializer(serializers.Serializer):
    """Serializer for advance payment statistics"""
    
    total_payments = serializers.IntegerField()
    total_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    today_payments = serializers.IntegerField()
    today_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    this_month_payments = serializers.IntegerField()
    this_month_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    amount_statistics = serializers.DictField()
    top_labor_recipients = serializers.ListField()
    monthly_breakdown = serializers.ListField()
    payments_with_receipts = serializers.IntegerField()
    payments_without_receipts = serializers.IntegerField()


class AdvancePaymentSearchSerializer(serializers.Serializer):
    """Serializer for advance payment search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for labor name, phone, role, or description"
    )
    date_from = serializers.DateField(
        required=False,
        help_text="Filter payments from this date"
    )
    date_to = serializers.DateField(
        required=False,
        help_text="Filter payments up to this date"
    )
    min_amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        help_text="Minimum amount filter"
    )
    max_amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        help_text="Maximum amount filter"
    )


class AdvancePaymentBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk advance payment actions"""
    
    payment_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of advance payment IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('activate', 'Activate'),
            ('deactivate', 'Deactivate'),
            ('delete', 'Delete'),
        ],
        required=True,
        help_text="Action to perform on selected payments"
    )
    
    def validate_payment_ids(self, value):
        """Validate that all payment IDs exist"""
        existing_ids = AdvancePayment.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Advance payments not found: {', '.join(missing_ids)}"
            )
        
        return value


class AdvancePaymentFilterSerializer(serializers.Serializer):
    """Serializer for advance payment filtering parameters"""
    
    labor_id = serializers.UUIDField(required=False)
    labor_name = serializers.CharField(required=False)
    labor_role = serializers.CharField(required=False)
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)
    min_amount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    max_amount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    has_receipt = serializers.BooleanField(required=False)
    is_recent = serializers.BooleanField(required=False)


class LaborAdvanceSummarySerializer(serializers.Serializer):
    """Serializer for labor advance payment summary"""
    
    labor_id = serializers.UUIDField(read_only=True)
    labor_name = serializers.CharField(read_only=True)
    labor_role = serializers.CharField(read_only=True)
    total_advances = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    payment_count = serializers.IntegerField(read_only=True)
    last_payment_date = serializers.DateField(read_only=True)
    this_month_advances = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    current_salary = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    remaining_salary_balance = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    