from django.contrib import admin
from .models import UserProfile, UserUtility, UtilityBill, ChatMessage, Notification, Review


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


@admin.register(UtilityBill)
class UtilityBillAdmin(admin.ModelAdmin):
    list_display = ['bill_id', 'utility_type', 'consumer_name', 'consumer_id', 'total_amount', 'created_at']
    list_filter = ['utility_type', 'created_at']


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['provider_name', 'user_name', 'sender_role', 'short_text', 'created_at']
    list_filter = ['provider_name', 'sender_role', 'created_at']
    search_fields = ['user_name', 'provider_name', 'text']

    def short_text(self, obj):
        return (obj.text or '')[:50]
    search_fields = ['bill_id', 'consumer_name', 'consumer_id']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'title', 'read', 'created_at']
    list_filter = ['notification_type', 'read', 'utility_type', 'created_at']
    search_fields = ['user__username', 'title', 'message', 'bill_id']
    readonly_fields = ['created_at']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['user', 'provider_name', 'utility_type', 'rating', 'created_at']
    list_filter = ['rating', 'utility_type', 'provider_name', 'created_at']
    search_fields = ['user__username', 'message', 'provider_name', 'utility_type']
    readonly_fields = ['created_at', 'updated_at']
