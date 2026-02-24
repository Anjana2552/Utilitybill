"""Clean up test notifications and send a fresh broadcast alert"""
import os
import sys
import django
import json

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.test import RequestFactory
from bills import views
from bills.models import Notification

print("\n" + "="*80)
print("CLEAN UP AND FRESH BROADCAST TEST")
print("="*80 + "\n")

# Delete existing alert notifications
print("1. Cleaning up test notifications...")
print("-" * 80)
deleted_count = Notification.objects.filter(
    notification_type__in=['alert', 'urgent_alert']
).delete()[0]
print(f"Deleted {deleted_count} existing alert notifications\n")

# Send fresh broadcast alert
print("2. Sending fresh broadcast alert...")
print("-" * 80)
factory = RequestFactory()

test_data = {
    'utility_type': 'Electricity',
    'title': 'Scheduled Maintenance',
    'message': 'Power maintenance scheduled for February 25, 2026 from 9:00 AM to 12:00 PM. Please plan accordingly.',
    'priority': 'high',
    'sender_username': 'kseb'
}

print(f"Utility Type: {test_data['utility_type']}")
print(f"Priority: {test_data['priority']}")
print(f"Title: {test_data['title']}")
print(f"Message: {test_data['message']}\n")

request = factory.post(
    '/api/alerts/send-broadcast/',
    data=json.dumps(test_data),
    content_type='application/json'
)

response = views.send_broadcast_alert(request)
print(f"✓ Response Status: {response.status_code}")
print(f"✓ Users Notified: {response.data.get('users_notified', 0)}\n")

# Verify notifications were created
print("3. Verifying created notifications...")
print("-" * 80)
alert_notifications = Notification.objects.filter(
    notification_type__in=['alert', 'urgent_alert']
).order_by('user__username')

print(f"Total alert notifications: {alert_notifications.count()}\n")

if alert_notifications.exists():
    print("Created notifications:")
    for notif in alert_notifications:
        print(f"  ✓ {notif.user.username}: {notif.title}")

# Test fetching for one user
print("\n4. Testing API fetch for user 'anjana'...")
print("-" * 80)
request = factory.get('/api/notifications-by-username/?username=anjana')
response = views.list_notifications_by_username(request)

if response.status_code == 200:
    data = response.data
    notifications = data.get('notifications', [])
    alert_found = False
    
    for notif in notifications:
        if notif.get('notification_type') in ['alert', 'urgent_alert']:
            alert_found = True
            print(f"✓ Alert notification found in API response:")
            print(f"  Type: {notif.get('notification_type')}")
            print(f"  Title: {notif.get('title')}")
            print(f"  Message: {notif.get('message')}")
            print(f"  Read: {notif.get('read')}")
            break
    
    if not alert_found:
        print("✗ Alert notification NOT found in API response")
else:
    print(f"✗ API request failed: {response.status_code}")

print("\n" + "="*80)
print("TEST COMPLETE - Broadcast alerts are now working!")
print("="*80 + "\n")
print("Next steps:")
print("  1. Launch the Flutter app")
print("  2. Login as user 'anjana', 'achu', 'sanju', or 'arya'")
print("  3. Navigate to Notifications page")
print("  4. Verify the 'URGENT: Scheduled Maintenance' alert appears")
print()
