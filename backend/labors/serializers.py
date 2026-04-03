from rest_framework import serializers
from django.db.models import Q
from datetime import date
from .models import Labor, SalarySlip


class LaborSerializer(serializers.ModelSerializer):
    """Complete serializer for Labor model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Computed fields
    display_name = serializers.CharField(read_only=True)
    is_new_labor = serializers.BooleanField(read_only=True)
    is_recent_labor = serializers.BooleanField(read_only=True)
    work_experience_days = serializers.IntegerField(read_only=True)
    work_experience_years = serializers.FloatField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    
    # Phone and location properties
    phone_country_code = serializers.CharField(read_only=True)
    formatted_phone = serializers.CharField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    gender_display = serializers.CharField(read_only=True)
    
    # Payment-related fields (placeholders for future integration)
    advance_payments_count = serializers.SerializerMethodField()
    total_advance_amount = serializers.SerializerMethodField()
    payments_count = serializers.SerializerMethodField()
    total_payments_amount = serializers.SerializerMethodField()
    last_payment_date = serializers.SerializerMethodField()
    remaining_monthly_salary = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    remaining_advance_amount = serializers.SerializerMethodField()
    total_advances_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = Labor
        fields = (
            'id',
            'name',
            'cnic',
            'phone_number',
            'caste',
            'designation',
            'joining_date',
            'salary',
            'current_month',
            'current_year',
            'area',
            'city',
            'gender',
            'age',
            'display_name',
            'initials',
            'is_new_labor',
            'is_recent_labor',
            'work_experience_days',
            'work_experience_years',
            'phone_country_code',
            'formatted_phone',
            'full_address',
            'gender_display',
            'advance_payments_count',
            'total_advance_amount',
            'payments_count',
            'total_payments_amount',
            'last_payment_date',
            'remaining_monthly_salary',
            'remaining_advance_amount',
            'total_advances_amount',
            'fixed_incentive',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'created_by', 'created_by_id',
            'display_name', 'initials', 'is_new_labor', 'is_recent_labor',
            'work_experience_days', 'work_experience_years', 'phone_country_code',
            'formatted_phone', 'full_address', 'gender_display',
            'advance_payments_count', 'total_advance_amount', 'payments_count',
            'total_payments_amount', 'last_payment_date', 'remaining_monthly_salary',
            'remaining_advance_amount', 'total_advances_amount'
        )
    
    def get_advance_payments_count(self, obj):
        """Get total advance payments count for labor"""
        return obj.get_advance_payments_count()
    
    def get_total_advance_amount(self, obj):
        """Get total advance amount for labor"""
        return obj.get_total_advance_amount()
    
    def get_payments_count(self, obj):
        """Get total payments count for labor"""
        return obj.get_payments_count()
    
    def get_total_payments_amount(self, obj):
        """Get total payments amount for labor"""
        return obj.get_total_payments_amount()
    
    def get_last_payment_date(self, obj):
        """Get last payment date for labor"""
        return obj.get_last_payment_date()
    
    def get_remaining_monthly_salary(self, obj):
        """Get remaining monthly salary for labor"""
        # Ensure the salary is reset/corrected before returning
        obj._reset_monthly_salary_if_needed()
        return obj.remaining_monthly_salary
    
    def get_remaining_advance_amount(self, obj):
        """Get remaining advance amount for labor"""
        try:
            from decimal import Decimal
            result = obj.get_remaining_advance_amount()
            return Decimal(str(result)) if result is not None else Decimal('0.00')
        except Exception:
            from decimal import Decimal
            return Decimal('0.00')
    
    def get_total_advances_amount(self, obj):
        """Get total advances amount for current month"""
        try:
            from decimal import Decimal
            result = obj.get_total_advances_amount()
            return Decimal(str(result)) if result is not None else Decimal('0.00')
        except Exception:
            from decimal import Decimal
            return Decimal('0.00')

    def validate_name(self, value):
        """Clean and validate labor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Labor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Labor name must be at least 2 characters long.")
        
        return name

    def validate_cnic(self, value):
        """Clean CNIC and check uniqueness"""
        if not value or not value.strip():
            return None
        
        cnic = value.strip()
        
        # Check if another labor has this CNIC (for create) or different labor (for update)
        queryset = Labor.objects.filter(cnic=cnic)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("A labor with this CNIC already exists.")
        
        return cnic

    def validate_phone_number(self, value):
        """Clean phone number"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        return phone

    def validate_caste(self, value):
        """Clean caste field"""
        if not value:
            return None
        return value.strip().title()

    def validate_designation(self, value):
        """Clean designation field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Designation is required.")
        return value.strip().title()

    def validate_joining_date(self, value):
        """Validate joining date"""
        if value > date.today():
            raise serializers.ValidationError("Joining date cannot be in the future.")
        return value

    def validate_salary(self, value):
        """Validate salary amount"""
        if value <= 0:
            raise serializers.ValidationError("Salary must be greater than zero.")
        return value

    def validate_age(self, value):
        """Validate age"""
        if value < 16:
            raise serializers.ValidationError("Minimum age must be 16 years.")
        if value > 70:
            raise serializers.ValidationError("Maximum age must be 70 years.")
        return value

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


class LaborCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating labors"""
    
    class Meta:
        model = Labor
        fields = (
            'name',
            'cnic',
            'phone_number',
            'caste',
            'designation',
            'joining_date',
            'salary',
            'area',
            'city',
            'gender',
            'age',
            'fixed_incentive'
        )

    def validate_name(self, value):
        """Clean and validate labor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Labor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Labor name must be at least 2 characters long.")
        
        return name

    def validate_cnic(self, value):
        """Clean CNIC and check uniqueness"""
        if not value or not value.strip():
            return None
        
        cnic = value.strip()
        
        # Check uniqueness with formatted CNIC
        if Labor.objects.filter(cnic=cnic).exists():
            raise serializers.ValidationError("A labor with this CNIC already exists in the system.")
        
        return cnic

    def validate_phone_number(self, value):
        """Clean phone number"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        return phone

    def validate_caste(self, value):
        """Clean caste field"""
        if not value:
            return None
        return value.strip().title()

    def validate_designation(self, value):
        """Clean designation field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Designation is required.")
        return value.strip().title()

    def validate_joining_date(self, value):
        """Validate joining date"""
        if value > date.today():
            raise serializers.ValidationError("Joining date cannot be in the future.")
        return value

    def validate_salary(self, value):
        """Validate salary amount"""
        if value <= 0:
            raise serializers.ValidationError("Salary must be greater than zero.")
        return value

    def validate_age(self, value):
        """Validate age"""
        if value < 16:
            raise serializers.ValidationError("Minimum age must be 16 years.")
        if value > 70:
            raise serializers.ValidationError("Maximum age must be 70 years.")
        return value

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

    def create(self, validated_data):
        """Create labor with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class LaborUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating labors"""
    
    class Meta:
        model = Labor
        fields = (
            'name',
            'cnic',
            'phone_number',
            'caste',
            'designation',
            'joining_date',
            'salary',
            'area',
            'city',
            'gender',
            'age',
            'fixed_incentive'
        )

    def validate_name(self, value):
        """Clean and validate labor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Labor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Labor name must be at least 2 characters long.")
        
        return name

    def validate_cnic(self, value):
        """Clean CNIC and check uniqueness"""
        if not value or not value.strip():
            return None
        
        cnic = value.strip()
        
        # Check uniqueness excluding current instance
        queryset = Labor.objects.filter(cnic=cnic)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        
        if queryset.exists():
            raise serializers.ValidationError("Another labor with this CNIC already exists.")
        
        return cnic

    def validate_phone_number(self, value):
        """Clean phone number"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        return phone

    def validate_caste(self, value):
        """Clean caste field"""
        if not value:
            return None
        return value.strip().title()

    def validate_designation(self, value):
        """Clean designation field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Designation is required.")
        return value.strip().title()

    def validate_joining_date(self, value):
        """Validate joining date"""
        if value > date.today():
            raise serializers.ValidationError("Joining date cannot be in the future.")
        return value

    def validate_salary(self, value):
        """Validate salary amount"""
        if value <= 0:
            raise serializers.ValidationError("Salary must be greater than zero.")
        return value

    def validate_age(self, value):
        """Validate age"""
        if value < 16:
            raise serializers.ValidationError("Minimum age must be 16 years.")
        if value > 70:
            raise serializers.ValidationError("Maximum age must be 70 years.")
        return value

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


class LaborListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing labors"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_labor = serializers.BooleanField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    gender_display = serializers.CharField(read_only=True)
    work_experience_years = serializers.FloatField(read_only=True)
    advance_payments_count = serializers.SerializerMethodField()
    total_advance_amount = serializers.SerializerMethodField()
    remaining_monthly_salary = serializers.SerializerMethodField()
    remaining_advance_amount = serializers.SerializerMethodField()
    total_advances_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = Labor
        fields = (
            'id',
            'name',
            'display_name',
            'initials',
            'cnic',
            'phone_number',
            'caste',
            'designation',
            'joining_date',
            'salary',
            'remaining_monthly_salary',
            'remaining_advance_amount',
            'total_advances_amount',
            'area',
            'city',
            'full_address',
            'gender',
            'gender_display',
            'age',
            'is_new_labor',
            'work_experience_years',
            'advance_payments_count',
            'total_advance_amount',
            'is_active',
            'created_at',
            'created_by_email',
            'fixed_incentive'
        )
    
    def get_advance_payments_count(self, obj):
        """Get total advance payments count for labor"""
        return obj.get_advance_payments_count()
    
    def get_total_advance_amount(self, obj):
        """Get total advance amount for labor"""
        return obj.get_total_advance_amount()
    
    def get_remaining_monthly_salary(self, obj):
        """Get remaining monthly salary with auto-correction"""
        obj._reset_monthly_salary_if_needed()
        return obj.remaining_monthly_salary
    
    def get_remaining_advance_amount(self, obj):
        """Get remaining advance amount for labor"""
        try:
            from decimal import Decimal
            result = obj.get_remaining_advance_amount()
            return Decimal(str(result)) if result is not None else Decimal('0.00')
        except Exception:
            return Decimal('0.00')
            
    def get_total_advances_amount(self, obj):
        """Get total advances amount for current month"""
        try:
            from decimal import Decimal
            result = obj.get_total_advances_amount()
            return Decimal(str(result)) if result is not None else Decimal('0.00')
        except Exception:
            return Decimal('0.00')


class LaborDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single labor view"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    initials = serializers.CharField(source='get_initials', read_only=True)
    is_new_labor = serializers.BooleanField(read_only=True)
    is_recent_labor = serializers.BooleanField(read_only=True)
    work_experience_days = serializers.IntegerField(read_only=True)
    work_experience_years = serializers.FloatField(read_only=True)
    phone_country_code = serializers.CharField(read_only=True)
    formatted_phone = serializers.CharField(read_only=True)
    full_address = serializers.CharField(read_only=True)
    gender_display = serializers.CharField(read_only=True)
    
    class Meta:
        model = Labor
        fields = (
            'id',
            'name',
            'display_name',
            'initials',
            'cnic',
            'phone_number',
            'caste',
            'designation',
            'joining_date',
            'salary',
            'area',
            'city',
            'gender',
            'gender_display',
            'age',
            'is_new_labor',
            'is_recent_labor',
            'work_experience_days',
            'work_experience_years',
            'phone_country_code',
            'formatted_phone',
            'full_address',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'fixed_incentive'
        )


class LaborStatsSerializer(serializers.Serializer):
    """Serializer for labor statistics"""
    
    total_labors = serializers.IntegerField()
    active_labors = serializers.IntegerField()
    inactive_labors = serializers.IntegerField()
    new_labors_this_month = serializers.IntegerField()
    recent_labors_this_week = serializers.IntegerField()
    salary_statistics = serializers.DictField()
    age_statistics = serializers.DictField()
    gender_breakdown = serializers.ListField()
    top_designations = serializers.ListField()
    top_cities = serializers.ListField()
    top_castes = serializers.ListField()


class LaborSearchSerializer(serializers.Serializer):
    """Serializer for labor search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for name, cnic, phone, caste, designation, city, or area"
    )
    city = serializers.CharField(
        required=False,
        help_text="Filter by city"
    )
    area = serializers.CharField(
        required=False,
        help_text="Filter by area"
    )
    designation = serializers.CharField(
        required=False,
        help_text="Filter by designation"
    )
    caste = serializers.CharField(
        required=False,
        help_text="Filter by caste"
    )
    gender = serializers.ChoiceField(
        choices=Labor.GENDER_CHOICES,
        required=False,
        help_text="Filter by gender"
    )


class LaborContactUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating labor contact information"""
    
    class Meta:
        model = Labor
        fields = ('phone_number', 'city', 'area')

    def validate_phone_number(self, value):
        """Clean phone number"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
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


class LaborSalaryUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating labor salary and designation"""
    
    class Meta:
        model = Labor
        fields = ('salary', 'designation', 'fixed_incentive')

    def validate_salary(self, value):
        """Validate salary amount"""
        if value <= 0:
            raise serializers.ValidationError("Salary must be greater than zero.")
        return value

    def validate_designation(self, value):
        """Clean designation field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Designation is required.")
        return value.strip().title()


class LaborBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk labor actions"""
    
    labor_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of labor IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('activate', 'Activate'),
            ('deactivate', 'Deactivate'),
            ('update_salary', 'Update Salary'),
        ],
        required=True,
        help_text="Action to perform on selected labors"
    )
    
    # Optional fields for bulk salary update
    salary_amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        help_text="New salary amount for bulk salary update"
    )
    salary_percentage = serializers.FloatField(
        required=False,
        help_text="Percentage increase/decrease for bulk salary update"
    )

    def validate_labor_ids(self, value):
        """Validate that all labor IDs exist"""
        existing_ids = Labor.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Labors not found: {', '.join(missing_ids)}"
            )
        
        return value
    
    def validate(self, data):
        """Cross-field validation"""
        action = data.get('action')
        salary_amount = data.get('salary_amount')
        salary_percentage = data.get('salary_percentage')
        
        if action == 'update_salary':
            if not salary_amount and not salary_percentage:
                raise serializers.ValidationError(
                    "Either salary_amount or salary_percentage is required for salary update action."
                )
            
            if salary_amount and salary_percentage:
                raise serializers.ValidationError(
                    "Cannot specify both salary_amount and salary_percentage."
                )
            
            if salary_amount and salary_amount <= 0:
                raise serializers.ValidationError(
                    "Salary amount must be greater than zero."
                )
        
        return data


class LaborFilterSerializer(serializers.Serializer):
    """Serializer for labor filtering parameters"""
    
    city = serializers.CharField(required=False)
    area = serializers.CharField(required=False)
    designation = serializers.CharField(required=False)
    caste = serializers.CharField(required=False)
    gender = serializers.ChoiceField(choices=Labor.GENDER_CHOICES, required=False)
    min_salary = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    max_salary = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    min_age = serializers.IntegerField(required=False)
    max_age = serializers.IntegerField(required=False)
    joined_after = serializers.DateField(required=False)
    joined_before = serializers.DateField(required=False)


class LaborDuplicateSerializer(serializers.Serializer):
    """Serializer for duplicating a labor"""
    
    name = serializers.CharField(
        max_length=200,
        required=True,
        help_text="Name for the new labor"
    )
    phone_number = serializers.CharField(
        max_length=20,
        required=True,
        help_text="Phone number for the new labor"
    )
    cnic = serializers.CharField(
        max_length=15,
        required=True,
        help_text="CNIC for the new labor"
    )
    age = serializers.IntegerField(
        required=False,
        help_text="Age for the new labor (optional, will use original if not provided)"
    )

    def validate_name(self, value):
        """Clean and validate labor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Labor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Labor name must be at least 2 characters long.")
        
        return name

    def validate_cnic(self, value):
        """Clean CNIC and check uniqueness"""
        if not value or not value.strip():
            raise serializers.ValidationError("CNIC is required.")
        
        cnic = value.strip()
        
        # Check uniqueness
        if Labor.objects.filter(cnic=cnic).exists():
            raise serializers.ValidationError("A labor with this CNIC already exists.")
        
        return cnic

    def validate_phone_number(self, value):
        """Clean phone number"""
        if not value or not value.strip():
            raise serializers.ValidationError("Phone number is required.")
        
        phone = value.strip()
        return phone

    def validate_age(self, value):
        """Validate age if provided"""
        if value and (value < 16 or value > 70):
            raise serializers.ValidationError("Age must be between 16 and 70 years.")
        return value


class LaborPaymentSummarySerializer(serializers.Serializer):
    """Serializer for labor payment summary (placeholder)"""
    
    labor_id = serializers.UUIDField(read_only=True)
    labor_name = serializers.CharField(read_only=True)
    advance_payments = serializers.ListField(read_only=True)
    regular_payments = serializers.ListField(read_only=True)
    total_advance_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_payments_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    remaining_advance_balance = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    last_payment_date = serializers.DateTimeField(read_only=True)
    note = serializers.CharField(read_only=True)
    
class SalarySlipSerializer(serializers.ModelSerializer):
    """Serializer for SalarySlip model"""
    labor_name = serializers.CharField(source='labor.name', read_only=True)
    labor_designation = serializers.CharField(source='labor.designation', read_only=True)
    labor_cnic = serializers.CharField(source='labor.cnic', read_only=True)
    labor_phone = serializers.CharField(source='labor.phone_number', read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = SalarySlip
        fields = (
            'id', 'reference_number', 'labor', 'labor_name', 'labor_designation', 'labor_cnic', 'labor_phone',
            'month', 'year', 'salary_date',
            'base_salary', 'total_advances', 'deductions', 'bonuses', 'net_salary',
            'status', 'payment_date', 'notes',
            'created_at', 'updated_at', 'created_by'
        )
        read_only_fields = ('net_salary', 'created_at', 'updated_at', 'created_by')

class SalaryGenerationSerializer(serializers.Serializer):
    """Serializer for generating monthly salary slips"""
    month = serializers.IntegerField(min_value=1, max_value=12)
    year = serializers.IntegerField(min_value=2000)

    def validate(self, data):
        # Additional validation if needed
        return data

