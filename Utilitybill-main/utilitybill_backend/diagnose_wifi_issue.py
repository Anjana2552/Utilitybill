#!/usr/bin/env python
"""Diagnose why WiFi consumers don't appear in generate bill page"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility
from django.contrib.auth.models import User

print("="*80)
print("DIAGNOSING WIFI CONSUMER VISIBILITY ISSUE")
print("="*80)

# Check WiFi utilities
wifi_utils = UserUtility.objects.filter(utility_type__iexact='WiFi')
print(f"\nTotal WiFi utilities: {wifi_utils.count()}")

for util in wifi_utils:
    print(f"\n--- WiFi Utility {util.id} ---")
    print(f"  user_name (string field): '{util.user_name}'")
    print(f"  user (FK to User): {util.user}")
    print(f"  user_id: {util.user_id}")
    print(f"  wifi_consumer_id: '{util.wifi_consumer_id}'")
    print(f"  provider_name: '{util.provider_name}'")
    
    # Check if user_name matches any User
    if util.user_name:
        matching_user = User.objects.filter(username__iexact=util.user_name).first()
        if matching_user:
            print(f"  ✓ Matching User found: {matching_user.username} (ID: {matching_user.id})")
            if util.user_id != matching_user.id:
                print(f"  ⚠️  WARNING: user_id is NULL but matching User exists!")
        else:
            print(f"  ✗ No User found with username '{util.user_name}'")

print("\n" + "="*80)
print("ISSUE ANALYSIS")
print("="*80)

missing_fk = wifi_utils.filter(user__isnull=True).count()
print(f"\nWiFi utilities with NULL user FK: {missing_fk}")
print(f"WiFi utilities with valid user FK: {wifi_utils.exclude(user__isnull=True).count()}")

if missing_fk > 0:
    print("\n⚠️  PROBLEM FOUND:")
    print("   Some WiFi utilities have user_name but no user FK relationship")
    print("   The generate bill page likely filters these out")
    print("\n📋 SOLUTION:")
    print("   Need to link UserUtility records to their corresponding User records")
