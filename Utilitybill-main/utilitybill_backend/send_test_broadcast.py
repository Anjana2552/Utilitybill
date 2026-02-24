"""Test script to send a broadcast alert and verify notifications are created"""
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
print("SEND BROADCAST ALERT TEST")
print("="*80 + "\n")

# Create a test request
factory = RequestFactory()

# Test data - send alert to all Electricity users
test_data = {
    'utility_type': 'Electricity',
    'title': 'Test Maintenance Alert',
    'message': 'This is a test alert to verify broadcast functionality. Power maintenance scheduled.',
    'priority': 'high',
    'sender_username': 'kseb'
}

print(f"Sending test broadcast alert...")
print(f"Utility Type: {test_data['utility_type']}")
print(f"Title: {test_data['title']}")
print(f"Priority: {test_data['priority']}")
print(f"Message: {test_data['message']}\n")

# Create request
request = factory.post(
    '/api/alerts/send-broadcast/',
    data=json.dumps(test_data),
    content_type='application/json'
)

# Call the view
response = views.send_broadcast_alert(request)

print(f"Response Status: {response.status_code}")
print(f"Response Data: {response.data}\n")

# Verify notifications were created
print("Checking created notifications...")
print("-" * 80)

alert_notifications = Notification.objects.filter(
    notification_type__in=['alert', 'urgent_alert']
).order_by('-created_at')

print(f"Total alert notifications now: {alert_notifications.count()}")

if alert_notifications.exists():
    print(f"\nCreated notifications:")
    for notif in alert_notifications[:10]:
        print(f"  - User: {notif.user.username}")
        print(f"    Type: {notif.notification_type}")
        print(f"    Title: {notif.title}")
        print(f"    Utility: {notif.utility_type}")
        print(f"    Created: {notif.created_at}")
        print()

print("="*80)
print("TEST COMPLETE")
print("="*80 + "\n")
