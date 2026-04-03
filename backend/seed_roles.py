import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from posapi.models import Role, RolePermission, User

def seed_roles():
    roles = [
        {'name': 'Admin', 'description': 'Full access to all system modules and settings'},
        {'name': 'Accountant', 'description': 'Access to finance, ledgers, reports, and payments'},
        {'name': 'Storekeeper', 'description': 'Access to inventory, tools, purchases, and orders'},
    ]

    modules = [
        'Dashboard',
        'Purchase',
        'Inventory',
        'Quotation',
        'Order & Rental',
        'Customer Management',
        'Invoice & Payment',
        'Partner/Payables',
        'Return & Tally',
        'Ledger',
        'Expense Management',
        'Tools & Consumables',
        'HR & Salary',
        'Reports',
        'Import/Export',
        'Backup',
        'User Management',
    ]

    for role_data in roles:
        role, created = Role.objects.get_or_create(
            name=role_data['name'],
            defaults={'description': role_data['description']}
        )
        
        if created:
            print(f"Created role: {role.name}")
        else:
            role.description = role_data['description']
            role.save()
            print(f"Role already exists: {role.name}. Updating permissions...")

        # Sync permissions for all modules
        for module in modules:
            # Logic for permissions based on role
            if role.name == 'Admin':
                can_v, can_a, can_e, can_d = True, True, True, True
            elif role.name == 'Accountant':
                # Accountant modules
                fin_modules = ['Dashboard', 'Invoice & Payment', 'Partner/Payables', 'Ledger', 'Expense Management', 'HR & Salary', 'Reports']
                if module in fin_modules:
                    can_v, can_a, can_e, can_d = True, True, True, False
                else:
                    can_v, can_a, can_e, can_d = True, False, False, False
            elif role.name == 'Storekeeper':
                # Storekeeper modules
                store_modules = ['Dashboard', 'Purchase', 'Inventory', 'Order & Rental', 'Return & Tally', 'Tools & Consumables']
                if module in store_modules:
                    can_v, can_a, can_e, can_d = True, True, True, False
                else:
                    can_v, can_a, can_e, can_d = True, False, False, False
            else:
                can_v, can_a, can_e, can_d = True, False, False, False
            
            perm, p_created = RolePermission.objects.get_or_create(
                role=role,
                module_name=module,
                defaults={
                    'can_view': can_v,
                    'can_add': can_a,
                    'can_edit': can_e,
                    'can_delete': can_d,
                }
            )
            
            if not p_created:
                perm.can_view = can_v
                perm.can_add = can_a
                perm.can_edit = can_e
                perm.can_delete = can_d
                perm.save()
            print(f"  - Synchronized permissions for module: {module}")

    # Assign Admin role to existing superusers
    admin_role = Role.objects.get(name='Admin')
    superusers = User.objects.filter(is_superuser=True)
    for user in superusers:
        if not user.role:
            user.role = admin_role
            user.save()
            print(f"Assigned Admin role to superuser: {user.email}")

if __name__ == '__main__':
    seed_roles()
