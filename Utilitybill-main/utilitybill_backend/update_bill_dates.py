#!/usr/bin/env python
"""
Script to update existing UtilityBill records with reading_date and due_date.
For historical bills, sets reading_date to created_at date and due_date to 14 days later.
"""
import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UtilityBill
from datetime import timedelta

def update_bill_dates():
    """Update bills that don't have reading_date or due_date set."""
    bills_without_dates = UtilityBill.objects.filter(due_date__isnull=True)
    count = bills_without_dates.count()
    
    print(f"Found {count} bills without due dates")
    
    if count == 0:
        print("All bills already have dates set!")
        return
    
    updated = 0
    for bill in bills_without_dates:
        # Set reading_date to the bill's creation date
        bill.reading_date = bill.created_at.date()
        # Set due_date to 14 days after creation
        bill.due_date = bill.created_at.date() + timedelta(days=14)
        bill.save()
        updated += 1
        print(f"Updated {bill.bill_id}: reading={bill.reading_date}, due={bill.due_date}")
    
    print(f"\n✓ Successfully updated {updated} bills!")

if __name__ == '__main__':
    update_bill_dates()
