#!/usr/bin/env python
"""Check WiFi consumers in database"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility

print("="*80)
print("CHECKING WIFI CONSUMERS")
print("="*80)

# Get all WiFi utilities
wifi_utilities = UserUtility.objects.filter(utility_type__iexact='WiFi')
print(f"\nTotal WiFi utilities registered: {wifi_utilities.count()}")

for util in wifi_utilities:
    print(f"\n--- WiFi Utility ---")
    print(f"  User: {util.user.username if util.user else 'No user'}")
    print(f"  User Name: {util.user_name}")
    print(f"  WiFi Consumer ID: '{util.wifi_consumer_id}'")
    print(f"  Provider Name: {util.provider_name}")
    print(f"  Created: {util.created_at}")
    
    if not util.wifi_consumer_id or util.wifi_consumer_id.strip() == '':
        print("  ⚠️  WARNING: WiFi Consumer ID is empty!")

print("\n" + "="*80)
print("SUMMARY")
print("="*80)

empty_count = wifi_utilities.filter(wifi_consumer_id='').count() + wifi_utilities.filter(wifi_consumer_id__isnull=True).count()
valid_count = wifi_utilities.exclude(wifi_consumer_id='').exclude(wifi_consumer_id__isnull=True).count()

print(f"WiFi utilities with valid Consumer ID: {valid_count}")
print(f"WiFi utilities with empty Consumer ID: {empty_count}")

if empty_count > 0:
    print("\n⚠️  ISSUE FOUND: Some WiFi utilities have empty wifi_consumer_id field")
    print("   These users will NOT appear in the Consumer Name dropdown")
    print("   Solution: Users need to re-register their WiFi utility with Consumer ID")
