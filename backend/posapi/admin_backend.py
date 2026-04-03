from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model

User = get_user_model()


class AdminBackend(ModelBackend):
    """
    Custom backend that allows superusers to access admin without is_staff field
    """
    
    def has_perm(self, user_obj, perm, obj=None):
        if user_obj.is_superuser:
            return True
        return super().has_perm(user_obj, perm, obj)
    
    def has_module_perms(self, user_obj, app_label):
        if user_obj.is_superuser:
            return True
        return super().has_module_perms(user_obj, app_label)
    