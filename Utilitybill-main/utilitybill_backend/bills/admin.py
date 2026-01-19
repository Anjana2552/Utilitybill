from django.contrib import admin
from .models import UserProfile, UserUtility


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'phone', 'created_at']
    search_fields = ['user__username', 'user__email', 'phone']
    list_filter = ['role', 'created_at']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(UserUtility)
class UserUtilityAdmin(admin.ModelAdmin):
    list_display = ['user_name', 'utility_type', 'provider_name', 'connection_type', 'is_active', 'created_at']
    list_filter = ['utility_type', 'connection_type', 'is_active', 'created_at']
    search_fields = ['user_name', 'provider_name', 'wifi_consumer_id', 'dth_subscriber_id']
