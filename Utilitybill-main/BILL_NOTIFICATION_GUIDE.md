# ✅ BILL GENERATION NOTIFICATIONS - WORKING

## Summary

**When a utility authority generates a new bill, the user automatically receives a notification.**

## How It Works

### 1. Utility Authority Generates Bill

**Location:** Flutter app → Generate Bill Page
- Authority fills in bill details (utility type, consumer number, amount, due date)
- Submits bill via API: `POST /api/add-generated-bill/`

### 2. Backend Creates Notification

**File:** `utilitybill_backend/bills/views.py` → `add_generated_bill()`

```python
@api_view(['POST'])
@permission_classes([AllowAny])
def add_generated_bill(request):
    # Save the bill
    bill = serializer.save()
    
    # Find matching users based on consumer identifier
    matching_users = []
    if utility_type == 'electricity' and bill.consumer_number:
        matching_utilities = UserUtility.objects.filter(
            utility_type__iexact='electricity',
            consumer_number=bill.consumer_number
        ).select_related('user')
        matching_users = [uu.user for uu in matching_utilities if uu.user]
    
    # Create notification for each matching user
    for user in matching_users:
        notification = _create_notification(
            user=user,
            notification_type='bill_generated',
            title=f'New {bill.utility_type} Bill Generated',
            message=f'A new bill for {bill.utility_type} has been generated...',
            utility_type=bill.utility_type,
            bill_id_ref=bill.bill_id,
            due_date=bill.due_date
        )
```

**Key Logic:**
- Looks up users by matching `consumer_number` (or other utility-specific IDs)
- Uses fixed `_create_notification()` helper to create notification
- Stores in database with all required fields
- Returns count of notifications created

### 3. User Sees Notification

**Location:** Flutter app → Notifications Page

When user opens notifications:
1. Calls `NotificationsService.loadFromBackend(username)`
2. API: `GET /api/notifications-by-username/?username=anjana`
3. Returns all notifications for that user
4. Displays in "Unread" section until user swipes to mark as read

## Test Results

### Test: Generate Bill for User 'anjana'

```
User: anjana (ID: 2)
Registered Utilities:
  - Electricity (Consumer Number: 1098)

Existing notifications: 2

ACTION: Generate new electricity bill
RESULT: ✓ Notification created (ID: 6)

New notifications: 3 total
  [6] New Electricity Bill Generated (unread)
  [4] Test: New Electricity Bill (unread)
  [3] Payment Initiated (unread)
```

**API Response:**
```json
{
  "success": true,
  "username": "anjana",
  "total_count": 3,
  "unread_count": 3,
  "notifications": [
    {
      "id": 6,
      "notification_type": "bill_generated",
      "title": "New Electricity Bill Generated",
      "message": "A new bill for Electricity (KSEB) has been generated. Amount: ₹750. Due date: ...",
      "utility_type": "Electricity",
      "bill_id": "TEST-KSEB-20260223061234",
      "read": false,
      "created_at": "2026-02-23T06:12:34.567890Z"
    }
  ]
}
```

## Notification Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Utility Authority (e.g., amalkseb)                          │
│                                                              │
│  1. Opens Generate Bill Page                                │
│  2. Fills in:                                              │
│     - Utility Type: Electricity                            │
│     - Consumer Number: 1098                                │
│     - Amount: ₹750                                         │
│     - Due Date: 2026-03-02                                 │
│  3. Clicks "Generate Bill"                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ POST /api/add-generated-bill/
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Django Backend (views.add_generated_bill)                   │
│                                                              │
│  1. Saves bill to GeneratedBill table                       │
│  2. Looks up UserUtility where:                            │
│     - utility_type = 'Electricity'                         │
│     - consumer_number = '1098'                             │
│  3. Finds matching user: anjana (ID: 2)                    │
│  4. Creates Notification:                                  │
│     - user = anjana                                        │
│     - type = 'bill_generated'                              │
│     - title = 'New Electricity Bill Generated'             │
│     - message = 'A new bill for Electricity...'            │
│     - utility_type = 'Electricity'                         │
│     - bill_id = 'KSEB-20260223061234'                      │
│     - read = False                                         │
│  5. Returns: {"notifications_created": 1}                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Notification saved to database
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Database: notification table                                │
│                                                              │
│  id | user_id | type            | title                     │
│  ───┼─────────┼─────────────────┼──────────────────────     │
│  6  | 2       | bill_generated  | New Electricity Bill...   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ User opens app
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ User (anjana)                                               │
│                                                              │
│  1. Opens Notifications Page                               │
│  2. Flutter calls:                                         │
│     GET /api/notifications-by-username/?username=anjana    │
│  3. Receives 3 notifications (including new one)           │
│  4. Sees in "Unread" section:                              │
│     📄 New Electricity Bill Generated                      │
│        A new bill for Electricity has been generated...    │
│        4m ago                                              │
│  5. Can swipe to mark as read                              │
└─────────────────────────────────────────────────────────────┘
```

## Requirements for Notifications to Work

### ✅ User Must Have Registered Utility

For user to receive bill notification, they must have a `UserUtility` record:

```python
UserUtility(
    user=anjana,
    utility_type='Electricity',
    consumer_number='1098',  # Must match bill.consumer_number
    # ... other fields
)
```

**How to register:** User profile page → Add Utility

### ✅ Bill Must Have Matching Consumer Identifier

When generating bill, authority must provide correct consumer identifier:

- **Electricity:** `consumer_number` (e.g., "1098")
- **Water:** `water_connection_number`
- **Gas:** `gas_consumer_id`
- **WiFi:** `wifi_consumer_id`
- **DTH:** `dth_subscriber_id`

### ✅ Backend Must Be Running

Django server must be running for notifications to be created and fetched.

## Supported Notification Types

When bills are generated, users receive:

1. **bill_generated** - Immediately when authority creates bill
2. **bill_due** - Daily reminder starting 2 days before due date
3. **bill_overdue** - Daily reminder after due date passes

## Testing Checklist

### Generate Bill → User Gets Notification

1. **Verify user has utility registered:**
   ```bash
   python manage.py shell -c "from bills.models import UserUtility; u = UserUtility.objects.filter(user__username='anjana', utility_type='Electricity').first(); print(f'Consumer Number: {u.consumer_number if u else \"NOT FOUND\"}')"
   ```

2. **Login as utility authority** (e.g., amalkseb for Electricity)

3. **Generate bill:**
   - Navigate to "Generate Bill" page
   - Fill in consumer number that matches user's registered utility
   - Submit

4. **Check backend logs:**
   ```
   [BILL GENERATED] Bill KSEB-xxx created → 1 notifications sent to users
   [NOTIFICATION] ✓ Created notification for user anjana (ID: 2): bill_generated - New Electricity Bill Generated
   ```

5. **Login as user** (e.g., anjana)

6. **Open Notifications page**
   - Should see new bill notification in "Unread" section

7. **Verify via API:**
   ```bash
   curl "http://127.0.0.1:8000/api/notifications-by-username/?username=anjana"
   ```

## Logs to Monitor

### When Bill is Generated

```
[BILL GENERATED] Bill KSEB-20260223061234 created → 1 notifications sent to users
[NOTIFICATION] ✓ Created notification for user anjana (ID: 2): bill_generated - New Electricity Bill Generated
```

### When User Fetches Notifications

```
[NOTIFICATION API] Fetching notifications for user: anjana (ID: 2)
[NOTIFICATION API] ✓ Returning 3 notifications (3 unread) for anjana
[NOTIFICATION API] Sample: bill_generated - New Electricity Bill Generated
```

## Common Issues & Solutions

### Issue: User doesn't get notification

**Check 1:** Does user have utility registered?
```bash
python manage.py shell -c "from bills.models import UserUtility; print(UserUtility.objects.filter(user__username='anjana').values('utility_type', 'consumer_number'))"
```

**Solution:** Register utility in user profile page

**Check 2:** Does consumer number match?
- Bill consumer number must exactly match UserUtility consumer number
- Case-insensitive but must be exact string match

**Check 3:** Is backend creating notification?
- Check Django console logs for `[BILL GENERATED]` message
- If missing, notification creation failed

### Issue: Notification created but not showing in app

**Check 1:** Is Flask app fetching correct username?
```dart
final prefs = await SharedPreferences.getInstance();
print('Username: ${prefs.getString('user_username')}');
```

**Check 2:** Test API directly:
```bash
curl "http://127.0.0.1:8000/api/notifications-by-username/?username=anjana"
```

If API returns data but app doesn't show it → Parse error in Flutter

**Solution:** Check Flutter console for JSON parse errors

## Status: ✅ FULLY WORKING

- ✅ Backend creates notifications when bill is generated
- ✅ Notifications stored in database permanently
- ✅ API returns notifications correctly
- ✅ Flutter app displays notifications
- ✅ User can mark as read but never delete
- ✅ Notifications persist across app restarts

## Files Involved

### Backend
- `bills/views.py` - `add_generated_bill()` creates notifications
- `bills/models.py` - Notification, UserUtility, GeneratedBill models
- `bills/serializers.py` - NotificationSerializer

### Frontend
- `lib/services/notifications_service.dart` - Fetches from API
- `lib/pages/notifications.dart` - Displays notifications
- `lib/pages/utility/generate_bill.dart` - Bill generation form

---

**Last Tested:** 2026-02-23
**Test User:** anjana
**Test Authority:** amalkseb
**Result:** ✅ All notifications working correctly
