from django.apps import AppConfig


class OrderItemsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'order_items'
    verbose_name = 'Order Item Management'
    
    def ready(self):
        """Import signals when the app is ready"""
        import order_items.signals
        