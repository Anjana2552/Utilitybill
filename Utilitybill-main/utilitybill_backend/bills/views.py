from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from .models import UserProfile, UserUtility, GeneratedBill, UtilityBill, Payment
from .serializers import (
    UserSerializer, UserProfileSerializer, 
    UserRegistrationSerializer, UserUtilitySerializer, GeneratedBillSerializer, UtilityBillSerializer
)
from rest_framework.authtoken.models import Token


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
    qs = UserUtility.objects.all().order_by('-created_at')
    if user_name:
        qs = qs.filter(user_name=user_name)
    if provider_name:
        qs = qs.filter(provider_name__iexact=provider_name)
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
    if utility_type:
        qs = qs.filter(utility_type__iexact=utility_type)
    if bill_id:
        qs = qs.filter(bill_id=bill_id)
    if consumer_id:
        qs = qs.filter(consumer_id=consumer_id)
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
    return Response({'message': 'Payment rejected', 'id': payment.id, 'status': payment.status}, status=status.HTTP_200_OK)
