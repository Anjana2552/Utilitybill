"""Show current notifications and how they appear to users"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import Notification
from django.contrib.auth.models import User

print("\n" + "="*80)
print("CURRENT NOTIFICATIONS STATUS")
print("="*80 + "\n")

# Show authority alerts
print("1. AUTHORITY ALERTS (Messages from Utility Authorities)")
print("-" * 80)
authority_alerts = Notification.objects.filter(
    notification_type__in=['alert', 'urgent_alert']
).select_related('user').order_by('-created_at')

if authority_alerts.exists():
    for notif in authority_alerts:
        print(f"\nUser: {notif.user.username}")
        print(f"Type: {notif.notification_type.upper()}")
        print(f"Title: {notif.title}")
        print(f"Message: {notif.message}")
        print(f"Read: {'Yes' if notif.read else 'No (NEW)'}")
        print(f"Created: {notif.created_at.strftime('%Y-%m-%d %H:%M')}")
else:
    print("No authority alerts found")

# Show system notifications
print("\n\n2. SYSTEM NOTIFICATIONS (Auto-generated)")
print("-" * 80)
system_notifs = Notification.objects.exclude(
    notification_type__in=['alert', 'urgent_alert']
).select_related('user').order_by('-created_at')[:10]

if system_notifs.exists():
    print(f"Total system notifications: {Notification.objects.exclude(notification_type__in=['alert', 'urgent_alert']).count()}")
    print(f"\nShowing last 10:")
    for notif in system_notifs:
        print(f"\n• {notif.user.username} - [{notif.notification_type}] {notif.title}")
else:
    print("No system notifications found")

# Show count by user
print("\n\n3. NOTIFICATIONS BY USER")
print("-" * 80)
users_with_alerts = User.objects.filter(
    notifications__notification_type__in=['alert', 'urgent_alert']
).distinct()

for user in users_with_alerts:
    alert_count = Notification.objects.filter(
        user=user,
        notification_type__in=['alert', 'urgent_alert']
    ).count()
    system_count = Notification.objects.filter(user=user).exclude(
        notification_type__in=['alert', 'urgent_alert']
    ).count()
    print(f"{user.username}: {alert_count} authority alerts, {system_count} system notifications")

print("\n" + "="*80)
print("SUMMARY")
print("="*80)
print("\nUsers with Electricity utility will see authority alerts in their")
print("notifications page with special highlighting:")
print("  • Red border and background for URGENT alerts")
print("  • Blue border and background for normal alerts")
print("  • Clear authority message display")
print("  • System notifications shown separately with standard styling")
print("\nUsers can filter notifications by:")
print("  • All - Show everything")
print("  • Authority Alerts - Only messages from utility authorities")
print("  • System - Only auto-generated bill/payment notifications")
print("\n" + "="*80 + "\n")
