from django.apps import AppConfig


class LaborsConfig(AppConfig):
    """Configuration for the labors app"""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'labors'
    verbose_name = 'Labor Management'
    
    def ready(self):
        """Called when the app is ready"""
        # Import signals to register them
        try:
            import labors.signals
        except ImportError:
            pass
        