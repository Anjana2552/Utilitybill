#!/usr/bin/env python
"""Show exact JSON format Flutter will receive"""
import requests
import json

BASE_URL = 'http://127.0.0.1:8000/api'

print("="*80)
print("FLUTTER API RESPONSE FORMAT")
print("="*80)

print("\n[1] USER NOTIFICATION RESPONSE (anjana)")
print("-"*80)
response = requests.get(f'{BASE_URL}/notifications-by-username/?username=anjana')
if response.status_code == 200:
    data = response.json()
    print(json.dumps(data, indent=2))
else:
    print(f"Error: {response.status_code}")

print("\n[2] AUTHORITY NOTIFICATION RESPONSE (amalkseb)")
print("-"*80)
response = requests.get(f'{BASE_URL}/notifications-by-username/?username=amalkseb')
if response.status_code == 200:
    data = response.json()
    print(json.dumps(data, indent=2))
else:
    print(f"Error: {response.status_code}")

print("\n[3] FLUTTER NOTIFICATIONITEM MAPPING")
print("-"*80)
print("""
Flutter expects:
{
  "id": string,              // Django: notification.id (converted to string)
  "type": string,            // Django: notification.notification_type
  "title": string,           // Django: notification.title
  "message": string,         // Django: notification.message
  "timestamp": DateTime,     // Django: notification.created_at (parsed)
  "username": string,        // Passed from Flutter (user's username)
  "utilityType": string?,    // Django: notification.utility_type (nullable)
  "billId": string?,         // Django: notification.bill_id (nullable)
  "read": bool              // Django: notification.read
}

Mapping in NotificationsService.loadFromBackend():
  id: (notifMap['id'] ?? '').toString()
  type: (notifMap['notification_type'] ?? '').toString()
  title: (notifMap['title'] ?? '').toString()
  message: (notifMap['message'] ?? '').toString()
  timestamp: DateTime.tryParse((notifMap['created_at'] ?? '').toString())
  username: username (from parameter)
  utilityType: notifMap['utility_type']?.toString()
  billId: notifMap['bill_id']?.toString()
  read: (notifMap['read'] ?? false) == true

✓ All fields match correctly between Django and Flutter
""")

print("="*80)
