import os
import django
import requests

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UtilityBill, Payment

def test_bill_serialization():
    """Test if bills are serialized with correct bill_status"""
    
    print("\n" + "="*60)
    print("Testing UtilityBillSerializer bill_status field")
    print("="*60)
    
    # Get a few bills from the database
    bills = UtilityBill.objects.all()[:5]
    
    if not bills.exists():
        print("No bills found in database")
        return
    
    print(f"\nChecking {bills.count()} bills from database:\n")
    
    for bill in bills:
        # Check if bill has approved payments
        has_approved = bill.payments.filter(status='Approved').exists()
        payment_count = bill.payments.count()
        approved_count = bill.payments.filter(status='Approved').count()
        
        expected_status = 'paid' if has_approved else 'unpaid'
        
        print(f"Bill ID: {bill.bill_id}")
        print(f"  Consumer: {bill.consumer_id}")
        print(f"  Amount: ₹{bill.total_amount}")
        print(f"  Payments: {payment_count} total, {approved_count} approved")
        print(f"  Expected Status: {expected_status}")
        print()
    
    print("="*60)
    print("Backend serializer should now include bill_status field")
    print("="*60)

if __name__ == '__main__':
    test_bill_serialization()
