#!/usr/bin/env python
"""Verify notifications appear in API"""
import requests

response = requests.get('http://127.0.0.1:8000/api/notifications-by-username/?username=anjana')
data = response.json()

print(f"\nAPI Response for user 'anjana':")
print(f"  Total notifications: {data['total_count']}")
print(f"  Unread: {data['unread_count']}")
print("\nNotifications:")
for n in data['notifications']:
    print(f"  [{n['id']}] {n['title']}")
    print(f"      Type: {n['notification_type']}, Read: {n['read']}")
