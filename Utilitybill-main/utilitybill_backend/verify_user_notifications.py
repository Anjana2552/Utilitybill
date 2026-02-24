"""Test script to verify broadcast alerts appear in user notification API"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.test import RequestFactory
from bills import views
import json

print("\n" + "="*80)
print("VERIFY USER NOTIFICATIONS API")
print("="*80 + "\n")

# Test fetching notifications for users who received the alert
test_usernames = ['anjana', 'achu', 'sanju', 'arya']

factory = RequestFactory()

for username in test_usernames:
    print(f"\nFetching notifications for: {username}")
    print("-" * 80)
    
    request = factory.get(f'/api/notifications-by-username/?username={username}')
    response = views.list_notifications_by_username(request)
    
    if response.status_code == 200:
        data = response.data
        print(f"Status: SUCCESS")
        print(f"Total notifications: {data.get('total_count', 0)}")
        print(f"Unread notifications: {data.get('unread_count', 0)}")
        
        notifications = data.get('notifications', [])
        if notifications:
            print(f"\nNotifications:")
            for notif in notifications[:5]:  # Show first 5
                notif_type = notif.get('notification_type', '')
                title = notif.get('title', '')
                is_read = notif.get('read', False)
                created = notif.get('created_at', '')
                print(f"  [{notif_type}] {title}")
                print(f"    Read: {is_read}, Created: {created[:19] if created else 'N/A'}")
        else:
            print("No notifications found")
    else:
        print(f"Status: ERROR {response.status_code}")
        print(f"Response: {response.data}")

print("\n" + "="*80)
print("VERIFICATION COMPLETE")
print("="*80 + "\n")
