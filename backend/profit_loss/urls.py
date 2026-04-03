from django.urls import path
from . import views

app_name = 'profit_loss'

urlpatterns = [
    # Main profit and loss calculation
    path('calculate/', views.ProfitLossCalculationView.as_view(), name='calculate'),
    
    # Profit and loss records
    path('records/', views.ProfitLossRecordListView.as_view(), name='records'),
    path('records/<uuid:id>/', views.ProfitLossRecordDetailView.as_view(), name='record_detail'),
    
    # Summary views
    path('summary/', views.ProfitLossSummaryView.as_view(), name='summary'),
    
    # Product profitability analysis
    path('product-profitability/', views.ProductProfitabilityView.as_view(), name='product_profitability'),
    
    # Dashboard
    path('dashboard/', views.profit_loss_dashboard, name='dashboard'),
]
