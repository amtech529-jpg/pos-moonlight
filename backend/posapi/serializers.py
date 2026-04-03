from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import User, Role, RolePermission
class RolePermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RolePermission
        fields = ('id', 'module_name', 'can_view', 'can_add', 'can_edit', 'can_delete')


class RoleSerializer(serializers.ModelSerializer):
    permissions = RolePermissionSerializer(many=True, read_only=True)

    class Meta:
        model = Role
        fields = ('id', 'name', 'description', 'permissions')


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    role_id = serializers.IntegerField(required=False, write_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'full_name', 'email', 'password', 'password_confirm', 'agreed_to_terms', 'role_id')
        extra_kwargs = {
            'password': {'write_only': True},
            'id': {'read_only': True}
        }
    
    def validate_email(self, value):
        """Validate email uniqueness"""
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists.")
        return value
    
    def validate_agreed_to_terms(self, value):
        """Validate that user agreed to terms"""
        if not value:
            raise serializers.ValidationError("You must agree to the terms and conditions.")
        return value
    
    def validate(self, attrs):
        """Validate password confirmation and strength"""
        password = attrs.get('password')
        password_confirm = attrs.get('password_confirm')
        
        if password != password_confirm:
            raise serializers.ValidationError({
                'password_confirm': 'Password confirmation does not match.'
            })
        
        # Validate password strength using Django's validators
        try:
            validate_password(password)
        except ValidationError as e:
            raise serializers.ValidationError({'password': e.messages})
        
        return attrs
    
    def create(self, validated_data):
        """Create user with encrypted password"""
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        role_id = validated_data.pop('role_id', None)
        
        # Check if this is the first user
        is_first_user = not User.objects.exists()
        
        user = User.objects.create_user(
            password=password,
            **validated_data
        )
        
        # Priority 1: Use provided role_id
        if role_id:
            try:
                role = Role.objects.get(id=role_id)
                user.role = role
                user.save()
            except Role.DoesNotExist:
                pass
        
        # Priority 2: If first user, make them Admin
        elif is_first_user:
            try:
                role, created = Role.objects.get_or_create(
                    name='Admin',
                    defaults={'description': 'Full access to all system modules and settings'}
                )
                user.role = role
                user.is_superuser = True
                user.save()
                print(f"DEBUG: First user {user.email} assigned Admin role")
            except Exception as e:
                print(f"DEBUG: Error assigning admin role: {e}")
                
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    
    email = serializers.EmailField()
    password = serializers.CharField(
        style={'input_type': 'password'},
        trim_whitespace=False
    )
    
    def validate(self, attrs):
        """Validate user credentials"""
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            user = authenticate(
                request=self.context.get('request'),
                username=email,
                password=password
            )
            
            if not user:
                raise serializers.ValidationError(
                    'Invalid email or password.',
                    code='authorization'
                )
            
            if not user.is_active:
                raise serializers.ValidationError(
                    'User account is disabled.',
                    code='authorization'
                )
            
            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError(
                'Must include email and password.',
                code='authorization'
            )


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user profile"""
    role_name = serializers.CharField(source='role.name', read_only=True)
    role_id = serializers.IntegerField(source='role.id', read_only=True)
    permissions = RolePermissionSerializer(source='role.permissions', many=True, read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'full_name', 'email', 'role_id', 'role_name', 'permissions', 'is_active', 'is_superuser', 'date_joined', 'last_login')
        read_only_fields = ('id', 'date_joined', 'last_login')


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password"""
    
    old_password = serializers.CharField(style={'input_type': 'password'})
    new_password = serializers.CharField(
        min_length=8,
        style={'input_type': 'password'}
    )
    new_password_confirm = serializers.CharField(style={'input_type': 'password'})
    
    def validate_old_password(self, value):
        """Validate old password"""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Old password is incorrect.')
        return value
    
    def validate(self, attrs):
        """Validate new password confirmation"""
        new_password = attrs.get('new_password')
        new_password_confirm = attrs.get('new_password_confirm')
        
        if new_password != new_password_confirm:
            raise serializers.ValidationError({
                'new_password_confirm': 'New password confirmation does not match.'
            })
        
        # Validate password strength
        try:
            validate_password(new_password)
        except ValidationError as e:
            raise serializers.ValidationError({'new_password': e.messages})
        
        return attrs
    