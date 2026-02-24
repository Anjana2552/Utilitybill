import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import User
from django.test import Client
import json

def test_monthly_limit_notification():
    """Test the monthly limit notification endpoint"""
    
    client = Client()
    
    print("\n" + "="*60)
    print("Testing Monthly Limit Notification Endpoint")
    print("="*60)
    
    # Test case 1: User exceeded budget
    print("\n1. Testing EXCEEDED budget scenario:")
    print("-" * 40)
    
    data = {
        'username': 'anjana',  # Replace with actual test user
        'monthly_limit': 3000.0,
        'current_month_spending': 3500.0
    }
    
    response = client.post(
        '/api/budget/check-monthly-limit/',
        data=json.dumps(data),
        content_type='application/json'
    )
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print(f"Response: {json.loads(response.content)}")
    else:
        print(f"Error: {response.content}")
    
    # Test case 2: User within budget
    print("\n2. Testing WITHIN budget scenario:")
    print("-" * 40)
    
    data = {
        'username': 'anjana',
        'monthly_limit': 3000.0,
        'current_month_spending': 2000.0
    }
    
    response = client.post(
        '/api/budget/check-monthly-limit/',
        data=json.dumps(data),
        content_type='application/json'
    )
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print(f"Response: {json.loads(response.content)}")
    else:
        print(f"Error: {response.content}")
    
    # Test case 3: User nearing limit
    print("\n3. Testing NEARING limit scenario:")
    print("-" * 40)
    
    data = {
        'username': 'anjana',
        'monthly_limit': 3000.0,
        'current_month_spending': 2500.0
    }
    
    response = client.post(
        '/api/budget/check-monthly-limit/',
        data=json.dumps(data),
        content_type='application/json'
    )
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print(f"Response: {json.loads(response.content)}")
    else:
        print(f"Error: {response.content}")
    
    # Check if notifications were created
    print("\n" + "="*60)
    print("Checking Created Notifications:")
    print("="*60)
    
    user = User.objects.get(username='anjana')
    from bills.models import Notification
    
    budget_notifications = Notification.objects.filter(
        user=user,
        notification_type='budget_alert'
    ).order_by('-created_at')[:5]
    
    print(f"\nFound {budget_notifications.count()} budget notifications:")
    for notif in budget_notifications:
        print(f"\n  - {notif.title}")
        print(f"    {notif.message}")
        print(f"    Created: {notif.created_at}")
        print(f"    Read: {notif.read}")

if __name__ == '__main__':
    test_monthly_limit_notification()
