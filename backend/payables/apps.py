from django.apps import AppConfig


class PayablesConfig(AppConfig):
    """
    Configuration for the Payables application
    """
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'payables'
    verbose_name = 'Payables Management'
    
    def ready(self):
        """
        Import signals when the app is ready
        This ensures that signal handlers are registered
        """
        try:
            import payables.signals
        except ImportError:
            pass
        