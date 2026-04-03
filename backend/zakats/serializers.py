from rest_framework import serializers
from django.utils import timezone
from django.db.models import Sum, Count, Avg
from decimal import Decimal
from .models import Zakat


class ZakatSerializer(serializers.ModelSerializer):
    """Main serializer for Zakat model"""
    
    formatted_amount = serializers.ReadOnlyField()
    authorized_initials = serializers.ReadOnlyField()
    zakat_summary = serializers.ReadOnlyField()
    zakat_age_days = serializers.ReadOnlyField()
    beneficiary_summary = serializers.ReadOnlyField()
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = Zakat
        fields = [
            'id', 'name', 'description', 'amount', 'formatted_amount',
            'authorized_by', 'authorized_initials', 'date', 'time',
            'beneficiary_name', 'beneficiary_contact', 'beneficiary_summary',
            'notes', 'zakat_summary', 'zakat_age_days',
            'created_at', 'updated_at', 'created_by', 'created_by_name'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'created_by']
    
    def validate_amount(self, value):
        """Validate amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive and greater than zero.")
        return value
    
    def validate_date(self, value):
        """Validate date is not in the future"""
        if value > timezone.now().date():
            raise serializers.ValidationError("Date cannot be in the future.")
        return value
    
    def validate_beneficiary_name(self, value):
        """Validate beneficiary name is provided"""
        if not value or not value.strip():
            raise serializers.ValidationError("Beneficiary name is required for all entries.")
        return value.strip()
    
    def validate(self, attrs):
        """Additional validation"""
        # Ensure authorized_by is from valid choices
        authorized_by = attrs.get('authorized_by')
        if authorized_by:
            valid_choices = [choice[0] for choice in Zakat.AUTHORIZATION_CHOICES]
            if authorized_by not in valid_choices:
                raise serializers.ValidationError({
                    'authorized_by': f'Invalid choice. Must be one of: {", ".join(valid_choices)}'
                })
        
        return attrs


class ZakatCreateSerializer(ZakatSerializer):
    """Serializer for creating Zakat entries"""
    
    def create(self, validated_data):
        """Create Zakat entry with current user as created_by"""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ZakatUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Zakat entries"""
    
    class Meta:
        model = Zakat
        fields = [
            'name', 'description', 'amount', 'authorized_by',
            'date', 'time', 'beneficiary_name', 'beneficiary_contact', 'notes'
        ]
    
    def validate_amount(self, value):
        """Validate amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive and greater than zero.")
        return value
    
    def validate_date(self, value):
        """Validate date is not in the future"""
        if value > timezone.now().date():
            raise serializers.ValidationError("Date cannot be in the future.")
        return value
    
    def validate_beneficiary_name(self, value):
        """Validate beneficiary name is provided"""
        if not value or not value.strip():
            raise serializers.ValidationError("Beneficiary name is required for all entries.")
        return value.strip()


class ZakatListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing Zakat entries"""
    
    formatted_amount = serializers.ReadOnlyField()
    authorized_initials = serializers.ReadOnlyField()
    zakat_summary = serializers.ReadOnlyField()
    beneficiary_summary = serializers.ReadOnlyField()
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = Zakat
        fields = [
            'id', 'name', 'zakat_summary', 'description', 'amount', 'formatted_amount', 
            'authorized_by', 'authorized_initials', 'date', 'time', 'beneficiary_name',
            'beneficiary_contact', 'beneficiary_summary', 'notes', 'created_by_name', 
            'created_at', 'updated_at', 'is_active'
        ]


class ZakatStatisticsSerializer(serializers.Serializer):
    """Serializer for Zakat statistics"""
    
    total_zakat = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    zakat_count = serializers.IntegerField(required=False)
    average_zakat = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    formatted_total = serializers.CharField(required=False)
    formatted_average = serializers.CharField(required=False)
    
    # By authority statistics
    by_authority = serializers.DictField(required=False)
    
    # By beneficiary statistics
    top_beneficiaries = serializers.ListField(required=False)
    
    # Recent trends
    monthly_trend = serializers.ListField(required=False)
    
    def to_representation(self, instance):
        """Custom representation for statistics"""
        # Get basic statistics
        zakat_entries = Zakat.objects.active()
        total_amount = zakat_entries.aggregate(total=Sum('amount'))['total'] or Decimal('0')
        count = zakat_entries.count()
        average = zakat_entries.aggregate(avg=Avg('amount'))['avg'] or Decimal('0')
        
        # Statistics by authority
        by_authority = {}
        for choice in Zakat.AUTHORIZATION_CHOICES:
            authority = choice[0]
            auth_zakat = zakat_entries.filter(authorized_by=authority)
            auth_total = auth_zakat.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            auth_count = auth_zakat.count()
            by_authority[authority] = {
                'total_amount': float(auth_total),
                'formatted_amount': f"PKR {auth_total:,.2f}",
                'count': auth_count,
                'percentage': float((auth_total / total_amount * 100) if total_amount > 0 else 0)
            }
        
        # Top beneficiaries
        top_beneficiaries = []
        beneficiary_stats = zakat_entries.values('beneficiary_name').annotate(
            total_amount=Sum('amount'),
            count=Count('id')
        ).order_by('-total_amount')[:10]
        
        for beneficiary in beneficiary_stats:
            top_beneficiaries.append({
                'name': beneficiary['beneficiary_name'],
                'total_amount': float(beneficiary['total_amount']),
                'formatted_amount': f"PKR {beneficiary['total_amount']:,.2f}",
                'count': beneficiary['count'],
                'percentage': float((beneficiary['total_amount'] / total_amount * 100) if total_amount > 0 else 0)
            })
        
        # Monthly trend (last 6 months)
        from datetime import datetime, timedelta
        from django.db.models import Q
        
        monthly_trend = []
        for i in range(6):
            month_start = (timezone.now().date().replace(day=1) - timedelta(days=i*30))
            month_end = month_start.replace(day=28) + timedelta(days=4)
            month_end = month_end - timedelta(days=month_end.day)
            
            month_zakat = zakat_entries.filter(date__range=[month_start, month_end])
            month_total = month_zakat.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            month_count = month_zakat.count()
            
            monthly_trend.append({
                'month': month_start.strftime('%B %Y'),
                'total_amount': float(month_total),
                'formatted_amount': f"PKR {month_total:,.2f}",
                'count': month_count
            })
        
        return {
            'total_zakat': float(total_amount),
            'zakat_count': count,
            'average_zakat': float(average),
            'formatted_total': f"PKR {total_amount:,.2f}",
            'formatted_average': f"PKR {average:,.2f}",
            'by_authority': by_authority,
            'top_beneficiaries': top_beneficiaries,
            'monthly_trend': monthly_trend
        }


class BulkZakatActionSerializer(serializers.Serializer):
    """Serializer for bulk operations on Zakat entries"""
    
    action = serializers.ChoiceField(choices=['delete', 'activate', 'deactivate'])
    zakat_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1
    )
    
    def validate_zakat_ids(self, value):
        """Validate that all Zakat IDs exist and belong to active entries"""
        existing_ids = set(
            Zakat.objects.filter(id__in=value, is_active=True).values_list('id', flat=True)
        )
        provided_ids = set(value)
        
        if not provided_ids.issubset(existing_ids):
            missing_ids = provided_ids - existing_ids
            raise serializers.ValidationError(
                f"The following Zakat IDs do not exist or are inactive: {list(missing_ids)}"
            )
        
        return value


class MonthlySummarySerializer(serializers.Serializer):
    """Serializer for monthly Zakat summary"""
    
    month = serializers.CharField(required=False)
    year = serializers.IntegerField(required=False)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    formatted_amount = serializers.CharField(required=False)
    zakat_count = serializers.IntegerField(required=False)
    average_zakat = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    formatted_average = serializers.CharField(required=False)
    beneficiaries = serializers.DictField(required=False)
    authorities = serializers.DictField(required=False)
    daily_breakdown = serializers.ListField(required=False)
    
    def to_representation(self, instance):
        """Custom representation for monthly summary"""
        month = instance.get('month', timezone.now().month)
        year = instance.get('year', timezone.now().year)
        
        # Get Zakat entries for the month
        zakat_entries = Zakat.objects.active().filter(
            date__year=year,
            date__month=month
        )
        
        total_amount = zakat_entries.aggregate(total=Sum('amount'))['total'] or Decimal('0')
        count = zakat_entries.count()
        average = zakat_entries.aggregate(avg=Avg('amount'))['avg'] or Decimal('0')
        
        # Beneficiary breakdown
        beneficiaries = {}
        beneficiary_stats = zakat_entries.values('beneficiary_name').annotate(
            total_amount=Sum('amount'),
            count=Count('id')
        )
        
        for beneficiary in beneficiary_stats:
            name = beneficiary['beneficiary_name']
            beneficiaries[name] = {
                'amount': float(beneficiary['total_amount']),
                'formatted_amount': f"PKR {beneficiary['total_amount']:,.2f}",
                'count': beneficiary['count']
            }
        
        # Authority breakdown
        authorities = {}
        for choice in Zakat.AUTHORIZATION_CHOICES:
            authority = choice[0]
            auth_zakat = zakat_entries.filter(authorized_by=authority)
            auth_total = auth_zakat.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            auth_count = auth_zakat.count()
            authorities[authority] = {
                'amount': float(auth_total),
                'formatted_amount': f"PKR {auth_total:,.2f}",
                'count': auth_count
            }
        
        # Daily breakdown
        daily_breakdown = []
        import calendar
        days_in_month = calendar.monthrange(year, month)[1]
        
        for day in range(1, days_in_month + 1):
            day_zakat = zakat_entries.filter(date__day=day)
            day_total = day_zakat.aggregate(total=Sum('amount'))['total'] or Decimal('0')
            day_count = day_zakat.count()
            
            daily_breakdown.append({
                'day': day,
                'amount': float(day_total),
                'formatted_amount': f"PKR {day_total:,.2f}",
                'count': day_count
            })
        
        month_name = calendar.month_name[month]
        
        return {
            'month': month_name,
            'year': year,
            'total_amount': float(total_amount),
            'formatted_amount': f"PKR {total_amount:,.2f}",
            'zakat_count': count,
            'average_zakat': float(average),
            'formatted_average': f"PKR {average:,.2f}",
            'beneficiaries': beneficiaries,
            'authorities': authorities,
            'daily_breakdown': daily_breakdown
        }


class BeneficiaryReportSerializer(serializers.Serializer):
    """Serializer for beneficiary distribution report"""
    
    beneficiary_name = serializers.CharField(required=False)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    formatted_amount = serializers.CharField(required=False)
    distribution_count = serializers.IntegerField(required=False)
    last_distribution_date = serializers.DateField(required=False)
    contact_info = serializers.CharField(required=False)
    recent_distributions = serializers.ListField(required=False)
    
    def to_representation(self, instance):
        """Custom representation for beneficiary report"""
        beneficiary_name = instance.get('beneficiary_name', '')
        
        # Get all Zakat entries for this beneficiary
        beneficiary_zakat = Zakat.objects.active().filter(
            beneficiary_name__icontains=beneficiary_name
        ).order_by('-date')
        
        if not beneficiary_zakat.exists():
            return {
                'beneficiary_name': beneficiary_name,
                'total_amount': 0,
                'formatted_amount': 'PKR 0.00',
                'distribution_count': 0,
                'last_distribution_date': None,
                'contact_info': '',
                'recent_distributions': []
            }
        
        # Calculate statistics
        total_amount = beneficiary_zakat.aggregate(total=Sum('amount'))['total'] or Decimal('0')
        count = beneficiary_zakat.count()
        latest_entry = beneficiary_zakat.first()
        
        # Recent distributions (last 5)
        recent_distributions = []
        for zakat in beneficiary_zakat[:5]:
            recent_distributions.append({
                'id': str(zakat.id),
                'name': zakat.name,
                'amount': float(zakat.amount),
                'formatted_amount': zakat.formatted_amount,
                'date': zakat.date,
                'authorized_by': zakat.authorized_by
            })
        
        return {
            'beneficiary_name': beneficiary_name,
            'total_amount': float(total_amount),
            'formatted_amount': f"PKR {total_amount:,.2f}",
            'distribution_count': count,
            'last_distribution_date': latest_entry.date if latest_entry else None,
            'contact_info': latest_entry.beneficiary_contact or '' if latest_entry else '',
            'recent_distributions': recent_distributions
        }
    