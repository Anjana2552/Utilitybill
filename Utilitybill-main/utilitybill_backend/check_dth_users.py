import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility

print("=" * 60)
print("DTH USERS IN DATABASE")
print("=" * 60)

dth_users = UserUtility.objects.filter(utility_type__iexact='dth')
print(f"\nTotal DTH users: {dth_users.count()}\n")

for u in dth_users:
    print(f"User Name: {u.user_name}")
    print(f"  - Linked User: {u.user.username if u.user else 'NO USER LINK'}")
    print(f"  - Subscriber ID: {u.dth_subscriber_id}")
    print(f"  - Provider: {u.provider_name}")
    print()
