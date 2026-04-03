import pandas as pd
from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.apps import apps
import io
import datetime
from django.conf import settings
from openpyxl.utils import get_column_letter

class DataExportView(APIView):
    permission_classes = []  # Secure this later with IsAuthenticated

    def get(self, request, model_name):
        try:
            # Map model_name to actual Model class
            model_map = {
                'products': 'products.Product',
                'customers': 'customers.Customer',
                'vendors': 'vendors.Vendor',
                'quotations': 'quotations.Quotation', # Added Quotation
                'orders': 'orders.Order', # Added Order
                'categories': 'categories.Category',
            }
            
            if model_name not in model_map:
                return Response({'error': 'Invalid model name'}, status=status.HTTP_400_BAD_REQUEST)
            
            app_label, model_class_name = model_map[model_name].split('.')
            try:
                Model = apps.get_model(app_label, model_class_name)
            except LookupError:
                 return Response({'error': f'Model {model_name} not found'}, status=status.HTTP_400_BAD_REQUEST)

            # Define exact fields to include to match frontend forms
            include_map = {
                'products': ['name', 'detail', 'price', 'quantity', 'category__name', 'pricing_type', 'is_rental', 'is_consumable', 'serial_number', 'warehouse_location', 'min_stock_threshold'],
                'customers': ['name', 'phone', 'email', 'address', 'city', 'country', 'customer_type', 'business_name', 'tax_number', 'notes'],
            }
            
            # Fetch data
            queryset = Model.objects.all()
            
            # Get available fields from Model
            all_fields = [field.name for field in Model._meta.fields]
            
            # Determine fields to export
            if model_name in include_map:
                export_fields = include_map[model_name]
            else:
                export_fields = all_fields
                
            # Convert to DataFrame
            data = list(queryset.values(*export_fields))
            df = pd.DataFrame(data)
            
            # Clean up column names for any related lookups
            if 'category__name' in df.columns:
                df.rename(columns={'category__name': 'category_name'}, inplace=True)
            
            # Handle empty dataframe
            if df.empty:
                # Create empty excel with headers if possible, or just empty
                pass
            else:
                # Convert UUIDs to strings
                import uuid
                for col in df.columns:
                    # Check if the column type is object (which UUIDs usually are in pandas)
                    if df[col].dtype == 'object':
                        # Check the first non-null value to see if it's a UUID
                        first_valid_idx = df[col].first_valid_index()
                        if first_valid_idx is not None:
                            val = df.at[first_valid_idx, col]
                            if isinstance(val, uuid.UUID):
                                df[col] = df[col].astype(str)
                
                # Convert timezone-aware datetimes to timezone-naive
                for col in df.select_dtypes(include=['datetime64[ns, UTC]', 'datetime64[ns]']).columns:
                     if hasattr(df[col].dt, 'tz') and df[col].dt.tz is not None:
                         df[col] = df[col].dt.tz_localize(None)


            # Create Excel response
            response = HttpResponse(content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            filename = f"{model_name}_export_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            
            with pd.ExcelWriter(response, engine='openpyxl') as writer:
                df.to_excel(writer, index=False, sheet_name=model_name)
                worksheet = writer.sheets[model_name]
                
                # Auto-adjust column widths
                for i, col in enumerate(worksheet.columns, 1):
                    max_length = 0
                    column_letter = get_column_letter(i)
                    for cell in col:
                        try:
                            if cell.value:
                                length = len(str(cell.value))
                                if length > max_length:
                                    max_length = length
                        except:
                            pass
                    
                    adjusted_width = (max_length + 2)
                    # Cap width at 50 to avoid extremely wide columns
                    if adjusted_width > 50:
                        adjusted_width = 50
                    worksheet.column_dimensions[column_letter].width = adjusted_width
                
            return response
            
        except Exception as e:
            print(f"Export Error: {e}") # Log to console
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DataImportView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [] # Secure later

    def post(self, request, model_name):
        try:
            # Map model_name to actual Model class
            model_map = {
                'products': 'products.Product',
                'customers': 'customers.Customer',
                'vendors': 'vendors.Vendor',
                'categories': 'categories.Category',
            }
            
            if model_name not in model_map:
                return Response({'error': 'Invalid model name'}, status=status.HTTP_400_BAD_REQUEST)
            
            app_label, model_class_name = model_map[model_name].split('.')
            Model = apps.get_model(app_label, model_class_name)
            
            file_obj = request.FILES['file']
            
            if not file_obj.name.endswith(('.xlsx', '.xls', '.csv')):
                 return Response({'error': 'Invalid file format. Please upload Excel or CSV.'}, status=status.HTTP_400_BAD_REQUEST)

            # Read file
            if file_obj.name.endswith('.csv'):
                df = pd.read_csv(file_obj)
            else:
                df = pd.read_excel(file_obj)
            
            # Iterate and save
            success_count = 0
            errors = []
            
            for index, row in df.iterrows():
                try:
                    data = row.to_dict()
                    # Remove NaNs
                    data = {k: v for k, v in data.items() if pd.notna(v)}
                    
                    # Basic logic: create only for now to avoid accidental overwrites
                    # ideally we check for existing ID or unique field
                    
                    # Remove 'id' if present to let DB handle it, or check for update
                    obj_id = data.pop('id', None)
                    
                    # Smart Category Resolution & Creation for products
                    if model_name == 'products' and 'category_name' in data:
                        cat_name = data.pop('category_name')
                        if cat_name and str(cat_name).strip():
                            from categories.models import Category
                            # Try to find exactly, ignoring case
                            category = Category.objects.filter(name__iexact=str(cat_name).strip()).first()
                            if not category:
                                # Create if it doesn't exist
                                category = Category.objects.create(name=str(cat_name).strip())
                            data['category_id'] = category.id
                    
                    # Determine unique fields to lookup against (upsert logic)
                    existing_obj = None
                    if model_name == 'products':
                        # Try to find by serial number first, then by exact name
                        serial = data.get('serial_number')
                        name = data.get('name')
                        if serial and str(serial).strip():
                            existing_obj = Model.objects.filter(serial_number__iexact=str(serial).strip()).first()
                        if not existing_obj and name and str(name).strip():
                            existing_obj = Model.objects.filter(name__iexact=str(name).strip()).first()
                    elif model_name == 'customers':
                        # Try to find by exact phone number
                        phone = data.get('phone')
                        if phone and str(phone).strip():
                            existing_obj = Model.objects.filter(phone__iexact=str(phone).strip()).first()

                    # Fallback to obj_id if passed (though we removed it from templates)
                    if not existing_obj and obj_id:
                        existing_obj = Model.objects.filter(id=obj_id).first()
                        
                    if existing_obj:
                        # Update existing
                        for k, v in data.items():
                            # If updating a product and the field is 'quantity', add it to existing
                            if model_name == 'products' and k == 'quantity':
                                try:
                                    current_qty = getattr(existing_obj, 'quantity', 0) or 0
                                    added_qty = int(v) if v else 0
                                    setattr(existing_obj, 'quantity', current_qty + added_qty)
                                    
                                    # Also update quantity_available to reflect the new stock correctly
                                    # (quantity_available = total quantity - reserved - damaged)
                                    reserved = getattr(existing_obj, 'quantity_reserved', 0) or 0
                                    damaged = getattr(existing_obj, 'quantity_damaged', 0) or 0
                                    setattr(existing_obj, 'quantity_available', (current_qty + added_qty) - reserved - damaged)
                                except (ValueError, TypeError):
                                    # If added value is not an integer, we fail gracefully
                                    pass
                            else:
                                setattr(existing_obj, k, v)
                        existing_obj.save()
                        success_count += 1
                    else:
                        # Create new
                        Model.objects.create(**data)
                        success_count += 1
                        
                except Exception as e:
                    errors.append(f"Row {index + 2}: {str(e)}")
            
            return Response({
                'success': True,
                'file_name': file_obj.name,
                'imported_count': success_count,
                'errors': errors
            })
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DataTemplateView(APIView):
    permission_classes = []

    def get(self, request, model_name):
        try:
            # Map model_name to actual Model class
            model_map = {
                'products': 'products.Product',
                'customers': 'customers.Customer',
                'vendors': 'vendors.Vendor',
                'categories': 'categories.Category',
            }
            
            if model_name not in model_map:
                return Response({'error': 'Invalid model name'}, status=status.HTTP_400_BAD_REQUEST)
            
            app_label, model_class_name = model_map[model_name].split('.')
            Model = apps.get_model(app_label, model_class_name)
            
            # Define exact fields to include to match frontend forms
            include_map = {
                'products': ['name', 'detail', 'price', 'quantity', 'category_name', 'pricing_type', 'is_rental', 'is_consumable', 'serial_number', 'warehouse_location', 'min_stock_threshold'],
                'customers': ['name', 'phone', 'email', 'address', 'city', 'country', 'customer_type', 'business_name', 'tax_number', 'notes'],
            }

            # Get fields
            all_fields = [field.name for field in Model._meta.fields]
            
            if model_name in include_map:
                fields = include_map[model_name]
            else:
                fields = [f for f in all_fields if f != 'id']
            
            # Create empty DataFrame
            df = pd.DataFrame(columns=fields)
            
            # Create Excel response
            response = HttpResponse(content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            filename = f"{model_name}_template.xlsx"
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            
            with pd.ExcelWriter(response, engine='openpyxl') as writer:
                df.to_excel(writer, index=False, sheet_name=model_name)
                
            return response
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
