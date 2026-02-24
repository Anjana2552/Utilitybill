#!/usr/bin/env python
"""Fix utility authority utility_type field based on their username"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import UserProfile

print("="*60)
print("FIXING UTILITY AUTHORITY UTILITY_TYPE FIELDS")
print("="*60)

# Mapping of username patterns to utility types
mappings = {
    'kseb': 'Electricity',
    'kwa': 'Water',
    'water': 'Water',
    'gas': 'Gas',
    'wifi': 'WiFi',
    'dth': 'DTH',
    'others': 'Others',
    'other': 'Others',
}

authorities = UserProfile.objects.filter(role='utility')
print(f"\nFound {authorities.count()} utility authorities\n")

fixed = 0
for profile in authorities:
    username = profile.user.username.lower()
    
    # Try to match username to utility type
    detected_type = None
    for key, value in mappings.items():
        if key in username:
            detected_type = value
            break
    
    if detected_type:
        profile.utility_type = detected_type
        profile.save()
        print(f"✓ {profile.user.username:15} -> {detected_type}")
        fixed += 1
    else:
        print(f"✗ {profile.user.username:15} -> Could not detect type")

print(f"\n{'='*60}")
print(f"Fixed {fixed} utility authority profiles")
print(f"{'='*60}")
