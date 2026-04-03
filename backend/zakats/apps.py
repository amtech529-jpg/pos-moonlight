from django.apps import AppConfig


class ZakatConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'zakats'
    verbose_name = 'Zakat Management'
    
    def ready(self):
        """
        Import signals when the app is ready
        """
        import zakats.signals