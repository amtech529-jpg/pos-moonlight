from django.apps import AppConfig


class PrincipalAccountConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'principal_account'
    verbose_name = 'Principal Account'
    
    def ready(self):
        """Import signals when app is ready"""
        try:
            import principal_account.signals
        except ImportError:
            pass

