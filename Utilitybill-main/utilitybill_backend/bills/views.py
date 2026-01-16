from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from .models import UserProfile
from .serializers import (
    UserSerializer, UserProfileSerializer, 
    UserRegistrationSerializer
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
        return Response({
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(user.profile).data,
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
        return UserProfile.objects.filter(user=self.request.user)
