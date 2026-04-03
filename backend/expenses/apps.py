# expenses/apps.py

from django.apps import AppConfig

class ExpensesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'expenses'
    verbose_name = 'Expense Management'
    
    def ready(self):
        """
        Import any signals or perform initialization tasks
        """
        try:
            # Import signals if you create them later
            # import expenses.signals
            pass
        except ImportError:
            pass
        