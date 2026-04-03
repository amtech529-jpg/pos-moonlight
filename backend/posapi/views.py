from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import login, logout
from django.utils import timezone
from django.db import transaction
from .models import User, Role, RolePermission
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    ChangePasswordSerializer,
    RoleSerializer,
    RolePermissionSerializer
)


@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """
    Register a new user
    """
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                user = serializer.save()
                
                # Create authentication token
                token, created = Token.objects.get_or_create(user=user)
                
                return Response({
                    'success': True,
                    'message': 'User registered successfully.',
                    'data': {
                        'user': UserSerializer(user).data,
                        'token': token.key
                    }
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Registration failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Registration failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """
    Login user with email and password
    """
    serializer = UserLoginSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            user = serializer.validated_data['user']
            
            # Update last login
            user.last_login = timezone.now()
            user.save(update_fields=['last_login'])
            
            # Get or create token
            token, created = Token.objects.get_or_create(user=user)
            
            # Login user (for session-based auth if needed)
            login(request, user)
            
            return Response({
                'success': True,
                'message': 'Login successful.',
                'data': {
                    'user': UserSerializer(user).data,
                    'token': token.key
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Login failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Login failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """
    Logout user and delete token
    """
    try:
        # Delete the user's token
        token = Token.objects.get(user=request.user)
        token.delete()
        
        # Logout user from session
        logout(request)
        
        return Response({
            'success': True,
            'message': 'Logout successful.'
        }, status=status.HTTP_200_OK)
        
    except Token.DoesNotExist:
        # Token doesn't exist, but still logout the session
        logout(request)
        return Response({
            'success': True,
            'message': 'Logout successful.'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Logout failed.',
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """
    Get current user profile
    """
    serializer = UserSerializer(request.user)
    
    return Response({
        'success': True,
        'data': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_user_profile(request):
    """
    Update user profile
    """
    serializer = UserSerializer(
        request.user,
        data=request.data,
        partial=request.method == 'PATCH'
    )
    
    if serializer.is_valid():
        serializer.save()
        
        return Response({
            'success': True,
            'message': 'Profile updated successfully.',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Profile update failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Change user password
    """
    serializer = ChangePasswordSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            user = request.user
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            
            # Delete old token and create new one for security
            try:
                old_token = Token.objects.get(user=user)
                old_token.delete()
            except Token.DoesNotExist:
                pass
            
            token = Token.objects.create(user=user)
            
            return Response({
                'success': True,
                'message': 'Password changed successfully.',
                'data': {
                    'token': token.key
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Password change failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Password change failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


# --- USER MANAGEMENT VIEWS ---

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def manage_users(request):
    """
    List or create users
    """
    if request.method == 'GET':
        users = User.objects.all().order_by('-date_joined')
        serializer = UserSerializer(users, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    elif request.method == 'POST':
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'success': True,
                'message': 'User created successfully.',
                'data': UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def user_detail(request, pk):
    """
    Get, update or delete user
    """
    try:
        user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response({'success': False, 'message': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    
    if request.method == 'GET':
        return Response({'success': True, 'data': UserSerializer(user).data})
    
    elif request.method == 'PUT':
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            # Handle role update specifically if provided
            role_id = request.data.get('role_id')
            if role_id:
                try:
                    role = Role.objects.get(id=role_id)
                    user.role = role
                    user.save()
                except Role.DoesNotExist:
                    pass
            # Handle admin password reset if provided
            new_password = request.data.get('new_password')
            if new_password and len(new_password) >= 4:
                user.set_password(new_password)
                user.save()
            return Response({'success': True, 'data': UserSerializer(user).data})
        return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
    
    elif request.method == 'DELETE':
        user.delete()
        return Response({'success': True, 'message': 'User deleted successfully'})


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def manage_roles(request):
    """
    List or create roles
    """
    if request.method == 'GET':
        roles = Role.objects.all().order_by('name')
        serializer = RoleSerializer(roles, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    elif request.method == 'POST':
        serializer = RoleSerializer(data=request.data)
        if serializer.is_valid():
            role = serializer.save()
            return Response({
                'success': True,
                'data': RoleSerializer(role).data
            }, status=status.HTTP_201_CREATED)
        return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_role_permissions(request, role_id):
    """
    Update permission matrix for a role
    """
    try:
        role = Role.objects.get(pk=role_id)
    except Role.DoesNotExist:
        return Response({'success': False, 'message': 'Role not found'}, status=status.HTTP_404_NOT_FOUND)
    
    permissions_data = request.data.get('permissions', [])
    
    with transaction.atomic():
        for perm in permissions_data:
            module_name = perm.get('module_name')
            role_perm, created = RolePermission.objects.get_or_create(
                role=role, 
                module_name=module_name
            )
            role_perm.can_view = perm.get('can_view', False)
            role_perm.can_add = perm.get('can_add', False)
            role_perm.can_edit = perm.get('can_edit', False)
            role_perm.can_delete = perm.get('can_delete', False)
            role_perm.save()
            
    return Response({
        'success': True,
        'message': 'Permissions updated successfully.',
        'data': RoleSerializer(role).data
    })
    