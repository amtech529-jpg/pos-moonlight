from rest_framework import serializers
from django.db.models import Q
from .models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    """Complete serializer for Customer model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Computed fields
    display_name = serializers.CharField(read_only=True)
    is_new_customer = serializers.BooleanField(read_only=True)
    is_recent_customer = serializers.BooleanField(read_only=True)
    customer_age_days = serializers.IntegerField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    
    # International customer properties
    is_pakistani_customer = serializers.BooleanField(read_only=True)
    phone_country_code = serializers.CharField(read_only=True)
    formatted_country_phone = serializers.CharField(read_only=True)
    
    # Status display
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    customer_type_display = serializers.CharField(source='get_customer_type_display', read_only=True)

    total_sales_amount = serializers.ReadOnlyField()
    total_sales_count = serializers.ReadOnlyField()
    latest_sale_date = serializers.SerializerMethodField()
    sales_summary = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = (
            'id',
            'name',
            'phone',
            'email',
            'address',
            'city',
            'country',
            'customer_type',
            'customer_type_display',
            'status',
            'status_display',
            'notes',
            'phone_verified',
            'email_verified',
            'business_name',
            'tax_number',
            'display_name',
            'initials',
            'is_new_customer',
            'is_recent_customer',
            'customer_age_days',
            'is_pakistani_customer',
            'phone_country_code',
            'formatted_country_phone',
            'last_order_date',
            'last_contact_date',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id',
            'total_sales_amount',
            'total_sales_count', 
            'latest_sale_date',
            'sales_summary'
        )
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'created_by', 'created_by_id',
            'display_name', 'initials', 'is_new_customer', 'is_recent_customer',
            'customer_age_days', 'status_display', 'customer_type_display',
            'is_pakistani_customer', 'phone_country_code', 'formatted_country_phone'
        )

    def get_latest_sale_date(self, obj):
        """Get customer's latest sale date"""
        latest_sale = obj.sales.filter(is_active=True).order_by('-date_of_sale').first()
        return latest_sale.date_of_sale if latest_sale else None
        
    def get_sales_summary(self, obj):
        """Get customer sales summary"""
        return {
            'total_sales': obj.total_sales_count,
            'total_amount': float(obj.total_sales_amount),
            'formatted_amount': f"PKR {obj.total_sales_amount:,.2f}",
            'has_sales': obj.total_sales_count > 0
        }

    def validate_name(self, value):
        """Clean and validate customer name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Customer name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Customer name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check if another customer has this phone (for create) or different customer (for update)
        queryset = Customer.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A customer with this phone number already exists.")
        
        return phone

    def validate_email(self, value):
        """Validate email and check uniqueness"""
        if value:
            email = value.strip().lower()
            if not email:
                return None
            
            # Check if another customer has this email (for create) or different customer (for update)
            queryset = Customer.objects.filter(email=email)
            if self.instance:
                queryset = queryset.exclude(id=self.instance.id)
            
            if queryset.exists():
                raise serializers.ValidationError("A customer with this email already exists.")
            
            return email
        return None

    def validate_city(self, value):
        """Clean city field"""
        if value:
            return value.strip().title()
        return value

    def validate_country(self, value):
        """Clean country field"""
        if value:
            return value.strip().title()
        return 'Pakistan'  # Default to Pakistan if not specified

    def validate_address(self, value):
        """Clean address field"""
        if value:
            return value.strip()
        return value

    def validate_business_name(self, value):
        """Clean business name"""
        if value:
            return value.strip()
        return value

    def validate_tax_number(self, value):
        """Clean tax number"""
        if value:
            return value.strip().upper()
        return value

    def validate(self, data):
        """Cross-field validation"""
        customer_type = data.get('customer_type', getattr(self.instance, 'customer_type', None))
        business_name = data.get('business_name', getattr(self.instance, 'business_name', None))
        
        # Business customers must have business name
        if customer_type == 'BUSINESS' and not business_name:
            raise serializers.ValidationError({
                'business_name': 'Business name is required for business customers.'
            })
        
        return data


class CustomerCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating customers"""
    
    class Meta:
        model = Customer
        fields = (
            'name',
            'phone',
            'email',
            'address',
            'city',
            'country',
            'customer_type',
            'business_name',
            'tax_number',
            'notes'
        )

    def validate_name(self, value):
        """Clean and validate customer name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Customer name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Customer name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness
        if Customer.objects.filter(phone=phone).exists():
            raise serializers.ValidationError("A customer with this phone number already exists.")
        
        return phone

    def validate_email(self, value):
        """Validate email and check uniqueness"""
        if value:
            email = value.strip().lower()
            if not email:
                return None
            
            if Customer.objects.filter(email=email).exists():
                raise serializers.ValidationError("A customer with this email already exists.")
            
            return email
        return None

    def validate_city(self, value):
        """Clean city field"""
        if value:
            return value.strip().title()
        return value

    def validate_country(self, value):
        """Clean country field"""
        if value:
            return value.strip().title()
        return 'Pakistan'  # Default to Pakistan if not specified

    def validate_address(self, value):
        """Clean address field"""
        if value:
            return value.strip()
        return value

    def validate_business_name(self, value):
        """Clean business name"""
        if value:
            return value.strip()
        return value

    def validate_tax_number(self, value):
        """Clean tax number"""
        if value:
            return value.strip().upper()
        return value

    def validate(self, data):
        """Cross-field validation"""
        customer_type = data.get('customer_type', 'INDIVIDUAL')
        business_name = data.get('business_name')
        
        # Business customers must have business name
        if customer_type == 'BUSINESS' and not business_name:
            raise serializers.ValidationError({
                'business_name': 'Business name is required for business customers.'
            })
        
        return data

    def create(self, validated_data):
        """Create customer with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class CustomerUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating customers"""
    
    class Meta:
        model = Customer
        fields = (
            'name',
            'phone',
            'email',
            'address',
            'city',
            'country',
            'customer_type',
            'status',
            'business_name',
            'tax_number',
            'notes',
            'phone_verified',
            'email_verified'
        )

    def validate_name(self, value):
        """Clean and validate customer name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Customer name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Customer name must be at least 2 characters long.")
        
        return name

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness excluding current instance
        queryset = Customer.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A customer with this phone number already exists.")
        
        return phone

    def validate_email(self, value):
        """Validate email and check uniqueness"""
        if value:
            email = value.strip().lower()
            if not email:
                return None
            
            # Check uniqueness excluding current instance
            queryset = Customer.objects.filter(email=email)
            if self.instance:
                queryset = queryset.exclude(id=self.instance.id)
            
            if queryset.exists():
                raise serializers.ValidationError("A customer with this email already exists.")
            
            return email
        return None

    def validate_city(self, value):
        """Clean city field"""
        if value:
            return value.strip().title()
        return value

    def validate_country(self, value):
        """Clean country field"""
        if value:
            return value.strip().title()
        return value

    def validate_address(self, value):
        """Clean address field"""
        if value:
            return value.strip()
        return value

    def validate_business_name(self, value):
        """Clean business name"""
        if value:
            return value.strip()
        return value

    def validate_tax_number(self, value):
        """Clean tax number"""
        if value:
            return value.strip().upper()
        return value

    def validate(self, data):
        """Cross-field validation"""
        customer_type = data.get('customer_type', getattr(self.instance, 'customer_type', None))
        business_name = data.get('business_name', getattr(self.instance, 'business_name', None))
        
        # Business customers must have business name
        if customer_type == 'BUSINESS' and not business_name:
            raise serializers.ValidationError({
                'business_name': 'Business name is required for business customers.'
            })
        
        return data


class CustomerListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing customers"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    customer_type_display = serializers.CharField(source='get_customer_type_display', read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_customer = serializers.BooleanField(read_only=True)
    
    # Fix: Add proper source for computed fields
    total_sales_count = serializers.IntegerField(read_only=True)
    total_sales_amount = serializers.ReadOnlyField()  # Add total sales amount
    has_recent_sales = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = (
            'id',
            'name',
            'display_name',
            'initials',
            'phone',
            'email',
            'city',
            'country',
            'customer_type',
            'customer_type_display',
            'status',
            'status_display',
            'phone_verified',
            'email_verified',
            'is_new_customer',
            'last_order_date',
            'is_active',
            'created_at',
            'created_by_email',
            'total_sales_count',
            'total_sales_amount',
            'has_recent_sales'
        )
    
    def get_has_recent_sales(self, obj):
        """Check if customer has sales in last 90 days"""
        try:
            return obj.get_has_recent_sales()
        except Exception:
            return False


class CustomerDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single customer view"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    customer_type_display = serializers.CharField(source='get_customer_type_display', read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_customer = serializers.BooleanField(read_only=True)
    is_recent_customer = serializers.BooleanField(read_only=True)
    customer_age_days = serializers.IntegerField(read_only=True)
    is_pakistani_customer = serializers.BooleanField(read_only=True)
    phone_country_code = serializers.CharField(read_only=True)
    formatted_country_phone = serializers.CharField(read_only=True)
    
    class Meta:
        model = Customer
        fields = (
            'id',
            'name',
            'display_name',
            'initials',
            'phone',
            'email',
            'address',
            'city',
            'country',
            'customer_type',
            'customer_type_display',
            'status',
            'status_display',
            'notes',
            'phone_verified',
            'email_verified',
            'business_name',
            'tax_number',
            'is_new_customer',
            'is_recent_customer',
            'customer_age_days',
            'is_pakistani_customer',
            'phone_country_code',
            'formatted_country_phone',
            'last_order_date',
            'last_contact_date',
            'is_active',
            'created_at',
            'updated_at',
            'created_by'
        )
    
    # Remove duplicate method - not needed for CustomerDetailSerializer


class CustomerStatsSerializer(serializers.Serializer):
    """Serializer for customer statistics"""
    
    total_customers = serializers.IntegerField()
    new_customers_this_month = serializers.IntegerField()
    recent_customers_this_week = serializers.IntegerField()
    inactive_customers = serializers.IntegerField()
    status_breakdown = serializers.DictField()
    type_breakdown = serializers.DictField()
    verification_stats = serializers.DictField()
    top_countries = serializers.ListField()


class CustomerSearchSerializer(serializers.Serializer):
    """Serializer for customer search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for name, phone, email, or business name"
    )
    customer_type = serializers.ChoiceField(
        choices=Customer.TYPE_CHOICES,
        required=False,
        help_text="Filter by customer type"
    )
    status = serializers.ChoiceField(
        choices=Customer.STATUS_CHOICES,
        required=False,
        help_text="Filter by customer status"
    )
    city = serializers.CharField(
        required=False,
        help_text="Filter by city"
    )
    country = serializers.CharField(
        required=False,
        help_text="Filter by country"
    )
    verified = serializers.ChoiceField(
        choices=[('any', 'Any'), ('phone', 'Phone'), ('email', 'Email'), ('both', 'Both')],
        required=False,
        default='any',
        help_text="Filter by verification status"
    )


class CustomerContactUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating customer contact information"""
    
    class Meta:
        model = Customer
        fields = ('phone', 'email', 'address', 'city', 'country')

    def validate_phone(self, value):
        """Clean phone number and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        
        # Check uniqueness excluding current instance
        queryset = Customer.objects.filter(phone=phone)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A customer with this phone number already exists.")
        
        return phone

    def validate_email(self, value):
        """Validate email and check uniqueness"""
        if value:
            email = value.strip().lower()
            if not email:
                return None
            
            # Check uniqueness excluding current instance
            queryset = Customer.objects.filter(email=email)
            if self.instance:
                queryset = queryset.exclude(id=self.instance.id)
            
            if queryset.exists():
                raise serializers.ValidationError("A customer with this email already exists.")
            
            return email
        return None


class CustomerVerificationSerializer(serializers.Serializer):
    """Serializer for customer verification actions"""
    
    verification_type = serializers.ChoiceField(
        choices=[('phone', 'Phone'), ('email', 'Email')],
        required=True,
        help_text="Type of verification to perform"
    )
    verified = serializers.BooleanField(
        default=True,
        help_text="Verification status to set"
    )


class CustomerBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk customer actions"""
    
    customer_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of customer IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('activate', 'Activate'),
            ('deactivate', 'Deactivate'),
            ('mark_regular', 'Mark as Regular'),
            ('mark_vip', 'Mark as VIP'),
            ('verify_phone', 'Verify Phone'),
            ('verify_email', 'Verify Email'),
        ],
        required=True,
        help_text="Action to perform on selected customers"
    )

    def validate_customer_ids(self, value):
        """Validate that all customer IDs exist"""
        existing_ids = Customer.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Customers not found: {', '.join(missing_ids)}"
            )
        
        return value
        