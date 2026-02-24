import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UserUtility, UtilityBill, Notification
from django.contrib.auth.models import User
from datetime import date

print("=" * 60)
print("TESTING NOTIFICATION CREATION")
print("=" * 60)

# Create a test water bill for rinu
try:
    user = User.objects.get(username='rinu')
    print(f"\n✓ User found: {user.username} (ID: {user.id})")
    
    # Check rinu's water utility
    water_utility = UserUtility.objects.filter(
        user=user,
        utility_type__iexact='water'
    ).first()
    
    if water_utility:
        print(f"✓ Water utility found: Connection {water_utility.water_connection_number}")
        
        # Create a test bill
        test_bill = UtilityBill.objects.create(
            bill_id=f'TEST-WATER-{date.today().strftime("%Y%m%d%H%M%S")}',
            utility_type='Water',
            consumer_id=water_utility.water_connection_number,
            consumer_name=user.username,
            total_amount=150.50,
            previous_reading=100,
            current_reading=115
        )
        print(f"✓ Test bill created: {test_bill.bill_id}")
        
        # Now manually trigger notification creation (simulating the API)
        from bills.views import _create_notification
        
        notification = _create_notification(
            user=user,
            notification_type='bill_generated',
            title=f'New Water Bill Generated',
            message=f'A new bill (ID: {test_bill.bill_id}) for Water has been generated. Amount: ₹{test_bill.total_amount}. Please check your bills section.',
            utility_type='Water',
            bill_id_ref=test_bill.bill_id,
            due_date=None
        )
        
        if notification:
            print(f"✓ Notification created: ID {notification.id}")
            print(f"  Title: {notification.title}")
            print(f"  Message: {notification.message}")
            
            # Verify notification exists
            notif_count = Notification.objects.filter(user=user).count()
            print(f"\n✓ Total notifications for rinu: {notif_count}")
        else:
            print("✗ Failed to create notification")
        
        # Clean up test bill
        test_bill.delete()
        print(f"\n✓ Test bill cleaned up")
        
    else:
        print("✗ No water utility found for rinu")
        
except User.DoesNotExist:
    print("✗ User 'rinu' not found")
except Exception as e:
    print(f"✗ Error: {e}")

print(f"\n{'=' * 60}")
print("TEST COMPLETE")
print(f"{'=' * 60}")
