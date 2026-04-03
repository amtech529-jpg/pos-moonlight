from django.apps import AppConfig


class SaleItemsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'sale_items'
    verbose_name = 'Sale Items Management'
    
    def ready(self):
        # Import signals to ensure they are registered
        import sale_items.signals
