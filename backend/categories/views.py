from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from .models import Category
from .serializers import (
    CategorySerializer,
    CategoryCreateSerializer,
    CategoryListSerializer,
    CategoryUpdateSerializer
)


# Function-based views (following your User module pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_categories(request):
    """
    List all active categories with pagination
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)  # Max 100 items per page
        page = int(request.GET.get('page', 1))
        
        # Filter categories
        if show_inactive:
            categories = Category.objects.all()
        else:
            categories = Category.active_categories()
        
        # Apply search filter if provided
        search = request.GET.get('search', '').strip()
        if search:
            categories = categories.filter(name__icontains=search)
        
        # Calculate pagination
        total_count = categories.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        categories = categories[start_index:end_index]
        
        serializer = CategoryListSerializer(categories, many=True)
        
        return Response({
            'success': True,
            'data': {
                'categories': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                }
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve categories.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_category(request):
    """
    Create a new category
    """
    serializer = CategoryCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                category = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Category created successfully.',
                    'data': CategorySerializer(category).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Category creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Category creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_category(request, category_id):
    """
    Retrieve a specific category by ID
    """
    try:
        category = Category.objects.get(id=category_id)
        serializer = CategorySerializer(category)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Category.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': 'Category with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_category(request, category_id):
    """
    Update a category
    """
    try:
        category = Category.objects.get(id=category_id)
        
        serializer = CategoryUpdateSerializer(
            category,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    category = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Category updated successfully.',
                        'data': CategorySerializer(category).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Category update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Category update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Category.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': 'Category with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_category(request, category_id):
    """
    Hard delete a category (permanently remove from database)
    """
    try:
        category = Category.objects.get(id=category_id)
        
        # Store category name for response message
        category_name = category.name
        
        # Check if category is being used by products (optional safety check)
        # Uncomment this if you have a Product model that references categories
        if hasattr(category, 'products') and category.products.exists():
            return Response({
                'success': False,
                'message': 'Cannot delete category as it is being used by products.',
                'errors': {'detail': 'This category is currently assigned to one or more products.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the category
        category.delete()
        
        return Response({
            'success': True,
            'message': f'Category "{category_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Category.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': 'Category with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Category deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_category(request, category_id):
    """
    Soft delete a category (set is_active=False) - Alternative endpoint
    """
    try:
        category = Category.objects.get(id=category_id)
        
        if not category.is_active:
            return Response({
                'success': False,
                'message': 'Category is already inactive.',
                'errors': {'detail': 'This category has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        category.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Category soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Category.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': 'Category with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Category soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_category(request, category_id):
    """
    Restore a soft-deleted category (set is_active=True)
    """
    try:
        category = Category.objects.get(id=category_id)
        
        if category.is_active:
            return Response({
                'success': False,
                'message': 'Category is already active.',
                'errors': {'detail': 'This category is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        category.restore()
        
        return Response({
            'success': True,
            'message': 'Category restored successfully.',
            'data': CategorySerializer(category).data
        }, status=status.HTTP_200_OK)
        
    except Category.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Category not found.',
            'errors': {'detail': 'Category with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Category restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Class-based views (DRF standard approach)

class CategoryListCreateAPIView(generics.ListCreateAPIView):
    """Class-based view for listing and creating categories"""
    
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get queryset based on parameters"""
        show_inactive = self.request.GET.get('show_inactive', 'false').lower() == 'true'
        search = self.request.GET.get('search', '').strip()
        
        if show_inactive:
            queryset = Category.objects.all()
        else:
            queryset = Category.active_categories()
        
        if search:
            queryset = queryset.filter(name__icontains=search)
        
        return queryset.order_by('name')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.request.method == 'POST':
            return CategoryCreateSerializer
        return CategoryListSerializer
    
    def create(self, request, *args, **kwargs):
        """Custom create method with consistent response format"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        category = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Category created successfully.',
            'data': CategorySerializer(category).data
        }, status=status.HTTP_201_CREATED)


class CategoryRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Class-based view for retrieving, updating, and deleting categories"""
    
    queryset = Category.objects.all()
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    lookup_url_kwarg = 'category_id'
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.request.method in ['PUT', 'PATCH']:
            return CategoryUpdateSerializer
        return CategorySerializer
    
    def update(self, request, *args, **kwargs):
        """Custom update method with consistent response format"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        category = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Category updated successfully.',
            'data': CategorySerializer(category).data
        }, status=status.HTTP_200_OK)
    
    def destroy(self, request, *args, **kwargs):
        """Custom delete method for hard deletion"""
        instance = self.get_object()
        category_name = instance.name
        
        # Optional safety check for products using this category
        # Uncomment if you have Product model
        if hasattr(instance, 'products') and instance.products.exists():
            return Response({
                'success': False,
                'message': 'Cannot delete category as it is being used by products.',
                'errors': {'detail': 'This category is currently assigned to one or more products.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete
        instance.delete()
        
        return Response({
            'success': True,
            'message': f'Category "{category_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
    