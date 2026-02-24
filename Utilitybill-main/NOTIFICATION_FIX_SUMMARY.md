# Notification System - Fix Summary

## Problems Identified

### 1. **Broken Helper Functions**
- `_create_notification()` was incomplete - just returned `None` without creating notifications
- `_create_authority_notification()` had unreachable code after a return statement
- This caused all event-driven notifications to fail silently

### 2. **Missing Utility Type Data**
- Utility authority `UserProfile` records had empty `utility_type` fields
- This prevented `_resolve_utility_authority_user()` from finding authorities
- Authorities never received notifications for their utility type

### 3. **Insufficient Debugging**
- No logging to track notification creation success/failure
- Hard to diagnose why notifications weren't appearing

## Solutions Implemented

### 1. Fixed Django Backend Functions

**File:** `utilitybill_backend/bills/views.py`

#### `_create_notification()` - Fixed
```python
def _create_notification(user, notification_type, title, message, utility_type=None, bill_id_ref=None, due_date=None):
    """Helper function to create a notification for a user"""
    if user is None:
        print(f"[NOTIFICATION] Cannot create notification - user is None")
        return None
    
    try:
        notification = Notification.objects.create(
            user=user,
            notification_type=notification_type,
            title=title,
            message=message,
            utility_type=utility_type or '',
            bill_id=bill_id_ref or '',
            due_date=due_date,
            read=False
        )
        print(f"[NOTIFICATION] ✓ Created notification for user {user.username} (ID: {user.id}): {notification_type} - {title}")
        return notification
    except Exception as e:
        print(f"[NOTIFICATION ERROR] Failed to create notification for user {user.username}: {e}")
        return None
```

#### `_resolve_utility_authority_user()` - Enhanced with logging
```python
def _resolve_utility_authority_user(utility_type):
    """Resolve a utility authority account for a given utility type."""
    if not utility_type:
        print(f"[NOTIFICATION] Cannot resolve authority - utility_type is empty")
        return None
    
    profile = UserProfile.objects.filter(
        role='utility',
        utility_type__iexact=str(utility_type).strip(),
    ).select_related('user').first()
    
    if profile and profile.user:
        print(f"[NOTIFICATION] ✓ Resolved utility authority: {profile.user.username} for {utility_type}")
        return profile.user
    else:
        print(f"[NOTIFICATION] ✗ No utility authority found for {utility_type}")
        return None
```

#### `_create_authority_notification()` - Fixed unreachable code
```python
def _create_authority_notification(user, notification_type, title, message, utility_type=None, bill_id_ref=None):
    """Create notification for utility authority"""
    if user is None:
        print(f"[NOTIFICATION] Cannot create authority notification - user is None")
        return None
    
    return _create_notification(
        user=user,
        notification_type=notification_type,
        title=title,
        message=message,
        utility_type=utility_type,
        bill_id_ref=bill_id_ref,
        due_date=None
    )
```

### 2. Enhanced API Endpoint

**File:** `utilitybill_backend/bills/views.py`

#### `list_notifications_by_username()` - Enhanced
- Added support for `utility_type` query parameter for authority filtering
- Added comprehensive debugging logs
- Returns notification count and sample notification type

```python
def list_notifications_by_username(request):
    """List all notifications for a user by username
    
    Query params:
    - username: Required. The username to fetch notifications for
    - utility_type: Optional. If provided, filter by utility_type (for authority notifications)
    """
    username = (request.GET.get('username') or '').strip()
    utility_type_filter = (request.GET.get('utility_type') or '').strip()
    
    # ... validation ...
    
    notifications = Notification.objects.filter(user=user)
    
    # Filter by utility_type if provided
    if utility_type_filter:
        notifications = notifications.filter(utility_type__iexact=utility_type_filter)
    
    notifications = notifications.order_by('-created_at')
    
    # ... serialization and response ...
```

### 3. Fixed Utility Authority Profiles

**Script:** `fix_utility_types.py`

- Populated `utility_type` field for all existing utility authorities based on their username
- Mapping:
  - `amalkseb` → Electricity
  - `appukwa` → Water
  - `shivagas` → Gas
  - `manuwifi` → WiFi
  - `dasdth` → DTH
  - `samothers` → Others

## API Endpoint Details

### Fetch Notifications

**Endpoint:** `GET /api/notifications-by-username/`

**Query Parameters:**
- `username` (required): Username to fetch notifications for
- `utility_type` (optional): Filter by utility type (for authorities)

**Example Requests:**

```bash
# For regular user
GET /api/notifications-by-username/?username=anjana

# For utility authority (all notifications)
GET /api/notifications-by-username/?username=amalkseb

# For utility authority (filtered by utility type)
GET /api/notifications-by-username/?username=amalkseb&utility_type=Electricity
```

**Response Format:**
```json
{
  "success": true,
  "username": "anjana",
  "total_count": 2,
  "unread_count": 1,
  "filtered_by_utility_type": null,
  "notifications": [
    {
      "id": 4,
      "notification_type": "bill_generated",
      "title": "New Electricity Bill",
      "message": "A new bill has been generated...",
      "utility_type": "Electricity",
      "bill_id": "KSEB-001",
      "due_date": "2026-03-01",
      "read": false,
      "created_at": "2026-02-23T10:30:00Z"
    }
  ]
}
```

### Mark Notification as Read

**Endpoint:** `POST /api/notifications/mark-read/`

**Request Body:**
```json
{
  "id": 4,
  "username": "anjana"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

## Flutter Integration

### NotificationsService

**File:** `lib/services/notifications_service.dart`

The existing service is correct and should work with the fixed backend:

```dart
Future<List<NotificationItem>> loadFromBackend(String username) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/notifications-by-username/?username=${Uri.encodeQueryComponent(username)}',
  );
  final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
  
  // ... parsing ...
}
```

### NotificationsPage

**File:** `lib/pages/notifications.dart`

Current implementation filters by `utilityType` on the client side. **This is correct** - the API now supports server-side filtering via query parameter, but client-side filtering works too.

## Testing Results

### Test 1: User Notifications
```
Username: anjana
Total: 2 notifications
Unread: 2
✓ All notifications visible in API response
```

### Test 2: Utility Authority Notifications  
```
Username: amalkseb (Electricity authority)
Total: 1 notification
Unread: 1
✓ Authority notifications working
```

### Test 3: Filtered Authority Notifications
```
Username: amalkseb
Filter: utility_type=Electricity
Total: 1 notification
✓ Filtering works correctly
```

## Notification Flow

### For Users:
1. Bill generated → `Notification.objects.create()` called directly
2. Payment initiated → `_create_notification()` called
3. Payment approved/rejected → `_create_notification()` called
4. Rewards earned → `Notification.objects.create()` called
5. Daily reminders → Management command creates directly

### For Utility Authorities:
1. Payment initiated → `_create_authority_notification()` called
2. Payment approved/rejected → `_create_authority_notification()` called
3. Authority user resolved via `_resolve_utility_authority_user(utility_type)`

## Debugging Checklist

If notifications still don't appear in Flutter:

1. **Check user exists:**
   ```bash
   python manage.py shell -c "from django.contrib.auth.models import User; print(User.objects.filter(username='username').exists())"
   ```

2. **Check notifications in database:**
   ```bash
   python manage.py shell -c "from bills.models import Notification; print(Notification.objects.filter(user__username='username').count())"
   ```

3. **Test API directly:**
   ```bash
   curl "http://127.0.0.1:8000/api/notifications-by-username/?username=anjana"
   ```

4. **Check Flutter logs:**
   - Look for API call logs
   - Check for JSON parsing errors
   - Verify `user_username` in SharedPreferences matches database username

5. **Check utility authority profile:**
   ```bash
   python manage.py shell -c "from bills.models import UserProfile; p = UserProfile.objects.get(user__username='amalkseb'); print(f'Role: {p.role}, Utility Type: {p.utility_type}')"
   ```

## Key Files Modified

1. `utilitybill_backend/bills/views.py` - Fixed notification creation functions
2. `utilitybill_backend/bills/models.py` - No changes (model was correct)
3. `utilitybill_backend/bills/serializers.py` - No changes (serializer was correct)
4. `utilitybill_frontend/lib/services/notifications_service.dart` - No changes needed
5. `utilitybill_frontend/lib/pages/notifications.dart` - No changes needed

## Status: ✅ FIXED

- Backend notification creation: **WORKING**
- API endpoint: **WORKING**
- User notifications: **WORKING**
- Authority notifications: **WORKING**
- Filtering by utility_type: **WORKING**
- Flutter integration: **SHOULD WORK** (verify with app restart)

## Next Steps

1. **Restart Flutter app** to clear any cached data
2. **Login as user** (e.g., 'anjana') → Check notifications page
3. **Login as authority** (e.g., 'amalkseb') → Check notifications page
4. **Test real flow:**
   - Generate bill → User should get notification
   - Initiate payment → User + Authority should get notifications
   - Approve payment → User + Authority should get notifications
