#!/usr/bin/env python
"""
Diagnostic script to check payment history data for utility authorities.
Run this from the utilitybill_backend directory with Django environment.
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UtilityBill, Payment, UserProfile
from collections import defaultdict

print("=" * 60)
print("PAYMENT HISTORY DIAGNOSTIC REPORT")
print("=" * 60)

# Check utility bills by type
print("\n📊 UTILITY BILLS BY TYPE:")
print("-" * 60)
utility_types = UtilityBill.objects.values_list('utility_type', flat=True).distinct()
for ut in utility_types:
    count = UtilityBill.objects.filter(utility_type=ut).count()
    print(f"  {ut}: {count} bills")

# Check payments by status
print("\n💰 PAYMENTS BY STATUS:")
print("-" * 60)
total_payments = Payment.objects.count()
approved = Payment.objects.filter(status='approved').count()
pending = Payment.objects.filter(status='pending').count()
rejected = Payment.objects.filter(status='rejected').count()
print(f"  Total Payments: {total_payments}")
print(f"  Approved: {approved}")
print(f"  Pending: {pending}")
print(f"  Rejected: {rejected}")

# Check payments per utility type
print("\n🔍 PAYMENTS PER UTILITY TYPE:")
print("-" * 60)
bill_type_map = {}
for bill in UtilityBill.objects.all():
    bill_type_map[bill.bill_id] = bill.utility_type

payment_counts = defaultdict(int)
for payment in Payment.objects.filter(status='approved'):
    bill_id = payment.bill.bill_id
    utility_type = bill_type_map.get(bill_id, 'Unknown')
    payment_counts[utility_type] += 1

for ut, count in sorted(payment_counts.items()):
    print(f"  {ut}: {count} approved payments")

# Check utility authority users
print("\n👥 UTILITY AUTHORITY USERS:")
print("-" * 60)
utility_users = UserProfile.objects.filter(role='utility')
for profile in utility_users:
    username = profile.user.username
    ut = profile.utility_type or 'Not specified'
    print(f"  {username}: {ut}")

# Sample some bills and payments
print("\n📋 SAMPLE BILLS (Last 5):")
print("-" * 60)
for bill in UtilityBill.objects.all().order_by('-created_at')[:5]:
    print(f"  Bill ID: {bill.bill_id}")
    print(f"    Type: {bill.utility_type}")
    print(f"    Consumer: {bill.consumer_id}")
    print(f"    Amount: {bill.total_amount}")
    payments = Payment.objects.filter(bill__bill_id=bill.bill_id)
    print(f"    Payments: {payments.count()}")
    print()

# Check for case sensitivity issues
print("⚠️  POTENTIAL ISSUES:")
print("-" * 60)
issues = []

# Check for mixed case in utility_type
types_with_case = UtilityBill.objects.values_list('utility_type', flat=True).distinct()
type_variations = defaultdict(list)
for t in types_with_case:
    type_variations[t.lower()].append(t)

for lower, variations in type_variations.items():
    if len(variations) > 1:
        issues.append(f"Case inconsistency: {variations}")
        print(f"  ⚠️  Multiple case variations for '{lower}': {', '.join(variations)}")

# Check for bills without payments
bills_without_payments = 0
for bill in UtilityBill.objects.all():
    if not Payment.objects.filter(bill__bill_id=bill.bill_id).exists():
        bills_without_payments += 1

if bills_without_payments > 0:
    print(f"  ⚠️  {bills_without_payments} bills have no payments")

# Check for payments without matching utility type filter
print("\n🎯 PAYMENT-BILL LINKAGE CHECK:")
print("-" * 60)
for payment in Payment.objects.filter(status='approved')[:5]:
    bill = payment.bill
    print(f"  Payment #{payment.id}")
    print(f"    Bill ID: {bill.bill_id}")
    print(f"    Utility Type: {bill.utility_type}")
    print(f"    Amount: {payment.amount}")
    print()

if not issues:
    print("  ✅ No obvious issues detected")

print("\n" + "=" * 60)
print("DIAGNOSTIC COMPLETE")
print("=" * 60)
print("\nNext steps:")
print("1. Check if utility_type values match the expected format")
print("2. Verify provider names in utility dashboard match mapping")
print("3. Check browser console for API request/response")
print("4. Add debug logging to payment_reports_page.dart")
