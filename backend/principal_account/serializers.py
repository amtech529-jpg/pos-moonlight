from rest_framework import serializers
from .models import PrincipalAccount, PrincipalAccountBalance


class PrincipalAccountSerializer(serializers.ModelSerializer):
    """Serializer for PrincipalAccount model"""
    
    formatted_amount = serializers.ReadOnlyField()
    formatted_balance_after = serializers.ReadOnlyField()
    is_credit = serializers.ReadOnlyField()
    is_debit = serializers.ReadOnlyField()
    relative_date = serializers.SerializerMethodField()
    
    class Meta:
        model = PrincipalAccount
        fields = [
            'id', 'date', 'time', 'source_module', 'source_id', 'description',
            'type', 'amount', 'balance_before', 'balance_after', 'handled_by',
            'notes', 'created_at', 'updated_at', 'formatted_amount',
            'formatted_balance_after', 'is_credit', 'is_debit', 'relative_date'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'formatted_amount',
                           'formatted_balance_after', 'is_credit', 'is_debit', 'relative_date']
    
    def get_relative_date(self, obj):
        """Calculate relative date for display"""
        from datetime import datetime, date
        today = date.today()
        record_date = obj.date
        difference = (today - record_date).days
        
        if difference == 0:
            return 'Today'
        elif difference == 1:
            return 'Yesterday'
        elif difference < 7:
            return f'{difference} days ago'
        elif difference < 30:
            weeks = difference // 7
            return f'{weeks} week{"s" if weeks > 1 else ""} ago'
        elif difference < 365:
            months = difference // 30
            return f'{months} month{"s" if months > 1 else ""} ago'
        else:
            years = difference // 365
            return f'{years} year{"s" if years > 1 else ""} ago'


class PrincipalAccountCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating PrincipalAccount records"""
    
    class Meta:
        model = PrincipalAccount
        fields = [
            'date', 'time', 'source_module', 'source_id', 'description',
            'type', 'amount', 'handled_by', 'notes'
        ]
    
    def validate(self, data):
        """Validate transaction data"""
        if data['amount'] <= 0:
            raise serializers.ValidationError("Amount must be greater than zero.")
        
        return data


class PrincipalAccountUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating PrincipalAccount records"""
    
    class Meta:
        model = PrincipalAccount
        fields = [
            'description', 'notes', 'handled_by'
        ]


class PrincipalAccountListSerializer(serializers.ModelSerializer):
    """Serializer for listing PrincipalAccount records"""
    
    formatted_amount = serializers.ReadOnlyField()
    formatted_balance_after = serializers.ReadOnlyField()
    is_credit = serializers.ReadOnlyField()
    is_debit = serializers.ReadOnlyField()
    relative_date = serializers.SerializerMethodField()
    
    class Meta:
        model = PrincipalAccount
        fields = [
            'id', 'date', 'time', 'source_module', 'source_id', 'description',
            'type', 'amount', 'balance_after', 'handled_by', 'formatted_amount',
            'formatted_balance_after', 'is_credit', 'is_debit', 'relative_date'
        ]
    
    def get_relative_date(self, obj):
        """Calculate relative date for display"""
        from datetime import datetime, date
        today = date.today()
        record_date = obj.date
        difference = (today - record_date).days
        
        if difference == 0:
            return 'Today'
        elif difference == 1:
            return 'Yesterday'
        elif difference < 7:
            return f'{difference} days ago'
        elif difference < 30:
            weeks = difference // 7
            return f'{weeks} week{"s" if weeks > 1 else ""} ago'
        elif difference < 365:
            months = difference // 30
            return f'{months} month{"s" if months > 1 else ""} ago'
        else:
            years = difference // 365
            return f'{years} year{"s" if years > 1 else ""} ago'


class PrincipalAccountBalanceSerializer(serializers.ModelSerializer):
    """Serializer for PrincipalAccountBalance model"""
    
    formatted_balance = serializers.ReadOnlyField()
    
    class Meta:
        model = PrincipalAccountBalance
        fields = ['id', 'current_balance', 'last_updated', 'last_transaction_id', 'formatted_balance']


class PrincipalAccountStatisticsSerializer(serializers.Serializer):
    """Serializer for Principal Account statistics"""
    
    total_credits = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_debits = serializers.DecimalField(max_digits=15, decimal_places=2)
    current_balance = serializers.DecimalField(max_digits=15, decimal_places=2)
    transaction_count = serializers.IntegerField()
    module_breakdown = serializers.DictField()
    monthly_trend = serializers.DictField()
    recent_transactions = PrincipalAccountListSerializer(many=True)


class PrincipalAccountSearchSerializer(serializers.Serializer):
    """Serializer for Principal Account search parameters"""
    
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)
    source_module = serializers.ChoiceField(choices=PrincipalAccount.SOURCE_MODULE_CHOICES, required=False)
    transaction_type = serializers.ChoiceField(choices=PrincipalAccount.TRANSACTION_TYPE_CHOICES, required=False)
    min_amount = serializers.DecimalField(max_digits=15, decimal_places=2, required=False)
    max_amount = serializers.DecimalField(max_digits=15, decimal_places=2, required=False)
    search = serializers.CharField(required=False)
    handled_by = serializers.CharField(required=False)

