from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.http import HttpResponse, FileResponse
from django.core.management import call_command
from django.conf import settings
import os
import json
import datetime
from pathlib import Path
import pandas as pd
from io import BytesIO
from customers.models import Customer
from products.models import Product
from sales.models import Sales
from purchases.models import Purchase
from expenses.models import Expense
from orders.models import Order

class DatabaseBackupView(APIView):
    """Create and download database backup"""
    permission_classes = []  # Add authentication later
    
    def get(self, request):
        try:
            # Create backups directory if it doesn't exist
            backup_dir = Path(settings.BASE_DIR) / 'backups'
            backup_dir.mkdir(exist_ok=True)
            
            # Get modules to backup from query params
            modules_param = request.query_params.get('modules')
            modules = modules_param.split(',') if modules_param else []
            
            # Generate backup filename with timestamp
            timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            prefix = f"backup_{'_'.join(modules)}" if modules else "backup_full"
            backup_file = backup_dir / f'{prefix}_{timestamp}.json'
            
            # Create backup using dumpdata
            with open(backup_file, 'w') as f:
                if modules:
                    # Partial backup for specific modules
                    call_command('dumpdata', *modules,
                               indent=2,
                               stdout=f)
                else:
                    # Full backup excluding internal Django tables
                    call_command('dumpdata', 
                               exclude=['contenttypes', 'auth.permission', 'sessions', 'admin.logentry'],
                               indent=2,
                               stdout=f)
            
            # Return file for download
            response = FileResponse(open(backup_file, 'rb'), content_type='application/json')
            response['Content-Disposition'] = f'attachment; filename="{backup_file.name}"'
            
            return response
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Backup failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DatabaseRestoreView(APIView):
    """Restore database from backup file"""
    permission_classes = []  # Add authentication later
    
    def post(self, request):
        try:
            # Get uploaded file
            backup_file = request.FILES.get('backup_file')
            
            if not backup_file:
                return Response({
                    'success': False,
                    'message': 'No backup file provided'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Save uploaded file temporarily
            backup_dir = Path(settings.BASE_DIR) / 'backups'
            backup_dir.mkdir(exist_ok=True)
            
            temp_file = backup_dir / f'temp_restore_{datetime.datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
            
            with open(temp_file, 'wb+') as destination:
                for chunk in backup_file.chunks():
                    destination.write(chunk)
            
            # Restore from backup
            call_command('loaddata', str(temp_file))
            
            # Clean up temp file
            temp_file.unlink()
            
            return Response({
                'success': True,
                'message': 'Database restored successfully'
            })
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Restore failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class BackupListView(APIView):
    """List all available backups"""
    permission_classes = []
    
    def get(self, request):
        try:
            backup_dir = Path(settings.BASE_DIR) / 'backups'
            
            if not backup_dir.exists():
                return Response({
                    'success': True,
                    'backups': []
                })
            
            backups = []
            for file in backup_dir.glob('backup_*.json'):
                stat = file.stat()
                backups.append({
                    'filename': file.name,
                    'size': stat.st_size,
                    'created_at': datetime.datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    'modified_at': datetime.datetime.fromtimestamp(stat.st_mtime).isoformat(),
                })
            
            # Sort by created date descending
            backups.sort(key=lambda x: x['created_at'], reverse=True)
            
            return Response({
                'success': True,
                'backups': backups
            })
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to list backups: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DeleteBackupView(APIView):
    """Delete a specific backup file"""
    permission_classes = []
    
    def delete(self, request, filename):
        try:
            backup_dir = Path(settings.BASE_DIR) / 'backups'
            backup_file = backup_dir / filename
            
            if not backup_file.exists():
                return Response({
                    'success': False,
                    'message': 'Backup file not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Security check - ensure file is in backups directory
            if not str(backup_file.resolve()).startswith(str(backup_dir.resolve())):
                return Response({
                    'success': False,
                    'message': 'Invalid file path'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            backup_file.unlink()
            
            return Response({
                'success': True,
                'message': 'Backup deleted successfully'
            })
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to delete backup: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DownloadBackupView(APIView):
    """Download an existing backup file"""
    permission_classes = []
    
    def get(self, request, filename):
        try:
            backup_dir = Path(settings.BASE_DIR) / 'backups'
            backup_file = backup_dir / filename
            
            if not backup_file.exists():
                return Response({
                    'success': False,
                    'message': 'Backup file not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Security check
            if not str(backup_file.resolve()).startswith(str(backup_dir.resolve())):
                return Response({
                    'success': False,
                    'message': 'Invalid file path'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            response = FileResponse(open(backup_file, 'rb'), content_type='application/json')
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            return response
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to download backup: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ReadableBackupView(APIView):
    """Create and download a human-readable Excel backup of key data"""
    permission_classes = []
    
    def get(self, request):
        try:
            # Get modules to export from query params
            modules_param = request.query_params.get('modules')
            selected_modules = modules_param.split(',') if modules_param else []
            is_full = not selected_modules

            output = BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                # 0. Summary Sheet (Ensures file is never empty)
                summary_data = [
                    {'Category': 'Export Date', 'Value': datetime.datetime.now().strftime('%d/%m/%Y %H:%M:%S')},
                    {'Category': 'Export Type', 'Value': 'Full' if is_full else 'Selective'},
                ]
                
                # Sheet Generation Helper
                def add_sheet(model, fields, sheet_name, filter_active=True):
                    qs = model.objects.filter(is_active=True) if filter_active else model.objects.all()
                    qs_values = qs.values(*fields)
                    df = pd.DataFrame(list(qs_values), columns=fields)
                    for col in df.select_dtypes(['datetimetz']).columns:
                        df[col] = df[col].dt.tz_localize(None)
                    df.to_excel(writer, sheet_name=sheet_name, index=False)
                    return qs.count()

                # 1. Customers
                if is_full or 'customers' in selected_modules:
                    count = add_sheet(Customer, ['name', 'phone', 'email', 'city', 'status', 'customer_type', 'created_at'], 'Customers')
                    summary_data.append({'Category': 'Total Customers', 'Value': count})
                
                # 2. Products
                if is_full or 'products' in selected_modules:
                    count = add_sheet(Product, ['name', 'sku', 'category__name', 'price', 'cost_price', 'quantity'], 'Products')
                    summary_data.append({'Category': 'Total Products', 'Value': count})
                
                # 3. Sales
                if is_full or 'sales' in selected_modules:
                    count = add_sheet(Sales, ['invoice_number', 'customer_name', 'grand_total', 'amount_paid', 'remaining_amount', 'status', 'date_of_sale'], 'Sales')
                    summary_data.append({'Category': 'Total Sales', 'Value': count})

                # 4. Purchases
                if is_full or 'purchases' in selected_modules:
                    # Purchase model doesn't have is_active in some versions, check if it exists
                    has_is_active = hasattr(Purchase, 'is_active')
                    count = add_sheet(Purchase, ['invoice_number', 'vendor__name', 'total', 'status', 'purchase_date'], 'Purchases', filter_active=has_is_active)
                    summary_data.append({'Category': 'Total Purchases', 'Value': count})

                # 5. Expenses
                if is_full or 'expenses' in selected_modules:
                    count = add_sheet(Expense, ['expense', 'amount', 'category', 'date', 'withdrawal_by'], 'Expenses')
                    summary_data.append({'Category': 'Total Expenses', 'Value': count})

                # 6. Labors / Employees
                if is_full or 'labors' in selected_modules:
                    from labors.models import Labor
                    count = add_sheet(Labor, ['name', 'phone_number', 'cnic', 'designation', 'salary', 'joining_date', 'city'], 'Employees')
                    summary_data.append({'Category': 'Total Employees', 'Value': count})

                # 7. Rental Orders
                if is_full or 'orders' in selected_modules:
                    count = add_sheet(Order, ['customer_name', 'total_amount', 'advance_payment', 'remaining_amount', 'status', 'date_ordered', 'event_date'], 'Rental Orders')
                    summary_data.append({'Category': 'Total Rental Orders', 'Value': count})

                # Write Summary last to ensure all counts are collected
                pd.DataFrame(summary_data).to_excel(writer, sheet_name='Summary', index=False)

            output.seek(0)
            timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            prefix = "excel_export_full" if is_full else f"excel_export_{'_'.join(selected_modules[:3])}"
            response = HttpResponse(
                output.read(),
                content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            )
            response['Content-Disposition'] = f'attachment; filename={prefix}_{timestamp}.xlsx'
            return response

        except Exception as e:
            return Response({
                'success': False,
                'message': f'Readable export failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
