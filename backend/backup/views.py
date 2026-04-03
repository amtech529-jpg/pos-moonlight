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
