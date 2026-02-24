import os
import django
from datetime import datetime

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import UtilityBill, UserUtility, Payment

def verify_health_score_data(username):
    """Verify the health score calculations for a specific user"""
    
    print(f"\n{'='*60}")
    print(f"Health Score Data Verification for: {username}")
    print(f"{'='*60}")
    
    # Get user utilities
    user_utilities = UserUtility.objects.filter(user_name=username)
    
    if not user_utilities.exists():
        print(f"No utilities found for user: {username}")
        return
    
    print(f"\nFound {user_utilities.count()} utilities for user")
    
    # Collect all consumer IDs
    consumer_ids = []
    for utility in user_utilities:
        utility_type = utility.utility_type.lower() if utility.utility_type else ''
        consumer_id = None
        
        if utility_type == 'electricity':
            consumer_id = utility.consumer_number
        elif utility_type == 'water':
            consumer_id = utility.water_connection_number
        elif utility_type == 'gas':
            consumer_id = utility.gas_connection_number
        elif utility_type in ['wifi', 'internet']:
            consumer_id = utility.wifi_consumer_id
        elif utility_type == 'dth':
            consumer_id = utility.dth_subscriber_id
        
        if consumer_id:
            consumer_ids.append((consumer_id, utility_type))
            print(f"  - {utility_type.title()}: {consumer_id}")
    
    # Initialize counts
    total_bills = 0
    paid_bills = 0
    pending_bills = 0
    overdue_bills = 0
    total_paid_amount = 0.0
    total_pending_amount = 0.0
    
    early_payments = 0
    on_time_payments = 0
    late_payments = 0
    
    print(f"\n{'='*60}")
    print("Bill Analysis:")
    print(f"{'='*60}\n")
    
    now = datetime.now()
    
    # Process bills for each consumer
    for consumer_id, utility_type in consumer_ids:
        bills = UtilityBill.objects.filter(consumer_id=consumer_id)
        
        if bills.exists():
            print(f"\n{utility_type.title()} - Consumer ID: {consumer_id}")
            print(f"  Total bills: {bills.count()}")
            
            for bill in bills:
                total_bills += 1
                amount = float(bill.total_amount) if bill.total_amount else 0.0
                
                # Check if bill is paid (has approved payment)
                has_payment = Payment.objects.filter(
                    bill=bill,  # Use the bill object, not bill_id string
                    status='Approved'
                ).exists()
                
                status = 'paid' if has_payment else 'unpaid'
                
                print(f"\n  Bill ID: {bill.bill_id}")
                print(f"    Status: {status}")
                print(f"    Amount: ₹{amount:.2f}")
                print(f"    Due Date: {bill.due_date}")
                
                if status == 'paid':
                    paid_bills += 1
                    total_paid_amount += amount
                    
                    # Check payment timing
                    payment = Payment.objects.filter(
                        bill=bill,  # Use the bill object
                        status='Approved'
                    ).first()
                    
                    if payment and bill.due_date:
                        payment_date = payment.payment_date.date() if hasattr(payment.payment_date, 'date') else payment.payment_date
                        due_date = bill.due_date
                        
                        # Compare dates
                        days_diff = (due_date - payment_date).days
                        
                        print(f"    Payment Date: {payment_date}")
                        print(f"    Days before due: {days_diff}")
                        
                        if days_diff > 5:
                            early_payments += 1
                            print(f"    ✓ EARLY PAYMENT (+3 points)")
                        elif days_diff >= 0:
                            on_time_payments += 1
                            print(f"    ✓ ON-TIME PAYMENT (+2 points)")
                        else:
                            late_payments += 1
                            print(f"    ✗ LATE PAYMENT (-5 points)")
                else:
                    # Unpaid bill
                    total_pending_amount += amount
                    
                    # Check if overdue
                    if bill.due_date:
                        due_date_end = datetime.combine(bill.due_date, datetime.max.time())
                        
                        if now > due_date_end:
                            overdue_bills += 1
                            print(f"    ✗ OVERDUE (due date passed)")
                        else:
                            pending_bills += 1
                            print(f"    ○ PENDING (not yet due)")
                    else:
                        pending_bills += 1
                        print(f"    ○ PENDING (no due date)")
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY:")
    print(f"{'='*60}")
    print(f"\nBill Counts:")
    print(f"  Total Bills:   {total_bills}")
    print(f"  Paid Bills:    {paid_bills}")
    print(f"  Pending Bills: {pending_bills}")
    print(f"  Overdue Bills: {overdue_bills}")
    print(f"\nVerification: {paid_bills} + {pending_bills} + {overdue_bills} = {paid_bills + pending_bills + overdue_bills}")
    
    if paid_bills + pending_bills + overdue_bills == total_bills:
        print(f"  ✓ VERIFIED: Counts match total ({total_bills})")
    else:
        print(f"  ✗ ERROR: Counts don't match total ({total_bills})")
    
    print(f"\nPayment Timing:")
    print(f"  Early Payments:   {early_payments} (>5 days before due)")
    print(f"  On-Time Payments: {on_time_payments} (0-5 days before/on due)")
    print(f"  Late Payments:    {late_payments} (after due date)")
    
    print(f"\nAmount Summary:")
    print(f"  Total Paid:    ₹{total_paid_amount:.2f}")
    print(f"  Total Pending: ₹{total_pending_amount:.2f}")
    
    # Calculate health score (simplified version)
    print(f"\n{'='*60}")
    print("Health Score Calculation:")
    print(f"{'='*60}")
    
    score = 100
    print(f"\nBase Score: {score}")
    
    # Rewards
    early_points = early_payments * 3
    on_time_points = on_time_payments * 2
    print(f"\n+ Early payment rewards:   +{early_points} ({early_payments} × 3)")
    print(f"+ On-time payment rewards: +{on_time_points} ({on_time_payments} × 2)")
    score += early_points + on_time_points
    
    if paid_bills > 0:
        on_time_ratio = (early_payments + on_time_payments) / paid_bills
        consistency_bonus = 0
        if on_time_ratio >= 0.9:
            consistency_bonus = 15
        elif on_time_ratio >= 0.7:
            consistency_bonus = 10
        elif on_time_ratio >= 0.5:
            consistency_bonus = 5
        
        if consistency_bonus > 0:
            print(f"+ Consistency bonus:       +{consistency_bonus} ({on_time_ratio*100:.0f}% on-time rate)")
            score += consistency_bonus
    
    # Penalties
    late_penalty = late_payments * 5
    if late_penalty > 0:
        print(f"\n- Late payment penalty:    -{late_penalty} ({late_payments} × 5)")
        score -= late_penalty
    
    if total_bills > 0:
        pending_penalty = int((pending_bills / total_bills) * 20)
        overdue_penalty = int((overdue_bills / total_bills) * 35)
        
        if pending_penalty > 0:
            print(f"- Pending bills penalty:   -{pending_penalty} ({pending_bills}/{total_bills} ratio)")
            score -= pending_penalty
        
        if overdue_penalty > 0:
            print(f"- Overdue bills penalty:   -{overdue_penalty} ({overdue_bills}/{total_bills} ratio)")
            score -= overdue_penalty
    
    if overdue_bills > 0:
        extra_overdue = overdue_bills * 3
        print(f"- Extra overdue penalty:   -{extra_overdue} ({overdue_bills} × 3)")
        score -= extra_overdue
    
    # Clamp score
    score = max(0, min(150, score))
    
    print(f"\n{'='*60}")
    print(f"FINAL HEALTH SCORE: {score}")
    print(f"{'='*60}")
    
    # Rating
    if score >= 120:
        rating = "Outstanding"
    elif score >= 100:
        rating = "Excellent"
    elif score >= 80:
        rating = "Very Good"
    elif score >= 60:
        rating = "Good"
    elif score >= 40:
        rating = "Fair"
    elif score >= 20:
        rating = "Poor"
    else:
        rating = "Critical"
    
    print(f"Rating: {rating}\n")


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("\nUsage: python verify_health_score.py <username>")
        print("\nExample: python verify_health_score.py anjana")
        sys.exit(1)
    
    username = sys.argv[1]
    verify_health_score_data(username)
