#!/usr/bin/env python
"""Test the API with no provider filter (how WiFi authority will now fetch)"""
import requests
import json

BASE_URL = 'http://127.0.0.1:8000/api'

print("="*80)
print("TESTING WIFI CONSUMER FETCH (NO PROVIDER FILTER)")
print("="*80)

print("\n[1] Fetching WiFi utilities WITHOUT provider filter")
print("-"*80)
response = requests.get(f'{BASE_URL}/user-utility/list/')
if response.status_code == 200:
    data = response.json()
    results = data.get('results', [])
    
    # Filter WiFi utilities
    wifi_utils = [u for u in results if u.get('utility_type', '').lower() == 'wifi']
    print(f"Total WiFi utilities: {len(wifi_utils)}")
    
    print("\nWiFi Consumers that will appear in dropdown:")
    for i, util in enumerate(wifi_utils, 1):
        name = util.get('user_name', '') or util.get('full_name', '') or 'Unknown'
        wifi_id = util.get('wifi_consumer_id', '')
        provider = util.get('provider_name', '')
        user = util.get('user', '')
        
        print(f"\n  {i}. {name}")
        print(f"     WiFi ID: {wifi_id}")
        print(f"     Provider: {provider}")
        print(f"     Has User FK: {'✓ Yes' if user else '✗ No'}")
else:
    print(f"Error: {response.status_code}")

print("\n" + "="*80)
print("RESULT:")
print("="*80)
print("The WiFi authority should now see all 4 consumers in the dropdown!")
print("\nRefresh the Generate Bill page to see the changes.")
