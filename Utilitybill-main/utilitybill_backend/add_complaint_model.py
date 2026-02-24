#!/usr/bin/env python
"""
Script to add Complaint model to bills/models.py if not already present.
"""

model_code = '''

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
'''

# Read the current models file
models_file = 'bills/models.py'
with open(models_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if Complaint model already exists
if 'class Complaint' not in content:
    # Append to the end
    with open(models_file, 'a', encoding='utf-8') as f:
        f.write(model_code)
    print("✓ Complaint model added to bills/models.py")
else:
    print("Complaint model already exists in bills/models.py")
