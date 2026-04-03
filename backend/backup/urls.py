from django.urls import path
from .views import (
    DatabaseBackupView,
    DatabaseRestoreView,
    BackupListView,
    DeleteBackupView,
    DownloadBackupView,
)

urlpatterns = [
    path('create/', DatabaseBackupView.as_view(), name='create-backup'),
    path('restore/', DatabaseRestoreView.as_view(), name='restore-backup'),
    path('list/', BackupListView.as_view(), name='list-backups'),
    path('delete/<str:filename>/', DeleteBackupView.as_view(), name='delete-backup'),
    path('download/<str:filename>/', DownloadBackupView.as_view(), name='download-backup'),
]
