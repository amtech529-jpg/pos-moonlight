from rest_framework import serializers
from decimal import Decimal
from .models import Receivable


class ReceivableSerializer(serializers.ModelSerializer):
    """Serializer for Receivable model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    related_sale_id = serializers.UUIDField(read_only=True, source='related_sale.id')
    is_overdue = serializers.BooleanField(read_only=True)
    days_overdue = serializers.IntegerField(read_only=True)
    is_fully_paid = serializers.BooleanField(read_only=True)
    is_partially_paid = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Receivable
        fields = (
            'id', 
            'debtor_name', 
            'debtor_phone', 
            'amount_given', 
            'reason_or_item', 
            'date_lent', 
            'expected_return_date', 
            'amount_returned', 
            'balance_remaining', 
            'notes', 
            'is_active', 
            'created_at', 
            'updated_at', 
            'created_by',
            'created_by_id',
            'related_sale_id',
            'is_overdue',
            'days_overdue',
            'is_fully_paid',
            'is_partially_paid'
        )
        read_only_fields = (
            'id', 
            'created_at', 
            'updated_at', 
            'created_by', 
            'created_by_id',
            'balance_remaining',
            'is_overdue',
            'days_overdue',
            'is_fully_paid',
            'is_partially_paid'
        )
        extra_kwargs = {
            'reason_or_item': {'required': False, 'allow_blank': True},
            'notes': {'required': False, 'allow_blank': True},
        }
    
    def validate_debtor_name(self, value):
        """Clean and validate debtor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Debtor name is required.")
        return value.strip().title()
    
    def validate_debtor_phone(self, value):
        """Clean and validate debtor phone"""
        if not value or not value.strip():
            raise serializers.ValidationError("Debtor phone is required.")
        return value.strip()
    
    def validate_reason_or_item(self, value):
        """Clean and validate reason or item"""
        if not value:
            return ""
        return value.strip()
    
    def validate_notes(self, value):
        """Clean notes field"""
        if value:
            return value.strip()
        return value
    
    def validate(self, data):
        """Validate the entire data set"""
        amount_given = data.get('amount_given')
        amount_returned = data.get('amount_returned', 0)
        date_lent = data.get('date_lent')
        expected_return_date = data.get('expected_return_date')
        
        # Validate amount returned doesn't exceed amount given
        if amount_returned > amount_given:
            raise serializers.ValidationError({
                'amount_returned': 'Amount returned cannot exceed amount given.'
            })
        
        # Validate expected return date is not before date lent
        if expected_return_date and date_lent and expected_return_date < date_lent:
            raise serializers.ValidationError({
                'expected_return_date': 'Expected return date cannot be before date lent.'
            })
        
        return data


class ReceivableCreateSerializer(ReceivableSerializer):
    """Serializer for creating receivables with additional validation"""
    
    class Meta(ReceivableSerializer.Meta):
        fields = (
            'debtor_name', 
            'debtor_phone', 
            'amount_given', 
            'reason_or_item', 
            'date_lent', 
            'expected_return_date', 
            'notes',
            'related_sale'
        )
    
    def create(self, validated_data):
        """Create receivable with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class ReceivableListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing receivables"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    days_overdue = serializers.IntegerField(read_only=True)
    is_fully_paid = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Receivable
        fields = (
            'id', 
            'debtor_name', 
            'debtor_phone', 
            'amount_given', 
            'amount_returned', 
            'balance_remaining', 
            'date_lent', 
            'expected_return_date', 
            'reason_or_item',
            'is_active',
            'created_at',
            'created_by_email',
            'is_overdue',
            'days_overdue',
            'is_fully_paid'
        )


class ReceivableUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating receivables"""
    
    class Meta:
        model = Receivable
        fields = (
            'debtor_name', 
            'debtor_phone', 
            'amount_given', 
            'reason_or_item', 
            'date_lent', 
            'expected_return_date', 
            'notes',
            'related_sale'
        )
    
    def validate_amount_given(self, value):
        """Validate amount given for updates"""
        instance = self.instance
        if instance and instance.amount_returned > value:
            raise serializers.ValidationError(
                "Amount given cannot be reduced below amount already returned."
            )
        return value


class ReceivablePaymentSerializer(serializers.Serializer):
    """Serializer for recording payments on receivables"""
    
    payment_amount = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        min_value=Decimal('0.01'),
        help_text="Amount being paid/returned"
    )
    payment_notes = serializers.CharField(
        max_length=500,
        required=False,
        allow_blank=True,
        help_text="Optional notes about this payment"
    )
    
    def validate_payment_amount(self, value):
        """Validate payment amount"""
        instance = self.context.get('receivable')
        if instance and value > instance.balance_remaining:
            raise serializers.ValidationError(
                f"Payment amount cannot exceed remaining balance of {instance.balance_remaining} PKR."
            )
        return value


class ReceivableSearchSerializer(serializers.Serializer):
    """Serializer for search parameters"""
    
    search = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Search by debtor name, phone, reason, or notes"
    )
    debtor_name = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Filter by debtor name"
    )
    debtor_phone = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text="Filter by debtor phone"
    )
    date_from = serializers.DateField(
        required=False,
        help_text="Filter from date (date lent)"
    )
    date_to = serializers.DateField(
        required=False,
        help_text="Filter to date (date lent)"
    )
    expected_return_from = serializers.DateField(
        required=False,
        help_text="Filter from expected return date"
    )
    expected_return_to = serializers.DateField(
        required=False,
        help_text="Filter to expected return date"
    )
    amount_min = serializers.DecimalField(
        required=False,
        max_digits=15,
        decimal_places=2,
        help_text="Minimum amount filter"
    )
    amount_max = serializers.DecimalField(
        required=False,
        max_digits=15,
        decimal_places=2,
        help_text="Maximum amount filter"
    )
    status = serializers.ChoiceField(
        required=False,
        choices=[
            ('all', 'All'),
            ('overdue', 'Overdue'),
            ('due_today', 'Due Today'),
            ('due_this_week', 'Due This Week'),
            ('fully_paid', 'Fully Paid'),
            ('partially_paid', 'Partially Paid'),
            ('unpaid', 'Unpaid')
        ],
        default='all',
        help_text="Filter by receivable status"
    )
    show_inactive = serializers.BooleanField(
        required=False,
        default=False,
        help_text="Include inactive receivables"
    )
