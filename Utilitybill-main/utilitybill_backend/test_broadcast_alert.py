"""Test script to verify broadcast alert notifications are created correctly"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import UserUtility, Notification

print("\n" + "="*80)
print("BROADCAST ALERT NOTIFICATION TEST")
print("="*80 + "\n")

# Check UserUtility records
print("1. Checking UserUtility records...")
print("-" * 80)
user_utilities = UserUtility.objects.all()
print(f"Total UserUtility records: {user_utilities.count()}")

# Group by utility type
from django.db.models import Count
utility_counts = UserUtility.objects.values('utility_type').annotate(count=Count('id'))
print(f"\nUtility type breakdown:")
for item in utility_counts:
    print(f"  - {item['utility_type']}: {item['count']} records")

# Check which ones have user FK set
utilities_with_user = UserUtility.objects.exclude(user__isnull=True).count()
utilities_without_user = UserUtility.objects.filter(user__isnull=True).count()
print(f"\nUserUtility records with user FK: {utilities_with_user}")
print(f"UserUtility records without user FK: {utilities_without_user}")

# Sample some UserUtility records
print(f"\nSample UserUtility records (first 5):")
for uu in UserUtility.objects.all()[:5]:
    user_info = f"User: {uu.user.username} (ID: {uu.user.id})" if uu.user else "User: None"
    print(f"  - {uu.utility_type} | {user_info} | user_name: {uu.user_name}")

# Check notifications with type 'alert' or 'urgent_alert'
print("\n2. Checking broadcast alert notifications...")
print("-" * 80)
alert_notifications = Notification.objects.filter(
    notification_type__in=['alert', 'urgent_alert']
).order_by('-created_at')

print(f"Total alert/urgent_alert notifications: {alert_notifications.count()}")

if alert_notifications.exists():
    print(f"\nRecent alert notifications (last 5):")
    for notif in alert_notifications[:5]:
        print(f"  - ID: {notif.id}")
        print(f"    User: {notif.user.username} (ID: {notif.user.id})")
        print(f"    Type: {notif.notification_type}")
        print(f"    Title: {notif.title}")
        print(f"    Message: {notif.message[:50]}...")
        print(f"    Utility Type: {notif.utility_type}")
        print(f"    Read: {notif.read}")
        print(f"    Created: {notif.created_at}")
        print()
else:
    print("No alert notifications found.")

# Check all notifications for a specific test user
print("\n3. Checking notifications for test users...")
print("-" * 80)
test_usernames = ['john', 'riya', 'rinu']  # Common test usernames
for username in test_usernames:
    try:
        user = User.objects.get(username__iexact=username)
        user_notifications = Notification.objects.filter(user=user).order_by('-created_at')
        alert_count = user_notifications.filter(notification_type__in=['alert', 'urgent_alert']).count()
        print(f"\nUser: {user.username} (ID: {user.id})")
        print(f"  Total notifications: {user_notifications.count()}")
        print(f"  Alert notifications: {alert_count}")
        
        if alert_count > 0:
            print(f"  Recent alerts:")
            for notif in user_notifications.filter(notification_type__in=['alert', 'urgent_alert'])[:3]:
                print(f"    - [{notif.notification_type}] {notif.title}")
    except User.DoesNotExist:
        print(f"\nUser '{username}' not found")

# Check Electricity utility users specifically
print("\n4. Checking Electricity utility users...")
print("-" * 80)
electricity_utilities = UserUtility.objects.filter(
    utility_type__iexact='Electricity'
).exclude(user__isnull=True).select_related('user')

print(f"Electricity UserUtility records with user FK: {electricity_utilities.count()}")
if electricity_utilities.exists():
    print(f"\nElectricity users:")
    for uu in electricity_utilities[:5]:
        notifications_count = Notification.objects.filter(user=uu.user).count()
        alert_count = Notification.objects.filter(
            user=uu.user, 
            notification_type__in=['alert', 'urgent_alert']
        ).count()
        print(f"  - {uu.user.username}: {notifications_count} total notifications, {alert_count} alerts")

print("\n" + "="*80)
print("TEST COMPLETE")
print("="*80 + "\n")
