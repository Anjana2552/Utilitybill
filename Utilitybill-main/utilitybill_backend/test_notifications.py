#!/usr/bin/env python
"""Test notification API"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import Notification, UserProfile

# Test for user 'anjana'
print("="*60)
print("NOTIFICATION DIAGNOSTIC")
print("="*60)

user = User.objects.filter(username='anjana').first()
if user:
    print(f"\n✓ User found: {user.username} (ID: {user.id})")
    
    # Get profile
    try:
        profile = user.profile
        print(f"  Role: {profile.role}")
        print(f"  Utility Type: {getattr(profile, 'utility_type', 'N/A')}")
    except:
        print("  No profile found")
    
    # Get notifications
    notifications = Notification.objects.filter(user=user).order_by('-created_at')
    print(f"\n✓ Notifications: {notifications.count()} total")
    
    for n in notifications:
        print(f"  - [{n.id}] {n.notification_type}: {n.title}")
        print(f"    Utility Type: {n.utility_type or 'None'}")
        print(f"    Bill ID: {n.bill_id or 'None'}")
        print(f"    Read: {n.read}")
        print(f"    Created: {n.created_at}")
else:
    print("✗ User 'anjana' not found")

# Test for utility authority
print("\n" + "="*60)
print("UTILITY AUTHORITY CHECK")
print("="*60)

authorities = UserProfile.objects.filter(role='utility')
print(f"\n✓ Found {authorities.count()} utility authorities:")
for auth in authorities:
    user = auth.user
    print(f"\n  - {user.username} (ID: {user.id})")
    print(f"    Utility Type: {getattr(auth, 'utility_type', 'None')}")
    
    notifs = Notification.objects.filter(user=user).order_by('-created_at')
    print(f"    Notifications: {notifs.count()}")
    for n in notifs[:3]:
        print(f"      • {n.notification_type}: {n.title}")

print("\n" + "="*60)
