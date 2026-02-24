from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    """Extended user profile for utility bill tracking"""
    ROLE_CHOICES = (
        ('user', 'User'),
        ('utility', 'Utility'),
        ('admin', 'Admin'),
    )
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    full_name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    phone = models.CharField(max_length=20, blank=True)
    house_number = models.CharField(max_length=50, blank=True)
    address = models.TextField(blank=True)
    utility_type = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    # Simple OTP verification fields
    otp_code = models.CharField(max_length=6, blank=True)
    otp_expires_at = models.DateTimeField(null=True, blank=True)
    otp_verified = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.user.username}'s profile ({self.get_role_display()})"
    
    def is_admin(self):
        return self.role == 'admin'
    
    def is_user(self):
        return self.role == 'user'
    
    def is_utility(self):
        return self.role == 'utility' 


class UserUtility(models.Model):
    """Stores utility details submitted from Add Bill form.

    Matches requested MySQL columns while keeping Django-friendly field names.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='utilities', null=True, blank=True)
    # Keep original column names via db_column for exact MySQL mapping where typos were provided
    user_name = models.CharField(max_length=150, blank=True)
    house_number = models.CharField(max_length=50, blank=True)
    utility_type = models.CharField(max_length=50)
    provider_name = models.CharField(max_length=150, blank=True)
    consumer_number = models.CharField(max_length=100, blank=True, db_column='consumr_number')
    water_connection_number = models.CharField(max_length=100, blank=True)
    gas_connection_number = models.CharField(max_length=100, blank=True)
    wifi_consumer_id = models.CharField(max_length=100, blank=True)
    dth_subscriber_id = models.CharField(max_length=100, blank=True)
    meter_number = models.CharField(max_length=100, blank=True)
    connection_type = models.CharField(max_length=50, blank=True)
    plan_name = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True, db_column='creeated_at')

    class Meta:
        db_table = 'user_utility'
        indexes = [
            models.Index(fields=['utility_type']),
            models.Index(fields=['user_name']),
        ]

    def __str__(self):
        base = f"{self.user_name or (self.user.username if self.user else 'unknown')} - {self.utility_type}"
        return base


class GeneratedBill(models.Model):
    """Represents a generated bill across multiple utility types."""
    bill_id = models.CharField(max_length=64, unique=True)
    utility_type = models.CharField(max_length=50)
    provider_name = models.CharField(max_length=150, blank=True)
    consumer_name = models.CharField(max_length=150, blank=True)

    # Identifiers per utility type
    consumer_number = models.CharField(max_length=100, blank=True)
    water_connection_number = models.CharField(max_length=100, blank=True)
    gas_consumer_id = models.CharField(max_length=100, blank=True)
    wifi_consumer_id = models.CharField(max_length=100, blank=True)
    dth_subscriber_id = models.CharField(max_length=100, blank=True)

    # Plan/package names where relevant
    plan_name = models.CharField(max_length=100, blank=True)
    dth_package_name = models.CharField(max_length=100, blank=True)
    specified_utility_type = models.CharField(max_length=100, blank=True)

    # Readings and amounts (nullable for non-metered types)
    previous_reading = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    current_reading = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    units_consumed = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    rate_per_unit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    reading_date = models.DateField()
    due_date = models.DateField()

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'generated_bill'
        indexes = [
            models.Index(fields=['utility_type']),
            models.Index(fields=['bill_id']),
        ]

    def __str__(self):
        return f"{self.bill_id} ({self.utility_type})"


class UtilityBill(models.Model):
    """Minimal bill record for reporting in MySQL table `utility_bill`."""
    utility_type = models.CharField(max_length=50)
    bill_id = models.CharField(max_length=64)
    consumer_name = models.CharField(max_length=150, blank=True)
    consumer_id = models.CharField(max_length=150, blank=True)
    previous_reading = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    current_reading = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    reading_date = models.DateField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'utility_bill'
        indexes = [
            models.Index(fields=['utility_type']),
            models.Index(fields=['bill_id']),
        ]

    def __str__(self):
        return f"{self.bill_id} - {self.utility_type}"


class Payment(models.Model):
    """Represents a payment made against a UtilityBill."""
    METHOD_CHOICES = (
        ('cash', 'Cash'),
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('bank_transfer', 'Bank Transfer'),
        ('online', 'Online Payment'),
        ('other', 'Other'),
    )
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    bill = models.ForeignKey(UtilityBill, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_date = models.DateTimeField(auto_now_add=True)
    payment_method = models.CharField(max_length=20, choices=METHOD_CHOICES, default='online')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    class Meta:
        db_table = 'payment'
        indexes = [
            models.Index(fields=['payment_method']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"Payment for {self.bill.bill_id} - {self.amount}"


class ChatMessage(models.Model):
    """Simple chat message between a user and a utility authority.

    A conversation is identified by (user_name, provider_name).
    The sender is captured by role and optional username for traceability.
    """
    ROLE_CHOICES = (
        ('user', 'User'),
        ('utility', 'Utility'),
        ('system', 'System'),
    )

    user_name = models.CharField(max_length=150)
    provider_name = models.CharField(max_length=150)
    sender_role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    sender_username = models.CharField(max_length=150, blank=True)
    text = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'chat_message'
        indexes = [
            models.Index(fields=['user_name']),
            models.Index(fields=['provider_name']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['created_at']

    def __str__(self):
        return f"{self.provider_name}:{self.user_name} [{self.sender_role}] {self.text[:20]}"


class Wallet(models.Model):
    """Simple wallet tied to a user for refunds/credits.

    Balance is maintained as Decimal for currency precision.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'wallet'

    def __str__(self):
        return f"Wallet({self.user.username}) ₹{self.balance}"


class WalletTransaction(models.Model):
    """Transaction history for wallet operations (credit/debit)."""
    TYPE_CHOICES = (
        ('credit', 'Credit'),
        ('debit', 'Debit'),
    )
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    reason = models.CharField(max_length=255, blank=True)
    payment = models.ForeignKey(Payment, null=True, blank=True, on_delete=models.SET_NULL, related_name='refund_txn')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'wallet_transaction'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.type.title()} ₹{self.amount} ({self.wallet.user.username})"


class PaymentMethod(models.Model):
    """Stores saved payment methods for users."""
    METHOD_CHOICES = (
        ('Credit Card', 'Credit Card'),
        ('Bank Transfer', 'Bank Transfer'),
        ('UPI', 'UPI'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_payment_methods')
    method = models.CharField(max_length=50, choices=METHOD_CHOICES)
    detail = models.CharField(max_length=255)  # Last 4 digits of card, UPI ID, Account number etc.
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'payment_method'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.method} ({self.detail})"


class Notification(models.Model):
    """Stores notifications for users"""
    TYPE_CHOICES = (
        ('bill_added', 'Bill Added'),
        ('bill_generated', 'Bill Generated'),
        ('payment_initiated', 'Payment Initiated'),
        ('payment_pending', 'Payment Pending'),
        ('payment_approved', 'Payment Approved'),
        ('payment_rejected', 'Payment Rejected'),
        ('bill_due', 'Bill Due'),
        ('bill_overdue', 'Bill Overdue'),
        ('reward_earned', 'Reward Earned'),
        ('profile_updated', 'Profile Updated'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    utility_type = models.CharField(max_length=50, blank=True)  # For utility authority filtering
    bill_id = models.CharField(max_length=64, blank=True)  # Reference to generated bill
    due_date = models.DateField(null=True, blank=True)  # For bill due notifications
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'notification'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'read']),
            models.Index(fields=['utility_type']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"


class Review(models.Model):
    """Stores customer reviews for utility providers"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews', null=True, blank=True)
    provider_name = models.CharField(max_length=150)  # e.g., 'kseb', 'water', 'gas'
    utility_type = models.CharField(max_length=50)  # e.g., 'Electricity', 'Water', 'Gas'
    rating = models.IntegerField(choices=[(i, str(i)) for i in range(1, 6)])  # 1-5 stars
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'review'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['provider_name', '-created_at']),
            models.Index(fields=['utility_type', '-created_at']),
            models.Index(fields=['user', '-created_at']),
        ]
    
    def __str__(self):
        user_str = self.user.username if self.user else 'Anonymous'
        return f"{user_str} - {self.utility_type} ({self.rating}★)"

class Complaint(models.Model):
    """User complaints and feedback"""
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    )
    
    username = models.CharField(max_length=150)
    category = models.CharField(max_length=100)
    subject = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    response = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'complaint'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['username']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"{self.username}: {self.subject}"
