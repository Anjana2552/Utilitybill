#!/usr/bin/env python
"""Test the user-utility list API endpoint"""
import requests
import json

BASE_URL = 'http://127.0.0.1:8000/api'

print("="*80)
print("TESTING USER-UTILITY LIST API")
print("="*80)

print("\n[1] Fetching all utilities")
print("-"*80)
response = requests.get(f'{BASE_URL}/user-utility/list/')
if response.status_code == 200:
    data = response.json()
    results = data.get('results', [])
    print(f"Total utilities: {len(results)}")
    
    # Find WiFi utilities
    wifi_utils = [u for u in results if u.get('utility_type', '').lower() == 'wifi']
    print(f"\nWiFi utilities: {len(wifi_utils)}")
    
    for util in wifi_utils:
        print(f"\n  User Name: {util.get('user_name', '')}")
        print(f"  Full Name: {util.get('full_name', '')}")
        print(f"  Username: {util.get('username', '')}")
        print(f"  User Username: {util.get('user_username', '')}")
        print(f"  WiFi Consumer ID: {util.get('wifi_consumer_id', '')}")
        print(f"  Provider: {util.get('provider_name', '')}")
        
        # Check which name fields are populated
        name_fields = ['full_name', 'user_name', 'username', 'user_username', 'user', 'name']
        populated = [f for f in name_fields if util.get(f) and str(util.get(f)).strip()]
        print(f"  Populated name fields: {populated}")
else:
    print(f"Error: {response.status_code}")
    print(response.text)

print("\n" + "="*80)
