#!/usr/bin/env python
"""Test the notifications API endpoint"""
import requests
import json

BASE_URL = 'http://127.0.0.1:8000/api'

print("="*60)
print("TESTING NOTIFICATIONS API")
print("="*60)

# Test 1: Get notifications for user 'anjana'
print("\n[TEST 1] Fetch notifications for USER 'anjana'")
print("-"*60)
response = requests.get(f'{BASE_URL}/notifications-by-username/?username=anjana')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"✓ Success: {data['success']}")
    print(f"  Username: {data['username']}")
    print(f"  Total: {data['total_count']}")
    print(f"  Unread: {data['unread_count']}")
    print(f"\n  Notifications:")
    for notif in data['notifications']:
        print(f"    • [{notif['id']}] {notif['notification_type']}: {notif['title']}")
        print(f"      Utility Type: {notif.get('utility_type', 'None')}")
        print(f"      Read: {notif['read']}")
else:
    print(f"✗ Failed: {response.text}")

# Test 2: Get notifications for utility authority 'amalkseb' (Electricity)
print("\n[TEST 2] Fetch notifications for AUTHORITY 'amalkseb'")
print("-"*60)
response = requests.get(f'{BASE_URL}/notifications-by-username/?username=amalkseb')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"✓ Success: {data['success']}")
    print(f"  Username: {data['username']}")
    print(f"  Total: {data['total_count']}")
    print(f"  Unread: {data['unread_count']}")
    print(f"\n  Notifications:")
    for notif in data['notifications']:
        print(f"    • [{notif['id']}] {notif['notification_type']}: {notif['title']}")
        print(f"      Message: {notif['message'][:60]}...")
        print(f"      Utility Type: {notif.get('utility_type', 'None')}")
else:
    print(f"✗ Failed: {response.text}")

# Test 3: Get notifications filtered by utility_type
print("\n[TEST 3] Fetch notifications for 'amalkseb' filtered by utility_type=Electricity")
print("-"*60)
response = requests.get(f'{BASE_URL}/notifications-by-username/?username=amalkseb&utility_type=Electricity')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"✓ Success: {data['success']}")
    print(f"  Filter: {data.get('filtered_by_utility_type', 'None')}")
    print(f"  Total: {data['total_count']}")
    print(f"\n  Notifications:")
    for notif in data['notifications']:
        print(f"    • [{notif['id']}] {notif['notification_type']}: {notif['title']}")
else:
    print(f"✗ Failed: {response.text}")

print("\n" + "="*60)
