from rest_framework import permissions


class IsCategoryOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of a category to edit it.
    All authenticated users can read, but only the creator can modify.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions are only allowed to the owner of the category
        return obj.created_by == request.user


class IsActiveCategoryOnly(permissions.BasePermission):
    """
    Permission to only allow access to active categories unless specifically requested.
    """

    def has_object_permission(self, request, view, obj):
        # Allow access to inactive categories only if explicitly requested
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        
        if not obj.is_active and not show_inactive:
            return False
        
        return True


class CanManageCategories(permissions.BasePermission):
    """
    Permission for users who can manage categories.
    This can be extended to check for specific user roles or permissions.
    """

    def has_permission(self, request, view):
        # For now, all authenticated users can manage categories
        # This can be extended to check for specific permissions
        return request.user and request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        # For now, all authenticated users can manage any category
        # This can be extended to check ownership or specific roles
        return request.user and request.user.is_authenticated
    