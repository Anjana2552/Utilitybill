#!/usr/bin/env python
"""Fix WiFi utilities by linking them to their User accounts"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility
from django.contrib.auth.models import User

print("="*80)
print("FIXING WIFI UTILITY USER RELATIONSHIPS")
print("="*80)

# Get all WiFi utilities with NULL user FK
wifi_utils = UserUtility.objects.filter(utility_type__iexact='WiFi', user__isnull=True)
print(f"\nFound {wifi_utils.count()} WiFi utilities with missing user FK\n")

fixed_count = 0
for util in wifi_utils:
    if util.user_name:
        # Find matching User
        matching_user = User.objects.filter(username__iexact=util.user_name).first()
        if matching_user:
            util.user = matching_user
            util.save()
            print(f"✓ Fixed: '{util.user_name}' → User ID {matching_user.id} ({matching_user.username})")
            fixed_count += 1
        else:
            print(f"✗ No matching User for: '{util.user_name}'")
    else:
        print(f"✗ UserUtility {util.id} has no user_name")

print("\n" + "="*80)
print(f"FIXED {fixed_count} WiFi utility records")
print("="*80)

# Verify the fix
wifi_with_user = UserUtility.objects.filter(utility_type__iexact='WiFi', user__isnull=False).count()
print(f"\nWiFi utilities with valid user FK: {wifi_with_user}")
print("These should now appear in the Generate Bill dropdown!")
