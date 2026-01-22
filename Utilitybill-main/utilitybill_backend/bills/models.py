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
    address = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

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