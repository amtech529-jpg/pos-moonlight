from rest_framework import serializers
from .models import Category


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    class Meta:
        model = Category
        fields = (
            'id', 
            'name', 
            'description', 
            'is_active', 
            'created_at', 
            'updated_at', 
            'created_by',
            'created_by_id'
        )
        read_only_fields = ('id', 'created_at', 'updated_at', 'created_by', 'created_by_id')
    
    def validate_name(self, value):
        """Validate category name uniqueness (case-insensitive)"""
        # Get the instance being updated (if any)
        instance = getattr(self, 'instance', None)
        
        # Check for existing category with same name (case-insensitive)
        existing_category = Category.objects.filter(
            name__iexact=value.strip()
        )
        
        # If updating, exclude the current instance from the check
        if instance:
            existing_category = existing_category.exclude(pk=instance.pk)
        
        if existing_category.exists():
            raise serializers.ValidationError(
                "A category with this name already exists."
            )
        
        return value.strip().title()  # Clean and title case the name
    
    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value


class CategoryCreateSerializer(CategorySerializer):
    """Serializer for creating categories with additional validation"""
    
    class Meta(CategorySerializer.Meta):
        fields = ('name', 'description')
    
    def create(self, validated_data):
        """Create category with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class CategoryListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing categories"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    
    class Meta:
        model = Category
        fields = (
            'id', 
            'name', 
            'description', 
            'is_active',
            'created_at',
            'created_by_email'
        )


class CategoryUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating categories"""
    
    class Meta:
        model = Category
        fields = ('name', 'description')
    
    def validate_name(self, value):
        """Validate category name uniqueness for updates"""
        instance = self.instance
        
        # Check for existing category with same name (case-insensitive)
        existing_category = Category.objects.filter(
            name__iexact=value.strip()
        ).exclude(pk=instance.pk)
        
        if existing_category.exists():
            raise serializers.ValidationError(
                "A category with this name already exists."
            )
        
        return value.strip().title()
    
    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value
    