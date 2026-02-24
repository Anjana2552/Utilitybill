from django.core.management.base import BaseCommand
from django.utils import timezone

from bills.models import GeneratedBill, Notification, Payment, UserUtility


class Command(BaseCommand):
    help = "Send due and overdue bill reminders"

    def handle(self, *args, **options):
        today = timezone.localdate()
        cutoff = today + timezone.timedelta(days=2)
        created = 0

        bills = GeneratedBill.objects.filter(due_date__isnull=False, due_date__lte=cutoff)
        for bill in bills:
            if Payment.objects.filter(bill__bill_id=bill.bill_id, status__iexact='approved').exists():
                continue

            users = _users_for_generated_bill(bill)
            if not users:
                continue

            for user in users:
                notif_type, title, message = _build_due_message(bill, today)
                already = Notification.objects.filter(
                    user=user,
                    bill_id=bill.bill_id,
                    notification_type=notif_type,
                    created_at__date=today,
                ).exists()
                if already:
                    continue

                Notification.objects.create(
                    user=user,
                    notification_type=notif_type,
                    title=title,
                    message=message,
                    utility_type=bill.utility_type,
                    bill_id=bill.bill_id,
                    due_date=bill.due_date,
                    read=False,
                )
                created += 1

        self.stdout.write(self.style.SUCCESS(f"Created {created} reminder notifications"))


def _users_for_generated_bill(bill):
    util_type = (bill.utility_type or '').strip().lower()
    if util_type == 'electricity' and bill.consumer_number:
        qs = UserUtility.objects.filter(
            utility_type__iexact='electricity',
            consumer_number=bill.consumer_number,
            user__isnull=False,
        ).select_related('user')
    elif util_type == 'water' and bill.water_connection_number:
        qs = UserUtility.objects.filter(
            utility_type__iexact='water',
            water_connection_number=bill.water_connection_number,
            user__isnull=False,
        ).select_related('user')
    elif util_type == 'gas' and bill.gas_consumer_id:
        qs = UserUtility.objects.filter(
            utility_type__iexact='gas',
            gas_connection_number=bill.gas_consumer_id,
            user__isnull=False,
        ).select_related('user')
    elif util_type == 'wifi' and bill.wifi_consumer_id:
        qs = UserUtility.objects.filter(
            utility_type__iexact='wifi',
            wifi_consumer_id=bill.wifi_consumer_id,
            user__isnull=False,
        ).select_related('user')
    elif util_type == 'dth' and bill.dth_subscriber_id:
        qs = UserUtility.objects.filter(
            utility_type__iexact='dth',
            dth_subscriber_id=bill.dth_subscriber_id,
            user__isnull=False,
        ).select_related('user')
    else:
        return []

    return [u.user for u in qs if u.user is not None]


def _build_due_message(bill, today):
    amount = bill.total_amount or 0
    if bill.due_date and bill.due_date < today:
        days_overdue = (today - bill.due_date).days
        title = f"Bill overdue ({days_overdue} day{'s' if days_overdue != 1 else ''})"
        message = (
            f"Your {bill.utility_type} bill {bill.bill_id} is overdue by "
            f"{days_overdue} day{'s' if days_overdue != 1 else ''}. "
            f"Amount: INR {amount}. Please pay as soon as possible."
        )
        return 'bill_overdue', title, message

    if bill.due_date and bill.due_date == today:
        title = "Bill due today"
        message = (
            f"Your {bill.utility_type} bill {bill.bill_id} is due today. "
            f"Amount: INR {amount}."
        )
        return 'bill_due', title, message

    days_left = (bill.due_date - today).days if bill.due_date else 0
    title = f"Bill due in {days_left} day{'s' if days_left != 1 else ''}"
    message = (
        f"Your {bill.utility_type} bill {bill.bill_id} is due in "
        f"{days_left} day{'s' if days_left != 1 else ''}. "
        f"Amount: INR {amount}."
    )
    return 'bill_due', title, message
