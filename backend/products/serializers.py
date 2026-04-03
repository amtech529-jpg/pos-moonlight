from rest_framework import serializers
from django.db.models import Q, Sum
from .models import Product
from categories.models import Category


class ProductSerializer(serializers.ModelSerializer):
    """Complete serializer for Product model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Category details
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_id = serializers.UUIDField(source='category.id', read_only=True)
    
    # Computed fields
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',
            'price',
            'cost_price',
            'serial_number',
            'warehouse_location',
            'pricing_type',
            'is_rental',
            'is_consumable',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'quantity_available',
            'quantity_reserved',
            'quantity_damaged',
            'barcode',
            'sku',
            'category_id',
            'category_name',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'created_by', 'created_by_id',
            'category_id', 'category_name', 'stock_status', 'stock_status_display', 'total_value'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        # Remove empty strings and strip whitespace
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        # if not cleaned_pieces:
        #    raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:  # Max value for decimal(12,2)
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        return value.strip()

    def validate_color(self, value):
        """Clean color field"""
        if value:
            return value.strip().title()
        return None

    def validate_fabric(self, value):
        """Clean fabric field"""
        if value:
            return value.strip().title()
        return None

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()


class ProductCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating products"""
    
    category = serializers.UUIDField(write_only=True, help_text="Category UUID")
    
    class Meta:
        model = Product
        fields = (
            'name',
            'detail',
            'price',
            'cost_price',
            'serial_number',
            'warehouse_location',
            'pricing_type',
            'is_rental',
            'is_consumable',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'barcode',
            'sku',
            'min_stock_threshold',
            'category'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        # if not cleaned_pieces:
        #    raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_category(self, value):
        """Validate category exists and is active"""
        try:
            category = Category.objects.get(id=value, is_active=True)
            return category
        except Category.DoesNotExist:
            raise serializers.ValidationError("Invalid category or category is not active.")

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        
        name = value.strip()
        # Access category from initial_data because it might not be validated yet
        category_id = self.initial_data.get('category')
        
        if category_id:
            exists = Product.objects.filter(
                name__iexact=name,
                category_id=category_id,
                is_active=True
            ).exists()
            
            if exists:
                raise serializers.ValidationError(
                    f"A product with the name '{name}' already exists in this category. Please update the existing product instead."
                )
        
        return name


    def validate_color(self, value):
        """Clean color field"""
        if value:
            return value.strip().title()
        return None

    def validate_fabric(self, value):
        """Clean fabric field"""
        if value:
            return value.strip().title()
        return None

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()

    def create(self, validated_data):
        """Create product with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)

    def validate_cost_price(self, value):
        """Validate cost price field"""
        if value is not None:
            if value < 0:
                raise serializers.ValidationError("Cost price cannot be negative.")
            if value > 9999999999.99:
                raise serializers.ValidationError("Cost price is too large.")
        return value


class ProductUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating products"""
    
    category = serializers.UUIDField(write_only=True, help_text="Category UUID", required=False)
    
    class Meta:
        model = Product
        fields = (
            'name',
            'detail',
            'price',
            'cost_price',
            'serial_number',
            'warehouse_location',
            'pricing_type',
            'is_rental',
            'is_consumable',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'category',
            'min_stock_threshold'
        )

    def validate_pieces(self, value):
        """Validate pieces field"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Pieces must be a list.")
        
        cleaned_pieces = [piece.strip() for piece in value if piece.strip()]
        
        # if not cleaned_pieces:
        #    raise serializers.ValidationError("At least one piece is required.")
        
        # Check for duplicates (case-insensitive)
        lower_pieces = [piece.lower() for piece in cleaned_pieces]
        if len(lower_pieces) != len(set(lower_pieces)):
            raise serializers.ValidationError("Pieces cannot contain duplicates.")
        
        return cleaned_pieces

    def validate_category(self, value):
        """Validate category exists and is active"""
        try:
            category = Category.objects.get(id=value, is_active=True)
            return category
        except Category.DoesNotExist:
            raise serializers.ValidationError("Invalid category or category is not active.")

    def validate_price(self, value):
        """Validate price field"""
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Price is too large.")
        return value

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative.")
        return value

    def validate_name(self, value):
        """Clean and validate product name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product name is required.")
        
        name = value.strip()
        # Get category_id from initial_data or current instance
        category_id = self.initial_data.get('category')
        if not category_id and self.instance:
            category_id = self.instance.category_id
            
        if category_id:
            query = Product.objects.filter(
                name__iexact=name,
                category_id=category_id,
                is_active=True
            )
            
            # Exclude current product if we are updating
            if self.instance:
                query = query.exclude(id=self.instance.id)
                
            if query.exists():
                raise serializers.ValidationError(
                    f"Another product with the name '{name}' already exists in this category."
                )
        
        return name


    def validate_color(self, value):
        """Clean color field"""
        if value:
            return value.strip().title()
        return None

    def validate_fabric(self, value):
        """Clean fabric field"""
        if value:
            return value.strip().title()
        return None

    def validate_detail(self, value):
        """Clean detail field"""
        if not value or not value.strip():
            raise serializers.ValidationError("Product detail/description is required.")
        return value.strip()

    def validate_cost_price(self, value):
        """Validate cost price field"""
        if value is not None:
            if value < 0:
                raise serializers.ValidationError("Cost price cannot be negative.")
            if value > 9999999999.99:
                raise serializers.ValidationError("Cost price is too large.")
        return value


    def update(self, instance, validated_data):
        """Override update to recalculate quantity_available after save.
        This fixes the bug where editing a product causes Out of Stock display.
        """
        instance = super().update(instance, validated_data)
        instance.update_available_quantity()
        return instance


class ProductListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing products"""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    total_sold = serializers.SerializerMethodField()
    monthly_revenue = serializers.SerializerMethodField()
    date_available_quantity = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',
            'price',
            'cost_price',
            'serial_number', # Added
            'warehouse_location', # Added
            'pricing_type', # Added
            'is_rental', # Added
            'is_consumable', # Added
            'color',
            'fabric',
            'pieces',
            'quantity',
            'quantity_available',
            'quantity_reserved',
            'quantity_damaged',
            'barcode',
            'sku',
            'category_name',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'created_by_email',
            'total_sold',
            'min_stock_threshold',
            'monthly_revenue',
            'date_available_quantity'
        )

    def get_total_sold(self, obj):
        """Get total quantity sold"""
        return obj.get_total_sales_quantity()
    
    def get_monthly_revenue(self, obj):
        """Get total revenue in last 30 days"""
        # This will be aggregated from last 30 days sales
        return obj.get_sales_by_period(30).aggregate(
            total=Sum('line_total')
        )['total'] or 0.0

    def get_date_available_quantity(self, obj):
        """Get available quantity for a specific date range if provided in context"""
        from datetime import datetime
        start_date_str = self.context.get('start_date')
        end_date_str = self.context.get('end_date')
        
        if not start_date_str or not end_date_str:
            return None
            
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            return obj.get_available_quantity_for_dates(start_date, end_date)
        except Exception:
            return None


class ProductDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single product view"""
    
    category = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    stock_status = serializers.CharField(read_only=True)
    stock_status_display = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    total_sales_quantity = serializers.SerializerMethodField()
    total_sales_revenue = serializers.SerializerMethodField()
    sales_performance = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = (
            'id',
            'name',
            'detail',
            'price',
            'cost_price',
            'serial_number',
            'warehouse_location',
            'pricing_type',
            'is_rental',
            'is_consumable',
            'color',
            'fabric',
            'pieces',
            'quantity',
            'quantity_available',
            'quantity_reserved',
            'quantity_damaged',
            'barcode',
            'sku',
            'min_stock_threshold',
            'category',
            'stock_status',
            'stock_status_display',
            'total_value',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'total_sales_quantity', 'total_sales_revenue', 'sales_performance'
        )

    def get_category(self, obj):
        """Get category details"""
        return {
            'id': str(obj.category.id),
            'name': obj.category.name,
            'description': obj.category.description
        }
    
    def get_total_sales_quantity(self, obj):
        """Get total quantity sold"""
        return obj.get_total_sales_quantity()
    
    def get_total_sales_revenue(self, obj):
        """Get total sales revenue"""
        revenue = obj.get_sales_revenue()
        return float(revenue)
    
    def get_sales_performance(self, obj):
        """Get sales performance summary"""
        total_quantity = obj.get_total_sales_quantity()
        total_revenue = obj.get_sales_revenue()
        return {
            'total_sold': total_quantity,
            'total_revenue': float(total_revenue),
            'formatted_revenue': f"PKR {total_revenue:,.2f}",
            'has_sales': total_quantity > 0
        }


class ProductStatsSerializer(serializers.Serializer):
    """Serializer for product statistics"""
    
    total_products = serializers.IntegerField()
    total_inventory_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    low_stock_count = serializers.IntegerField()
    out_of_stock_count = serializers.IntegerField()
    category_breakdown = serializers.ListField()
    stock_status_summary = serializers.DictField()


class BulkQuantityUpdateSerializer(serializers.Serializer):
    """Serializer for bulk quantity updates"""
    
    updates = serializers.ListField(
        child=serializers.DictField(
            child=serializers.CharField()
        ),
        help_text="List of {product_id: new_quantity} updates"
    )

    def validate_updates(self, value):
        """Validate bulk updates"""
        if not value:
            raise serializers.ValidationError("At least one update is required.")
        
        validated_updates = []
        product_ids = []
        
        for update in value:
            if 'product_id' not in update or 'quantity' not in update:
                raise serializers.ValidationError(
                    "Each update must contain 'product_id' and 'quantity'."
                )
            
            try:
                product_id = update['product_id']
                quantity = int(update['quantity'])
                
                if quantity < 0:
                    raise serializers.ValidationError(
                        f"Quantity for product {product_id} cannot be negative."
                    )
                
                product_ids.append(product_id)
                validated_updates.append({
                    'product_id': product_id,
                    'quantity': quantity
                })
                
            except (ValueError, TypeError):
                raise serializers.ValidationError(
                    f"Invalid quantity for product {update.get('product_id', 'unknown')}."
                )
        
        # Check for duplicates
        if len(product_ids) != len(set(product_ids)):
            raise serializers.ValidationError("Duplicate product IDs found in updates.")
        
        # Verify all products exist and are active
        existing_products = Product.active_products().filter(
            id__in=product_ids
        ).values_list('id', flat=True)
        
        existing_ids = [str(pid) for pid in existing_products]
        missing_ids = [pid for pid in product_ids if pid not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Products not found or inactive: {', '.join(missing_ids)}"
            )
        
        return validated_updates
    