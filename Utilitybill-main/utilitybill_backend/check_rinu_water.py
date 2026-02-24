import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility, Notification
from django.contrib.auth.models import User

print("=" * 60)
print("CHECKING RINU'S WATER UTILITY")
print("=" * 60)

try:
    user = User.objects.get(username='rinu')
    print(f"\n✓ User found: {user.username} (ID: {user.id})")
    
    # Check if rinu has water utility registered
    water_utilities = UserUtility.objects.filter(
        user=user,
        utility_type__iexact='water'
    )
    
    print(f"\nWater utilities for rinu: {water_utilities.count()}")
    for uu in water_utilities:
        print(f"  - Connection Number: {uu.water_connection_number}")
        print(f"  - Provider: {uu.provider_name}")
        print(f"  - User Name: {uu.user_name}")
    
    # Check all water utilities with connection 5554
    print(f"\n{'=' * 60}")
    print("ALL WATER UTILITIES WITH CONNECTION 5554")
    print(f"{'=' * 60}")
    
    water_5554 = UserUtility.objects.filter(
        utility_type__iexact='water',
        water_connection_number='5554'
    )
    
    print(f"\nFound {water_5554.count()} utilities with connection 5554:")
    for uu in water_5554:
        print(f"  - User Name: {uu.user_name}")
        print(f"  - Linked User: {uu.user.username if uu.user else 'NO USER LINK'}")
        print(f"  - Provider: {uu.provider_name}")
        print()
    
    # Check notifications for rinu
    print(f"{'=' * 60}")
    print("NOTIFICATIONS FOR RINU")
    print(f"{'=' * 60}")
    
    notifications = Notification.objects.filter(user=user).order_by('-created_at')
    print(f"\nTotal notifications: {notifications.count()}")
    for n in notifications[:5]:
        print(f"  - {n.notification_type}: {n.title}")
        print(f"    Created: {n.created_at}")
        print()
    
except User.DoesNotExist:
    print("✗ User 'rinu' not found")
