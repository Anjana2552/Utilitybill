#!/usr/bin/env python
"""Create test notifications for users and utility authorities"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import Notification, UserProfile

print("="*60)
print("CREATING TEST NOTIFICATIONS")
print("="*60)

# Create notification for user 'anjana'
user = User.objects.filter(username='anjana').first()
if user:
    notif = Notification.objects.create(
        user=user,
        notification_type='bill_generated',
        title='Test: New Electricity Bill',
        message='This is a test notification for bill generation. Amount: ₹500',
        utility_type='Electricity',
        bill_id='TEST-001',
        read=False
    )
    print(f"\n✓ Created notification for USER: {user.username}")
    print(f"  ID: {notif.id}")
    print(f"  Type: {notif.notification_type}")
    print(f"  Title: {notif.title}")

# Create notification for Electricity authority
authority = UserProfile.objects.filter(role='utility', utility_type='Electricity').first()
if authority:
    notif = Notification.objects.create(
        user=authority.user,
        notification_type='payment_initiated',
        title='Test: Payment Initiated',
        message='User anjana initiated payment for Electricity bill TEST-001. Amount: ₹500',
        utility_type='Electricity',
        bill_id='TEST-001',
        read=False
    )
    print(f"\n✓ Created notification for AUTHORITY: {authority.user.username}")
    print(f"  ID: {notif.id}")
    print(f"  Type: {notif.notification_type}")
    print(f"  Title: {notif.title}")
    print(f"  Utility Type: {notif.utility_type}")

# Show counts
print("\n" + "="*60)
print("NOTIFICATION COUNTS")
print("="*60)
print(f"\nUser 'anjana': {Notification.objects.filter(user__username='anjana').count()} notifications")
print(f"Authority 'amalkseb': {Notification.objects.filter(user__username='amalkseb').count()} notifications")

print("\n" + "="*60)
