from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from .models import Receivable


def create_receivable_permissions():
    """
    Create default permissions for the Receivable model
    This function can be called during app initialization or migration
    """
    content_type = ContentType.objects.get_for_model(Receivable)
    
    # Create basic permissions
    permissions = [
        {
            'codename': 'add_receivable',
            'name': 'Can add receivable',
            'content_type': content_type,
        },
        {
            'codename': 'change_receivable',
            'name': 'Can change receivable',
            'content_type': content_type,
        },
        {
            'codename': 'delete_receivable',
            'name': 'Can delete receivable',
            'content_type': content_type,
        },
        {
            'codename': 'view_receivable',
            'name': 'Can view receivable',
            'content_type': content_type,
        },
        {
            'codename': 'view_all_receivables',
            'name': 'Can view all receivables',
            'content_type': content_type,
        },
        {
            'codename': 'change_all_receivables',
            'name': 'Can change all receivables',
            'content_type': content_type,
        },
        {
            'codename': 'record_payment',
            'name': 'Can record payment on receivable',
            'content_type': content_type,
        },
        {
            'codename': 'restore_receivable',
            'name': 'Can restore deleted receivable',
            'content_type': content_type,
        },
    ]
    
    created_permissions = []
    for perm_data in permissions:
        permission, created = Permission.objects.get_or_create(
            codename=perm_data['codename'],
            content_type=perm_data['content_type'],
            defaults={'name': perm_data['name']}
        )
        if created:
            created_permissions.append(permission)
            print(f"Created permission: {permission.name}")
    
    return created_permissions


def assign_default_permissions_to_superusers():
    """
    Assign all receivable permissions to superusers
    This ensures superusers have full access
    """
    from django.contrib.auth import get_user_model
    User = get_user_model()
    
    content_type = ContentType.objects.get_for_model(Receivable)
    permissions = Permission.objects.filter(content_type=content_type)
    
    superusers = User.objects.filter(is_superuser=True)
    
    for user in superusers:
        user.user_permissions.add(*permissions)
        print(f"Assigned all receivable permissions to superuser: {user.email}")


def setup_receivable_permissions():
    """
    Complete setup function for receivable permissions
    Call this during app initialization
    """
    print("Setting up Receivable permissions...")
    
    # Create permissions
    created_permissions = create_receivable_permissions()
    print(f"Created {len(created_permissions)} permissions")
    
    # Assign to superusers
    assign_default_permissions_to_superusers()
    
    print("Receivable permissions setup complete!")


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
