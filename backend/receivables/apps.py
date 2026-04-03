from django.apps import AppConfig


class ReceivablesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'receivables'
    verbose_name = 'Receivables'
    
    def ready(self):
        """Import signals when app is ready"""
        try:
            import receivables.signals
        except ImportError:
            pass
