"""
Script to create a test user with payment methods for wallet testing
"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from django.contrib.auth.models import User
from bills.models import UserProfile, PaymentMethod

# Create or get user
username = 'samee'
user, created = User.objects.get_or_create(
    username=username,
    defaults={
        'email': 'samee@example.com',
        'first_name': 'Samee',
        'last_name': 'User',
    }
)

if created:
    user.set_password('password123')
    user.save()
    print(f"✅ Created user: {username}")
else:
    print(f"ℹ️  User already exists: {username}")

# Create or get profile
profile, created = UserProfile.objects.get_or_create(
    user=user,
    defaults={
        'full_name': 'Samee Test User',
        'role': 'user',
    }
)
print(f"{'✅ Created' if created else 'ℹ️  Existing'} profile for {username}")

# Add payment methods
payment_methods = ['Credit Card', 'Bank Transfer', 'UPI']
added_count = 0

for method in payment_methods:
    pm, created = PaymentMethod.objects.get_or_create(
        user=user,
        method=method,
    )
    if created:
        added_count += 1
        print(f"✅ Added payment method: {method}")
    else:
        print(f"ℹ️  Payment method already exists: {method}")

print(f"\n✅ Setup complete!")
print(f"Username: {username}")
print(f"Password: password123")
print(f"Payment methods: {len(payment_methods)} total")
