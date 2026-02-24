import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility
from django.contrib.auth.models import User

print("=" * 60)
print("FIXING ALL USER UTILITY LINKS")
print("=" * 60)

# Get all utilities without user links
utilities_without_links = UserUtility.objects.filter(user__isnull=True)

print(f"\nFound {utilities_without_links.count()} utilities without user links\n")

fixed_count = 0

for utility in utilities_without_links:
    username = utility.user_name.lower().strip()
    print(f"Processing: {utility.user_name} ({utility.utility_type})")
    
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
    print()

print(f"{'=' * 60}")
print(f"Fixed {fixed_count}/{utilities_without_links.count()} user links")
print(f"{'=' * 60}")
