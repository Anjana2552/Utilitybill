#!/usr/bin/env python
"""Create test reviews"""

import requests
import json

test_reviews = [
    {'provider': 'water', 'type': 'Water', 'rating': 4, 'message': 'Good water supply, minor issues during monsoon.', 'username': 'user2'},
    {'provider': 'gas', 'type': 'Gas', 'rating': 5, 'message': 'Timely delivery and excellent customer support.', 'username': 'user1'},
    {'provider': 'wifi', 'type': 'WiFi', 'rating': 3, 'message': 'Average speed, needs improvement.', 'username': 'user3'},
    {'provider': 'kseb', 'type': 'Electricity', 'rating': 4, 'message': 'Generally reliable, occasional power cuts.', 'username': 'user2'},
]

for review in test_reviews:
    try:
        data = {
            'provider_name': review['provider'],
            'utility_type': review['type'],
            'rating': review['rating'],
            'message': review['message'],
            'username': review['username']
        }
        response = requests.post('http://127.0.0.1:8000/api/reviews/add/', json=data, timeout=5)
        if response.status_code == 201:
            print(f'✓ Created review: {review["type"]} ({review["rating"]}★) by {review["username"]}')
        else:
            print(f'✗ Failed: {response.text}')
    except Exception as e:
        print(f'Error: {e}')

print('\nAll reviews created!')
