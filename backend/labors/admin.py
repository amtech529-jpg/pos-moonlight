from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.db.models import Count, Avg, Sum
from decimal import Decimal
from .models import Labor


@admin.register(Labor)
class LaborAdmin(admin.ModelAdmin):
    list_display = (
        'display_name_formatted',
        'designation_formatted',
        'cnic',
        'phone_formatted',
        'location_formatted',
        'salary_formatted',
        'remaining_advance_amount_display',
        'age_gender_formatted',
        'joining_status_badge',
        'is_active',
        'joining_date'
    )
    
    list_filter = (
        'is_active',
        'gender',
        'designation',
        'caste',
        'city',
        'area',
        'joining_date',
        'created_at',
    )
    
    search_fields = (
        'name',
        'cnic',
        'phone_number',
        'designation',
        'caste',
        'city',
        'area',
    )
    
    readonly_fields = (
        'id',
        'created_at',
        'updated_at',
        'created_by',
        'work_experience_display',
        'initials_display',
        'formatted_phone_display',
        'full_address_display',
        'gender_display_full',
        'remaining_monthly_salary_display',
        'remaining_advance_amount_display',
        'total_advances_amount_display',
    )
    
    fieldsets = (
        ('Personal Information', {
            'fields': ('id', 'name', 'cnic', 'age', 'gender', 'gender_display_full', 'caste')
        }),
        ('Contact Details', {
            'fields': ('phone_number', 'city', 'area', 'formatted_phone_display', 'full_address_display')
        }),
        ('Employment Information', {
            'fields': ('designation', 'joining_date', 'salary', 'work_experience_display')
        }),
        ('Financial Information', {
            'fields': ('remaining_monthly_salary_display', 'remaining_advance_amount_display', 'total_advances_amount_display'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by', 'initials_display'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    date_hierarchy = 'joining_date'
    ordering = ('-created_at', 'name')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'bulk_salary_increase',
        'export_labor_summary',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by')

    def display_name_formatted(self, obj):
        """Display formatted labor name with initials"""
        initials = obj.get_initials()
        return format_html(
            '<strong>{}</strong> <small style="color: #666;">({initials})</small>',
            obj.name,
            initials=initials
        )
    display_name_formatted.short_description = 'Labor Name'
    display_name_formatted.admin_order_field = 'name'

    def designation_formatted(self, obj):
        """Display formatted designation with experience"""
        experience_years = obj.work_experience_years
        experience_text = f" ({experience_years}y)" if experience_years > 0 else " (New)"
        
        return format_html(
            '<strong style="color: #0066cc;">{}</strong>'
            '<small style="color: #666;">{}</small>',
            obj.designation,
            experience_text
        )
    designation_formatted.short_description = 'Designation'
    designation_formatted.admin_order_field = 'designation'

    def phone_formatted(self, obj):
        """Display formatted phone number"""
        country_info = ""
        if obj.phone_country_code:
            country_info = f" <small style='color: #666;'>({obj.phone_country_code})</small>"
        
        return format_html(
            '{}{} ',
            obj.phone_number,
            country_info
        )
    phone_formatted.short_description = 'Phone'
    phone_formatted.admin_order_field = 'phone_number'

    def location_formatted(self, obj):
        """Display formatted location"""
        return format_html(
            '<strong>{}</strong><br><small style="color: #666;">{}</small>',
            obj.city,
            obj.area
        )
    location_formatted.short_description = 'Location'
    location_formatted.admin_order_field = 'city'

    def salary_formatted(self, obj):
        """Display formatted salary"""
        if obj.salary:
            # Format salary with commas and currency
            salary_str = f"₹{obj.salary:,.0f}"
            
            # Color code based on salary ranges
            if obj.salary < 20000:
                color = "#dc3545"  # Red for low salary
            elif obj.salary < 50000:
                color = "#ffc107"  # Yellow for medium salary  
            else:
                color = "#28a745"  # Green for high salary
            
            return format_html(
                '<span style="color: {}; font-weight: bold;">{}</span>',
                color,
                salary_str
            )
        return format_html('<span style="color: #6c757d;">—</span>')
    salary_formatted.short_description = 'Salary'
    salary_formatted.admin_order_field = 'salary'
    
    def remaining_advance_amount_display(self, obj):
        """Display remaining advance amount with color coding"""
        try:
            # Debug: Check if labor has salary
            if not obj.salary or obj.salary <= 0:
                return format_html('<span style="color: #6c757d;">No Salary Set</span>')
            
            # Get remaining advance amount
            remaining = obj.get_remaining_advance_amount()
            
            # Debug: Log the values
            print(f"DEBUG: Labor {obj.name} - Salary: {obj.salary}, Remaining: {remaining}")
            
            if remaining <= 0:
                color = '#D32F2F'  # Red
                text = 'No Advance Available'
            elif remaining < obj.salary * 0.3:  # Less than 30% of salary
                color = '#F57C00'  # Orange
                text = f'₹{remaining:,.0f}'
            else:
                color = '#388E3C'  # Green
                text = f'₹{remaining:,.0f}'
            
            return format_html(
                '<span style="color: {}; font-weight: 600;">{}</span>',
                color, text
            )
        except Exception as e:
            print(f"ERROR in remaining_advance_amount_display: {str(e)}")
            return format_html('<span style="color: #ff0000;">Error: {}</span>', str(e)[:50])
    remaining_advance_amount_display.short_description = 'Remaining Advance'
    remaining_advance_amount_display.admin_order_field = 'remaining_monthly_salary'
    
    def remaining_monthly_salary_display(self, obj):
        """Display remaining monthly salary"""
        try:
            if not obj.salary or obj.salary <= 0:
                return format_html('<span style="color: #6c757d;">No Salary Set</span>')
            
            remaining = obj.remaining_monthly_salary
            print(f"DEBUG: Labor {obj.name} - Salary: {obj.salary}, Remaining Monthly: {remaining}")
            
            if remaining <= 0:
                color = '#D32F2F'  # Red
                text = 'No Salary Available'
            elif remaining < obj.salary * 0.3:  # Less than 30% of salary
                color = '#F57C00'  # Orange
                text = f'₹{remaining:,.0f}'
            else:
                color = '#388E3C'  # Green
                text = f'₹{remaining:,.0f}'
            
            return format_html(
                '<span style="color: {}; font-weight: 600;">{}</span>',
                color, text
            )
        except Exception as e:
            print(f"ERROR in remaining_monthly_salary_display: {str(e)}")
            return format_html('<span style="color: #ff0000;">Error: {}</span>', str(e)[:50])
    remaining_monthly_salary_display.short_description = 'Remaining Monthly Salary'
    
    def total_advances_amount_display(self, obj):
        """Display total advances for current month"""
        try:
            if not obj.salary or obj.salary <= 0:
                return format_html('<span style="color: #6c757d;">No Salary Set</span>')
            
            total_advances = obj.get_total_advances_amount()
            print(f"DEBUG: Labor {obj.name} - Total Advances: {total_advances}")
            
            if total_advances > 0:
                color = '#E91E63'  # Pink
                text = f'₹{total_advances:,.0f}'
            else:
                color = '#6c757d'  # Gray
                text = '₹0'
            
            return format_html(
                '<span style="color: {}; font-weight: 600;">{}</span>',
                color, text
            )
        except Exception as e:
            print(f"ERROR in total_advances_amount_display: {str(e)}")
            return format_html('<span style="color: #ff0000;">Error: {}</span>', str(e)[:50])
    total_advances_amount_display.short_description = 'Total Advances (Month)'

    def age_gender_formatted(self, obj):
        """Display age and gender"""
        gender_icons = {
            'M': '♂',
            'F': '♀', 
            'O': '⚥'
        }
        gender_colors = {
            'M': '#007bff',
            'F': '#e83e8c',
            'O': '#6f42c1'
        }
        
        icon = gender_icons.get(obj.gender, '?')
        color = gender_colors.get(obj.gender, '#6c757d')
        
        return format_html(
            '<span style="color: {}; font-size: 16px;">{}</span> {}y',
            color,
            icon,
            obj.age
        )
    age_gender_formatted.short_description = 'Age/Gender'
    age_gender_formatted.admin_order_field = 'age'

    def joining_status_badge(self, obj):
        """Display joining status badge"""
        if not obj.joining_date:
            return format_html(
                '<span style="background-color: #17a2b8; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">UNSAVED</span>'
            )
        elif obj.is_new_labor:
            return format_html(
                '<span style="background-color: #007bff; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">NEW</span>'
            )
        elif obj.is_recent_labor:
            return format_html(
                '<span style="background-color: #28a745; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">RECENT</span>'
            )
        else:
            experience_years = obj.work_experience_years
            if experience_years >= 5:
                return format_html(
                    '<span style="background-color: #6f42c1; color: white; padding: 2px 6px; '
                    'border-radius: 3px; font-size: 10px; font-weight: bold;">VETERAN</span>'
                )
            elif experience_years >= 2:
                return format_html(
                    '<span style="background-color: #fd7e14; color: white; padding: 2px 6px; '
                    'border-radius: 3px; font-size: 10px; font-weight: bold;">EXPERIENCED</span>'
                )
        return format_html('<span style="color: #6c757d;">—</span>')
    joining_status_badge.short_description = 'Status'

    def work_experience_display(self, obj):
        """Display work experience"""
        if not obj.joining_date:
            return "New labor"
        return f"{obj.work_experience_years} years ({obj.work_experience_days} days)"
    work_experience_display.short_description = 'Work Experience'

    def initials_display(self, obj):
        """Display labor initials"""
        return obj.get_initials()
    initials_display.short_description = 'Initials'

    def formatted_phone_display(self, obj):
        """Display formatted phone with country code"""
        return obj.formatted_phone
    formatted_phone_display.short_description = 'Formatted Phone'

    def full_address_display(self, obj):
        """Display complete address"""
        return obj.full_address
    full_address_display.short_description = 'Complete Address'

    def gender_display_full(self, obj):
        """Display full gender description"""
        return obj.gender_display
    gender_display_full.short_description = 'Gender (Full)'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new labor"""
        if not change:  # Creating new labor
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected labors as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} labors were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected labors as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected labors as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} labors were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected labors as inactive'

    def bulk_salary_increase(self, request, queryset):
        """Show salary increase summary"""
        count = queryset.count()
        total_current_salary = queryset.aggregate(total=Sum('salary'))['total'] or 0
        avg_salary = queryset.aggregate(avg=Avg('salary'))['avg'] or 0
        
        self.message_user(
            request,
            f'Selected {count} labors for salary review. '
            f'Current total monthly cost: ₹{total_current_salary:,.0f}, '
            f'Average salary: ₹{avg_salary:,.0f}'
        )
    bulk_salary_increase.short_description = 'Review salary increase for selected labors'

    def export_labor_summary(self, request, queryset):
        """Show labor summary for export"""
        count = queryset.count()
        
        # Designation breakdown
        designations = queryset.values('designation').annotate(
            count=Count('id'),
            avg_salary=Avg('salary')
        ).order_by('designation')
        
        # City breakdown  
        cities = queryset.values('city').annotate(
            count=Count('id')
        ).order_by('city')
        
        designation_summary = ', '.join([
            f"{item['designation']}: {item['count']} (avg: ₹{item['avg_salary']:,.0f})" 
            for item in designations
        ])
        
        city_summary = ', '.join([
            f"{item['city']}: {item['count']}" 
            for item in cities
        ])
        
        self.message_user(
            request,
            f'Selected {count} labors for export. '
            f'Designations: {designation_summary}. '
            f'Cities: {city_summary}'
        )
    export_labor_summary.short_description = 'Show export summary'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get labor statistics
        stats = Labor.get_statistics()
        
        # Calculate additional metrics
        active_labors = Labor.active_labors()
        salary_stats = active_labors.aggregate(
            total_salary_cost=Sum('salary'),
            avg_salary=Avg('salary')
        )
        
        extra_context.update({
            'total_labors': stats['total_labors'],
            'active_labors': stats['active_labors'],
            'inactive_labors': stats['inactive_labors'],
            'new_labors_count': stats['new_labors_this_month'],
            'recent_labors_count': stats['recent_labors_this_week'],
            'top_cities': stats['top_cities'][:5],  # Show top 5 cities
            'top_designations': stats['top_designations'][:5],  # Show top 5 designations
            'total_salary_cost': salary_stats['total_salary_cost'] or 0,
            'avg_salary': salary_stats['avg_salary'] or 0,
        })
        
        return super().changelist_view(request, extra_context)


# Optional: Custom admin site configuration
admin.site.site_header = "Labor Management System"
admin.site.site_title = "Labor Admin"
admin.site.index_title = "Welcome to Labor Management System"
