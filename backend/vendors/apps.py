from django.apps import AppConfig


class VendorsConfig(AppConfig):
    """Configuration for the vendors app"""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'vendors'
    verbose_name = 'Vendor Management'
    
    def ready(self):
        """Called when the app is ready"""
        # Import signals to register them
        try:
            import vendors.signals
        except ImportError:
            pass
