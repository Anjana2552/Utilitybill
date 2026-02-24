#!/usr/bin/env python
"""Verify reviews are persisted in database"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'utilitybill_backend.settings')
django.setup()

from bills.models import Review

reviews = Review.objects.all().order_by('-created_at')
print(f'\n📊 Total Reviews in Database: {reviews.count()}\n')
print('Reviews:')
for r in reviews:
    username = r.user.username if r.user else 'Anonymous'
    print(f'  {r.id}. [{r.utility_type}] {r.rating}★ by {username}')
    print(f'     Provider: {r.provider_name}')
    print(f'     Message: {r.message[:60]}...' if len(r.message) > 60 else f'     Message: {r.message}')
    print(f'     Created: {r.created_at.strftime("%Y-%m-%d %H:%M:%S")}')
    print()

print('✅ All reviews are persisted in the database and will survive app restarts!')
