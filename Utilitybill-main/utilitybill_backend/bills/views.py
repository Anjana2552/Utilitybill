from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.db.models import Count
import random
import string
from .models import UserProfile, UserUtility, GeneratedBill, UtilityBill, Payment, ChatMessage, Wallet, WalletTransaction, PaymentMethod, Notification, Review
from decimal import Decimal, InvalidOperation
from .serializers import (
    UserSerializer, UserProfileSerializer, 
    UserRegistrationSerializer, UserUtilitySerializer, GeneratedBillSerializer, UtilityBillSerializer, ChatMessageSerializer, PaymentMethodSerializer, NotificationSerializer, ReviewSerializer
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
        
        print(f"[RESOLVE_USER] Looking for user for bill: utility_type={util_type}, consumer_id={cid}")
        
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
            print(f"[RESOLVE_USER] Primary match ({util_type}): Found util={util is not None}")
            
            if util:
                if util.user_id:
                    print(f"[RESOLVE_USER] Resolved to user: {util.user.username}")
                    return util.user
                uname = (util.user_name or '').strip()
                if uname:
                    user = User.objects.filter(username__iexact=uname).first()
                    if user:
                        print(f"[RESOLVE_USER] Resolved via user_name: {user.username}")
                        return user

        # Fallback 1: match by consumer_name to UserUtility.user_name
        cname = (bill.consumer_name or '').strip()
        print(f"[RESOLVE_USER] Fallback 1 - consumer_name={cname}")
        if cname:
            util = UserUtility.objects.filter(user_name__iexact=cname).order_by('-created_at').first()
            if util:
                if util.user_id:
                    print(f"[RESOLVE_USER] Fallback 1 resolved: {util.user.username}")
                    return util.user
                uname = (util.user_name or '').strip()
                if uname:
                    user = User.objects.filter(username__iexact=uname).first()
                    if user:
                        print(f"[RESOLVE_USER] Fallback 1 via username: {user.username}")
                        return user

        # Fallback 2: match consumer_name to User.username or UserProfile.full_name
        print(f"[RESOLVE_USER] Fallback 2")
        if cname:
            user = User.objects.filter(username__iexact=cname).first()
            if user:
                print(f"[RESOLVE_USER] Fallback 2 resolved: {user.username}")
                return user
            profile = UserProfile.objects.filter(full_name__iexact=cname).select_related('user').first()
            if profile:
                print(f"[RESOLVE_USER] Fallback 2 via profile: {profile.user.username}")
                return profile.user
        
        print(f"[RESOLVE_USER] FAILED to resolve user for bill {bill.bill_id}")
        return None
    except Exception as e:
        print(f"[RESOLVE_USER] ERROR: {e}")
        return None


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
@csrf_exempt
def reset_password_otp(request):
    """Reset password using OTP verification.

    Body: { email: str, otp: str, new_password: str }
    """
    email = (request.data.get('email') or '').strip()
    otp = (request.data.get('otp') or '').strip()
    new_password = request.data.get('new_password', '').strip()
    
    if not email or not otp or not new_password:
        return Response(
            {'error': 'email, otp, and new_password are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Find user profile by email
        profile = UserProfile.objects.filter(email=email).first()
        if not profile:
            user = User.objects.filter(email=email).first()
            if not user:
                return Response(
                    {'error': 'User not found for email'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            profile = user.profile
        
        # Verify OTP hasn't been used
        if not profile.otp_code:
            return Response(
                {'error': 'OTP not requested or already used'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check OTP expiration
        if profile.otp_expires_at and timezone.now() > profile.otp_expires_at:
            return Response(
                {'error': 'OTP has expired. Please request a new one.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verify OTP code
        if otp != profile.otp_code:
            return Response(
                {'error': 'Invalid OTP code'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # All checks passed - reset the password
        user = profile.user
        user.set_password(new_password)
        user.save()
        
        # Clear OTP data to prevent reuse
        profile.otp_code = ''
        profile.otp_expires_at = None
        profile.otp_verified = True
        profile.save(update_fields=['otp_code', 'otp_expires_at', 'otp_verified'])
        
        return Response(
            {'message': 'Password reset successful. You can now login with your new password.'}, 
            status=status.HTTP_200_OK
        )
        
    except Exception as e:
        return Response(
            {'error': f'Failed to reset password: {str(e)}'}, 
            status=status.HTTP_400_BAD_REQUEST
        )


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
            address=address or '',
            utility_type=(utility_type or '').strip(),
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
    """Persist a generated bill record from the frontend form and create notifications for matching users."""
    print(f"[BILL ADD] Received bill data: {request.data}")
    serializer = GeneratedBillSerializer(data=request.data)
    if serializer.is_valid():
        bill = serializer.save()
        print(f"[BILL ADD] Bill saved: {bill.bill_id}, Type: {bill.utility_type}, Provider: {bill.provider_name}")
        
        # Create notifications for users who have this utility
        matching_users = []
        utility_type = bill.utility_type.lower()
        print(f"[BILL ADD] Looking for users with utility_type={utility_type}")
        
        # Find matching users based on utility type and consumer identifiers
        if utility_type == 'electricity' and bill.consumer_number:
            print(f"[BILL ADD] Searching for electricity users with consumer_number={bill.consumer_number}")
            matching_utilities = UserUtility.objects.filter(
                utility_type__iexact='electricity',
                consumer_number=bill.consumer_number
            ).select_related('user')
            matching_users = [uu.user for uu in matching_utilities if uu.user]
            
        elif utility_type == 'water' and bill.water_connection_number:
            matching_utilities = UserUtility.objects.filter(
                utility_type__iexact='water',
                water_connection_number=bill.water_connection_number
            ).select_related('user')
            matching_users = [uu.user for uu in matching_utilities if uu.user]
            
        elif utility_type == 'gas' and bill.gas_consumer_id:
            matching_utilities = UserUtility.objects.filter(
                utility_type__iexact='gas',
                gas_connection_number=bill.gas_consumer_id
            ).select_related('user')
            matching_users = [uu.user for uu in matching_utilities if uu.user]
            
        elif utility_type == 'wifi' and bill.wifi_consumer_id:
            print(f"[BILL ADD] Searching for WiFi users with wifi_consumer_id={bill.wifi_consumer_id}")
            matching_utilities = UserUtility.objects.filter(
                utility_type__iexact='wifi',
                wifi_consumer_id=bill.wifi_consumer_id
            ).select_related('user')
            matching_users = [uu.user for uu in matching_utilities if uu.user]
            print(f"[BILL ADD] Found {len(matching_users)} WiFi users: {[u.username for u in matching_users]}")
            
        elif utility_type == 'dth' and bill.dth_subscriber_id:
            print(f"[BILL ADD] Searching for DTH users with dth_subscriber_id={bill.dth_subscriber_id}")
            matching_utilities = UserUtility.objects.filter(
                utility_type__iexact='dth',
                dth_subscriber_id=bill.dth_subscriber_id
            ).select_related('user')
            matching_users = [uu.user for uu in matching_utilities if uu.user]
            print(f"[BILL ADD] Found {len(matching_users)} DTH users: {[u.username for u in matching_users]}")
        
        # Create notifications for all matching users
        if not matching_users:
            print(f"[BILL ADD] ⚠️ No matching users found for {utility_type} bill {bill.bill_id}")
        
        notifications_created = 0
        for user in matching_users:
            due_date_str = bill.due_date.strftime('%B %d, %Y') if bill.due_date else 'N/A'
            notification = _create_notification(
                user=user,
                notification_type='bill_generated',
                title=f'New {bill.utility_type} Bill Generated',
                message=f'A new bill for {bill.utility_type} ({bill.provider_name or "your provider"}) has been generated. Amount: ₹{bill.total_amount or 0}. Due date: {due_date_str}',
                utility_type=bill.utility_type,
                bill_id_ref=bill.bill_id,
                due_date=bill.due_date
            )
            if notification:
                notifications_created += 1
        
        print(f"[BILL GENERATED] Bill {bill.bill_id} created → {notifications_created} notifications sent to users")
        
        return Response({
            'message': 'Bill saved', 
            'bill': GeneratedBillSerializer(bill).data,
            'notifications_created': notifications_created
        }, status=status.HTTP_201_CREATED)
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
    print(f"[UTILITY BILL ADD] Received data: {request.data}")
    serializer = UtilityBillSerializer(data=request.data)
    if serializer.is_valid():
        bill = serializer.save()
        print(f"[UTILITY BILL ADD] Bill saved: {bill.bill_id}, Type: {bill.utility_type}, Consumer: {bill.consumer_id}")
        
        # Create notifications for matching users
        matching_users = []
        utility_type = bill.utility_type.lower() if bill.utility_type else ''
        consumer_id = bill.consumer_id or ''
        
        print(f"[UTILITY BILL ADD] Looking for users with utility_type={utility_type}, consumer_id={consumer_id}")
        
        if not consumer_id:
            print(f"[UTILITY BILL ADD] ⚠️ No consumer_id provided, cannot match users")
        else:
            # Find matching users based on utility type and consumer identifier
            if utility_type == 'electricity':
                matching_utilities = UserUtility.objects.filter(
                    utility_type__iexact='electricity',
                    consumer_number=consumer_id
                ).select_related('user')
                matching_users = [uu.user for uu in matching_utilities if uu.user]
                
            elif utility_type == 'water':
                matching_utilities = UserUtility.objects.filter(
                    utility_type__iexact='water',
                    water_connection_number=consumer_id
                ).select_related('user')
                matching_users = [uu.user for uu in matching_utilities if uu.user]
                
            elif utility_type == 'gas':
                matching_utilities = UserUtility.objects.filter(
                    utility_type__iexact='gas',
                    gas_connection_number=consumer_id
                ).select_related('user')
                matching_users = [uu.user for uu in matching_utilities if uu.user]
                
            elif utility_type == 'wifi':
                matching_utilities = UserUtility.objects.filter(
                    utility_type__iexact='wifi',
                    wifi_consumer_id=consumer_id
                ).select_related('user')
                matching_users = [uu.user for uu in matching_utilities if uu.user]
                
            elif utility_type == 'dth':
                matching_utilities = UserUtility.objects.filter(
                    utility_type__iexact='dth',
                    dth_subscriber_id=consumer_id
                ).select_related('user')
                matching_users = [uu.user for uu in matching_utilities if uu.user]
        
            print(f"[UTILITY BILL ADD] Found {len(matching_users)} matching users: {[u.username for u in matching_users]}")
        
        # Create notifications for all matching users
        notifications_created = 0
        for user in matching_users:
            amount = bill.total_amount or 0
            notification = _create_notification(
                user=user,
                notification_type='bill_generated',
                title=f'New {bill.utility_type} Bill Generated',
                message=f'A new bill (ID: {bill.bill_id}) for {bill.utility_type} has been generated. Amount: ₹{amount}. Please check your bills section.',
                utility_type=bill.utility_type,
                bill_id_ref=bill.bill_id,
                due_date=None
            )
            if notification:
                notifications_created += 1
        
        print(f"[UTILITY BILL ADD] ✓ Bill {bill.bill_id} saved → {notifications_created} notifications created")
        
        return Response({
            'message': 'Utility bill saved', 
            'bill': UtilityBillSerializer(bill).data,
            'notifications_created': notifications_created
        }, status=status.HTTP_201_CREATED)
    
    print(f"[UTILITY BILL ADD] ✗ Validation failed: {serializer.errors}")
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
        # If payment uses wallet, deduct balance first
        if method == 'wallet':
            user = _resolve_user_for_bill(bill)
            if user is None:
                return Response({'error': 'User not found for bill'}, status=status.HTTP_404_NOT_FOUND)
            wallet, _ = Wallet.objects.get_or_create(user=user)
            amount_dec = Decimal(str(amount))
            if wallet.balance is None or wallet.balance < amount_dec:
                return Response(
                    {'error': 'Insufficient wallet balance'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            wallet.balance = (wallet.balance or Decimal('0')) - amount_dec
            wallet.save(update_fields=['balance', 'updated_at'])
            WalletTransaction.objects.create(
                wallet=wallet,
                amount=amount_dec,
                type='debit',
                reason=f"Wallet payment for bill {bill_id}",
                payment=None,
            )

        payment = Payment.objects.create(bill=bill, amount=amount, payment_method=method)
        
        # Create notification for the user
        user = _resolve_user_for_bill(bill)
        if user:
            _create_notification(
                user=user,
                notification_type='payment_initiated',
                title='Payment Initiated',
                message=f'Payment of ₹{amount} for {bill.utility_type} bill has been initiated. Bill ID: {bill_id}',
                utility_type=bill.utility_type,
                bill_id_ref=bill_id
            )

        # Create notification for utility authority
        authority_user = _resolve_utility_authority_user(bill.utility_type)
        if authority_user and user:
            _create_authority_notification(
                user=authority_user,
                notification_type='payment_initiated',
                title='Payment Initiated',
                message=f'User {user.username} initiated payment for {bill.utility_type} bill {bill_id} (₹{amount}).',
                utility_type=bill.utility_type,
                bill_id_ref=bill_id,
            )
        
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

    # Create notification for payment approved
    user = _resolve_user_for_bill(payment.bill)
    if user:
        _create_notification(
            user=user,
            notification_type='payment_approved',
            title='Payment Approved',
            message=f'Your payment of ₹{payment.amount} for {payment.bill.utility_type} bill has been approved. Thank you!',
            utility_type=payment.bill.utility_type,
            bill_id_ref=payment.bill.bill_id
        )
        authority_user = _resolve_utility_authority_user(payment.bill.utility_type)
        if authority_user:
            _create_authority_notification(
                user=authority_user,
                notification_type='payment_approved',
                title='Payment Approved',
                message=f'User {user.username} payment approved for {payment.bill.utility_type} bill {payment.bill.bill_id} (₹{payment.amount}).',
                utility_type=payment.bill.utility_type,
                bill_id_ref=payment.bill.bill_id,
            )

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
                    
                    # Create reward notification
                    _create_notification(
                        user=user,
                        notification_type='reward_earned',
                        title='Reward Earned!',
                        message=f'Congratulations! You earned ₹{reward_amount} as reward. Reason: {reason}. Check your wallet.',
                        utility_type=bill.utility_type,
                        bill_id_ref=bill.bill_id
                    )
    except Exception as e:
        # Silently ignore reward calculation issues
        print(f"Error calculating rewards: {e}")
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
        
        # Create notification for payment rejected
        _create_notification(
            user=user,
            notification_type='payment_rejected',
            title='Payment Rejected',
            message=f'Your payment of ₹{payment.amount} for {payment.bill.utility_type} bill has been rejected. Amount refunded to your wallet.',
            utility_type=payment.bill.utility_type,
            bill_id_ref=payment.bill.bill_id
        )

        authority_user = _resolve_utility_authority_user(payment.bill.utility_type)
        if authority_user:
            _create_authority_notification(
                user=authority_user,
                notification_type='payment_rejected',
                title='Payment Rejected',
                message=f'User {user.username} payment rejected for {payment.bill.utility_type} bill {payment.bill.bill_id} (₹{payment.amount}).',
                utility_type=payment.bill.utility_type,
                bill_id_ref=payment.bill.bill_id,
            )

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


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def wallet_add_funds(request):
    """Add funds to user wallet with payment method selection.

    Body: { username, amount, payment_method }
    - username: User to credit
    - amount: Amount to add (positive number)
    - payment_method: UPI, Credit Card, Bank Transfer
    """
    try:
        username = (request.data.get('username') or '').strip()
        amount_str = (request.data.get('amount') or '').strip()
        payment_method = (request.data.get('payment_method') or '').strip()
        
        # Validate username
        if not username:
            return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = User.objects.filter(username=username).first()
        if not user:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Validate amount
        try:
            amount = Decimal(amount_str)
            if amount <= 0:
                return Response({'error': 'Amount must be positive'}, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, InvalidOperation):
            return Response({'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate payment method
        valid_methods = ['UPI', 'Credit Card', 'Bank Transfer']
        if not payment_method or payment_method not in valid_methods:
            return Response({'error': f'Invalid payment method. Choose from: {", ".join(valid_methods)}'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get or create wallet
        wallet, _ = Wallet.objects.get_or_create(user=user)
        
        # Calculate cashback (10% of added amount, max ₹100)
        cashback = min(amount * Decimal('0.10'), Decimal('100.00'))
        
        # Update wallet balance (including cashback)
        total_credit = amount + cashback
        wallet.balance += total_credit
        wallet.save()
        
        # Create transaction record for the added amount
        txn = WalletTransaction.objects.create(
            wallet=wallet,
            amount=amount,
            type='credit',
            reason=f'Added funds via {payment_method}'
        )
        
        # Create transaction record for cashback
        WalletTransaction.objects.create(
            wallet=wallet,
            amount=cashback,
            type='credit',
            reason=f'Cashback on wallet top-up'
        )
        
        # Create success notification
        try:
            Notification.objects.create(
                user=user,
                type='reward',
                title='Wallet Credited Successfully',
                message=f'₹{amount} added to your wallet via {payment_method}. You earned ₹{cashback} cashback!',
                is_read=False
            )
        except Exception as e:
            # Log notification error but don't fail the transaction
            print(f"Warning: Failed to create notification: {e}")
        
        return Response({
            'success': True,
            'message': f'₹{amount} added successfully',
            'new_balance': str(wallet.balance),
            'cashback': str(cashback),
            'transaction': {
                'id': txn.id,
                'amount': str(txn.amount),
                'type': txn.type,
                'reason': txn.reason,
                'created_at': txn.created_at.isoformat() if txn.created_at else ''
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        # Catch any unexpected errors
        print(f"Error in wallet_add_funds: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Server error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def user_payment_methods(request):
    """Get saved payment methods for a user by username.

    Query: username (required)
    Returns: List of saved payment methods for the user
    """
    username = (request.GET.get('username') or '').strip()
    if not username:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    user = User.objects.filter(username=username).first()
    if not user:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    
    methods = PaymentMethod.objects.filter(user=user).order_by('-created_at')
    results = [{
        'id': m.id,
        'method': m.method,
        'created_at': m.created_at,
    } for m in methods]
    
    return Response({
        'success': True,
        'username': user.username,
        'payment_methods': results
    }, status=status.HTTP_200_OK)


# ------------------------
# Chat endpoints
# ------------------------

@api_view(['GET'])
@permission_classes([AllowAny])
def chat_unread_counts(request):
    """Get unread message counts for each conversation.
    
    Query params:
    - username: The user to get unread counts for
    - role: 'user' or 'utility'
    
    Returns a list of conversations with unread counts.
    """
    username = (request.GET.get('username') or '').strip()
    role = (request.GET.get('role') or 'user').strip().lower()
    
    if not username:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # For users: count messages where sender_role='utility' and is_read=False
    # For utilities: count messages where sender_role='user' and is_read=False
    
    if role == 'utility':
        # Utility sees conversations grouped by user_name
        # Count unread messages from users
        conversations = ChatMessage.objects.filter(
            provider_name__iexact=username,
            sender_role='user',
            is_read=False
        ).values('user_name', 'provider_name').annotate(
            unread_count=Count('id')
        )
        
        results = [
            {
                'key': conv['user_name'],
                'unread_count': conv['unread_count']
            }
            for conv in conversations
        ]
    else:
        # User sees conversations grouped by provider_name
        # Count unread messages from utilities
        conversations = ChatMessage.objects.filter(
            user_name__iexact=username,
            sender_role='utility',
            is_read=False
        ).values('user_name', 'provider_name').annotate(
            unread_count=Count('id')
        )
        
        results = [
            {
                'key': conv['provider_name'],
                'unread_count': conv['unread_count']
            }
            for conv in conversations
        ]
    
    return Response({'unread_counts': results}, status=status.HTTP_200_OK)


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
    
    # Mark messages as read for the current user
    # If user is reading: mark utility messages as read
    # If utility is reading: mark user messages as read
    try:
        user_role = request.user.profile.role if hasattr(request.user, 'profile') else 'user'
    except:
        user_role = 'user'
    
    if user_role.lower() == 'utility':
        # Mark user messages as read
        ChatMessage.objects.filter(
            user_name=user_name,
            provider_name__iexact=provider_name,
            sender_role='user',
            is_read=False
        ).update(is_read=True)
    else:
        # Mark utility messages as read
        ChatMessage.objects.filter(
            user_name=user_name,
            provider_name__iexact=provider_name,
            sender_role='utility',
            is_read=False
        ).update(is_read=True)
    
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

class PaymentMethodViewSet(viewsets.ViewSet):
    """ViewSet for managing user's saved payment methods."""
    permission_classes = [IsAuthenticated]

    def list(self, request):
        """Get all saved payment methods for the current user."""
        methods = PaymentMethod.objects.filter(user=request.user).order_by('-created_at')
        serializer = PaymentMethodSerializer(methods, many=True)
        return Response({'success': True, 'data': serializer.data}, status=status.HTTP_200_OK)

    def create(self, request):
        """Save a new payment method for the current user."""
        data = request.data.copy()
        data['user'] = request.user.id
        
        serializer = PaymentMethodSerializer(data=data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response({
                'success': True, 
                'message': f"{data.get('method', 'Payment method')} saved successfully",
                'data': serializer.data
            }, status=status.HTTP_201_CREATED)
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    def destroy(self, request, pk=None):
        """Delete a saved payment method."""
        try:
            method = PaymentMethod.objects.get(id=pk, user=request.user)
            method.delete()
            return Response({
                'success': True,
                'message': 'Payment method deleted successfully'
            }, status=status.HTTP_204_NO_CONTENT)
        except PaymentMethod.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Payment method not found'
            }, status=status.HTTP_404_NOT_FOUND)


class NotificationViewSet(viewsets.ViewSet):
    """ViewSet for managing user notifications"""
    permission_classes = [IsAuthenticated]

    def list(self, request):
        """Get all notifications for the current user"""
        notifications = Notification.objects.filter(user=request.user).order_by('-created_at')
        serializer = NotificationSerializer(notifications, many=True)
        return Response({
            'success': True,
            'notifications': serializer.data,
            'unread_count': notifications.filter(read=False).count()
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read for the current user"""
        updated_count = Notification.objects.filter(user=request.user, read=False).update(read=True)
        return Response({
            'success': True,
            'message': f'{updated_count} notifications marked as read'
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a specific notification as read"""
        try:
            notification = Notification.objects.get(id=pk, user=request.user)
            notification.read = True
            notification.save()
            return Response({
                'success': True,
                'message': 'Notification marked as read'
            }, status=status.HTTP_200_OK)
        except Notification.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Notification not found'
            }, status=status.HTTP_404_NOT_FOUND)

    def destroy(self, request, pk=None):
        """Delete a notification"""
        try:
            notification = Notification.objects.get(id=pk, user=request.user)
            notification.delete()
            return Response({
                'success': True,
                'message': 'Notification deleted'
            }, status=status.HTTP_204_NO_CONTENT)
        except Notification.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Notification not found'
            }, status=status.HTTP_404_NOT_FOUND)


def _create_due_soon_notifications_for_user(user, days_before=3):
    """Create bill due reminders for unpaid bills that are due soon.

    Uses GeneratedBill records (which include due_date) and matches them
    to the user's utilities. Avoids duplicate notifications per bill.
    """
    try:
        today = timezone.localdate()
        end_date = today + timezone.timedelta(days=days_before)
        utilities = UserUtility.objects.filter(user=user)
        if not utilities.exists():
            return 0

        created = 0
        seen_bill_ids = set()

        for util in utilities:
            util_type = (util.utility_type or '').strip().lower()
            if not util_type:
                continue

            qs = GeneratedBill.objects.filter(
                utility_type__iexact=util.utility_type,
                due_date__isnull=False,
                due_date__gte=today,
                due_date__lte=end_date,
            )

            if util_type == 'electricity' and util.consumer_number:
                qs = qs.filter(consumer_number=util.consumer_number)
            elif util_type == 'water' and util.water_connection_number:
                qs = qs.filter(water_connection_number=util.water_connection_number)
            elif util_type == 'gas' and util.gas_connection_number:
                qs = qs.filter(gas_consumer_id=util.gas_connection_number)
            elif util_type == 'wifi' and util.wifi_consumer_id:
                qs = qs.filter(wifi_consumer_id=util.wifi_consumer_id)
            elif util_type == 'dth' and util.dth_subscriber_id:
                qs = qs.filter(dth_subscriber_id=util.dth_subscriber_id)

            for bill in qs:
                if bill.bill_id in seen_bill_ids:
                    continue
                seen_bill_ids.add(bill.bill_id)

                # Skip if already paid (approved)
                if Payment.objects.filter(
                    bill__bill_id=bill.bill_id,
                    status__iexact='approved',
                ).exists():
                    continue

                # Skip if reminder already exists
                if Notification.objects.filter(
                    user=user,
                    notification_type='bill_due',
                    bill_id=bill.bill_id,
                ).exists():
                    continue

                days_left = (bill.due_date - today).days if bill.due_date else None
                due_str = bill.due_date.strftime('%B %d, %Y') if bill.due_date else 'N/A'
                title = 'Bill due soon'
                if days_left is not None:
                    if days_left == 0:
                        title = 'Bill due today'
                    elif days_left == 1:
                        title = 'Bill due in 1 day'
                    else:
                        title = f'Bill due in {days_left} days'

                amount = bill.total_amount or 0
                message = (
                    f"Your {bill.utility_type} bill (ID: {bill.bill_id}) of ₹{amount} "
                    f"is due on {due_str}. Please pay before the deadline."
                )

                if _create_notification(
                    user=user,
                    notification_type='bill_due',
                    title=title,
                    message=message,
                    utility_type=bill.utility_type,
                    bill_id_ref=bill.bill_id,
                    due_date=bill.due_date,
                ):
                    created += 1

        return created
    except Exception as e:
        print(f"[NOTIFICATION ERROR] Failed to create due reminders: {e}")
        return 0


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def list_notifications_by_username(request):
    """List all notifications for a user by username (unauthenticated endpoint for mobile app)
    
    Query params:
    - username: Required. The username to fetch notifications for
    - utility_type: Optional. If provided, filter by utility_type (for authority notifications)
    """
    username = (request.GET.get('username') or '').strip()
    utility_type_filter = (request.GET.get('utility_type') or '').strip()
    
    if not username:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Case-insensitive username lookup
        user = User.objects.get(username__iexact=username)
        print(f"[NOTIFICATION API] Fetching notifications for user: {user.username} (ID: {user.id})")
    except User.DoesNotExist:
        print(f"[NOTIFICATION API] ✗ User not found with username: {username}")
        return Response({
            'error': f'User not found',
            'requested_username': username
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Start with all notifications for this user
    notifications = Notification.objects.filter(user=user)
    
    # If utility_type is provided, filter by it (for utility authorities)
    if utility_type_filter:
        notifications = notifications.filter(utility_type__iexact=utility_type_filter)
        print(f"[NOTIFICATION API] Filtering by utility_type: {utility_type_filter}")
    
    # Order by newest first
    notifications = notifications.order_by('-created_at')
    
    # Serialize
    serializer = NotificationSerializer(notifications, many=True)
    
    total_count = notifications.count()
    unread_count = notifications.filter(read=False).count()
    
    print(f"[NOTIFICATION API] ✓ Returning {total_count} notifications ({unread_count} unread) for {user.username}")
    if total_count > 0:
        print(f"[NOTIFICATION API] Sample: {notifications.first().notification_type} - {notifications.first().title}")
    
    return Response({
        'success': True,
        'username': user.username,
        'notifications': serializer.data,
        'unread_count': unread_count,
        'total_count': total_count,
        'filtered_by_utility_type': utility_type_filter or None
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def mark_notification_read(request):
    """Mark a notification as read (unauthenticated endpoint for mobile app)"""
    notification_id = request.data.get('id')
    username = (request.data.get('username') or '').strip()
    
    if not notification_id or not username:
        return Response({'error': 'id and username are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(username=username)
        notification = Notification.objects.get(id=notification_id, user=user)
        notification.read = True
        notification.save()
        return Response({
            'success': True,
            'message': 'Notification marked as read'
        }, status=status.HTTP_200_OK)
    except (User.DoesNotExist, Notification.DoesNotExist):
        return Response({
            'success': False,
            'error': 'Notification or user not found'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def notifications_diagnostic(request):
    """Diagnostic endpoint to debug notification issues"""
    username = (request.GET.get('username') or '').strip()
    if not username:
        return Response({'error': 'username is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(username__iexact=username)
    except User.DoesNotExist:
        return Response({
            'error': 'User not found',
            'requested_username': username
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Check notifications
    notifications = Notification.objects.filter(user=user).order_by('-created_at')
    
    # Check UserUtility records
    user_utilities = UserUtility.objects.filter(user=user)
    
    # Check all bills for this user (via UserUtility)
    all_bills = []
    for util in user_utilities:
        consumer_id = util.consumer_id or getattr(util, 'consumer_number', None) or getattr(util, 'water_connection_number', None)
        if consumer_id:
            bills = UtilityBill.objects.filter(consumer_id=consumer_id, utility_type__iexact=util.utility_type)[:5]
            for bill in bills:
                all_bills.append({
                    'bill_id': bill.bill_id,
                    'utility_type': bill.utility_type,
                    'amount': str(bill.total_amount),
                    'due_date': str(bill.due_date)
                })
    
    return Response({
        'success': True,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email
        },
        'notifications': {
            'total': notifications.count(),
            'unread': notifications.filter(read=False).count(),
            'by_type': dict(notifications.values_list('notification_type').distinct().annotate(count=Count('id')).values_list('notification_type', 'count')),
            'sample': NotificationSerializer(notifications[:5], many=True).data
        },
        'user_utilities': {
            'count': user_utilities.count(),
            'list': [{'id': u.id, 'utility_type': u.utility_type, 'provider': u.provider_name} for u in user_utilities]
        },
        'sample_bills': all_bills,
        'debug_info': {
            'user_found': True,
            'notifications_table_count': Notification.objects.count(),
            'total_notifications_in_system': Notification.objects.count()
        }
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def create_notification_manual(request):
    """Admin endpoint to manually create a notification for a user"""
    username = (request.data.get('username') or '').strip()
    notification_type = (request.data.get('notification_type') or '').strip()
    title = (request.data.get('title') or '').strip()
    message = (request.data.get('message') or '').strip()
    utility_type = request.data.get('utility_type', '').strip() or None
    bill_id = request.data.get('bill_id', '').strip() or None
    
    if not username or not notification_type or not title or not message:
        return Response({
            'error': 'username, notification_type, title, and message are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(username__iexact=username)
    except User.DoesNotExist:
        return Response({
            'error': f'User {username} not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    try:
        notification = Notification.objects.create(
            user=user,
            notification_type=notification_type,
            title=title,
            message=message,
            utility_type=utility_type,
            bill_id=bill_id,
            read=False
        )
        print(f"[MANUAL NOTIFICATION] Created for user {user.username}: {notification_type} - {title}")
        return Response({
            'success': True,
            'message': 'Notification created',
            'notification': NotificationSerializer(notification).data
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        print(f"[MANUAL NOTIFICATION ERROR] {e}")
        return Response({
            'error': f'Failed to create notification: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def delete_notification(request):
    """Delete a notification (unauthenticated endpoint for mobile app)"""
    notification_id = request.data.get('id')
    username = (request.data.get('username') or '').strip()
    
    if not notification_id or not username:
        return Response({'error': 'id and username are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(username=username)
        notification = Notification.objects.get(id=notification_id, user=user)
        notification.delete()
        return Response({
            'success': True,
            'message': 'Notification deleted'
        }, status=status.HTTP_200_OK)
    except (User.DoesNotExist, Notification.DoesNotExist):
        return Response({
            'success': False,
            'error': 'Notification or user not found'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def delete_notification_old(request):
    """Delete a notification (unauthenticated endpoint for mobile app) - OLD VERSION"""
    pass


# ==================== REVIEW ENDPOINTS ====================

@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def add_review(request):
    """Add a new review (unauthenticated endpoint for mobile app)"""
    try:
        provider_name = (request.data.get('provider_name') or '').strip()
        utility_type = (request.data.get('utility_type') or '').strip()
        rating = request.data.get('rating')
        message = (request.data.get('message') or '').strip()
        username = (request.data.get('username') or '').strip()
        
        # Validate required fields
        if not all([provider_name, utility_type, rating, message]):
            return Response({
                'error': 'provider_name, utility_type, rating, and message are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate rating
        try:
            rating = int(rating)
            if rating < 1 or rating > 5:
                return Response({
                    'error': 'Rating must be between 1 and 5'
                }, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, TypeError):
            return Response({
                'error': 'Rating must be an integer'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get user if username is provided
        user = None
        if username:
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                pass
        
        # Create review
        review = Review.objects.create(
            user=user,
            provider_name=provider_name,
            utility_type=utility_type,
            rating=rating,
            message=message
        )
        
        serializer = ReviewSerializer(review)
        return Response({
            'success': True,
            'message': 'Review created successfully',
            'review': serializer.data
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        print(f"[REVIEW ERROR] {e}")
        return Response({
            'error': f'Failed to create review: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def list_reviews(request):
    """List reviews by provider or utility type"""
    try:
        provider_name = (request.query_params.get('provider_name') or '').strip()
        utility_type = (request.query_params.get('utility_type') or '').strip()
        
        # Build query
        query = Review.objects.all()
        
        if provider_name:
            query = query.filter(provider_name__iexact=provider_name)
        
        if utility_type:
            query = query.filter(utility_type__iexact=utility_type)
        
        # Order by created_at descending
        query = query.order_by('-created_at')
        
        serializer = ReviewSerializer(query, many=True)
        return Response({
            'success': True,
            'count': query.count(),
            'reviews': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"[REVIEW LIST ERROR] {e}")
        return Response({
            'error': f'Failed to fetch reviews: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def review_stats(request):
    """Get review statistics for a provider"""
    try:
        provider_name = (request.query_params.get('provider_name') or '').strip()
        utility_type = (request.query_params.get('utility_type') or '').strip()
        
        if not provider_name and not utility_type:
            return Response({
                'error': 'provider_name or utility_type is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Build query
        query = Review.objects.all()
        
        if provider_name:
            query = query.filter(provider_name__iexact=provider_name)
        
        if utility_type:
            query = query.filter(utility_type__iexact=utility_type)
        
        # Calculate stats
        total_reviews = query.count()
        avg_rating = 0
        rating_distribution = {
            1: query.filter(rating=1).count(),
            2: query.filter(rating=2).count(),
            3: query.filter(rating=3).count(),
            4: query.filter(rating=4).count(),
            5: query.filter(rating=5).count(),
        }
        
        if total_reviews > 0:
            from django.db.models import Avg
            avg_rating = float(query.aggregate(Avg('rating'))['rating__avg'] or 0)
        
        return Response({
            'success': True,
            'total_reviews': total_reviews,
            'average_rating': round(avg_rating, 2),
            'rating_distribution': rating_distribution
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"[REVIEW STATS ERROR] {e}")
        return Response({
            'error': f'Failed to fetch stats: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)
