import uuid
from django.db import models
from django.conf import settings


class Category(models.Model):
    """Category model for organizing products"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    name = models.CharField(
        max_length=100,
        unique=True,
        help_text="Category name must be unique"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Optional description of the category"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion. Inactive categories won't appear in lists"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_categories',
        help_text="User who created this category"
    )
    
    class Meta:
        db_table = 'category'
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def soft_delete(self):
        """Soft delete the category by setting is_active to False"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted category"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    @classmethod
    def active_categories(cls):
        """Return only active categories"""
        return cls.objects.filter(is_active=True)
    