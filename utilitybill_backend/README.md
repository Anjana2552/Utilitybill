# Utility Bill Backend

Django REST API backend for utility bill management system.

## Features

- User registration and authentication
- Utility bill management (electricity, water, gas, internet, phone)
- Payment tracking
- Bill status management (pending, paid, overdue)
- Bill and receipt image uploads
- User profiles
- RESTful API endpoints

## Tech Stack

- Django 5.1.7
- Django REST Framework 3.16.0
- Django CORS Headers 4.9.0
- Pillow 11.2.1
- SQLite (default database)

## Setup Instructions

1. **Create a virtual environment** (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run migrations**:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

4. **Create a superuser** (for admin access):
   ```bash
   python manage.py createsuperuser
   ```

5. **Run the development server**:
   ```bash
   python manage.py runserver
   ```

The API will be available at `http://localhost:8000/api/`

## API Endpoints

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/current-user/` - Get current user details

### User Profiles
- `GET /api/profiles/` - List user profiles
- `POST /api/profiles/` - Create profile
- `GET /api/profiles/{id}/` - Retrieve profile
- `PUT /api/profiles/{id}/` - Update profile
- `DELETE /api/profiles/{id}/` - Delete profile

### Utility Bills
- `GET /api/bills/` - List all bills
- `POST /api/bills/` - Create new bill
- `GET /api/bills/{id}/` - Retrieve bill details
- `PUT /api/bills/{id}/` - Update bill
- `DELETE /api/bills/{id}/` - Delete bill
- `POST /api/bills/{id}/mark_paid/` - Mark bill as paid
- `GET /api/bills/summary/` - Get bill statistics

**Query Parameters for bills:**
- `?status=pending|paid|overdue` - Filter by status
- `?bill_type=electricity|water|gas|internet|phone|other` - Filter by type

### Payments
- `GET /api/payments/` - List all payments
- `POST /api/payments/` - Create new payment
- `GET /api/payments/{id}/` - Retrieve payment details
- `PUT /api/payments/{id}/` - Update payment
- `DELETE /api/payments/{id}/` - Delete payment

## Models

### UserProfile
- Extended user profile with phone and address

### UtilityBill
- Bill type (electricity, water, gas, internet, phone, other)
- Provider name and account number
- Amount and billing period
- Due date and status
- Optional bill image

### Payment
- Payment date and amount
- Payment method
- Transaction ID
- Optional receipt image

## Admin Panel

Access the admin panel at `http://localhost:8000/admin/` using the superuser credentials.

## CORS Configuration

CORS is currently configured to allow all origins for development. Update the `CORS_ALLOW_ALL_ORIGINS` setting in `settings.py` for production.

## Media Files

Uploaded bill and receipt images are stored in the `media/` directory.

## Database

The project uses SQLite by default. For production, consider using PostgreSQL or MySQL.
