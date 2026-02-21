from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
import random
import string
from .models import UserProfile, UserUtility, GeneratedBill, UtilityBill, Payment, ChatMessage, Wallet, WalletTransaction
from decimal import Decimal
from .serializers import (
    UserSerializer, UserProfileSerializer, 
    UserRegistrationSerializer, UserUtilitySerializer, GeneratedBillSerializer, UtilityBillSerializer, ChatMessageSerializer
)
from rest_framework.authtoken.models import Token


def _has_conversation_access(user: User, user_name: str, provider_name: str) -> bool:
    """Return True if the authenticated `user` can access a conversation
    identified by (`user_name`, `provider_name`).

    Access rules:
      - Superusers and admins can access all conversations.
      - Regular `user` can only access conversations where `user.username == user_name`.
      - `utility` role can access any conversation (relaxed for development).
        If you need stricter enforcement later, map providers to authority
        accounts and compare `provider_name` accordingly.
    """
    try:
        # Admins and superusers: full access
        if getattr(user, 'is_superuser', False):
            return True
        if hasattr(user, 'profile') and user.profile.role == 'admin':
            return True

        # Users: only own conversations
        if hasattr(user, 'profile') and user.profile.role == 'user':
            return user.username.lower() == (user_name or '').lower()

        # Utility authorities: allow access (development-friendly)
        if hasattr(user, 'profile') and user.profile.role == 'utility':
            return True
    except Exception:
        pass
    return False


def _resolve_user_for_bill(bill: UtilityBill):
    """Attempt to resolve the User who owns the given bill via UserUtility.

    Match UserUtility by utility_type and consumer identifier (stored in UtilityBill.consumer_id).
    Returns a `User` instance or None if not found.
    Fallbacks:
      - If no consumer_id match, try matching UtilityBill.consumer_name to UserUtility.user_name.
      - If still not found, try matching UtilityBill.consumer_name to User.username or UserProfile.full_name.
    """
    try:
        util_type = (bill.utility_type or '').lower()
        cid = (bill.consumer_id or '').strip()
        qs = UserUtility.objects.all()

        # Primary match: consumer_id against appropriate field by utility type
        if cid:
            if 'electricity' in util_type:
                qs = qs.filter(utility_type__iexact='Electricity', consumer_number=cid)
            elif 'water' in util_type:
                qs = qs.filter(utility_type__iexact='Water', water_connection_number=cid)
            elif 'gas' in util_type:
                qs = qs.filter(utility_type__iexact='Gas', gas_connection_number=cid)
            elif 'wifi' in util_type or 'internet' in util_type:
                qs = qs.filter(utility_type__iexact='Wifi', wifi_consumer_id=cid)
            elif 'dth' in util_type:
                qs = qs.filter(utility_type__iexact='DTH', dth_subscriber_id=cid)
            util = qs.order_by('-created_at').first()
            if util:
                if util.user_id:
                    return util.user
                uname = (util.user_name or '').strip()
                if uname:
                    user = User.objects.filter(username=uname).first()
                    if user:
                        return user

        # Fallback 1: match by consumer_name to UserUtility.user_name
        cname = (bill.consumer_name or '').strip()
        if cname:
            util = UserUtility.objects.filter(user_name__iexact=cname).order_by('-created_at').first()
            if util:
                if util.user_id:
                    return util.user
                uname = (util.user_name or '').strip()
                if uname:
                    user = User.objects.filter(username=uname).first()
                    if user:
                        return user

        # Fallback 2: match consumer_name to User.username or UserProfile.full_name
        if cname:
            user = User.objects.filter(username__iexact=cname).first()
            if user:
                return user
            profile = UserProfile.objects.filter(full_name__iexact=cname).select_related('user').first()
            if profile:
                return profile.user
        return None
    except Exception:
        return None


@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Register a new user with default 'user' role"""
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(user.profile).data,
            'message': 'User registered successfully with role: user'
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def request_otp(request):
    """Generate and print a 6-digit OTP for the given email.

    Body: { email: str }
    """
    email = (request.data.get('email') or '').strip()
    if not email:
        return Response({'error': 'email is required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        # Find profile by email (or user.email)
        profile = UserProfile.objects.filter(email=email).first()
        if not profile:
            user = User.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'User not found for email'}, status=status.HTTP_404_NOT_FOUND)
            profile = user.profile
        # Generate a 6-digit numeric OTP
        otp = ''.join(random.choices(string.digits, k=6))
        expires = timezone.now() + timezone.timedelta(minutes=10)
        profile.otp_code = otp
        profile.otp_expires_at = expires
        profile.otp_verified = False
        profile.save(update_fields=['otp_code', 'otp_expires_at', 'otp_verified'])
        print(f"OTP for {email}: {otp}")
        return Response({'message': 'OTP generated', 'ttl_minutes': 10}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': f'Failed to generate OTP: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def verify_otp(request):
    """Verify OTP for the given email.

    Body: { email: str, otp: str }
    """
    email = (request.data.get('email') or '').strip()
    otp = (request.data.get('otp') or '').strip()
    if not email or not otp:
        return Response({'error': 'email and otp are required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        profile = UserProfile.objects.filter(email=email).first()
        if not profile:
            user = User.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'User not found for email'}, status=status.HTTP_404_NOT_FOUND)
            profile = user.profile
        if not profile.otp_code:
            return Response({'error': 'OTP not requested'}, status=status.HTTP_400_BAD_REQUEST)
        if profile.otp_expires_at and timezone.now() > profile.otp_expires_at:
            return Response({'error': 'OTP expired'}, status=status.HTTP_400_BAD_REQUEST)
        if otp != profile.otp_code:
            return Response({'error': 'Invalid OTP'}, status=status.HTTP_400_BAD_REQUEST)
        profile.otp_verified = True
        # Clear OTP to prevent reuse
        profile.otp_code = ''
        profile.otp_expires_at = None
        profile.save(update_fields=['otp_verified', 'otp_code', 'otp_expires_at'])
        return Response({'message': 'OTP verified successfully'}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': f'Failed to verify OTP: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """Login user"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response({
            'error': 'Please provide both username and password'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    user = authenticate(username=username, password=password)
    if user:
        login(request, user)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(user.profile).data,
            'token': token.key,
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)
    
    return Response({
        'error': 'Invalid credentials'
    }, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """Logout user"""
    logout(request)
    return Response({
        'message': 'Logout successful'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def current_user(request):
    """Get current user details"""
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([AllowAny])  # Temporarily allow any for testing
@csrf_exempt
def add_utility_authority(request):
    """Add a new utility authority user (Admin only)"""
    # Check if user is admin (skip check for now during testing)
    # if not hasattr(request.user, 'profile') or request.user.profile.role != 'admin':
    #     return Response({
    #         'error': 'Only admins can add utility authorities'
    #     }, status=status.HTTP_403_FORBIDDEN)
    
    name = request.data.get('name')
    email = request.data.get('email')
    contact = request.data.get('contact')
    utility_type = request.data.get('utility_type')
    address = request.data.get('address')
    
    if not name or not email:
        return Response({
            'error': 'Name and email are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Generate username from email (before @)
    username = email.split('@')[0].lower()
    
    # Check if username already exists, append number if needed
    base_username = username
    counter = 1
    while User.objects.filter(username=username).exists():
        username = f"{base_username}{counter}"
        counter += 1
    
    # Generate password in format: Username@123
    password = f"{username}@123"
    
    try:
        # Create Django User
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password
        )
        
        # Create UserProfile with role='utility'
        profile = UserProfile.objects.create(
            user=user,
            full_name=name,
            email=email,
            role='utility',
            phone=contact or '',
            address=address or ''
        )
        
        return Response({
            'message': 'Utility authority registration successfully',
            'username': username,
            'password': password,
            'email': email,
            'name': name,
            'utility_type': utility_type,
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(profile).data
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'error': f'Failed to create utility authority: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


class UserProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for UserProfile"""
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Admins and superusers can view all profiles
        try:
            if getattr(user, 'is_superuser', False) or (
                hasattr(user, 'profile') and user.profile.role == 'admin'
            ):
                return UserProfile.objects.all().order_by('-created_at')
        except Exception:
            # Fallback to self-only if any profile access issue
            pass
        # Regular users: only their own profile
        return UserProfile.objects.filter(user=user).order_by('-created_at')


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def add_user_utility(request):
    """Create a user utility record from Add Bill form."""
    serializer = UserUtilitySerializer(data=request.data)
    if serializer.is_valid():
        utility = serializer.save()
        return Response({
            'message': 'Successfully added',
            'utility': UserUtilitySerializer(utility).data,
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def list_user_utilities(request):
    """List user utilities; filter by user_name if provided."""
    user_name = request.GET.get('user_name')
    provider_name = request.GET.get('provider_name')
    utility_type = request.GET.get('utility_type')
    qs = UserUtility.objects.all().order_by('-created_at')
    if user_name:
        qs = qs.filter(user_name=user_name)
    if provider_name:
        qs = qs.filter(provider_name__iexact=provider_name)
    # New: allow filtering by utility_type (case-insensitive exact)
    if utility_type:
        qs = qs.filter(utility_type__iexact=utility_type)
    data = UserUtilitySerializer(qs, many=True).data
    return Response({'results': data}, status=status.HTTP_200_OK)


@api_view(['GET', 'PUT', 'PATCH', 'DELETE'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def user_utility_detail(request, pk: int):
    """Retrieve/Update/Delete a single user utility by ID."""
    try:
        utility = UserUtility.objects.get(pk=pk)
    except UserUtility.DoesNotExist:
        return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        return Response(UserUtilitySerializer(utility).data, status=status.HTTP_200_OK)

    if request.method in ['PUT', 'PATCH']:
        partial = request.method == 'PATCH'
        serializer = UserUtilitySerializer(utility, data=request.data, partial=partial)
        if serializer.is_valid():
            utility = serializer.save()
            return Response({'message': 'Successfully updated', 'utility': UserUtilitySerializer(utility).data}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    if request.method == 'DELETE':
        utility.delete()
        return Response({'message': 'Deleted'}, status=status.HTTP_200_OK)

    return Response({'error': 'Method not allowed'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def count_user_utilities_by_provider(request):
        """Return count of user utilities for a given provider name.

        Query params:
            - provider_name: case-insensitive provider filter (required)
        """
        provider_name = request.GET.get('provider_name')
        if not provider_name:
                return Response({'error': 'provider_name is required'}, status=status.HTTP_400_BAD_REQUEST)
        count = UserUtility.objects.filter(provider_name__iexact=provider_name).count()
        return Response({'provider_name': provider_name, 'count': count}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def add_generated_bill(request):
    """Persist a generated bill record from the frontend form."""
    serializer = GeneratedBillSerializer(data=request.data)
    if serializer.is_valid():
        bill = serializer.save()
        return Response({'message': 'Bill saved', 'bill': GeneratedBillSerializer(bill).data}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def list_generated_bills(request):
    """List generated bills with optional filters."""
    qs = GeneratedBill.objects.all().order_by('-created_at')
    utility_type = request.GET.get('utility_type')
    consumer_number = request.GET.get('consumer_number')
    water_conn = request.GET.get('water_connection_number')
    gas_id = request.GET.get('gas_consumer_id')
    wifi_id = request.GET.get('wifi_consumer_id')
    dth_id = request.GET.get('dth_subscriber_id')
    provider_name = request.GET.get('provider_name')
    if utility_type:
        qs = qs.filter(utility_type__iexact=utility_type)
    if consumer_number:
        qs = qs.filter(consumer_number=consumer_number)
    if water_conn:
        qs = qs.filter(water_connection_number=water_conn)
    if gas_id:
        qs = qs.filter(gas_consumer_id=gas_id)
    if wifi_id:
        qs = qs.filter(wifi_consumer_id=wifi_id)
    if dth_id:
        qs = qs.filter(dth_subscriber_id=dth_id)
    if provider_name:
        qs = qs.filter(provider_name__iexact=provider_name)
    data = GeneratedBillSerializer(qs, many=True).data
    return Response({'results': data}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def last_reading(request):
    """Return the last current_reading for a given identifier and utility_type.

    Query params:
      - utility_type: Electricity | Water | Gas (required)
      - consumer_number (for Electricity)
      - water_connection_number (for Water)
      - gas_consumer_id (for Gas)
    """
    utility_type = (request.GET.get('utility_type') or '').strip()
    if not utility_type:
        return Response({'error': 'utility_type is required'}, status=status.HTTP_400_BAD_REQUEST)

    qs = GeneratedBill.objects.filter(utility_type__iexact=utility_type)
    identifier_applied = False
    if 'electricity' in utility_type.lower():
        cn = request.GET.get('consumer_number')
        if cn:
            qs = qs.filter(consumer_number=cn)
            identifier_applied = True
    elif 'water' in utility_type.lower():
        w = request.GET.get('water_connection_number')
        if w:
            qs = qs.filter(water_connection_number=w)
            identifier_applied = True
    elif 'gas' in utility_type.lower():
        g = request.GET.get('gas_consumer_id')
        if g:
            qs = qs.filter(gas_consumer_id=g)
            identifier_applied = True

    if not identifier_applied:
        return Response({'error': 'Missing required identifier for the given utility_type'}, status=status.HTTP_400_BAD_REQUEST)

    last = qs.order_by('-reading_date', '-created_at').first()
    if not last:
        return Response({'current_reading': None}, status=status.HTTP_200_OK)
    return Response({'current_reading': last.current_reading}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def add_utility_bill(request):
    """Persist a minimal bill record in `utility_bill` table."""
    serializer = UtilityBillSerializer(data=request.data)
    if serializer.is_valid():
        bill = serializer.save()
        return Response({'message': 'Utility bill saved', 'bill': UtilityBillSerializer(bill).data}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def list_utility_bills(request):
    qs = UtilityBill.objects.all().order_by('-created_at')
    utility_type = request.GET.get('utility_type')
    bill_id = request.GET.get('bill_id')
    consumer_id = request.GET.get('consumer_id')
    provider_name = request.GET.get('provider_name')
    if utility_type:
        qs = qs.filter(utility_type__iexact=utility_type)
    if bill_id:
        qs = qs.filter(bill_id=bill_id)
    if consumer_id:
        qs = qs.filter(consumer_id=consumer_id)
    # New: filter by provider_name (case-insensitive) when provided
    if provider_name:
        qs = qs.filter(provider_name__iexact=provider_name)
    data = UtilityBillSerializer(qs, many=True).data
    return Response({'results': data}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated with admin role check
@csrf_exempt
def set_user_active(request):
    """Set a user's is_active flag.

    Body: { user_id?: int, username?: str, is_active: bool }
    """
    user_id = request.data.get('user_id')
    username = request.data.get('username')
    is_active = request.data.get('is_active')
    if is_active is None:
        return Response({'error': 'is_active is required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        if user_id:
            user = User.objects.get(id=user_id)
        elif username:
            user = User.objects.get(username=username)
        else:
            return Response({'error': 'user_id or username is required'}, status=status.HTTP_400_BAD_REQUEST)
        user.is_active = bool(is_active)
        user.save(update_fields=['is_active'])
        return Response({'message': 'User activation updated', 'user': UserSerializer(user).data}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated with admin role check
@csrf_exempt
def delete_user_account(request):
    """Delete a user account (and cascade delete the profile). Query params or body can provide user_id or username."""
    user_id = request.data.get('user_id') or request.GET.get('user_id')
    username = request.data.get('username') or request.GET.get('username')
    try:
        if user_id:
            user = User.objects.get(id=int(user_id))
        elif username:
            user = User.objects.get(username=username)
        else:
            return Response({'error': 'user_id or username is required'}, status=status.HTTP_400_BAD_REQUEST)
        user.delete()
        return Response({'message': 'User deleted'}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def add_payment(request):
    """Create a payment record for a given bill_id and amount."""
    bill_id = (request.data.get('bill_id') or '').strip()
    amount = request.data.get('amount')
    method = (request.data.get('payment_method') or 'online').strip()

    if not bill_id or amount is None:
        return Response({'error': 'bill_id and amount are required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        bill = UtilityBill.objects.get(bill_id=bill_id)
    except UtilityBill.DoesNotExist:
        return Response({'error': 'Bill not found'}, status=status.HTTP_404_NOT_FOUND)

    try:
        payment = Payment.objects.create(bill=bill, amount=amount, payment_method=method)
        return Response({'message': 'Payment recorded', 'payment': {
            'id': payment.id,
            'bill_id': bill.bill_id,
            'amount': str(payment.amount),
            'payment_method': payment.payment_method,
            'payment_date': payment.payment_date,
            'status': payment.status,
        }}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': f'Failed to record payment: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def list_payments(request):
    """List all payments with optional filter by bill_id."""
    bill_id = request.GET.get('bill_id')
    status_filter = request.GET.get('status')
    qs = Payment.objects.all().order_by('-payment_date')
    if bill_id:
        qs = qs.filter(bill__bill_id=bill_id)
    if status_filter:
        qs = qs.filter(status__iexact=status_filter)
    # Simple serializer output
    results = [{
        'id': p.id,
        'bill_id': p.bill.bill_id,
        'amount': str(p.amount),
        'payment_method': p.payment_method,
        'payment_date': p.payment_date,
        'status': p.status,
    } for p in qs]
    return Response({'results': results}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def approve_payment(request):
    """Mark a payment as approved.

    Body: { id: int }
    """
    pid = request.data.get('id')
    if not pid:
        return Response({'error': 'id is required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        payment = Payment.objects.get(id=int(pid))
    except (Payment.DoesNotExist, ValueError):
        return Response({'error': 'Payment not found'}, status=status.HTTP_404_NOT_FOUND)
    payment.status = 'approved'
    payment.save(update_fields=['status'])

    # Rewards: credit wallet based on bill amount and improvement vs previous
    try:
        bill = payment.bill
        reward_small_bill = Decimal('0')
        reward_reduction = Decimal('0')
        current_amount = bill.total_amount or Decimal('0')

        # Rule 1: If bill amount < 100, reward 50
        if bill.total_amount is not None and current_amount < Decimal('100'):
            reward_small_bill = Decimal('50')

        # Rule 2: If current bill amount at least 200 less than previous bill, reward 100
        prev_bill = UtilityBill.objects.filter(
            utility_type__iexact=bill.utility_type,
            consumer_id=bill.consumer_id,
            created_at__lt=bill.created_at,
        ).order_by('-created_at').first()
        if prev_bill and prev_bill.total_amount is not None and bill.total_amount is not None:
            diff = prev_bill.total_amount - bill.total_amount
            if diff >= Decimal('200'):
                reward_reduction = Decimal('100')

        # Choose the higher applicable reward (avoid double-award per bill)
        reward_amount = max(reward_small_bill, reward_reduction)

        if reward_amount > 0:
            # Prevent duplicate reward for same payment
            already = WalletTransaction.objects.filter(payment=payment, reason__icontains='Reward').exists()
            if not already:
                user = _resolve_user_for_bill(bill)
                if user is not None:
                    wallet, _ = Wallet.objects.get_or_create(user=user)
                    wallet.balance = (wallet.balance or Decimal('0')) + reward_amount
                    wallet.save(update_fields=['balance', 'updated_at'])
                    # Reason message
                    if reward_amount == reward_reduction:
                        reason = 'Reward: big reduction (>=200 vs previous)'
                    else:
                        reason = 'Reward: small bill (<100)'
                    WalletTransaction.objects.create(
                        wallet=wallet,
                        amount=reward_amount,
                        type='credit',
                        reason=reason,
                        payment=payment,
                    )
    except Exception:
        # Silently ignore reward calculation issues
        pass

    return Response({'message': 'Payment approved', 'id': payment.id, 'status': payment.status}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Consider switching to IsAuthenticated later
@csrf_exempt
def reject_payment(request):
    """Mark a payment as rejected.

    Body: { id: int }
    """
    pid = request.data.get('id')
    if not pid:
        return Response({'error': 'id is required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        payment = Payment.objects.get(id=int(pid))
    except (Payment.DoesNotExist, ValueError):
        return Response({'error': 'Payment not found'}, status=status.HTTP_404_NOT_FOUND)
    payment.status = 'rejected'
    payment.save(update_fields=['status'])

    # Credit refund to user's wallet if bill owner can be resolved
    user = _resolve_user_for_bill(payment.bill)
    if user is not None:
        wallet, _ = Wallet.objects.get_or_create(user=user)
        try:
            # Update balance
            wallet.balance = (wallet.balance or 0) + (payment.amount or 0)
            wallet.save(update_fields=['balance', 'updated_at'])
            # Log transaction
            WalletTransaction.objects.create(
                wallet=wallet,
                amount=payment.amount,
                type='credit',
                reason=f"Refund for rejected payment {payment.bill.bill_id}",
                payment=payment,
            )
        except Exception:
            pass

    return Response({'message': 'Payment rejected and refunded to wallet', 'id': payment.id, 'status': payment.status}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])  # Keep open to avoid auth header requirements for now
@csrf_exempt
def wallet_balance(request):
    """Return wallet balance for a given username (query param) or current user.

    Query: username? If missing and user is authenticated, uses request.user.
    """
    username = (request.GET.get('username') or '').strip()
    user = None
    if username:
        user = User.objects.filter(username=username).first()
    elif request.user and request.user.is_authenticated:
        user = request.user
    if not user:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    wallet, _ = Wallet.objects.get_or_create(user=user)
    return Response({'username': user.username, 'balance': str(wallet.balance), 'currency': 'INR'}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])  # Keep open to avoid auth header requirements for now
@csrf_exempt
def wallet_transactions(request):
    """List recent wallet transactions for a username.

    Query: username, limit? (default 20)
    """
    username = (request.GET.get('username') or '').strip()
    limit = int((request.GET.get('limit') or '20').strip() or '20')
    user = User.objects.filter(username=username).first()
    if not user:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    wallet, _ = Wallet.objects.get_or_create(user=user)
    txns = wallet.transactions.all().order_by('-created_at')[:limit]
    results = [{
        'id': t.id,
        'amount': str(t.amount),
        'type': t.type,
        'reason': t.reason,
        'payment_id': t.payment_id,
        'created_at': t.created_at,
    } for t in txns]
    return Response({'username': user.username, 'results': results}, status=status.HTTP_200_OK)


# ------------------------
# Chat endpoints
# ------------------------

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@csrf_exempt
def chat_thread(request):
    """Return messages for a (user_name, provider_name) conversation.

    Query params: user_name, provider_name (required)
    """
    user_name = (request.GET.get('user_name') or '').strip()
    provider_name = (request.GET.get('provider_name') or '').strip()
    if not user_name or not provider_name:
        return Response({'error': 'user_name and provider_name are required'}, status=status.HTTP_400_BAD_REQUEST)

    # Enforce per-conversation access control
    if not _has_conversation_access(request.user, user_name, provider_name):
        return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
    qs = ChatMessage.objects.filter(
        user_name=user_name,
        provider_name__iexact=provider_name
    ).order_by('created_at')
    data = ChatMessageSerializer(qs, many=True).data
    return Response({'results': data}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@csrf_exempt
def chat_send(request):
    """Send a message in a conversation.

    Body: { user_name, provider_name, text, sender_role?, sender_username? }
    If authenticated, sender_username defaults to request.user.username.
    """
    payload = request.data.copy()
    user_name = (payload.get('user_name') or '').strip()
    provider_name = (payload.get('provider_name') or '').strip()
    if not user_name or not provider_name:
        return Response({'error': 'user_name and provider_name are required'}, status=status.HTTP_400_BAD_REQUEST)

    # Enforce per-conversation access control
    if not _has_conversation_access(request.user, user_name, provider_name):
        return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)

    # Normalize sender identity from authenticated user
    payload['sender_username'] = request.user.username
    try:
        role = request.user.profile.role if hasattr(request.user, 'profile') else 'user'
    except Exception:
        role = 'user'
    payload['sender_role'] = role

    serializer = ChatMessageSerializer(data=payload)
    if serializer.is_valid():
        msg = serializer.save()
        return Response({'message': 'sent', 'data': ChatMessageSerializer(msg).data}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
