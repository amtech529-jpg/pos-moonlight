from rest_framework import permissions


class ReceivablePermissions(permissions.BasePermission):
    """
    Custom permissions for Receivable model
    
    Permissions:
    - CREATE: Authenticated users can create receivables
    - READ: Users can read receivables they created or all if they have view_all permission
    - UPDATE: Users can update receivables they created or all if they have change_all permission
    - DELETE: Only superusers can delete receivables (soft delete)
    """
    
    def has_permission(self, request, view):
        """Check if user has permission to access the view"""
        # All authenticated users can access receivables
        if not request.user.is_authenticated:
            return False
        
        # Superusers have all permissions
        if request.user.is_superuser:
            return True
        
        # Check specific permissions based on action
        if view.action in ['create', 'list', 'retrieve']:
            return True
        
        if view.action in ['update', 'partial_update']:
            return request.user.has_perm('receivables.change_receivable')
        
        if view.action == 'destroy':
            return request.user.is_superuser
        
        if view.action in ['record_payment', 'restore']:
            return request.user.has_perm('receivables.change_receivable')
        
        return True
    
    def has_object_permission(self, request, view, obj):
        """Check if user has permission to access specific object"""
        # Superusers have all permissions
        if request.user.is_superuser:
            return True
        
        # Users can always read receivables
        if view.action in ['retrieve']:
            return True
        
        # Users can update/delete receivables they created
        if obj.created_by == request.user:
            return True
        
        # Check model-level permissions
        if view.action in ['update', 'partial_update', 'record_payment', 'restore']:
            return request.user.has_perm('receivables.change_receivable')
        
        if view.action == 'destroy':
            return request.user.is_superuser
        
        return False


class ReceivablePaymentPermissions(permissions.BasePermission):
    """
    Custom permissions for recording payments on receivables
    
    Permissions:
    - Only authenticated users can record payments
    - Users can record payments on receivables they created
    - Users with change_receivable permission can record payments on any receivable
    """
    
    def has_permission(self, request, view):
        """Check if user has permission to record payments"""
        return request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        """Check if user has permission to record payment on specific receivable"""
        # Users can record payments on receivables they created
        if obj.created_by == request.user:
            return True
        
        # Users with change permission can record payments on any receivable
        if request.user.has_perm('receivables.change_receivable'):
            return True
        
        return False


class ReceivableSearchPermissions(permissions.BasePermission):
    """
    Custom permissions for searching receivables
    
    Permissions:
    - Authenticated users can search receivables
    - Search results are filtered based on user permissions
    """
    
    def has_permission(self, request, view):
        """Check if user has permission to search receivables"""
        return request.user.is_authenticated


class ReceivableSummaryPermissions(permissions.BasePermission):
    """
    Custom permissions for receivable summary
    
    Permissions:
    - Authenticated users can view summary
    - Summary data is filtered based on user permissions
    """
    
    def has_permission(self, request, view):
        """Check if user has permission to view summary"""
        return request.user.is_authenticated


# Permission constants for easy reference
RECEIVABLE_PERMISSIONS = {
    'add_receivable': 'Can add receivable',
    'change_receivable': 'Can change receivable',
    'delete_receivable': 'Can delete receivable',
    'view_receivable': 'Can view receivable',
    'view_all_receivables': 'Can view all receivables',
    'change_all_receivables': 'Can change all receivables',
    'record_payment': 'Can record payment on receivable',
    'restore_receivable': 'Can restore deleted receivable',
}
