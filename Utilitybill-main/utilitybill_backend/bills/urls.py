from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'profiles', views.UserProfileViewSet, basename='profile')

urlpatterns = [
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),
    path('auth/logout/', views.logout_user, name='logout'),
    path('auth/current-user/', views.current_user, name='current-user'),
    path('auth/request-otp/', views.request_otp, name='request-otp'),
    path('auth/verify-otp/', views.verify_otp, name='verify-otp'),
    path('admin/add-utility-authority/', views.add_utility_authority, name='add-utility-authority'),
    path('user-utility/add/', views.add_user_utility, name='add-user-utility'),
    path('user-utility/list/', views.list_user_utilities, name='list-user-utilities'),
    path('user-utility/count/', views.count_user_utilities_by_provider, name='count-user-utilities-by-provider'),
    path('user-utility/<int:pk>/', views.user_utility_detail, name='user-utility-detail'),
    # Generated bills endpoints
    path('bills/add/', views.add_generated_bill, name='add-generated-bill'),
    path('bills/list/', views.list_generated_bills, name='list-generated-bills'),
    path('bills/last-reading/', views.last_reading, name='last-reading'),
    # Minimal UtilityBill endpoints
    path('utility-bill/add/', views.add_utility_bill, name='add-utility-bill'),
    path('utility-bill/list/', views.list_utility_bills, name='list-utility-bills'),
    # Payments endpoints
    path('payments/add/', views.add_payment, name='add-payment'),
    path('payments/list/', views.list_payments, name='list-payments'),
    path('payments/approve/', views.approve_payment, name='approve-payment'),
    path('payments/reject/', views.reject_payment, name='reject-payment'),
    # Wallet endpoints
    path('wallet/balance/', views.wallet_balance, name='wallet-balance'),
    path('wallet/transactions/', views.wallet_transactions, name='wallet-transactions'),
    # Chat endpoints
    path('chat/thread/', views.chat_thread, name='chat-thread'),
    path('chat/send/', views.chat_send, name='chat-send'),
    # Admin user management
    path('admin/set-user-active/', views.set_user_active, name='set-user-active'),
    path('admin/delete-user/', views.delete_user_account, name='delete-user'),
    path('', include(router.urls)),
]
