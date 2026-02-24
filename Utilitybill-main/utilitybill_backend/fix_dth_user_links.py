import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility, UserProfile
from django.contrib.auth.models import User

print("=" * 60)
print("FIXING DTH USER LINKS")
print("=" * 60)

# Get all DTH utilities without user links
dth_utilities = UserUtility.objects.filter(utility_type__iexact='dth', user__isnull=True)

fixed_count = 0

for utility in dth_utilities:
    username = utility.user_name.lower()
    print(f"\nProcessing: {utility.user_name} (Subscriber ID: {utility.dth_subscriber_id})")
    
    try:
        # Try to find matching User account
        user = User.objects.get(username__iexact=username)
        utility.user = user
        utility.save()
        print(f"  ✓ Linked to User: {user.username} (ID: {user.id})")
        fixed_count += 1
    except User.DoesNotExist:
        print(f"  ✗ No matching User account found for '{username}'")
    except User.MultipleObjectsReturned:
        print(f"  ✗ Multiple User accounts found for '{username}'")

print(f"\n{'=' * 60}")
print(f"Fixed {fixed_count} DTH user links")
print(f"{'=' * 60}")
