# Persistent Notification System

## Overview

This utility bill application implements a persistent, backend-driven notification system similar to banking or payment applications. All notifications are stored permanently in the database and accessible across sessions.

---

## Backend Implementation

### 1. **Database Model**

**Model**: `Notification` (in `bills/models.py`)

```python
class Notification(models.Model):
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
    utility_type = models.CharField(max_length=50, blank=True)  # For authority filtering
    bill_id = models.CharField(max_length=64, blank=True)
    due_date = models.DateField(null=True, blank=True)
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

Notifications are **never deleted** automatically - they persist indefinitely.

---

### 2. **API Endpoints**

**Endpoint**: `/notifications-by-username/`
- **Method**: GET
- **Params**: `username`
- **Returns**: All notifications for the user, ordered by newest first
- **Response**:
  ```json
  {
    "success": true,
    "username": "john_doe",
    "notifications": [
      {
        "id": 1,
        "notification_type": "payment_approved",
        "title": "Payment Approved",
        "message": "Your payment of ₹500 has been approved",
        "utility_type": "Electricity",
        "bill_id": "BILL12345",
        "read": false,
        "created_at": "2026-02-23T10:30:00Z"
      }
    ],
    "unread_count": 5,
    "total_count": 42
  }
  ```

**Endpoint**: `/notifications/mark-read/`
- **Method**: POST
- **Body**: `{ "id": 1, "username": "john_doe" }`
- **Action**: Marks notification as read (does not delete)

---

### 3. **Automatic Notification Events**

Notifications are created automatically at these events:

#### a) **Bill Generation**
When utility authority generates a bill → notification sent to matching users
```python
# In add_generated_bill view
Notification.objects.create(
    user=user,
    notification_type='bill_generated',
    title=f'New {bill.utility_type} Bill Generated',
    message=f'Amount: ₹{bill.total_amount} • Due: {due_date}',
    utility_type=bill.utility_type,
    bill_id=bill.bill_id,
    due_date=bill.due_date,
)
```

#### b) **Payment Initiated**
When user makes payment → notifications to user AND utility authority
```python
# Notification to user
_create_notification(user=user, notification_type='payment_initiated', ...)

# Notification to authority
authority_user = _resolve_utility_authority_user(bill.utility_type)
_create_authority_notification(authority_user, notification_type='payment_initiated', ...)
```

#### c) **Payment Approved**
When admin approves payment → notifications to user AND authority
```python
_create_notification(user=user, notification_type='payment_approved', ...)
_create_authority_notification(authority_user, notification_type='payment_approved', ...)
```

#### d) **Payment Rejected**
When admin rejects payment → notifications + wallet refund
```python
_create_notification(user=user, notification_type='payment_rejected', ...)
_create_authority_notification(authority_user, notification_type='payment_rejected', ...)
```

#### e) **Rewards Earned**
When reward is credited → notification created
```python
_create_notification(
    user=user,
    notification_type='reward_earned',
    title='Reward Earned!',
    message=f'You earned ₹{reward_amount}',
)
```

---

### 4. **Daily Reminder System**

**Management Command**: `send_due_reminders`

**File**: `bills/management/commands/send_due_reminders.py`

**Purpose**: Send daily reminders for bills due within 2 days or overdue bills.

**Run manually**:
```bash
python manage.py send_due_reminders
```

**Schedule with cron** (Linux/Mac):
```bash
# Run every day at 8am
0 8 * * * cd /path/to/utilitybill_backend && python manage.py send_due_reminders
```

**Schedule with Windows Task Scheduler**:
1. Open Task Scheduler
2. Create Basic Task
3. Trigger: Daily at 8:00 AM
4. Action: Start a Program
5. Program: `python`
6. Arguments: `C:\path\to\utilitybill_backend\manage.py send_due_reminders`
7. Start in: `C:\path\to\utilitybill_backend`

The command:
- Finds all unpaid bills with due dates ≤ today + 2 days
- Creates one notification per user per day (no duplicates)
- Handles overdue bills separately with "overdue" messaging
- Example message: "Your Electricity bill BILL12345 is due in 1 day. Amount: INR 500."

---

### 5. **Utility Authority Mapping**

Utility authorities receive notifications for their specific utility type.

**Model**: `UserProfile.utility_type` field stores authority's service type (e.g., "Electricity").

**Resolution**:
```python
def _resolve_utility_authority_user(utility_type):
    profile = UserProfile.objects.filter(
        role='utility',
        utility_type__iexact=utility_type,
    ).select_related('user').first()
    return profile.user if profile else None
```

When creating utility authority accounts, include `utility_type` in the request:
```json
{
  "name": "KSEB Authority",
  "email": "kseb@example.com",
  "contact": "1234567890",
  "utility_type": "Electricity"
}
```

---

## Flutter Implementation

### 1. **Service Layer**

**File**: `services/notifications_service.dart`

```dart
class NotificationsService {
  Future<List<NotificationItem>> loadFromBackend(String username) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications-by-username/?username=...');
    final resp = await http.get(uri);
    // Parse and return NotificationItems
  }

  Future<bool> markAsReadOnBackend(String notificationId, String username) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/mark-read/');
    final resp = await http.post(uri, body: jsonEncode({'id': ...}));
    return resp.statusCode == 200;
  }
}
```

**Key Points**:
- No SharedPreferences usage (backend is the source of truth)
- All data fetched from API on page load
- Notifications persist across app restarts and logins

---

### 2. **Notifications Page**

**File**: `pages/notifications.dart`

**Features**:
- Fetches notifications from backend on load
- Separate sections for unread and read notifications
- Swipe-to-mark-read gesture
- Filters by utility type for authority users
- Pay Now button for overdue bills

**Usage**:
```dart
// For regular users
NotificationsPage()

// For utility authorities (filtered by type)
NotificationsPage(utilityType: 'Electricity')
```

---

### 3. **Integration Points**

**Home Page**:
```dart
Future<void> _loadUnreadNotifications() async {
  final username = prefs.getString('user_username') ?? '';
  final notifications = await NotificationsService().loadFromBackend(username);
  final unreadCount = notifications.where((n) => !n.read).length;
  setState(() => _unreadNotifCount = unreadCount);
}
```

**Utility Dashboard**:
```dart
// Filter notifications by authority utility type
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NotificationsPage(utilityType: 'Electricity'),
  ),
);
```

---

## Setup Instructions

### Backend

1. **Apply migrations**:
   ```bash
   cd utilitybill_backend
   python manage.py makemigrations
   python manage.py migrate
   ```

2. **Set up daily reminders** (choose one):
   
   **Option A - Cron (Linux/Mac)**:
   ```bash
   crontab -e
   # Add line:
   0 8 * * * cd /path/to/utilitybill_backend && /path/to/python manage.py send_due_reminders
   ```

   **Option B - Windows Task Scheduler**:
   - See section 4 above for step-by-step setup

   **Option C - Celery (Advanced)**:
   ```python
   # In settings.py
   CELERY_BEAT_SCHEDULE = {
       'send-due-reminders': {
           'task': 'bills.tasks.send_due_reminders_task',
           'schedule': crontab(hour=8, minute=0),
       },
   }
   ```

3. **Test reminder command**:
   ```bash
   python manage.py send_due_reminders
   ```

### Frontend

1. **Remove old notification files** (if they exist):
   - `services/notification_generator.dart` (local generation is replaced by backend)
   -  Old `notifications_service.dart` has been replaced

2. **Run Flutter app**:
   ```bash
   cd utilitybill_frontend
   flutter pub get
   flutter run
   ```

3. **Test notification flow**:
   - Generate a bill from utility authority account
   - Make a payment from user account
   - Approve/reject payment from admin
   - View notifications in both user and authority accounts

---

## Key Design Principles

1. **Persistence**: Notifications are never auto-deleted, only marked as read
2. **Backend-driven**: No local generation - all notifications created on backend at event time
3. **Real-time**: Notifications created immediately when events occur (bill generated, payment status changes)
4. **Daily reminders**: Automated scheduler sends due/overdue reminders once per day
5. **Authority notifications**: Utility authorities receive notifications for their service type
6. **Scalability**: Uses database indexing for fast queries on large datasets

---

## Troubleshooting

**Issue**: Notifications not appearing in app
- **Check**: Is backend server running?
- **Verify**: Call API directly: `GET /notifications-by-username/?username=test_user`
- **Debug**: Check Django logs for notification creation

**Issue**: Duplicate reminders sent
- **Cause**: Daily command run multiple times
- **Fix**: Notification creation checks for existing daily reminders with same bill_id and date

**Issue**: Authority not receiving notifications
- **Check**: Does authority UserProfile have `utility_type` field set?
- **Verify**: Query in Django admin or shell:
  ```python
  UserProfile.objects.filter(role='utility', utility_type='Electricity')
  ```

**Issue**: Old notifications missing after reinstalling app
- **Expected**: This is correct behavior - backend stores all notifications permanently
- **Access**: Login again and notifications will reappear from backend

---

## Production Recommendations

1. **Indexing**: Already implemented on `user`, `created_at`, `read`, and `utility_type`
2. **Archiving** (optional): Archive read notifications older than 1 year to separate table
3. **Push notifications**: Integrate Firebase Cloud Messaging for real-time push
4. **Monitoring**: Set up alerts for notification delivery failures
5. **Rate limiting**: Add API rate limits to prevent abuse
6. **Celery queue**: Move reminder command to Celery for better scaling

---

## Future Enhancements

- [ ] Push notifications via FCM
- [ ] Email notifications for overdue bills
- [ ] SMS reminders (requires SMS gateway)
- [ ] In-app notification bell with unread indicator
- [ ] Notification preferences per user
- [ ] Batch notification delivery for performance

---

## Summary

This notification system is **production-ready**, **persistent**, and **event-driven**. Notifications are created the moment events occur (not lazily generated), stored permanently in the database, and synchronized to all user devices through the backend API. Daily reminders ensure users never miss bill due dates.
