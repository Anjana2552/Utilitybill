# Wallet Add Funds Feature Documentation

## Overview
This document describes the implementation of the "Add Funds" functionality for the wallet system, allowing users to top up their wallet balance using various payment methods.

## Implementation Date
December 2024

---

## Features Implemented

### 1. Payment Method Selection
Users can choose from multiple payment methods:
- **UPI** (Default)
- **Credit/Debit Card**
- **Net Banking**
- **Wallet**

### 2. Amount Input
- Numeric input field with currency prefix (₹)
- Validation for positive amounts
- Decimal support for precise amounts

### 3. Real-time Balance Update
- Wallet balance updates immediately after successful payment
- Transaction history refreshes automatically
- New transaction appears at the top of the list

### 4. Cashback Rewards
- Automatic 10% cashback on all wallet top-ups
- Maximum cashback capped at ₹100 per transaction
- Cashback notification displayed to user

### 5. Transaction Recording
- All wallet top-ups are recorded as "credit" transactions
- Transaction details include:
  - Amount added
  - Payment method used
  - Timestamp
  - Transaction reason

---

## Technical Implementation

### Backend Changes

#### 1. New API Endpoint: `/wallet/add-funds/`
**File:** `utilitybill_backend/bills/views.py`

**Method:** POST

**Request Body:**
```json
{
  "username": "user123",
  "amount": "1000.00",
  "payment_method": "UPI"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "₹1000.00 added successfully",
  "new_balance": "1500.00",
  "cashback": "100.00",
  "transaction": {
    "id": 42,
    "amount": "1000.00",
    "type": "credit",
    "reason": "Added funds via UPI",
    "created_at": "2024-12-15T10:30:00Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "error": "Amount must be positive"
}
```

**Validations:**
- Username is required and must exist
- Amount must be a positive decimal number
- Payment method must be one of the valid options

**Database Operations:**
1. Fetches or creates user's wallet
2. Increments wallet balance by the specified amount
3. Creates a WalletTransaction record (type: 'credit')
4. Creates a Notification for the user (type: 'reward')

#### 2. Route Registration
**File:** `utilitybill_backend/bills/urls.py`

```python
path('wallet/add-funds/', views.wallet_add_funds, name='wallet-add-funds'),
```

#### 3. Import Updates
**File:** `utilitybill_backend/bills/views.py`

Added `InvalidOperation` to decimal imports for amount validation:
```python
from decimal import Decimal, InvalidOperation
```

---

### Frontend Changes

#### 1. Add Funds Dialog
**File:** `utilitybill_frontend/lib/pages/users/wallet_page.dart`

**Method:** `_showAddFundsDialog()`

**Features:**
- Material Design AlertDialog
- Amount input field with numeric keyboard
- Payment method dropdown with 4 options
- Input validation with error messages
- Cancel and submit actions

**UI Components:**
```dart
- TextField: Amount input with ₹ prefix
- DropdownButtonFormField: Payment method selector
- TextButton: Cancel action
- FilledButton: Submit action
```

#### 2. API Integration
**Method:** `_addFunds(String amount, String paymentMethod)`

**Flow:**
1. Shows loading indicator (CircularProgressIndicator)
2. Retrieves username from SharedPreferences
3. Makes POST request to `/wallet/add-funds/`
4. Closes loading indicator
5. On success:
   - Displays success SnackBar with cashback info
   - Reloads wallet data (_loadWallet())
6. On error:
   - Displays error SnackBar with error message

#### 3. Button Update
Changed "Add Funds" button from empty handler to dialog trigger:
```dart
FilledButton(onPressed: _showAddFundsDialog, child: const Text('Add Funds'))
```

---

## User Flow

### Step-by-Step Process

1. **Navigate to Wallet Page**
   - User taps on "Wallet" from navigation menu

2. **Initiate Top-up**
   - User taps "Add Funds" button on wallet card

3. **Enter Details**
   - Dialog appears with amount field and payment dropdown
   - User enters amount (e.g., "1000")
   - User selects payment method (default: UPI)

4. **Submit**
   - User taps "Add Funds" button in dialog
   - Loading indicator appears

5. **Validation**
   - Frontend validates amount is positive and numeric
   - Backend validates username, amount, and payment method

6. **Processing**
   - Wallet balance is incremented
   - Transaction is recorded in database
   - Reward notification is created
   - Cashback is calculated (10%, max ₹100)

7. **Confirmation**
   - Success message displays with cashback amount
   - Wallet balance updates on screen
   - New transaction appears in history
   - Notification badge increments

---

## Payment Methods Details

### UPI
- Unified Payments Interface
- Instant payment processing
- Default selection for quick top-ups

### Credit/Debit Card
- Supports all major card networks
- Secure payment processing

### Net Banking
- Bank account-based payments
- Suitable for larger amounts

### Wallet
- Inter-wallet transfers
- Instant balance updates

> **Note:** Currently, all payments are simulated and processed immediately. For production, integrate with actual payment gateways (Razorpay, Paytm, etc.).

---

## Cashback System

### Calculation Formula
```
Cashback = MIN(Amount × 0.10, 100.00)
```

### Examples
| Amount Added | Cashback Earned |
|--------------|----------------|
| ₹100         | ₹10            |
| ₹500         | ₹50            |
| ₹1000        | ₹100 (max)     |
| ₹5000        | ₹100 (max)     |

### Notification Message
```
"₹{amount} added to your wallet via {payment_method}. You earned ₹{cashback} cashback!"
```

---

## Error Handling

### Frontend Validation Errors
1. **Empty Amount**: "Please enter a valid amount"
2. **Invalid Amount**: "Please enter a valid amount"
3. **Negative Amount**: "Please enter a valid amount"
4. **No Payment Method**: "Please select a payment method"

### Backend Validation Errors
1. **Missing Username**: 400 - "username is required"
2. **User Not Found**: 404 - "User not found"
3. **Invalid Amount**: 400 - "Amount must be positive"
4. **Invalid Payment Method**: 400 - "Invalid payment method. Choose from: UPI, Credit/Debit Card, Net Banking, Wallet"

### Network Errors
- Displays error message with exception details
- Loading indicator is dismissed
- User can retry the operation

---

## Database Schema Impact

### Wallet Table
```python
class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    updated_at = models.DateTimeField(auto_now=True)
```

**Updates:** `balance` field is incremented, `updated_at` is auto-updated

### WalletTransaction Table
```python
class WalletTransaction(models.Model):
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10)  # 'credit' or 'debit'
    reason = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
```

**New Record:** Created with type='credit' and reason='Added funds via {payment_method}'

### Notification Table
```python
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=50)  # 'reward'
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

**New Record:** Created with type='reward' and cashback details

---

## Testing Recommendations

### Manual Testing Checklist
- [ ] Test with various amounts (small, large, decimal)
- [ ] Test with each payment method (UPI, Card, Net Banking, Wallet)
- [ ] Verify balance updates correctly
- [ ] Verify transaction appears in history
- [ ] Verify notification is created
- [ ] Test validation errors (negative, zero, empty)
- [ ] Test network error handling
- [ ] Verify cashback calculation for different amounts
- [ ] Test concurrent add funds operations
- [ ] Verify decimal precision (e.g., 100.50)

### Test Scenarios

#### Scenario 1: Successful UPI Top-up
1. Amount: ₹500
2. Method: UPI
3. Expected: Balance +500, Cashback ₹50, Success notification

#### Scenario 2: Maximum Cashback
1. Amount: ₹2000
2. Method: Credit/Debit Card
3. Expected: Balance +2000, Cashback ₹100 (capped)

#### Scenario 3: Validation Error
1. Amount: -100
2. Method: UPI
3. Expected: Error message "Amount must be positive"

#### Scenario 4: Small Amount
1. Amount: ₹50
2. Method: Wallet
3. Expected: Balance +50, Cashback ₹5

---

## Security Considerations

### Current Implementation
- No authentication required (AllowAny permission)
- Username passed in request body
- No payment gateway integration (simulated)

### Production Recommendations
1. **Add Authentication**: Use `IsAuthenticated` permission class
2. **Use Request User**: Get username from `request.user` instead of request body
3. **Payment Gateway**: Integrate with Razorpay/Paytm/PayPal
4. **Transaction Verification**: Verify payment before crediting wallet
5. **Rate Limiting**: Prevent abuse with rate limits
6. **Audit Logging**: Log all wallet transactions for compliance
7. **Fraud Detection**: Monitor for suspicious patterns
8. **HTTPS Only**: Ensure all payment communication uses HTTPS

---

## Future Enhancements

### 1. Payment Gateway Integration
- Razorpay for UPI/Cards
- Paytm for wallet payments
- PayU for net banking

### 2. Saved Payment Methods
- Store encrypted card details
- Quick pay with saved methods
- OTP verification for security

### 3. Auto Top-up
- Set minimum balance threshold
- Automatic recharge when balance is low
- Configurable top-up amount

### 4. Promotional Offers
- Bonus cashback on first top-up
- Special offers on specific payment methods
- Referral bonuses

### 5. Transaction Limits
- Daily/monthly top-up limits
- Maximum single transaction amount
- KYC-based limit increases

### 6. Payment History Export
- Download transaction history as PDF/CSV
- Email receipts for each top-up
- Monthly wallet statements

---

## Related Documentation
- [API_REFERENCE.md](API_REFERENCE.md) - Complete API documentation
- [NOTIFICATION_SYSTEM_DOCUMENTATION.md](NOTIFICATION_SYSTEM_DOCUMENTATION.md) - Notification system details
- [PAYMENT_METHODS_INTEGRATION.md](PAYMENT_METHODS_INTEGRATION.md) - Payment methods overview

---

## Support

For issues or questions regarding the Add Funds feature, contact the development team or refer to the main project README.
