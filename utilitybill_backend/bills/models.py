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