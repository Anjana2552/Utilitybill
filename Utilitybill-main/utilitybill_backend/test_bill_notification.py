#!/usr/bin/env python
"""Test bill generation notification flow"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import GeneratedBill, Notification, UserUtility
from datetime import datetime, timedelta

print("="*80)
print("TEST: BILL GENERATION NOTIFICATION FLOW")
print("="*80)

# Check if user 'anjana' has electricity utility registered
user = User.objects.filter(username='anjana').first()
if not user:
    print("✗ User 'anjana' not found")
    exit(1)

print(f"\n✓ User found: {user.username} (ID: {user.id})")

# Check user's utilities
utilities = UserUtility.objects.filter(user=user)
print(f"\nUser's registered utilities:")
for util in utilities:
    print(f"  - {util.utility_type}")
    if util.utility_type.lower() == 'electricity':
        print(f"    Consumer Number: {util.consumer_number}")

# Count existing notifications
existing_notifs = Notification.objects.filter(user=user).count()
print(f"\nExisting notifications for {user.username}: {existing_notifs}")

# Simulate creating a bill via API (using the same logic as add_generated_bill view)
print("\n" + "-"*80)
print("SIMULATING BILL GENERATION")
print("-"*80)

# Check for electricity utility
elec_util = UserUtility.objects.filter(user=user, utility_type__iexact='electricity').first()
if not elec_util:
    print("✗ User doesn't have electricity utility registered")
    print("\nRECOMMENDATION: Register electricity utility for user 'anjana' first")
else:
    consumer_num = elec_util.consumer_number
    print(f"\n✓ Found electricity utility with consumer number: {consumer_num}")
    
    # Create a test bill
    from bills.views import _create_notification
    
    bill_id = f"TEST-KSEB-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    due_date = datetime.now().date() + timedelta(days=7)
    
    # Create notification (simulating what add_generated_bill does)
    notification = _create_notification(
        user=user,
        notification_type='bill_generated',
        title=f'New Electricity Bill Generated',
        message=f'A new bill for Electricity (KSEB) has been generated. Amount: ₹750. Due date: {due_date.strftime("%B %d, %Y")}',
        utility_type='Electricity',
        bill_id_ref=bill_id,
        due_date=due_date
    )
    
    if notification:
        print(f"\n✓ NOTIFICATION CREATED!")
        print(f"  ID: {notification.id}")
        print(f"  Type: {notification.notification_type}")
        print(f"  Title: {notification.title}")
        print(f"  User: {notification.user.username}")
        
        # Verify it appears in API
        new_count = Notification.objects.filter(user=user).count()
        print(f"\n✓ Total notifications for {user.username}: {new_count} (was {existing_notifs})")
        print(f"✓ New notifications: {new_count - existing_notifs}")
    else:
        print("\n✗ Failed to create notification")

print("\n" + "="*80)
print("TEST COMPLETE")
print("="*80)
print("\nNow check Flutter app:")
print("1. Login as 'anjana'")
print("2. Go to Notifications page")
print("3. You should see the new bill notification")
print("\nAPI endpoint to verify:")
print("  http://127.0.0.1:8000/api/notifications-by-username/?username=anjana")
