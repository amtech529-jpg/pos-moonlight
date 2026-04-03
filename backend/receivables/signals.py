from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from .models import Receivable


@receiver(post_save, sender=Receivable)
def receivable_post_save(sender, instance, created, **kwargs):
    """
    Signal handler for Receivable post_save
    """
    if created:
        # Log creation
        print(f"New receivable created: {instance.debtor_name} - {instance.amount_given} PKR")
        
        # You can add additional logic here like:
        # - Sending notifications
        # - Updating related models
        # - Creating audit logs
        # - Sending SMS/email reminders
        
    else:
        # Log updates
        print(f"Receivable updated: {instance.debtor_name} - {instance.balance_remaining} PKR remaining")
        
        # Check if fully paid
        if instance.is_fully_paid():
            print(f"Receivable fully paid: {instance.debtor_name}")
            # You can add logic here like:
            # - Sending completion notifications
            # - Updating customer status
            # - Creating payment records
        
        # Check if overdue
        if instance.is_overdue():
            print(f"Receivable overdue: {instance.debtor_name} - {instance.days_overdue()} days overdue")
            # You can add logic here like:
            # - Sending overdue notifications
            # - Creating reminder records
            # - Updating customer risk status


@receiver(post_delete, sender=Receivable)
def receivable_post_delete(sender, instance, **kwargs):
    """
    Signal handler for Receivable post_delete
    """
    print(f"Receivable deleted: {instance.debtor_name} - {instance.amount_given} PKR")
    
    # You can add additional logic here like:
    # - Creating audit logs
    # - Updating related models
    # - Sending notifications


# You can add more signals as needed:
# - pre_save for validation
# - m2m_changed for many-to-many relationships
# - Custom signals for business logic
