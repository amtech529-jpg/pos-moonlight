from rest_framework import serializers
from django.db.models import Q
from .models import Vendor


class VendorSerializer(serializers.ModelSerializer):
    """Complete serializer for Vendor model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Computed fields
    display_name = serializers.CharField(read_only=True)
    is_new_vendor = serializers.BooleanField(read_only=True)
    is_recent_vendor = serializers.BooleanField(read_only=True)
    vendor_age_days = serializers.IntegerField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    
    # Phone and location properties
    phone_country_code = serializers.CharField(read_only=True)
    formatted_phone = serializers.CharField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    
    # Payment-related fields (placeholders for future integration)
    payments_count = serializers.SerializerMethodField()
    total_payments_amount = serializers.SerializerMethodField()
    last_payment_date = serializers.SerializerMethodField()
    
    # Make CNIC optional
    cnic = serializers.CharField(
        required=False,
        allow_null=True,
        allow_blank=True,
        help_text="Pakistani CNIC in format: 12345-1234567-1 (optional)"
    )
    
    class Meta:
        model = Vendor
        fields = (
            'id',
            'name',
            'business_name',
            'cnic',
            'phone',
            'city',
            'area',
            'display_name',
            'initials',
            'is_new_vendor',
            'is_recent_vendor',
            'vendor_age_days',
            'phone_country_code',
            'formatted_phone',
            'full_address',
            'payments_count',
            'total_payments_amount',
            'last_payment_date',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'created_by', 'created_by_id',
            'display_name', 'initials', 'is_new_vendor', 'is_recent_vendor',
            'vendor_age_days', 'phone_country_code', 'formatted_phone',
            'full_address', 'payments_count', 'total_payments_amount', 'last_payment_date'
        )
    
    def get_payments_count(self, obj):
        """Get total payments count for vendor"""
        return obj.get_payments_count()
    
    def get_total_payments_amount(self, obj):
        """Get total payments amount for vendor"""
        return obj.get_total_payments_amount()
    
    def get_last_payment_date(self, obj):
        """Get last payment date for vendor"""
        return obj.get_last_payment_date()

    def validate_name(self, value):
        """Clean and validate vendor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Vendor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Vendor name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check if another vendor has this phone (for create) or different vendor (for update)
        queryset = Vendor.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A vendor with this phone number already exists.")
        
        return phone




class VendorCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating vendors"""
    
    cnic = serializers.CharField(
        required=False,
        allow_null=True,
        allow_blank=True,
        help_text="Pakistani CNIC in format: 12345-1234567-1 (optional)"
    )
    
    class Meta:
        model = Vendor
        fields = (
            'name',
            'business_name',
            'cnic',
            'phone',
            'city',
            'area',
            'created_at'
        )

    def validate_name(self, value):
        """Clean and validate vendor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Vendor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Vendor name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness
        if Vendor.objects.filter(phone=phone).exists():
            raise serializers.ValidationError("A vendor with this phone number already exists.")
        
        return phone



    def create(self, validated_data):
        """Create vendor with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class VendorUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating vendors"""
    
    cnic = serializers.CharField(
        required=False,
        allow_null=True,
        allow_blank=True,
        help_text="Pakistani CNIC in format: 12345-1234567-1 (optional)"
    )
    
    class Meta:
        model = Vendor
        fields = (
            'name',
            'business_name',
            'cnic',
            'phone',
            'city',
            'area'
        )

    def validate_name(self, value):
        """Clean and validate vendor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Vendor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Vendor name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness excluding current instance
        queryset = Vendor.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A vendor with this phone number already exists.")
        
        return phone




class VendorListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing vendors"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_vendor = serializers.BooleanField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    payments_count = serializers.SerializerMethodField()
    total_payments_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = Vendor
        fields = (
            'id',
            'name',
            'business_name',
            'display_name',
            'initials',
            'cnic',
            'phone',
            'city',
            'area',
            'full_address',
            'is_new_vendor',
            'payments_count',
            'total_payments_amount',
            'is_active',
            'created_at',
            'created_by_email'
        )
    
    def get_payments_count(self, obj):
        """Get total payments count for vendor"""
        return obj.get_payments_count()
    
    def get_total_payments_amount(self, obj):
        """Get total payments amount for vendor"""
        return obj.get_total_payments_amount()


class VendorDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single vendor view"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_vendor = serializers.BooleanField(read_only=True)
    is_recent_vendor = serializers.BooleanField(read_only=True)
    vendor_age_days = serializers.IntegerField(read_only=True)
    phone_country_code = serializers.CharField(read_only=True)
    formatted_phone = serializers.CharField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    
    class Meta:
        model = Vendor
        fields = (
            'id',
            'name',
            'business_name',
            'display_name',
            'initials',
            'cnic',
            'phone',
            'city',
            'area',
            'is_new_vendor',
            'is_recent_vendor',
            'vendor_age_days',
            'phone_country_code',
            'formatted_phone',
            'full_address',
            'is_active',
            'created_at',
            'updated_at',
            'created_by'
        )


class VendorStatsSerializer(serializers.Serializer):
    """Serializer for vendor statistics"""
    
    total_vendors = serializers.IntegerField()
    active_vendors = serializers.IntegerField()
    inactive_vendors = serializers.IntegerField()
    new_vendors_this_month = serializers.IntegerField()
    recent_vendors_this_week = serializers.IntegerField()
    top_cities = serializers.ListField()
    top_areas = serializers.ListField()


class VendorSearchSerializer(serializers.Serializer):
    """Serializer for vendor search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for name, business name, phone, CNIC, city, or area"
    )
    city = serializers.CharField(
        required=False,
        help_text="Filter by city"
    )
    area = serializers.CharField(
        required=False,
        help_text="Filter by area"
    )


class VendorContactUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating vendor contact information"""
    
    class Meta:
        model = Vendor
        fields = ('phone', 'city', 'area')

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness excluding current instance
        queryset = Vendor.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A vendor with this phone number already exists.")
        
        return phone

    def validate_city(self, value):
        """Clean city field"""
        if not value or not value.strip():
            raise serializers.ValidationError("City is required.")
        return value.strip().title()

    def validate_area(self, value):
        """Clean area field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Area is required.")
        return value.strip().title()


class VendorBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk vendor actions"""
    
    vendor_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of vendor IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('activate', 'Activate'),
            ('deactivate', 'Deactivate'),
        ],
        required=True,
        help_text="Action to perform on selected vendors"
    )

    def validate_vendor_ids(self, value):
        """Validate that all vendor IDs exist"""
        existing_ids = Vendor.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Vendors not found: {', '.join(missing_ids)}"
            )
        
        return value
    