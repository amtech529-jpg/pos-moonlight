from django.apps import AppConfig


class AdvancePaymentsConfig(AppConfig):
    """Configuration for the advance_payments app"""
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'advance_payments'
    verbose_name = 'Advance Payment Management'
    
    def ready(self):
        """Called when the app is ready"""
        # Import signals to register them
        try:
            import advance_payments.signals
        except ImportError:
            pass
        